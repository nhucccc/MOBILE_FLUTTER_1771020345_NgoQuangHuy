import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_screen.dart';
import 'screens/tournament/tournaments_screen.dart';
import 'screens/booking/recurring_booking_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/tournament_provider.dart';
import 'services/api_service.dart';
import 'services/signalr_service.dart';
import 'services/biometric_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PCMApp());
}

class PCMApp extends StatelessWidget {
  const PCMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
      ],
      child: MaterialApp(
        title: 'PCM - Vợt Thủ Phố Núi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        routes: {
          '/tournaments': (context) => const TournamentsScreen(),
          '/recurring-booking': (context) => const RecurringBookingScreen(),
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check for biometric authentication first
    final biometricService = BiometricService();
    if (await biometricService.isBiometricEnabled()) {
      final credentials = await biometricService.authenticateAndGetCredentials();
      if (credentials != null) {
        final success = await authProvider.login(
          credentials['email']!,
          credentials['password']!,
        );
        
        if (success && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
          return;
        }
      }
    }
    
    // Fallback to regular auth check
    await authProvider.checkAuthStatus();
    
    if (!mounted) return;
    
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sports_tennis,
                size: 60,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'PCM',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Vợt Thủ Phố Núi',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Vui - Khỏe - Có Thưởng',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white60,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check for biometric authentication first
    final biometricService = BiometricService();
    if (await biometricService.isBiometricEnabled()) {
      final credentials = await biometricService.authenticateAndGetCredentials();
      if (credentials != null) {
        await authProvider.login(
          credentials['email']!,
          credentials['password']!,
        );
      }
    } else {
      // Fallback to regular auth check
      await authProvider.checkAuthStatus();
    }
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('AuthWrapper build called, _isInitialized = $_isInitialized'); // Debug log
    
    if (!_isInitialized) {
      return const SplashScreen();
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('AuthWrapper Consumer rebuild: isLoading=${authProvider.isLoading}, isAuthenticated=${authProvider.isAuthenticated}'); // Debug log
        
        if (authProvider.isLoading) {
          return const SplashScreen();
        }

        if (authProvider.isAuthenticated) {
          // Load wallet data when user is authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final walletProvider = Provider.of<WalletProvider>(context, listen: false);
            walletProvider.loadWalletData();
          });
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}