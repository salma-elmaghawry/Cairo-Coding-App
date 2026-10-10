import 'package:cairo_coding_app/bootstrap.dart';
import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/student/student_router.dart';

Future<void> main() => bootstrap(flavor: AppFlavor.student, routerProvider: studentRouterProvider);
