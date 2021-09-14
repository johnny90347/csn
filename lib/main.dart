import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WebViewScreen(),
    );
  }
}

/// 啟動頁
class SplashView extends StatefulWidget {
  final VoidCallback completedCallBack;

  const SplashView({required this.completedCallBack, Key? key}) : super(key: key);

  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _animation = Tween(
      begin: 1.0,
      end: 0.0,
    ).animate(_controller)
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          widget.completedCallBack();
        }
      });

    /// 1.3 秒後,開始漸變淡
    Future.delayed(Duration(milliseconds: 3000), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: FadeTransition(
        opacity: _animation,
        child: Image(
          image: AssetImage("assets/images/splash_bg.jpeg"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key}) : super(key: key);

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  /// mobile 網址
  final _mobileUrl = "https://csnclubs.com";

  final GlobalKey _parentKey = GlobalKey();

  double slimmingSize = 0.0;

  /// close splash
  bool closeSplashView = false;

  /// start Loading webview
  bool startLoadingWebView = false;

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      /// 0.5秒後,開始載入WebView
      Future.delayed(Duration(milliseconds: 400), () {
        setState(() {
          startLoadingWebView = true;
        });
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appBarHeight = kToolbarHeight;
    slimmingSize = appBarHeight * (2 / 3);

    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) => Container(
          margin: EdgeInsets.only(
              top: orientation == Orientation.portrait ? slimmingSize : 0,
              left: orientation == Orientation.landscape ? slimmingSize : 0,
              right: orientation == Orientation.landscape ? slimmingSize : 0,
              bottom: 0),
          color: Colors.black,
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            key: _parentKey,
            children: [
              /// webView
              Positioned.fill(
                child: startLoadingWebView
                    ? InAppWebView(
                        initialUrlRequest: URLRequest(url: Uri.parse(_mobileUrl)),
                        initialOptions: InAppWebViewGroupOptions(
                            crossPlatform: InAppWebViewOptions(
                          // cacheEnabled: false,
                          supportZoom: false,
                        )),
                        onWebViewCreated: (InAppWebViewController controller) {},
                      )
                    : SizedBox(),
              ),

              /// 啟動頁覆蓋
              if (!closeSplashView)
                Positioned.fill(
                  child: SplashView(
                    completedCallBack: () {
                      /// 動畫做完了
                      Future.delayed(Duration(milliseconds: 300), () {
                        setState(() {
                          closeSplashView = true;
                        });
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
