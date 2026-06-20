import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/splash/splash_screen.dart';
import 'core/constants/supabase_constants.dart';
import 'features/auth/login_screen.dart';

import 'package:nexora/features/onboarding/basic_info_screen.dart';
import 'package:nexora/features/navigation/main_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  runApp(const NexoraApp());
}

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nexora',
      theme: ThemeData.dark(),
      home: const SplashScreen(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;
  }

  Future<bool> hasProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) return false;

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return data != null;
    } catch (e) {
      print("PROFILE CHECK ERROR: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, streamSnapshot) {
        // Always check the live session, not a stale snapshot
        final session = Supabase.instance.client.auth.currentSession;

        if (session == null) {
          return const LoginScreen();
        }

        return FutureBuilder<bool>(
          // key forces a fresh profile check whenever the user changes
          key: ValueKey(session.user.id),
          future: hasProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                body: Center(child: Text("Auth Error: ${snapshot.error}")),
              );
            }

            final hasProfile = snapshot.data ?? false;

            if (hasProfile) {
              return const MainNavigationScreen();
            }

            return const BasicInfoScreen();
          },
        );
      },
    );
  }
}