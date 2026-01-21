import '../../../core/network/api_client.dart';
import 'models/leave_decision.dart';
import 'models/leave_type.dart';
import 'models/manager_leave_history.dart';
import 'models/my_leave_request.dart';
import 'models/pending_leave_request.dart';

enum LeaveFilter { all, pending, history }

class LeaveService {
  // kullanıcı kendi izin taleplerini listeler query parama göre bekleyen tümü gibi ayrım yapabilir
  Future<List<MyLeaveRequest>> getMyLeaves({
    LeaveFilter filter = LeaveFilter.all,
  }) async {
    final statusQuery = switch (filter) {
      LeaveFilter.all => null,
      LeaveFilter.pending => 'pending',
      LeaveFilter.history => 'history',
    };

    final path = statusQuery == null
        ? 'api/LeaveRequests/my'
        : 'api/LeaveRequests/my?status=$statusQuery';

    final dynamic res = await ApiClient().get(path);

    if (res is List) {
      return res
          .map<MyLeaveRequest>(
            (e) => MyLeaveRequest.fromJson(e as Map<String, dynamic>)).toList();
    }
    else if (res is Map && res['data'] is List) {
      final list = res['data'] as List;
      return list
          .map<MyLeaveRequest>(
            (e) => MyLeaveRequest.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception(
      'Beklenmeyen API response tipi: ${res.runtimeType}',
    );
  }

  // kullanıcı kendi izin talepini günceller
  Future<void> updateMyLeave({
    required int id,
    required int leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    required String? description,
  }) async {
    await ApiClient().put(
      'api/LeaveRequests/$id',
      {
        'leaveTypeId': leaveTypeId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'description': description,
      },
    );
  }

  // izin talebini silmeyip cancel yapıyoruz
  Future<void> cancelMyLeave(int id) async {
    await ApiClient().post('api/LeaveRequests/$id/cancel', {});
  }

  // talep oluşturma
  Future<void> createLeave({
    required int leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    required String? description,
  }) async {
    await ApiClient().post(
      'api/LeaveRequests',
      {
        'leaveTypeId': leaveTypeId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'description': description,
      },
    );
  }

  // izin türlerinin listesi
  Future<List<LeaveType>> getLeaveTypes() async {
    final dynamic res = await ApiClient().get('api/LeaveTypes');

    if (res is List) {
      return res.map((e) => LeaveType.fromJson(e as Map<String, dynamic>)).toList();
    }
    else if (res is Map && res['data'] is List) {
      final list = res['data'] as List;
      return list
          .map<LeaveType>(
              (e) => LeaveType.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Beklenmeyen yanıt formatı: ${res.runtimeType}');
  }

  // kullanıcı izin talebinin detayını görmek isterse
  Future<MyLeaveRequest> getMyLeaveDetail(int id) async {
    final dynamic res = await ApiClient().get('api/LeaveRequests/$id');


    return MyLeaveRequest.fromJson(res as Map<String, dynamic>);
  }



  // Yönetici onay beklemedeki izin taleplerini listeler
  Future<List<PendingLeaveRequest>> getPendingInbox() async {
    final dynamic res = await ApiClient().get('api/LeaveRequests/pending');

    if (res is List) {
      return res
          .map((e) => PendingLeaveRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (res is Map && res['data'] is List) {
      final list = res['data'] as List;
      return list
          .map((e) => PendingLeaveRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Beklenmeyen yanıt formatı: ${res.runtimeType}');
  }

  // Yönetici kullanıcının talebini onaylar veya reddeder
  Future<String> decideLeaveRequest({
    required int id,
    required LeaveDecision decision,
  }) async {
    final res = await ApiClient().post(
      'api/LeaveRequests/$id/decision',
      decision.toJson(),
    );

    if (res is String) return res;
    if (res is Map && res['message'] != null) return res['message'].toString();

    return "İşlem beklenmedik şekilde tamamlandı.";
  }

  // yöneticin departmanındaki onaylanan ve reddedilen talepleri listesi
  Future<List<ManagerLeaveHistory>> getManagerHistory() async {
    final res = await ApiClient().get('api/LeaveRequests/manager/history');

    if (res is List) {
      return res.map((e) => ManagerLeaveHistory.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Beklenmeyen yanıt formatı: ${res.runtimeType}');
  }
}
