import 'package:get/get.dart';
import 'package:truelovebiker/features/auth/bindings/auth_binding.dart';
import 'package:truelovebiker/features/auth/presentation/screens/login_screen.dart';
import 'package:truelovebiker/features/home/bindings/home_binding.dart';
import 'package:truelovebiker/features/home/presentation/screens/home_screen.dart';
import 'package:truelovebiker/features/orders/bindings/orders_binding.dart';
import 'package:truelovebiker/features/profile/bindings/profile_binding.dart';
import 'package:truelovebiker/features/splash/bindings/splash_binding.dart';
import 'package:truelovebiker/features/splash/presentation/screens/splash_screen.dart';

import 'package:truelovebiker/features/profile/bindings/edit_profile_binding.dart';
import 'package:truelovebiker/features/profile/presentation/screens/edit_profile_screen.dart';

import 'package:truelovebiker/features/profile/bindings/edit_bank_binding.dart';
import 'package:truelovebiker/features/profile/presentation/screens/edit_bank_screen.dart';
import 'package:truelovebiker/features/orders/bindings/viaje_binding.dart';
import 'package:truelovebiker/features/orders/presentation/screens/viaje_screen.dart';
import 'package:truelovebiker/features/orders/bindings/order_detail_binding.dart';
import 'package:truelovebiker/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:truelovebiker/features/chat/bindings/chat_binding.dart';
import 'package:truelovebiker/features/chat/presentation/screens/chat_screen.dart';
import 'package:truelovebiker/features/profile/bindings/change_password_binding.dart';
import 'package:truelovebiker/features/profile/presentation/screens/change_password_screen.dart';
import 'package:truelovebiker/features/auth/bindings/email_verify_binding.dart';
import 'package:truelovebiker/features/auth/presentation/screens/email_verify_screen.dart';
import 'package:truelovebiker/features/orders/presentation/screens/rating_screen.dart';
import 'package:truelovebiker/features/orders/bindings/rating_binding.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const HomeScreen(),
      bindings: [
        HomeBinding(),
        OrdersBinding(),
        ProfileBinding(),
      ],
    ),
    GetPage(
      name: Routes.EDIT_PROFILE,
      page: () => const EditProfileScreen(),
      binding: EditProfileBinding(),
    ),
    GetPage(
      name: Routes.EDIT_BANK,
      page: () => const EditBankScreen(),
      binding: EditBankBinding(),
    ),
    GetPage(
      name: Routes.ACTIVE_ORDER,
      page: () => const ViajeScreen(),
      binding: ViajeBinding(),
    ),
    GetPage(
      name: Routes.ORDER_DETAIL,
      page: () => const OrderDetailScreen(),
      binding: OrderDetailBinding(),
    ),
    GetPage(
      name: Routes.CHAT,
      page: () => const ChatScreen(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: Routes.CHANGE_PASSWORD,
      page: () => const ChangePasswordScreen(),
      binding: ChangePasswordBinding(),
    ),
    GetPage(
      name: Routes.EMAIL_VERIFY,
      page: () => const EmailVerifyScreen(),
      binding: EmailVerifyBinding(),
    ),
    GetPage(
      name: Routes.RATING,
      page: () => const RatingScreen(),
      binding: RatingBinding(),
    ),
  ];
}
