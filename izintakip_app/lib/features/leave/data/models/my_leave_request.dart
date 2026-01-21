class MyLeaveRequest {
  final int leaveRequestId;
  final String? leaveTypeName;
  final int? leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final String? status;
  final String? description;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final bool isCancelled;
  final int? employeeId;
  final String? employeeName;

  MyLeaveRequest({
    required this.leaveRequestId,
    required this.leaveTypeName,
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.description,
    required this.rejectionReason,
    required this.approvedAt,
    required this.isCancelled,
    required this.employeeId,
    required this.employeeName
  });

  factory MyLeaveRequest.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) => DateTime.parse(v as String);
    DateTime? parseDateNullable(dynamic v) => v == null ? null : DateTime.parse(v as String);

    return MyLeaveRequest(
      leaveRequestId: (json['leaveRequestId'] as num).toInt(),
      leaveTypeName: json['leaveTypeName'] as String?,
      leaveTypeId: (json['leaveTypeId'] as num?)?.toInt(),
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      status: json['status'] as String?,
      description: json['description'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      approvedAt: parseDateNullable(json['approvedAt']),
      isCancelled: (json['isCancelled'] ?? false) as bool,
      employeeId: (json['employeeId'] as num?)?.toInt(),
      employeeName: json['employeeName']?.toString(),
    );
  }
}
