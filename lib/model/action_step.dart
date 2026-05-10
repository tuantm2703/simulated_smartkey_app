import 'package:simulated_smartkey_app/util/enum.dart';

class ActionStep {
  final String message;
  final ActionState step;

  const ActionStep({required this.message, required this.step});

  ActionStep copyWith({String? message, ActionState? step}) {
    return ActionStep(
      message: message ?? this.message,
      step: step ?? this.step,
    );
  }
}
