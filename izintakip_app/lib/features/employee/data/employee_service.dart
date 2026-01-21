import '../../../core/network/api_client.dart';
import 'models/manager_employee.dart';

class EmployeeService {
  Future<List<ManagerEmployee>> getMyEmployees() async {
    final res = await ApiClient().get('api/Employees/manager/myemployees');

    if (res is List) {
      return res
          .map((e) => ManagerEmployee.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Beklenmeyen yanıt formatı: ${res.runtimeType}');
  }
}
