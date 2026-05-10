import 'package:flutter/material.dart';
import 'package:simulated_smartkey_app/model/action_step.dart';
import 'package:simulated_smartkey_app/presentation/widget/lock_progress_sheet.dart';
import 'package:simulated_smartkey_app/presentation/widget/remote_action_widget.dart';
import 'package:simulated_smartkey_app/util/enum.dart';

class LockDetailPage extends StatelessWidget {
  const LockDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_remoteActionWidget(context)],
      ),
    );
  }

  Widget _remoteActionWidget(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Open Remotely',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              RemoteActionWidget(
                icon: Icons.lock_open_rounded,
                title: 'Unlock',
                color: const Color(0xFF34A853),
                backgroundColor: const Color(0xFFEAF7EE),
                onTap: () => _commandLock(context, 'UNLOCK'),
              ),
              RemoteActionWidget(
                icon: Icons.lock_outline_rounded,
                title: 'Lock',
                color: const Color(0xFFEA4335),
                backgroundColor: const Color(0xFFFFEEEC),
                onTap: () => _commandLock(context, 'LOCK'),
              ),
              RemoteActionWidget(
                icon: Icons.info_outline_rounded,
                title: 'Status',
                color: const Color(0xFF4285F4),
                backgroundColor: const Color(0xFFEAF2FF),
                onTap: () => _commandLock(context, 'STATUS'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _commandLock(BuildContext context, String command) {
    _displayRemoteLockProgress(context);
  }

  void _displayRemoteLockProgress(BuildContext context) {
    final actionStepList = [
      ActionStep(message: 'Sending command to lock', step: ActionState.loading),
      ActionStep(
        message: 'Waiting for lock response',
        step: ActionState.pending,
      ),
    ];
    showModalBottomSheet(
      context: context,
      // isDismissible: false,
      // enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return LockProgressSheetWidget(
          title: 'Unlocking lock remotely',
          subtitle: 'Please wait while application is on process',
          actionStepList: actionStepList,
        );
      },
    );
  }
}
