// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class NoConnectionPage extends StatefulWidget {
  const NoConnectionPage({super.key});

  @override
  State<NoConnectionPage> createState() => _NoConnectionPageState();
}

enum AnimType { d, i }

class _NoConnectionPageState extends State<NoConnectionPage> {
  List<IconData> icons = [Icons.wifi_1_bar, Icons.wifi_2_bar, Icons.wifi];
  int selectedIcon = 0;
  AnimType at = AnimType.i;
  void loopAnim() async {
    while (true) {
      await Future.delayed(Duration(milliseconds: 1000)).then((d) {
        setState(() {
          if (selectedIcon < 2 && at == AnimType.i) {
            selectedIcon++;
            if (selectedIcon == 2) {
              at = AnimType.d;
            }
          } else if (selectedIcon > 0 && at == AnimType.d) {
            selectedIcon--;
            if (selectedIcon == 0) {
              at = AnimType.i;
            }
          }
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loopAnim();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.white70.withValues(alpha: .8),
            Colors.white70.withValues(alpha: .9),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(55.0),
            child: Row(
              children: [
                Column(
                  children: [
                    Icon(
                      MdiIcons.wifiOff,
                      size: 42,
                      color: Colors.grey.withValues(alpha: .8),
                    ),
                    Icon(MdiIcons.cellphone, size: 43),
                    SizedBox(height: 8),
                    Text(
                      "No Internet!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Expanded(child: Divider(color: Colors.blueGrey)),
                Column(
                  children: [
                    Icon(
                      icons[selectedIcon],
                      size: 42,
                      color: Colors.grey.withValues(alpha: .8),
                    ),
                    Icon(MdiIcons.cellphone, size: 43),
                    SizedBox(height: 8),
                    Text(
                      "Connecting${"." * (selectedIcon + 1)}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: TextAnimater(text: "Hello This is Haris"),
          ),
        ],
      ),
    );
  }
}

class TextAnimater extends StatefulWidget {
  final String text;
  const TextAnimater({super.key, required this.text});

  @override
  State<TextAnimater> createState() => _TextAnimaterState();
}

class _TextAnimaterState extends State<TextAnimater> {
  late String text;
  String partFirst = "";
  String partHigh = "";
  String partLast = "";
  @override
  void initState() {
    super.initState();
    text = widget.text;
    animteText();
  }

  void animteText() async {
    int lastAnimIndex = 0;
    while (true) {
      List<String> slicedText = text.split(" ");
      print(text);
      print(slicedText);
      setState(() {
        partHigh = slicedText[lastAnimIndex].toUpperCase();
        partFirst = slicedText.getRange(0, lastAnimIndex - 1).join(" ");
        partLast = slicedText
            .getRange(lastAnimIndex + 1, slicedText.length)
            .join(" ");
      });
      if (lastAnimIndex >= slicedText.length) {
        lastAnimIndex = 0;
      } else {
        lastAnimIndex++;
      }

      await Future.delayed(Duration(milliseconds: 1500));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: partFirst,
        children: [
          TextSpan(
            text: " $partHigh",
            style: TextStyle(
              color: Colors.blue,
              fontSize: 18,
              decoration: TextDecoration.none,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: " $partLast",
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 18,
              decoration: TextDecoration.none,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        style: TextStyle(
          color: Colors.blueGrey,
          fontSize: 18,
          decoration: TextDecoration.none,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
