import 'package:cairo_coding_app/admin/admin_router.dart';
import 'package:cairo_coding_app/bootstrap.dart';
import 'package:cairo_coding_app/core/config/app_flavor.dart';

Future<void> main() => bootstrap(flavor: AppFlavor.admin, routerProvider: adminRouterProvider);
