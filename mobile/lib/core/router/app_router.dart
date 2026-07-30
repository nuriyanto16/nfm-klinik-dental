import 'package:go_router/go_router.dart';

import '../../features/branches/presentation/branches_page.dart';
import '../../features/content/data/content_models.dart';
import '../../features/content/presentation/article_detail_page.dart';
import '../../features/content/presentation/articles_page.dart';
import '../../features/doctors/presentation/doctor_detail_page.dart';
import '../../features/doctors/presentation/doctors_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/patient/presentation/profile_page.dart';
import '../../features/patient/presentation/register_page.dart';
import '../../features/payment/presentation/payment_history_page.dart';
import '../../features/reservation/presentation/booking_flow_page.dart';
import '../../features/reservation/presentation/reservation_history_page.dart';
import '../../features/treatments/presentation/price_list_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
    GoRoute(path: '/branches', builder: (context, state) => const BranchesPage()),
    GoRoute(path: '/doctors', builder: (context, state) => const DoctorsPage()),
    GoRoute(
      path: '/doctors/:id',
      builder: (context, state) => DoctorDetailPage(doctorId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/pricelist', builder: (context, state) => const PriceListPage()),
    GoRoute(path: '/articles', builder: (context, state) => const ArticlesPage()),
    GoRoute(
      path: '/articles/:id',
      builder: (context, state) => ArticleDetailPage(article: state.extra as Article),
    ),
    GoRoute(
      path: '/reservations/new',
      builder: (context, state) => BookingFlowPage(
        initialBranchId: state.uri.queryParameters['branchId'],
        initialDoctorId: state.uri.queryParameters['doctorId'],
      ),
    ),
    GoRoute(path: '/reservations/history', builder: (context, state) => const ReservationHistoryPage()),
    GoRoute(path: '/payments/history', builder: (context, state) => const PaymentHistoryPage()),
  ],
);
