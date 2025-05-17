import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widget/appbar.dart';
import '../../widget/drawer.dart';


class ParticipantsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> emails = List.generate(
    8,
        (index) => {
      "name": "John Doe",
      "subject": "Monthly Report",
      "time": "10:30 AM",
      "avatarColor": index % 2 == 0 ? Colors.blue : Colors.red,
    },
  );

  ParticipantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      CustomAppBar(
        title: "AI Assistant",
        onNotificationPressed: () {
          print("Notification Clicked!");
        },
        onProfilePressed: () {
          print("Profile Clicked!");
        },
      ),
      drawer: SideMenu(),

      backgroundColor: Colors.white,
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
                            border: Border.all(
                              color: Colors.grey,
                              width: 1,
                            ),
                            color: Colors.white,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.menu, color: Colors.black),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();


                            },
                          ),
                        );
                      }
                  ),
                  SizedBox(width: 3.w,),
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

            SizedBox(height: 10),


            SizedBox(height: 20),
            Text(
              "Participants",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: emails.length,
                itemBuilder: (context, index) {
                  final email = emails[index];
                  return Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: email["avatarColor"],
                          child: Text(
                            email["name"][0],
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          email["name"],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(email["subject"], style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        trailing: Text(email["time"]),
                      ),
                      Divider(),
                    ],
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