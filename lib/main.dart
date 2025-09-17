// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/todo_provider.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'utils/app_theme.dart';
import 'utils/app_constants.dart';

void main() async {
  // ✅ ENSURE WIDGET BINDING IS INITIALIZED
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ GLOBAL ERROR HANDLING
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('Flutter Error: ${details.exception}');
      print('Stack Trace: ${details.stack}');
    }
  };

  // ✅ PLATFORM-SPECIFIC CONFIGURATIONS
  await _configurePlatform();

  // ✅ INITIALIZE CORE SERVICES
  await _initializeCoreServices();

  // ✅ RUN APP
  runApp(const TodoApp());
}

// ✅ PLATFORM-SPECIFIC CONFIGURATIONS
Future<void> _configurePlatform() async {
  try {
    // ✅ SYSTEM UI OVERLAY STYLE
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // ✅ PREFERRED ORIENTATIONS
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    if (kDebugMode) {
      print('✅ Platform configuration completed');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Platform configuration failed: $e');
    }
  }
}

// ✅ INITIALIZE CORE SERVICES
Future<void> _initializeCoreServices() async {
  try {
    // ✅ INITIALIZE API SERVICE
    final apiService = ApiService();
    apiService.init();

    // ✅ CLEAR INVALID TOKENS IF ANY
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      try {
        // Basic token validation
        if (token.isEmpty || token.split('.').length != 3) {
          await prefs.remove('auth_token');
          if (kDebugMode) {
            print('🧹 Cleared invalid token');
          }
        }
      } catch (e) {
        await prefs.remove('auth_token');
        if (kDebugMode) {
          print('🧹 Cleared corrupted token: $e');
        }
      }
    }

    if (kDebugMode) {
      print('✅ Core services initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Core services initialization failed: $e');
    }
  }
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ AUTH PROVIDER - FIRST TO INITIALIZE
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
          lazy: false, // Initialize immediately
        ),

        // ✅ TODO PROVIDER - SEPARATE PROVIDER
        ChangeNotifierProvider(
          create: (context) => TodoProvider(),
          lazy: false,
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            // ✅ ENHANCED THEME CONFIGURATION
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,

            // ✅ LOCALIZATION
            locale: const Locale('en', 'US'),
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('vi', 'VN'),
            ],

            // ✅ NAVIGATION
            home: const AppWrapper(),

            // ✅ ROUTE CONFIGURATION
            onGenerateRoute: _generateRoute,
            onUnknownRoute: _unknownRoute,

            // ✅ APP-LEVEL ERROR HANDLING
            builder: (context, widget) {
              return MediaQuery(
                // ✅ PREVENT TEXT SCALING BEYOND LIMITS
                data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.of(context).textScaler.clamp(
                        minScaleFactor: 0.8,
                        maxScaleFactor: 1.2,
                      ),
                ),
                child: widget ?? const SizedBox(),
              );
            },
          );
        },
      ),
    );
  }

  // ✅ ROUTE GENERATOR
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case '/home':
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      default:
        return null;
    }
  }

  // ✅ UNKNOWN ROUTE HANDLER
  Route<dynamic> _unknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy trang: ${settings.name}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _splashAnimationController;
  bool _isInitializing = true;
  String? _initializationError;

  @override
  void initState() {
    super.initState();

    // ✅ LIFECYCLE OBSERVER
    WidgetsBinding.instance.addObserver(this);

    // ✅ SPLASH ANIMATION CONTROLLER
    _splashAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // ✅ INITIALIZE APP
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _splashAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      default:
        break;
    }
  }

  // ✅ APP INITIALIZATION
  Future<void> _initializeApp() async {
    try {
      setState(() {
        _isInitializing = true;
        _initializationError = null;
      });

      // ✅ START SPLASH ANIMATION
      _splashAnimationController.forward();

      final authProvider = context.read<AuthProvider>();

      // ✅ INITIALIZE AUTH PROVIDER
      await authProvider.initialize();

      // ✅ MINIMUM SPLASH DURATION FOR UX
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }

      if (kDebugMode) {
        print('✅ App initialization completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ App initialization failed: $e');
      }

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initializationError = e.toString();
        });
      }
    }
  }

  // ✅ HANDLE APP LIFECYCLE EVENTS
  void _handleAppResumed() {
    if (kDebugMode) {
      print('📱 App resumed');
    }

    // ✅ REFRESH AUTH STATUS WHEN APP RESUMES
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated) {
      authProvider.refreshUserData();
    }
  }

  void _handleAppPaused() {
    if (kDebugMode) {
      print('📱 App paused');
    }
  }

  void _handleAppDetached() {
    if (kDebugMode) {
      print('📱 App detached');
    }
  }

  // ✅ RETRY INITIALIZATION
  Future<void> _retryInitialization() async {
    await _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ SHOW SPLASH DURING INITIALIZATION
    if (_isInitializing) {
      return const SplashScreen();
    }

    // ✅ SHOW ERROR IF INITIALIZATION FAILED
    if (_initializationError != null) {
      return _buildInitializationError();
    }

    // ✅ MAIN APP NAVIGATION
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('🔄 Consumer rebuild - isAuthenticated: ${authProvider.isAuthenticated}, isInitialized: ${authProvider.isInitialized}');
        
        // ✅ SHOW SPLASH IF AUTH NOT INITIALIZED
        if (!authProvider.isInitialized) {
          print('📱 Showing SplashScreen');
          return const SplashScreen();
        }

        // ✅ NAVIGATE BASED ON AUTH STATUS
        if (authProvider.isAuthenticated) {
          print('🏠 Showing HomeScreen');
          return const HomeScreen();
        }

        print('🔐 Showing LoginScreen');
        return const LoginScreen();
      },
    );
  }

  // ✅ INITIALIZATION ERROR SCREEN
  Widget _buildInitializationError() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Lỗi khởi tạo ứng dụng',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _initializationError!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _retryInitialization,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (kDebugMode)
                      OutlinedButton.icon(
                        onPressed: () {
                          // ✅ SHOW DEBUG INFO
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Debug Info'),
                              content: SingleChildScrollView(
                                child: Text(
                                  'Error: $_initializationError\n\n'
                                  'API Base URL: ${ApiService.baseUrl}\n'
                                  'Platform: ${Theme.of(context).platform}\n'
                                  'Debug Mode: $kDebugMode',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Đóng'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.bug_report),
                        label: const Text('Debug'),
                      ),
                  ],
                ),

                // ✅ API CONNECTION TEST (DEBUG ONLY)
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'API Server: ${ApiService.baseUrl}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        final apiService = ApiService();
                        apiService.init();
                        final isHealthy = await apiService.checkApiHealth();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isHealthy
                                    ? '✅ API Server kết nối thành công'
                                    : '❌ API Server không phản hồi',
                              ),
                              backgroundColor:
                                  isHealthy ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Lỗi kết nối: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Test API Connection'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
