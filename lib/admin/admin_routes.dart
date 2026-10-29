enum CourseTab { groups, sessions, instructors, students }

enum GroupTab { students, schedule, recordings }

class AdminRoutes {
  static const String courses = '/courses';
  static const String groups = '/groups';
  static const String students = '/students';
  static const String instructors = '/instructors';
  static const String settings = '/settings';

  static String course(String courseId, [CourseTab tab = CourseTab.groups]) => '$courses/$courseId/${tab.name}';

  static String group(String groupId, [GroupTab tab = GroupTab.students]) => '$groups/$groupId/${tab.name}';
}
