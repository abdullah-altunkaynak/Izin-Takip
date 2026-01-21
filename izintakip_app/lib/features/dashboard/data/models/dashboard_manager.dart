import 'dashboard_latest_item.dart';

class DashboardManager {
  final int pendingApprovalCount;
  final int onLeaveTodayCount;
  final List<DashboardLatestItem> latest5;

  const DashboardManager({
    required this.pendingApprovalCount,
    required this.onLeaveTodayCount,
    required this.latest5,
  });

  factory DashboardManager.fromJson(Map<String, dynamic> json) {
    final list = (json['latest5'] as List? ?? const [])
        .map((e) => DashboardLatestItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardManager(
      pendingApprovalCount: (json['pendingApprovalCount'] as num).toInt(),
      onLeaveTodayCount: (json['onLeaveTodayCount'] as num).toInt(),
      latest5: list,
    );
  }
}
