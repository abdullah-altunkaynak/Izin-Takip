class PendingLeaveRequest {
  final int leaveRequestId;
  final int employeeId;
  final String employeeName;
  final String leaveTypeName;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;

  PendingLeaveRequest({
    required this.leaveRequestId,
    required this.employeeId,
    required this.employeeName,
    required this.leaveTypeName,
    required this.startDate,
    required this.endDate,
    required this.description,
  });

  factory PendingLeaveRequest.fromJson(Map<String, dynamic> json) {
    return PendingLeaveRequest(
      leaveRequestId: (json['leaveRequestId'] as num).toInt(),
      employeeId: (json['employeeId'] as num).toInt(),
      employeeName: (json['employeeName'] ?? '').toString(),
      leaveTypeName: (json['leaveTypeName'] ?? '').toString(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      description: json['description'] as String?,
    );
  }
}
