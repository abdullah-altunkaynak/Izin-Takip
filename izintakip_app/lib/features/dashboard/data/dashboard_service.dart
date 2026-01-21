import '../../../core/network/api_client.dart';
import 'models/dashboard_me.dart';
import 'models/dashboard_manager.dart';

class DashboardService {
  Future<DashboardMe> getMe() async {
    final res = await ApiClient().get('api/Dashboard/me');
    if (res is! Map<String, dynamic>) {
      throw Exception("Beklenmeyen format");
    }
    return DashboardMe.fromJson(res);
  }

  Future<DashboardManager> getManager() async {
    final res = await ApiClient().get('api/Dashboard/manager');
    if (res is! Map<String, dynamic>) {
      throw Exception("Beklenmeyen format");
    }
    return DashboardManager.fromJson(res);
  }
}
