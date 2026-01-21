class LeaveDecision {
  final bool isApproved;
  final String? rejectionReason;

  LeaveDecision({required this.isApproved, this.rejectionReason});

  Map<String, dynamic> toJson() => {
    'isApproved': isApproved,
    'rejectionReason': rejectionReason,
  };
}