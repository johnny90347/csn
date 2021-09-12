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

  @override
  Widget build(BuildContext context) {
    final appBarHeight = kToolbarHeight;
    slimmingSize = appBarHeight * (2 / 3);

    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) => Container(
          margin: EdgeInsets.only(
            top:  orientation == Orientation.portrait ? slimmingSize : 0,
            left: orientation == Orientation.landscape ? slimmingSize : 0,
            right: orientation == Orientation.landscape ? slimmingSize : 0,
            bottom: 0
          ),
          color: Colors.black,
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            key: _parentKey,
            children: [
              Positioned.fill(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: Uri.parse(_mobileUrl)),
                  initialOptions: InAppWebViewGroupOptions(
                      crossPlatform: InAppWebViewOptions(
                    // cacheEnabled: false,
                    supportZoom: false,
                  )),
                  onWebViewCreated: (InAppWebViewController controller) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
