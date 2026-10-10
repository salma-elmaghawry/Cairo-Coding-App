enum AppFlavor {
  student(titleKey: 'app_name'),
  admin(titleKey: 'app_name_admin');

  const AppFlavor({required this.titleKey});

  final String titleKey;

  bool get isAdmin => this == AppFlavor.admin;
}
