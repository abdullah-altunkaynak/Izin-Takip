class DashboardMe {
  final int year;
  final int totalDays;
  final int usedDays;
  final int remainingDays;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;

  const DashboardMe({
    required this.year,
    required this.totalDays,
    required this.usedDays,
    required this.remainingDays,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
  });

  factory DashboardMe.fromJson(Map<String, dynamic> json) {
    return DashboardMe(
      year: (json['year'] as num).toInt(),
      totalDays: (json['totalDays'] as num).toInt(),
      usedDays: (json['usedDays'] as num).toInt(),
      remainingDays: (json['remainingDays'] as num).toInt(),
      pendingCount: (json['pendingCount'] as num).toInt(),
      approvedCount: (json['approvedCount'] as num).toInt(),
      rejectedCount: (json['rejectedCount'] as num).toInt(),
    );
  }
}
