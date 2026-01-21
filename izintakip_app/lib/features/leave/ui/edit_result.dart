class EditResult {
  final bool success;
  final String message;

  const EditResult._(this.success, this.message);

  // ._ korumalı kullanım içindir
  factory EditResult.success(String message) => EditResult._(true, message);
  factory EditResult.fail(String message) => EditResult._(false, message);
}
