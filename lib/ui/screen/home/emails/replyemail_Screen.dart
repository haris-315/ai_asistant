// import 'package:flutter/material.dart';
// import 'package:responsive_sizer/responsive_sizer.dart';
//
// import '../../../widget/appbar.dart';
//
// class ReplyemailScreen extends StatefulWidget {
//   final Map<String, dynamic> email;
//
//   ReplyemailScreen({required this.email});
//
//   @override
//   _ReplyemailScreenState createState() => _ReplyemailScreenState();
// }
//
// class _ReplyemailScreenState extends State<ReplyemailScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//
//   @override
//   void dispose() {
//     _focusNode.dispose();
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final textTheme = Theme.of(context).textTheme;
//
//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       backgroundColor: Colors.white,
//       appBar: CustomAppBar(
//         title: "AI Assistant",
//         onNotificationPressed: () {
//           print("Notification Clicked!");
//         },
//         onProfilePressed: () {
//           print("Profile Clicked!");
//         },
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: EdgeInsets.symmetric(horizontal: 16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   IconButton(
//                     icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 24),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   SizedBox(height: 2.h),
//
//                   Row(
//                     children: [
//                       CircleAvatar(
//                         backgroundColor: Colors.pink.shade100,
//                         child: Text(
//                           widget.email["name"][0],
//                           style: textTheme.titleMedium?.copyWith(
//                               color: Colors.black, fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       SizedBox(width: 10),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             widget.email["name"],
//                             style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
//                           ),
//                           Row(
//                             children: [
//                               Text(
//                                 "<michelle.rivera@example.com>",
//                                 style: textTheme.bodyMedium?.copyWith(
//                                     color: Colors.black, fontWeight: FontWeight.bold),
//                               ),
//                               TextButton(
//                                 onPressed: () {},
//                                 child: Text(
//                                   "Unsubscribe",
//                                   style: textTheme.bodyMedium?.copyWith(
//                                       color: Colors.black,
//                                       fontWeight: FontWeight.bold,
//                                       decoration: TextDecoration.underline),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 1.h),
//
//                   Text(
//                     "to me",
//                     style: textTheme.bodyMedium?.copyWith(
//                         color: Colors.black, fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 2.h),
//
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: Container(
//                       padding: EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.shade50,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Text(
//                         "Hello Arslan,",
//                         style: textTheme.bodyLarge,
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 1.h),
//
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: Container(
//                       padding: EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.shade50,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Text(
//                         '''Wanted to give you an update on the project:
// - Task 1 completed
// - Task 2 in progress
// - Task 3 scheduled for tomorrow''',
//                         style: textTheme.bodyLarge,
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 1.h),
//
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: Container(
//                       padding: EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.shade50,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Text(
//                         "Best regards,\nJohn Doe",
//                         style: textTheme.bodyLarge,
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 2.h),
//
//                   Row(
//                     children: [
//                       Icon(Icons.image, size: 40, color: Colors.black),
//                       SizedBox(width: 10),
//                       Text("[📎 1.png]",
//                           style: textTheme.bodyLarge?.copyWith(color: Colors.black)),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//
//       bottomNavigationBar: Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).viewInsets.bottom,
//           left: 10,
//           right: 10,
//           top: 5,
//         ),
//         child: Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.grey.shade100,
//             borderRadius: BorderRadius.circular(30),
//           ),
//           child: Row(
//             children: [
//               SizedBox(width: 8),
//               Image.asset('assets/link.png'),
//               Expanded(
//                 child: TextField(
//                   controller: _controller,
//                   focusNode: _focusNode,
//                   decoration: InputDecoration(
//                     hintText: "Type Something...",
//                     border: InputBorder.none,
//                   ),
//                 ),
//               ),
//               GestureDetector(
//                 onTap: () {
//                   FocusScope.of(context).unfocus();
//                 },
//                 child: Container(
//                   padding: EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.blue,
//                   ),
//                   child: Icon(Icons.send, color: Colors.white),
//                 ),
//               ),
//
//             ],
//           ),
//
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../../Controller/auth_controller.dart';
import '../../../widget/appbar.dart';
import '../../../widget/snackbar.dart';

class ReplyemailScreen extends StatefulWidget {
  final Map<String, dynamic> email;

  const ReplyemailScreen({super.key, required this.email});

  @override
  _ReplyemailScreenState createState() => _ReplyemailScreenState();
}

class _ReplyemailScreenState extends State<ReplyemailScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool isLoading = false;
  final AuthController authcontroller = Get.find<AuthController>();

  List<Map<String, dynamic>> messages = [];

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    String replyText = _controller.text.trim();
    if (replyText.isEmpty) {
      showCustomSnackbar(
        title: "Error",
        message: "Please Enter your Reply Message",
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    bool? success = await authcontroller.emailReply(widget.email["id"], replyText);

    if (success == true) {
      setState(() {
        messages.add({
          "sender": "You",
          "body": replyText,
        });
        _controller.clear();
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final email = widget.email;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "AI Assistant",
        onNotificationPressed: () => print("Notification Clicked!"),
        onProfilePressed: () => print("Profile Clicked!"),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(height: 2.h),

                  // Sender Information
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.pink.shade100,
                        child: Text(
                          email["sender"]?["name"]?[0] ?? 'N',
                          style: textTheme.titleMedium?.copyWith(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email["sender"]?["name"] ?? "Unknown Sender",
                            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Text(
                                "<${email["sender"]?["email"] ?? "No email"}>",
                                style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  "Unsubscribe",
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),

                  // To Recipient Information
                  Text(
                    "to ${email["toRecipients"]?.first["name"] ?? "Unknown Recipient"}",
                    style: textTheme.bodyMedium?.copyWith(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2.h),

                  // Email Body Preview
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        email['body_preview'] ?? 'No email body content available.',
                        style: textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Display previous replies
                  Text(
                    "Replies:",
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  ...messages.map((msg) => Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Align(
                      alignment: msg["sender"] == "You"
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: msg["sender"] == "You" ? Colors.blue.shade50 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          msg["body"],
                          style: textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  )),

                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 10,
          right: 10,
          top: 5,
        ),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              SizedBox(width: 8),
              Image.asset('assets/link.png'),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: "Type Something...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _sendReply,
                child: isLoading
                    ? CircularProgressIndicator()
                    : Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
