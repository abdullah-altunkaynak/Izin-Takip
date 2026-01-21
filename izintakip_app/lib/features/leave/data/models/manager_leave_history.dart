class ManagerLeaveHistory {
  final int leaveRequestId;
  final String employeeName;
  final String leaveTypeName;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String? rejectionReason;
  final DateTime? approvedAt;

  ManagerLeaveHistory({
    required this.leaveRequestId,
    required this.employeeName,
    required this.leaveTypeName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.rejectionReason,
    required this.approvedAt,
  });

  factory ManagerLeaveHistory.fromJson(Map<String, dynamic> json) {
    return ManagerLeaveHistory(
      leaveRequestId: (json['leaveRequestId'] as num).toInt(),
      employeeName: (json['employeeName'] ?? '').toString(),
      leaveTypeName: (json['leaveTypeName'] ?? '').toString(),
      startDate: DateTime.parse(json['startDate'].toString()),
      endDate: DateTime.parse(json['endDate'].toString()),
      status: (json['status'] ?? '').toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      approvedAt: json['approvedAt'] == null ? null : DateTime.parse(json['approvedAt'].toString()),
    );
  }
}
