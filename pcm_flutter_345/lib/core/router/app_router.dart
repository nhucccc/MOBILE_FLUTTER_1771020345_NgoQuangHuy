import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/screens/main_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/booking/screens/booking_screen.dart';
import '../../features/booking/screens/booking_detail_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';
import '../../features/wallet/screens/deposit_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/members/screens/members_screen.dart';
import '../../features/members/screens/member_detail_screen.dart';
import '../../features/tournaments/screens/tournaments_screen.dart';
import '../../features/tournaments/screens/tournament_detail_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = authProvider.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login' || 
                         state.matchedLocation == '/register';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Main App Routes
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/booking',
            name: 'booking',
            builder: (context, state) => const BookingScreen(),
            routes: [
              GoRoute(
                path: '/detail/:id',
                name: 'booking-detail',
                builder: (context, state) => BookingDetailScreen(
                  bookingId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/tournaments',
            name: 'tournaments',
            builder: (context, state) => const TournamentsScreen(),
            routes: [
              GoRoute(
                path: '/detail/:id',
                name: 'tournament-detail',
                builder: (context, state) => TournamentDetailScreen(
                  tournamentId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/wallet',
            name: 'wallet',
            builder: (context, state) => const WalletScreen(),
            routes: [
              GoRoute(
                path: '/deposit',
                name: 'deposit',
                builder: (context, state) => const DepositScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: '/edit',
                name: 'edit-profile',
                builder: (context, state) => const EditProfileScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/members',
            name: 'members',
            builder: (context, state) => const MembersScreen(),
            routes: [
              GoRoute(
                path: '/detail/:id',
                name: 'member-detail',
                builder: (context, state) => MemberDetailScreen(
                  memberId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/admin',
            name: 'admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
        ],
      ),
    ],
  );
}