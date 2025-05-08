// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:get/get.dart';
// import '../home/dashboard.dart';
//
// class OutlookScreen extends StatefulWidget {
//   // final String link;
//   const OutlookScreen({super.key,
//     // required this.link
//   });
//
//   @override
//   State<OutlookScreen> createState() => _OutlookScreenState();
// }
//
// class _OutlookScreenState extends State<OutlookScreen> {
//   late WebViewController _controller;
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     initializeWebView();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Outlook", style: TextStyle(color: Colors.white, fontSize: 18)),
//         backgroundColor: Colors.blue,
//         iconTheme: const IconThemeData(color: Colors.white),
//         centerTitle: true,
//       ),
//       body: Stack(
//         children: [
//           WebViewWidget(controller: _controller),
//           if (isLoading)
//             const Center(
//               child: CircularProgressIndicator(),
//             ),
//         ],
//       ),
//     );
//   }
//
//   void initializeWebView() {
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(Colors.white)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageStarted: (url) {
//             setState(() => isLoading = true);
//           },
//           onPageFinished: (url) {
//             setState(() => isLoading = false);
//             checkForRedirect(url);
//           },
//         ),
//       )
//       ..loadRequest(Uri.parse("https://ai-assistant-backend-dk0q.onrender.com/auth/outlook/login"));
//       // ..loadRequest(Uri.parse(widget.link));
//   }
//
//   void checkForRedirect(String url) {
//     if (url.contains("https://jarvis-ai-b6ge.onrender.com/api/auth/callback")) {
//       Get.offAll(() => HomeScreen());
//     }
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../home/dashboard.dart';

class OutlookScreen extends StatefulWidget {
  const OutlookScreen({super.key});

  @override
  State<OutlookScreen> createState() => _OutlookScreenState();
}

class _OutlookScreenState extends State<OutlookScreen> {
  late WebViewController _controller;
  bool isLoading = true;
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    initializeWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Outlook", style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print("Page Started: $url");
            setState(() => isLoading = true);
          },
          onPageFinished: (url) {
            print("Page Loaded: $url");
            setState(() => isLoading = false);
            checkForToken(url);
          },
          onNavigationRequest: (request) {
            print("🔹 Navigation Request: ${request.url}");
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse("https://ai-assistant-backend-dk0q.onrender.com/auth/outlook/login"));
  }

  void checkForToken(String url) async {
    if (url.contains("/auth/outlook/callback")) {
      try {
        Uri uri = Uri.parse(url);
        String? code = uri.queryParameters["code"];

        if (code != null) {
          print("Code Found: $code");
        }

        String rawResponse = await _controller.runJavaScriptReturningResult("document.body.innerText") as String;

        print("Raw Response: $rawResponse");

        String extractedToken = extractToken(rawResponse);

        if (extractedToken.isNotEmpty) {
          await _secureStorage.write(key: "access_token", value: extractedToken);
          print("Stored Token: $extractedToken");
          Get.offAll(() => HomeScreen());
          print("➡ Redirecting to HomeScreen...");
        } else {
          print("Error: Token extraction failed");
        }

      } catch (e) {
        print("Error extracting token: $e");
      }
    }
  }

  String extractToken(String jsonResponse) {
    try {
      String cleanJson = jsonResponse.replaceAll("\\\"", "\"").replaceAll("\"{", "{").replaceAll("}\"", "}");

      Map<String, dynamic> jsonMap = jsonDecode(cleanJson);

      return jsonMap["access_token"] ?? "";
    } catch (e) {
      print("JSON Parsing Error: $e");
      return "";
    }
  }
}
