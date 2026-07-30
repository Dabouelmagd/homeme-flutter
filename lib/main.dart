import 'dart:async';
import 'package:flutter/foundation.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF059669)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.forward();
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const WebViewScreen()));
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF059669),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(child: Text('🏠', style: TextStyle(fontSize: 48))),
              ),
              const SizedBox(height: 16),
              const Text('HomeMe',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('نظام إدارة الكمبوندات السكنية',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _error  = false;
  bool _errorIsConnectivity = true;
  bool _hasRetried = false;
  double _progress = 0;

  static const _url = 'https://homemeapp.net';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF059669))
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() { _loading = true; _error = false; }),
        onProgress:  (p) => setState(() => _progress = p / 100.0),
        onPageFinished: (_) {
          setState(() => _loading = false);
          _hasRetried = false; // successful load resets the retry counter
        },
        onWebResourceError: _handleWebResourceError,
        onNavigationRequest: (req) {
          if (req.url.startsWith('https://homemeapp.net') ||
              req.url.startsWith('http://homemeapp.net') ||
              req.url.startsWith('https://www.homemeapp.net')) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(_url));
  }

  Future<void> _handleWebResourceError(WebResourceError e) async {
    // Log the real error so it shows up in `flutter run` / logcat instead of
    // guessing. This was the missing diagnostic in the previous build.
    debugPrint(
      'WebView error: code=${e.errorCode}, description=${e.description}, '
      'type=${e.errorType}, isMainFrame=${e.isForMainFrame}',
    );

    // Errors on iframes/subresources (ads, analytics, fonts) shouldn't take
    // down the whole screen.
    if (e.isForMainFrame != true) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasConnection = connectivityResult != ConnectivityResult.none;

    if (!hasConnection) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _errorIsConnectivity = true;
        _loading = false;
      });
      return;
    }

    // Device genuinely has connectivity, so this is a transient WebView load
    // failure (very common right after cold start before the WebView's
    // internal network stack settles). Retry once automatically before
    // bothering the user with an error screen.
    if (!_hasRetried) {
      _hasRetried = true;
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _controller.reload();
      return;
    }

    if (!mounted) return;
    setState(() {
      _error = true;
      _errorIsConnectivity = false;
      _loading = false;
    });
  }

  Future<bool> _onPop() async {
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
      onPopInvoked: (did) async { if (!did) await _onPop(); },
      child: Scaffold(
        backgroundColor: const Color(0xFF059669),
        body: SafeArea(
          child: Stack(
            children: [
              if (!_error) WebViewWidget(controller: _controller),
              if (_loading && !_error)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 3,
                  ),
                ),
              if (_error)
                Container(
                  color: const Color(0xFF059669),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_errorIsConnectivity ? '📶' : '⚠️', style: const TextStyle(fontSize: 56)),
                          const SizedBox(height: 16),
                          Text(_errorIsConnectivity ? 'تعذّر الاتصال' : 'تعذّر تحميل الصفحة',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_errorIsConnectivity
                              ? 'تحقق من اتصالك بالإنترنت'
                              : 'حدث خطأ أثناء تحميل الموقع، حاول مرة أخرى',
                            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14)),
                          const SizedBox(height: 28),
                          ElevatedButton(
                            onPressed: () {
                              _hasRetried = false;
                              setState(() { _error = false; _loading = true; });
                              _controller.reload();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF059669),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('إعادة المحاولة',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
