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

import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/core/shared/constants.dart';
import 'package:ai_asistant/state_mgmt/email/cubit/email_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../home/dashboard.dart';

class OutlookScreen extends StatefulWidget {
  const OutlookScreen({super.key});

  @override
  State<OutlookScreen> createState() => _OutlookScreenState();
}

class _OutlookScreenState extends State<OutlookScreen> {
  late WebViewController _controller;
  bool isLoading = true;
  // final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    initializeWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Outlook",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  void initializeWebView() {
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (url) {
                setState(() => isLoading = true);
              },
              onPageFinished: (url) {
                setState(() => isLoading = false);
                checkForToken(url);
              },
              onNavigationRequest: (request) {
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse("${AppConstants.baseUrl}auth/outlook/login"));
  }

  void checkForToken(String url) async {
    if (url.contains("/auth/outlook/callback")) {
      try {
        Uri uri = Uri.parse(url);
        String? code = uri.queryParameters["code"];

        if (code != null) {
          if (kDebugMode) {
            print("Code Found: $code");
          }
        }

        String rawResponse =
            await _controller.runJavaScriptReturningResult(
                  "document.body.innerText",
                )
                as String;

        if (kDebugMode) {
          print("Raw Response: $rawResponse");
        }

        String extractedToken = extractToken(rawResponse);

        if (extractedToken.isNotEmpty) {
          await SettingsService.storeSetting("access_token", extractedToken);
          if (kDebugMode) {
            print("Stored Token: $extractedToken");
          }
          try {
            Get.context?.read<EmailCubit>().backLoadEmails();
          } catch (_) {}
          Get.offAll(() => HomeScreen());
          if (kDebugMode) {
            print("➡ Redirecting to HomeScreen...");
          }
        } else {
          if (kDebugMode) {
            print("Error: Token extraction failed");
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error extracting token: $e");
        }
      }
    }
  }

  String extractToken(String jsonResponse) {
    try {
      String cleanJson = jsonResponse
          .replaceAll("\\\"", "\"")
          .replaceAll("\"{", "{")
          .replaceAll("}\"", "}");

      Map<String, dynamic> jsonMap = jsonDecode(cleanJson);

      return jsonMap["access_token"] ?? "";
    } catch (e) {
      if (kDebugMode) {
        print("JSON Parsing Error: $e");
      }
      return "";
    }
  }
}
