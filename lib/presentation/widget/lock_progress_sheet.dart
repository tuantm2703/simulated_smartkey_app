import 'package:flutter/material.dart';
import 'package:simulated_smartkey_app/model/action_step.dart';
import 'package:simulated_smartkey_app/util/enum.dart';

class LockProgressSheetWidget extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Color? iconColor;
  final Method? method;
  final List<ActionStep>? actionStepList;

  const LockProgressSheetWidget({
    super.key,
    this.title,
    this.subtitle,
    this.iconColor,
    this.method = Method.remote,
    this.actionStepList,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(
        left: 16,
        top: 24,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: (iconColor ?? Color(0xFF6C3CF0)).withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_rounded,
              size: 40,
              color: (iconColor ?? Color(0xFF6C3CF0)),
            ),
          ),
          Text(
            title ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          _progressStatusWidget(),
        ],
      ),
    );
  }

  Widget _progressStatusWidget() {
    switch (method) {
      case null:
        return const SizedBox.shrink();
      case Method.remote:
        return _remoteActionStatusWidget();
      case Method.ble:
        return const SizedBox.shrink();
      case Method.nfc:
        return const SizedBox.shrink();
      case Method.uwb:
        return const SizedBox.shrink();
    }
  }

  Widget _remoteActionStatusWidget() {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: (actionStepList ?? []).length,
      itemBuilder: (BuildContext context, int index) {
        ActionStep action = (actionStepList ?? [])[index];
        return _itemActionStep(action);
      },
      separatorBuilder: (BuildContext context, int index) =>
          SizedBox(height: 4),
    );
  }

  Widget _itemActionStep(ActionStep action) {
    return Row(
      children: [
        Expanded(
          child: Text(
            action.message,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: action.step == ActionState.pending
                  ? Colors.grey.shade500
                  : const Color(0xFF1C1C1E),
            ),
          ),
        ),
        _suffixWidget(action.step),
      ],
    );
  }

  Widget _suffixWidget(ActionState step) {
    switch (step) {
      case ActionState.pending:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
        );
      case ActionState.loading:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3.2,
            color: iconColor,
            strokeCap: StrokeCap.round,
          ),
        );
      case ActionState.success:
        return Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 16, color: Colors.white),
        );
      case ActionState.fail:
        return Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 16, color: Colors.white),
        );
    }
  }
}
