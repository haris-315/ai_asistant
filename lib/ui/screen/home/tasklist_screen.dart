import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widget/appbar.dart';
import '../../widget/drawer.dart';
import 'emails/newemail_screen.dart';

class TasklistScreen extends StatelessWidget {
  final List<Map<String, dynamic>> emails = List.generate(
    4,
    (index) => {
      "name": index % 2 == 0 ? "John Doe" : "Prepare",
      "subject":
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed eiusmod tempor incididunt ut labore et dolore magna aliqua.",
      "time": "01/10",
      "avatar": index % 2 == 0 ? "assets/Avatar1.png" : "assets/Avatar2.png",
    },
  );

  TasklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: "AI Assistant",
       
      ),
      drawer: SideMenu(),

      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        shape: CircleBorder(),
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Get.to(() => NewMessageScreen());
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Builder(
                    builder: (context) {
                      return Container(
                        height: 6.5.h,
                        width: 13.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey, width: 1),
                          color: Colors.white,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.menu, color: Colors.black),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
            Text(
              "Urgent emails",
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: emails.length,
                itemBuilder: (context, index) {
                  final email = emails[index];
                  return Padding(
                    padding: EdgeInsets.only(left: 2.5.w, right: 2.5.w),
                    child: GestureDetector(
                      // onTap: () {
                      //   Get.to(() => EmailDetailScreen(email: email));
                      // },
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey, width: 0.1),
                        ),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,

                                    children: [
                                      CircleAvatar(
                                        backgroundImage: AssetImage(
                                          email["avatar"],
                                        ),
                                      ),
                                      SizedBox(width: 5.w),
                                      Text(
                                        email["name"],
                                        style: textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(width: 10),
                                  Text(
                                    email["time"],
                                    style: textTheme.labelLarge,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          email["subject"],
                                          style: textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
