import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  /// 必要
  WidgetsFlutterBinding.ensureInitialized();
  
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

    /// 2 秒後,開始漸變淡
    Future.delayed(Duration(milliseconds: 2000), () {
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
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          startLoadingWebView = true;
        });
      });
    });

    super.initState();
  }

  bool _isWindowDisplayed = false;

  Future<bool> _onCreateWindow(InAppWebViewController controller, CreateWindowAction createWindowAction) async {
    _isWindowDisplayed = true;
    showDialog<AlertDialog>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(2.0),
          insetPadding: EdgeInsets.all(20.0),
          content: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: InAppWebView(
              // Setting the windowId property is important here!
              windowId: createWindowAction.windowId,
              initialOptions: InAppWebViewGroupOptions(
                android: AndroidInAppWebViewOptions(
                  builtInZoomControls: true,
                  thirdPartyCookiesEnabled: true,
                ),
                // crossPlatform: InAppWebViewOptions(
                //     userAgent: "Mozilla/5.0 (Linux; Android 9; LG-H870 Build/PKQ1.190522.001) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/83.0.4103.106 Mobile Safari/537.36"
                // ),
              ),
              onLoadStart: (controller,url){
                print("開始載入: $url");
              },
              onCloseWindow: (controller) {
                // On Facebook Login, this event is called twice,
                // so here we check if we already popped the alert dialog context
                // if (_isWindowDisplayed) {
                //   Navigator.pop(context);
                //   _isWindowDisplayed = false;
                // }

                print("onCloseWindowonCloseWindowonCloseWindowonCloseWindow");
              },
            ),
          ),
        );
      },
    );
    return true;
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
                              disableContextMenu: false,
                          javaScriptCanOpenWindowsAutomatically: true,
                          // cacheEnabled: false,
                          supportZoom: false,
                        )),
                        onWebViewCreated: (InAppWebViewController controller) {},
                        onCreateWindow: (InAppWebViewController controller, CreateWindowAction createWidowAction) async {
                          print("接收到的網址 : ${createWidowAction.request}");

                          final urlString = createWidowAction.request.url.toString();
                          final urlEncodeFull = Uri.encodeFull(urlString);
                          print("網址: $urlEncodeFull");
                          if (await canLaunch(urlEncodeFull)) {
                            await launch(urlEncodeFull);
                          } else {
                            throw 'Could not launch $urlEncodeFull';
                          }

                          return Future<bool>.value(true);
                        }
                        // onCreateWindow: (InAppWebViewController controller, CreateWindowAction createWidowAction) async {
                        //   print("來看看喔!: ${createWidowAction.request}");
                        //
                        //   final urlString = createWidowAction.request.url.toString();
                        //   final urlEncodeFull = Uri.encodeFull(urlString);
                        //   // print("看看網址: $urlEncodeFull");
                        //   // if (await canLaunch(urlEncodeFull)) {
                        //   //   await launch(urlEncodeFull);
                        //   // } else {
                        //   //   throw 'Could not launch $urlEncodeFull';
                        //   // }
                        //   //
                        //   // return Future<bool>.value(true);
                        //
                        //   return _onCreateWindow(controller, createWidowAction);
                        // }
                        
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
