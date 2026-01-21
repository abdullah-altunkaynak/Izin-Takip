class DashboardLatestItem {
  final int leaveRequestId;
  final String employeeName;
  final String leaveTypeName;
  final DateTime startDate;
  final DateTime endDate;
  final int statusId;
  final String status;
  final bool isCancelled;

  const DashboardLatestItem({
    required this.leaveRequestId,
    required this.employeeName,
    required this.leaveTypeName,
    required this.startDate,
    required this.endDate,
    required this.statusId,
    required this.status,
    required this.isCancelled,
  });

  factory DashboardLatestItem.fromJson(Map<String, dynamic> json) {
    return DashboardLatestItem(
      leaveRequestId: (json['leaveRequestId'] as num).toInt(),
      employeeName: (json['employeeName'] ?? '').toString(),
      leaveTypeName: (json['leaveTypeName'] ?? '').toString(),
      startDate: DateTime.parse(json['startDate'].toString()),
      endDate: DateTime.parse(json['endDate'].toString()),
      statusId: (json['statusId'] as num).toInt(),
      status: (json['status'] ?? '').toString(),
      isCancelled: json['isCancelled'] == true,
    );
  }
}
