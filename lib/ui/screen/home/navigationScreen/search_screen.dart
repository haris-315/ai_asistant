import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // final TextEditingController _searchController = TextEditingController();

  List<Map<String, String>> mediaItems = [
    {
      "title": "3D Arcade style experiments",
      "artist": "ARTCADE STUDIO",
      "image": "assets/Image.png",
      "views": "45",
      "likes": "6",
    },
    {
      "title": "Fashion Illustration Vol.22",
      "artist": "SIMONSON DESIGN",
      "image": "assets/Image1.png",
      "views": "12",
      "likes": "43",
    },
    {
      "title": "A search for matter",
      "artist": "Boris Tim",
      "image": "assets/Image2.png",
      "views": "39",
      "likes": "32",
    },
    {
      "title": "Cow Cow Cow!",
      "artist": "Multiple Creators",
      "image": "assets/Image3.png",
      "views": "101",
      "likes": "12",
    },
    {
      "title": "3D Arcade style experiments",
      "artist": "ARTCADE STUDIO",
      "image": "assets/Image.png",
      "views": "45",
      "likes": "6",
    },
    {
      "title": "Fashion Illustration Vol.22",
      "artist": "SIMONSON DESIGN",
      "image": "assets/Image1.png",
      "views": "12",
      "likes": "43",
    },
    {
      "title": "A search for matter",
      "artist": "Boris Tim",
      "image": "assets/Image2.png",
      "views": "39",
      "likes": "32",
    },
    {
      "title": "Cow Cow Cow!",
      "artist": "Multiple Creators",
      "image": "assets/Image3.png",
      "views": "101",
      "likes": "12",
    },
    {
      "title": "3D Arcade style experiments",
      "artist": "ARTCADE STUDIO",
      "image": "assets/Image.png",
      "views": "45",
      "likes": "6",
    },
    {
      "title": "Fashion Illustration Vol.22",
      "artist": "SIMONSON DESIGN",
      "image": "assets/Image1.png",
      "views": "12",
      "likes": "43",
    },
    {
      "title": "A search for matter",
      "artist": "Boris Tim",
      "image": "assets/Image2.png",
      "views": "39",
      "likes": "32",
    },
    {
      "title": "Cow Cow Cow!",
      "artist": "Multiple Creators",
      "image": "assets/Image3.png",
      "views": "101",
      "likes": "12",
    },
    {
      "title": "3D Arcade style experiments",
      "artist": "ARTCADE STUDIO",
      "image": "assets/Image.png",
      "views": "45",
      "likes": "6",
    },
    {
      "title": "Fashion Illustration Vol.22",
      "artist": "SIMONSON DESIGN",
      "image": "assets/Image1.png",
      "views": "12",
      "likes": "43",
    },
    {
      "title": "A search for matter",
      "artist": "Boris Tim",
      "image": "assets/Image2.png",
      "views": "39",
      "likes": "32",
    },
    {
      "title": "Cow Cow Cow!",
      "artist": "Multiple Creators",
      "image": "assets/Image3.png",
      "views": "101",
      "likes": "12",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                FilterChip(label: Text("Image"), onSelected: (val) {}),
                SizedBox(width: 8),
                FilterChip(label: Text("Video"), onSelected: (val) {}),
              ],
            ),
            SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: mediaItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  // crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.67,
                ),
                itemBuilder: (context, index) {
                  var item = mediaItems[index];
                  return Card(
                    color: Colors.white,
                    // shape: RoundedRectangleBorder(
                    //   borderRadius: BorderRadius.circular(10),
                    // ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              item["image"]!,
                              width: double.infinity,
                              height: 19.h,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                // Prevents overflow
                                child: Text(
                                  item["title"]!,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 1),
                              Icon(
                                Icons.favorite,
                                size: 14,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 1),
                              Text(
                                item["likes"]!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(width: 1.w),
                              Icon(
                                Icons.visibility,
                                size: 14,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 1),
                              Text(
                                item["views"]!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 1.5.h),

                          Text(
                            item["artist"]!,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
