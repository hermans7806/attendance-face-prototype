class StaffAccount {
  const StaffAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final bool isActive;
  final String role;

  factory StaffAccount.fromFirestore(String id, Map<String, dynamic> data) {
    return StaffAccount(
      id: id,
      name: data['name'] as String? ?? 'User',
      email: data['email'] as String? ?? '',
      isActive: data['is_active'] as bool? ?? true,
      role: data['role'] as String? ?? 'staff',
    );
  }
}
