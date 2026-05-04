import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/prime256v1.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/ec_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';
import 'package:simulated_smartkey_app/util/app_util.dart';

class AppBluetoothService {
  BluetoothCharacteristic? _authResultChar;
  BluetoothCharacteristic? _credExchangeChar;

  void onStartScanning() {
    AppUtil().log('Start scanning');
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        AppUtil().log('Result ${result.toString()}');
      }
    });
  }

  Future<void> connectDevice(BluetoothDevice device) async {
    await onStop();
    await device.connect(license: License.free, timeout: Duration(seconds: 10));
    final services = await device.discoverServices();
    for (BluetoothService service in services) {
      AppUtil().log('=======> ${service.serviceUuid.str}');
      final characteristics = service.characteristics;
      for (final char in characteristics) {
        if (char.characteristicUuid.str.contains('fff4')) {
          _authResultChar = char;
        }
        if (char.characteristicUuid.str.contains('fff5')) {
          _credExchangeChar = char;
        }
      }
    }
  }

  Future<void> onStop() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> handleFlow() async {
    List<int>? sessionKey = await _getCredentialKey();
    if (sessionKey == null) {
      return;
    }

    final unlocked = await _sendAction(sessionKey);
    if (unlocked) {
      AppUtil().log('Door unlocked!');
    } else {
      AppUtil().log('Access denied');
    }
  }

  Future<List<int>?> _getCredentialKey() async {
    final lockNonce = FakeCredential.lockNonce;
    AppUtil().log('lockNonce: $lockNonce');

    final phoneNonce = _generateRandom(16);
    AppUtil().log('phoneNonce: $phoneNonce');

    final ephemeralKeyPair = _generateEphemeralKeyPair();
    final ephemeralPublicKey = _getPublicKeyBytes(ephemeralKeyPair);
    final ephemeralPrivateKey = _getPrivateKeyBytes(ephemeralKeyPair);
    AppUtil().log('ephemeralPublicKey: $ephemeralPublicKey');
    AppUtil().log('ephemeralPrivateKey: $ephemeralPrivateKey');

    final timestamp = _getTimestamp8B();
    AppUtil().log('timestamp: $timestamp');

    final nonceInput = [...lockNonce, ...phoneNonce];
    AppUtil().log('nonceInput: $nonceInput');
    final nonceSig = _sign(nonceInput, FakeCredential.privateKey);
    AppUtil().log('nonceSig: $nonceSig');

    final payload = [
      ...FakeCredential.ver, // 2B
      ...FakeCredential.bytes, // 135B full blob
      ...FakeCredential.userPk, // 65B
      ...ephemeralPublicKey, // 65B
      ...phoneNonce, // 16B
      ...timestamp, // 8B
      ...nonceSig, // 64B
    ];
    AppUtil().log('payload: $payload');

    final completer = Completer<List<int>>();
    await _authResultChar?.setNotifyValue(true);
    final sub = _authResultChar?.onValueReceived.listen((data) {
      if (!completer.isCompleted) completer.complete(data);
    });

    await _credExchangeChar!.write(payload, withoutResponse: false);

    final result = await completer.future.timeout(const Duration(seconds: 5));
    await sub?.cancel();
    AppUtil().log('Result: $result');

    final status = result[0];
    if (status != 0x00) {
      AppUtil().log('Auth failed with status: $status');
      return null;
    }

    // 8. ECDH → sessionKey
    final lockEphemeralPk = result.sublist(1, 66);
    List<int> sessionKey = _ecdh(ephemeralKeyPair, lockEphemeralPk);
    return sessionKey;
  }

  List<int> _generateRandom(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  AsymmetricKeyPair<PublicKey, PrivateKey> _generateEphemeralKeyPair() {
    final keyParams = ECKeyGeneratorParameters(ECCurve_prime256v1());

    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seed = List<int>.generate(32, (_) => seedSource.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seed)));

    final generator = ECKeyGenerator();
    generator.init(ParametersWithRandom(keyParams, secureRandom));

    return generator.generateKeyPair();
  }

  List<int> _getPublicKeyBytes(AsymmetricKeyPair keyPair) {
    final pub = keyPair.publicKey as ECPublicKey;
    final x = pub.Q!.x!.toBigInteger()!.toRadixString(16).padLeft(64, '0');
    final y = pub.Q!.y!.toBigInteger()!.toRadixString(16).padLeft(64, '0');
    final hex = '04$x$y';
    return List<int>.generate(
      hex.length ~/ 2,
      (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
    );
  }

  List<int> _getPrivateKeyBytes(AsymmetricKeyPair keyPair) {
    final priv = keyPair.privateKey as ECPrivateKey;
    final hex = priv.d!.toRadixString(16).padLeft(64, '0');
    return List<int>.generate(
      hex.length ~/ 2,
      (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
    );
  }

  List<int> _getTimestamp8B() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final bytes = ByteData(8);
    bytes.setInt64(0, timestamp, Endian.big);
    return bytes.buffer.asUint8List().toList();
  }

  List<int> _sign(List<int> message, List<int> privateKeyBytes) {
    // 1. Build EC private key from bytes
    final d = BigInt.parse(
      privateKeyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      radix: 16,
    );
    final privateKey = ECPrivateKey(d, ECCurve_prime256v1());

    // 2. Setup signer
    final signer = ECDSASigner(SHA256Digest());
    final signerParams = ParametersWithRandom(
      PrivateKeyParameter<ECPrivateKey>(privateKey),
      _buildSecureRandom(),
    );
    signer.init(true, signerParams);

    // 3. Sign the message
    final messageBytes = Uint8List.fromList(message);
    final sig = signer.generateSignature(messageBytes) as ECSignature;

    // 4. Encode as raw 64B [r(32B) | s(32B)]
    final r = _bigIntToBytes(sig.r, 32);
    final s = _bigIntToBytes(sig.s, 32);

    return [...r, ...s]; // 64B
  }

  List<int> _bigIntToBytes(BigInt value, int length) {
    final hex = value.toRadixString(16).padLeft(length * 2, '0');
    return List<int>.generate(
      length,
      (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
    );
  }

  // Helper: secure random for signer
  SecureRandom _buildSecureRandom() {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seed = List<int>.generate(32, (_) => seedSource.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seed)));
    return secureRandom;
  }

  List<int> _ecdh(AsymmetricKeyPair ephemeralKeyPair, List<int> lockEphemPkBytes) {
    // 1. Rebuild lock's ephemeral public key from 65B bytes
    final curve = ECCurve_prime256v1();
    final point = curve.curve.decodePoint(Uint8List.fromList(lockEphemPkBytes));
    final lockPublicKey = ECPublicKey(point, curve);

    // 2. Get our ephemeral private key
    final ourPrivateKey = ephemeralKeyPair.privateKey as ECPrivateKey;

    // 3. ECDH: sharedPoint = ourPrivateKey * lockPublicKey
    final agreement = ECDHBasicAgreement();
    agreement.init(ourPrivateKey);
    final sharedSecret = agreement.calculateAgreement(lockPublicKey);

    // 4. Convert to 32B
    final sessionKey = _bigIntToBytes(sharedSecret, 32);
    return sessionKey; // 32B shared secret
  }

  Future<bool> _sendAction(List<int> sessionKey) async{
    final command = [0x01]; // open command

    // 2. Encrypt with AES-GCM
    final iv = _generateRandom(12); // 12B
    final key = Uint8List.fromList(sessionKey);

    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      true,
      AEADParameters(
        KeyParameter(key),
        128,                        // 16B tag
        Uint8List.fromList(iv),
        Uint8List.fromList([]),     // no AAD
      ),
    );

    final encrypted = cipher.process(Uint8List.fromList(command));
    // encrypted = ciphertext + tag(16B)

    final payload = [...iv, ...encrypted]; // iv(12B) + ciphertext + tag(16B)

    // 3. Listen for response BEFORE writing
    final completer = Completer<List<int>>();
    final sub = _authResultChar?.onValueReceived.listen((data) {
      if (!completer.isCompleted) completer.complete(data);
    });

    await _credExchangeChar!.write(payload, withoutResponse: false);

    // 5. Wait for response
    final result = await completer.future.timeout(const Duration(seconds: 5));
    await sub?.cancel();
    AppUtil().log('getAction result: $result');

    // 6. Decrypt response
    final responseIv = result.sublist(0, 12);
    final responseCipher = result.sublist(12);

    final decipher = GCMBlockCipher(AESEngine());
    decipher.init(
      false, // decrypt
      AEADParameters(
        KeyParameter(key),
        128,
        Uint8List.fromList(responseIv),
        Uint8List.fromList([]),
      ),
    );

    final decrypted = decipher.process(Uint8List.fromList(responseCipher));
    AppUtil().log('decrypted response: $decrypted');

    return decrypted[0] == 0x01; // 0x01 = granted
  }
}

