import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  /// 必要
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);

    var swAvailable = await AndroidWebViewFeature.isFeatureSupported(AndroidWebViewFeature.SERVICE_WORKER_BASIC_USAGE);
    var swInterceptAvailable = await AndroidWebViewFeature.isFeatureSupported(AndroidWebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST);

    if (swAvailable && swInterceptAvailable) {
      AndroidServiceWorkerController serviceWorkerController = AndroidServiceWorkerController.instance();

      serviceWorkerController.serviceWorkerClient = AndroidServiceWorkerClient(
        shouldInterceptRequest: (request) async {
          print("攔截 ${request}");
          return null;
        },
      );
    }
  }

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
  final _mobileUrl = "https://csnclubs.com/";

  double slimmingSize = 0.0;

  /// close splash
  bool closeSplashView = false;

  /// start Loading webview
  bool startLoadingWebView = false;

  /// 主畫面使用的webViewCtr
  InAppWebViewController? mainWebViewController;

  /// 彈出的webViewCtr
  InAppWebViewController? popupWebViewController;

  /// 有額外彈出的WebView視窗
  bool newPopupWebViewWindowDisplayed = false;

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      /// 0.5秒後,開始載入WebView
      Future.delayed(Duration(milliseconds: 500), () async {
        setState(() {
          startLoadingWebView = true;
        });
      });
    });

    super.initState();
  }

  Future<bool> _onCreateWindow(InAppWebViewController controller, CreateWindowAction createWindowAction) async {
    newPopupWebViewWindowDisplayed = true;
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
                ios: IOSInAppWebViewOptions(
                  sharedCookiesEnabled: true,
                ),
                crossPlatform: InAppWebViewOptions(
                    // userAgent: "Mozilla/5.0 (Linux; Android 9; LG-H870 Build/PKQ1.190522.001) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/83.0.4103.106 Mobile Safari/537.36"
                    ),
              ),

              /// ssl證書
              onReceivedServerTrustAuthRequest: (InAppWebViewController controller, URLAuthenticationChallenge challenge) async {
                return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
              },
              onLoadStart: (controller, url) async {
                print("彈窗開始載入: $url");

                /// url 字串
                final urlString = url.toString();

                /// 如果載入的字串中,包含了 line.me 的字元,則用外開的方式開啟
                if (urlString.contains("line.me") || urlString.contains("lin.ee")) {
                  final urlEncodeFull = Uri.encodeFull(urlString);

                  // 外開網頁
                  if (await canLaunch(urlEncodeFull)) {
                    await launch(urlEncodeFull);

                    // 因為他很奇怪會popup兩次,避免此情況
                    if (newPopupWebViewWindowDisplayed) {
                      Navigator.pop(context);
                      newPopupWebViewWindowDisplayed = false;
                    }
                  } else {
                    throw 'Could not launch $urlEncodeFull';
                  }
                }
              },
              onCloseWindow: (controller) {
                newPopupWebViewWindowDisplayed = false;
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

    /// 點擊返回上一頁  => webView回上一頁
    return WillPopScope(
      onWillPop: () async {
        if (mainWebViewController != null) {
          mainWebViewController!.goBack();
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: Platform.isAndroid ? false : true,
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
              children: [
                /// webView
                Positioned.fill(
                  child: startLoadingWebView
                      ? InAppWebView(
                          initialUrlRequest: URLRequest(url: Uri.parse(_mobileUrl)),
                          initialOptions: InAppWebViewGroupOptions(
                              android: AndroidInAppWebViewOptions(
                                supportMultipleWindows: true,
                              ),
                              ios: IOSInAppWebViewOptions(sharedCookiesEnabled: true),
                              crossPlatform: InAppWebViewOptions(
                                useShouldOverrideUrlLoading: true,
                                disableContextMenu: false,
                                javaScriptCanOpenWindowsAutomatically: true,
                                cacheEnabled: false,
                                supportZoom: false,
                                javaScriptEnabled: true,
                              )),
                          onWebViewCreated: (InAppWebViewController controller) {
                            mainWebViewController = controller;
                          },
                      // shouldOverrideUrlLoading: (InAppWebViewController controller, NavigationAction navigationAction) async{
                      //
                      //       print("我看houldOverrideUrlLoading: $navigationAction");
                      //       return NavigationActionPolicy.ALLOW;
                      // },

                          /// 第二種寫法
                          onCreateWindow: (InAppWebViewController controller, CreateWindowAction createWidowAction) async {
                            print("來看看喔!: ${createWidowAction.request}");
                            print("來看看第二種喔!: ${createWidowAction}");
                            final urlString = createWidowAction.request.url.toString();
                            final urlEncodeFull = Uri.encodeFull(urlString);
                            // print("看看網址: $urlEncodeFull");
                            // if (await canLaunch(urlEncodeFull)) {
                            //   await launch(urlEncodeFull);
                            // } else {
                            //   throw 'Could not launch $urlEncodeFull';
                            // }
                            //
                            // return Future<bool>.value(true);
                            //
                            // createWidowAction.request.url = Uri.parse(_mobileUrl + "gotopage?/type=totopay");
                            // createWidowAction.request.headers = null;

                            print("看看新的!: ${createWidowAction.windowId}");
                            return _onCreateWindow(controller, createWidowAction);
                          }
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
      ),
    );
  }
}
