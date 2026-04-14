import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:simulated_smartkey_app/util/app_util.dart';

class NfcService {
  bool _isScanning = false;
  bool _isAvailable = false;

  Future<void> checkAvailabilityNFC() async {
    NfcAvailability nfcAvailability = await NfcManager.instance
        .checkAvailability();
    _isAvailable = (nfcAvailability == NfcAvailability.enabled);
  }

  Future<void> onScan() async {
    await checkAvailabilityNFC();
    if (_isScanning || (_isAvailable == false)) return;

    _isScanning = true;
    AppUtil().log('On Scanning NFC');
    await NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag nfcTag) async {
        final ndef = Ndef.from(nfcTag);
        bool isWritable = ndef?.isWritable ?? false;
        if (ndef != null && isWritable) {
          NdefMessage? ndefMessage = ndef.cachedMessage;
          for (NdefRecord ndefRecord in (ndefMessage?.records ?? [])) {
            AppUtil().log('Ndef record: ${ndefRecord.payload}');
          }
          String payload = (ndefMessage?.records ?? []).isEmpty
              ? 'HASH_USER_ID'
              : '';
          await _writeData(ndef, payload);
          await onStop();
        }
      },
    );
  }

  Future<void> onStop() async {
    _isScanning = false;
    await NfcManager.instance.stopSession();
  }

  Future<void> _writeData(Ndef ndef, String payload) async {
    NdefRecord ndefRecord = NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList(utf8.encode('TEXT')),
      identifier: Uint8List.fromList(utf8.encode('userId')),
      payload: Uint8List.fromList(utf8.encode(payload)),
    );
    NdefMessage message = NdefMessage(records: [ndefRecord]);
    await ndef.write(message: message);
  }
}