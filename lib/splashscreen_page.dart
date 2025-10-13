import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:metro_ui/page_scaffold.dart';

/// 艺术化文字展示页面
class ArtisticTextPage extends StatefulWidget {
  const ArtisticTextPage({super.key});

  @override
  State<ArtisticTextPage> createState() => _ArtisticTextPageState();
}

class _ArtisticTextPageState extends State<ArtisticTextPage> {
  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      body: Center(
        child: 
        SizedBox(
          width: 330,
          height: 128,
          // color: Colors.grey.shade300,
          child: 
        Stack(
          children: [
             //一个80x80的红色矩形，中间一个icon
             Positioned(
               child: Container(
                 width: 73.6,
                 height: 73.6,
                 color: Colors.red,
                 child: Center(
                   //padding: const EdgeInsets.all(8.0),
                   child: SvgPicture.asset(
                    height: 50,
                    width: 50,
                     'images/icons/flutter.svg',
                     colorFilter: const ColorFilter.mode(
                       Colors.white,
                       BlendMode.srcIn,
                     ),
                   ),
                 ),
               ),
             ),
            const Positioned(
              left: 90,
              top: -15,
              child: Text(
                'Flumetro',
                style: TextStyle(
                  fontSize: 66,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -3.0,
                ),
              ),
            ),
            const Positioned(
              left: 90,
              top: 45,
              child: Text(
                'Phone',
                style: TextStyle(
                  fontSize: 66,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -3.0,
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
