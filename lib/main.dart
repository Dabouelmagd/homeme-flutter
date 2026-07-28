import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const HomeMeApp());
}

class HomeMeApp extends StatelessWidget {
  const HomeMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeMe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF059669),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF059669),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}

// ── Splash Screen ──────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim  = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
    Timer(const Duration(milliseconds: 2200), () {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const WebViewScreen()));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF059669),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Opacity(
            opacity: _fadeAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: const Center(
                      child: Text('🏠',
                        style: TextStyle(fontSize: 52)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('HomeMe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    )),
                  const SizedBox(height: 6),
                  Text('نظام إدارة الكمبوندات السكنية',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── WebView Screen ─────────────────────────────────────────────────────────
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError  = false;
  bool _isOffline = false;
  double _progress = 0;

  static const String _baseUrl = 'https://homemeapp.net';

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _initWebView();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => _isOffline = results.contains(ConnectivityResult.none));
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF059669))
      ..setUserAgent(
        'HomeMe-Flutter/1.0 (Mobile; Android)')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (mounted) setState(() { _isLoading = true; _hasError = false; });
        },
        onProgress: (p) {
          if (mounted) setState(() => _progress = p / 100.0);
        },
        onPageFinished: (url) {
          if (mounted) setState(() => _isLoading = false);
          // Inject CSS for better mobile experience
          _controller.runJavaScript('''
            (function() {
              var meta = document.querySelector('meta[name="viewport"]');
              if (!meta) {
                meta = document.createElement('meta');
                meta.name = 'viewport';
                document.head.appendChild(meta);
              }
              meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0';
            })();
          ''');
        },
        onWebResourceError: (error) {
          if (mounted) setState(() { _hasError = true; _isLoading = false; });
        },
        onNavigationRequest: (request) {
          // Open external links in browser
          if (!request.url.startsWith(_baseUrl) &&
              !request.url.startsWith('http://homemeapp.net')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(_baseUrl));
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF059669),
        body: SafeArea(
          child: Stack(
            children: [
              // ── WebView ──────────────────────────────────────────────────
              if (!_isOffline && !_hasError)
                WebViewWidget(controller: _controller),

              // ── Progress bar ─────────────────────────────────────────────
              if (_isLoading && !_isOffline)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 3,
                  ),
                ),

              // ── Offline screen ───────────────────────────────────────────
              if (_isOffline) _buildStatusScreen(
                icon: '📶',
                title: 'لا يوجد اتصال بالإنترنت',
                subtitle: 'تحقق من اتصالك وحاول مجدداً',
                buttonLabel: 'إعادة المحاولة',
                onTap: () async {
                  await _checkConnectivity();
                  if (!_isOffline) _controller.reload();
                },
              ),

              // ── Error screen ─────────────────────────────────────────────
              if (_hasError && !_isOffline) _buildStatusScreen(
                icon: '⚠️',
                title: 'تعذّر تحميل الصفحة',
                subtitle: 'تحقق من اتصالك أو حاول لاحقاً',
                buttonLabel: 'إعادة المحاولة',
                onTap: () {
                  setState(() => _hasError = false);
                  _controller.reload();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusScreen({
    required String icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      color: const Color(0xFF059669),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 14)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(buttonLabel,
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
