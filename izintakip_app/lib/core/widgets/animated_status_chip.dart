import 'dart:math' as math;
import 'package:flutter/material.dart';

enum LeaveStatusKind { pending, approved, rejected, cancelled, other }

class AnimatedStatusChip extends StatefulWidget {
  final LeaveStatusKind kind;
  final String label;

  final bool dense;

  const AnimatedStatusChip({
    super.key,
    required this.kind,
    required this.label,
    this.dense = true,
  });

  static LeaveStatusKind fromApi({required int statusId, required bool isCancelled}) {
    if (isCancelled) return LeaveStatusKind.cancelled;
    if (statusId == 1) return LeaveStatusKind.pending;
    if (statusId == 2) return LeaveStatusKind.approved;
    if (statusId == 3) return LeaveStatusKind.rejected;
    return LeaveStatusKind.other;
  }

  @override
  State<AnimatedStatusChip> createState() => _AnimatedStatusChipState();
}

class _AnimatedStatusChipState extends State<AnimatedStatusChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();

    final repeat = widget.kind == LeaveStatusKind.pending;
    _c = AnimationController(
      vsync: this,
      duration: repeat ? const Duration(milliseconds: 1100) : const Duration(milliseconds: 520),
    );

    if (repeat) {
      _c.repeat(reverse: true);
    } else {
      _c.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedStatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.kind == widget.kind) return;

    _c.stop();
    _c.reset();

    if (widget.kind == LeaveStatusKind.pending) {
      _c.duration = const Duration(milliseconds: 1100);
      _c.repeat(reverse: true);
    } else {
      _c.duration = const Duration(milliseconds: 520);
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (bg, fg, icon) = switch (widget.kind) {
      LeaveStatusKind.pending => (cs.tertiaryContainer, cs.onTertiaryContainer, Icons.hourglass_bottom_rounded),
      LeaveStatusKind.approved => (cs.secondaryContainer, cs.onSecondaryContainer, Icons.check_circle_rounded),
      LeaveStatusKind.rejected => (cs.errorContainer, cs.onErrorContainer, Icons.cancel_rounded),
      LeaveStatusKind.cancelled => (cs.surfaceContainerHighest, cs.onSurfaceVariant, Icons.do_not_disturb_on_rounded),
      _ => (cs.surfaceContainerHighest, cs.onSurfaceVariant, Icons.info_rounded),
    };

    final base = _ChipBase(
      bg: bg,
      fg: fg,
      icon: icon,
      label: widget.label,
      dense: widget.dense,
    );

    // Animasyon: pending=pulse, approved=pop, rejected=shake
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        if (widget.kind == LeaveStatusKind.pending) {
          final t = _c.value; // 0..1..0 (repeat reverse)
          final scale = 1.0 + (t * 0.06);
          return Transform.scale(scale: scale, child: child);
        }

        if (widget.kind == LeaveStatusKind.approved) {
          final t = Curves.elasticOut.transform(_c.value.clamp(0, 1));
          final scale = 0.92 + (t * 0.12);
          return Transform.scale(scale: scale, child: child);
        }

        if (widget.kind == LeaveStatusKind.rejected) {
          final t = _c.value.clamp(0, 1);
          final shake = math.sin(t * math.pi * 8) * (1 - t) * 6; // px
          return Transform.translate(offset: Offset(shake, 0), child: child);
        }

        return child!;
      },
      child: base,
    );
  }
}

class _ChipBase extends StatelessWidget {
  final Color bg;
  final Color fg;
  final IconData icon;
  final String label;
  final bool dense;

  const _ChipBase({
    required this.bg,
    required this.fg,
    required this.icon,
    required this.label,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) {
    final padH = dense ? 10.0 : 12.0;
    final padV = dense ? 6.0 : 8.0;
    final iconSize = dense ? 16.0 : 18.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
