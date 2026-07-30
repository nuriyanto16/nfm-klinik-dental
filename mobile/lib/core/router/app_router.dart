import 'package:go_router/go_router.dart';

import '../../features/branches/presentation/branches_page.dart';
import '../../features/content/data/content_models.dart';
import '../../features/content/presentation/article_detail_page.dart';
import '../../features/content/presentation/articles_page.dart';
import '../../features/content/presentation/promos_page.dart';
import '../../features/content/presentation/testimonials_page.dart';
import '../../features/content/presentation/videos_page.dart';
import '../../features/doctors/presentation/doctor_detail_page.dart';
import '../../features/doctors/presentation/doctors_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/patient/presentation/edit_profile_page.dart';
import '../../features/patient/presentation/insurance_page.dart';
import '../../features/patient/presentation/login_page.dart';
import '../../features/patient/presentation/membership_page.dart';
import '../../features/patient/presentation/notification_page.dart';
import '../../features/patient/presentation/profile_page.dart';
import '../../features/patient/presentation/qr_profile_page.dart';
import '../../features/patient/presentation/register_page.dart';
import '../../features/patient/presentation/reward_page.dart';
import '../../features/payment/presentation/payment_history_page.dart';
import '../../features/payment/presentation/payment_selection_page.dart';
import '../../features/reservation/presentation/booking_flow_page.dart';
import '../../features/reservation/presentation/schedule_page.dart';
import '../../features/treatments/presentation/price_list_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
    GoRoute(path: '/profile/edit', builder: (context, state) => const EditProfilePage()),
    GoRoute(path: '/qr-profile', builder: (context, state) => const QrProfilePage()),
    GoRoute(path: '/membership', builder: (context, state) => const MembershipPage()),
    GoRoute(path: '/reward', builder: (context, state) => const RewardPage()),
    GoRoute(path: '/notifications', builder: (context, state) => const NotificationPage()),
    GoRoute(path: '/insurance', builder: (context, state) => const InsurancePage()),
    GoRoute(path: '/schedule', builder: (context, state) => const SchedulePage()),
    GoRoute(path: '/branches', builder: (context, state) => const BranchesPage()),
    GoRoute(path: '/doctors', builder: (context, state) => const DoctorsPage()),
    GoRoute(
      path: '/doctors/:id',
      builder: (context, state) => DoctorDetailPage(doctorId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/pricelist', builder: (context, state) => const PriceListPage()),
    GoRoute(path: '/promos', builder: (context, state) => const PromosPage()),
    GoRoute(path: '/testimonials', builder: (context, state) => const TestimonialsPage()),
    GoRoute(path: '/videos', builder: (context, state) => const VideosPage()),
    GoRoute(path: '/articles', builder: (context, state) => const ArticlesPage()),
    GoRoute(
      path: '/articles/:id',
      builder: (context, state) {
        final article = state.extra as Article?;
        if (article != null) return ArticleDetailPage(article: article);
        final id = state.pathParameters['id']!;
        return ArticleDetailPage(
          article: Article(
            id: id,
            title: 'Manfaat Perawatan Dental Care',
            slug: 'manfaat-dental-care',
            body: 'Perawatan gigi secara rutin di klinik Nina Dental Care sangat penting untuk menjaga kesehatan gusi, mencegah pembentukan karang gigi (tartar), serta menjaga penampilan senyum Anda tetap percaya diri.',
            categoryName: 'Informasi',
            publishedAt: DateTime.now(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/reservations/new',
      builder: (context, state) => const BookingFlowPage(),
    ),
    GoRoute(path: '/reservations/history', builder: (context, state) => const SchedulePage()),
    GoRoute(
      path: '/payment/checkout',
      builder: (context, state) => PaymentSelectionPage(
        reservationId: state.uri.queryParameters['reservationId'],
      ),
    ),
    GoRoute(path: '/payments/history', builder: (context, state) => const PaymentHistoryPage()),
  ],
);
