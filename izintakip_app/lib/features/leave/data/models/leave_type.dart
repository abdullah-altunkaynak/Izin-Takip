class LeaveType {
  final int leaveTypeId;
  final String leaveTypeName;

  LeaveType({required this.leaveTypeId, required this.leaveTypeName});

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      leaveTypeId: (json['leaveTypeId'] as num).toInt(),
      leaveTypeName: (json['leaveTypeName'] ?? '').toString(),
    );
  }
}
