class ManagerEmployee {
  final int employeeId;
  final String fullName;
  final String email;
  final bool isDepartmentManager;
  final bool isActive;

  ManagerEmployee({
    required this.employeeId,
    required this.fullName,
    required this.email,
    required this.isDepartmentManager,
    required this.isActive,
  });

  factory ManagerEmployee.fromJson(Map<String, dynamic> json) {
    return ManagerEmployee(
      employeeId: (json['employeeId'] as num).toInt(),
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      isDepartmentManager: (json['isDepartmentManager'] ?? false) as bool,
      isActive: (json['isActive'] ?? true) as bool,
    );
  }
}