// FAKE CREDENTIAL - for testing only
class FakeCredential {
  static final List<int> ver = [0x00, 0x01]; // version 1

  static final List<int> lockId = [
    0x01,
    0x02,
    0x03,
    0x04,
    0x05,
    0x06,
    0x07,
    0x08,
    0x09,
    0x0A,
    0x0B,
    0x0C,
    0x0D,
    0x0E,
    0x0F,
    0x10,
  ]; // 16B

  static final List<int> lockNonce = [
    0x11,
    0x22,
    0x33,
    0x44,
    0x55,
    0x66,
    0x77,
    0x88,
    0x99,
    0xAA,
    0xBB,
    0xCC,
    0xDD,
    0xEE,
    0xFF,
    0x00,
  ];

  static final List<int> expiry = [
    0x67, 0xEB, 0x5B, 0x80, // Unix timestamp ~2025
  ]; // 4B

  static final List<int> keyId = [
    0xAA,
    0xBB,
    0xCC,
    0xDD,
    0xEE,
    0xFF,
    0x11,
    0x22,
    0x33,
    0x44,
    0x55,
    0x66,
    0x77,
    0x88,
    0x99,
    0x00,
  ]; // 16B UUID

  static final List<int> userPk = [
    0x04, // uncompressed point
    // x (32B)
    0x1a, 0x2b, 0x3c, 0x4d, 0x5e, 0x6f, 0x70, 0x81,
    0x92, 0xa3, 0xb4, 0xc5, 0xd6, 0xe7, 0xf8, 0x09,
    0x1a, 0x2b, 0x3c, 0x4d, 0x5e, 0x6f, 0x70, 0x81,
    0x92, 0xa3, 0xb4, 0xc5, 0xd6, 0xe7, 0xf8, 0x09,
    // y (32B)
    0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88,
    0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0x00,
    0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88,
    0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0x00,
  ]; // 65B

  static final List<int> signature = List<int>.filled(64, 0xAB); // 64B fake sig

  // Full 135B blob
  static List<int> get bytes => [
    ...ver,
    ...lockId,
    ...expiry,
    ...keyId,
    ...userPk.sublist(0, 33), // compressed pubkey 33B
    ...signature,
  ];

  // Fake private key (32B) - paired with userPk above (not really, just for testing)
  static final List<int> privateKey = List<int>.filled(32, 0x42);
}
