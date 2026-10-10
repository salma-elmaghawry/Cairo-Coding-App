enum GroupTab { students, schedule, recordings }

class AdminRoutes {
  static const String groups = '/groups';
  static const String settings = '/settings';

  static String group(String groupId, [GroupTab tab = GroupTab.students]) => '$groups/$groupId/${tab.name}';
}
