import 'package:flutter/material.dart';
import 'package:metro_ui/page_scaffold.dart';

class RotPage extends StatelessWidget {
  const RotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          //背景图片
          SizedBox(
            child: Opacity(
              opacity: 1,
              child: Image.asset(
                'images/3d.png', // 替换为你的图片路径
                fit: BoxFit.fitWidth,
                alignment: Alignment.topLeft,
              ),
            ),
          ),
          //3D旋转
          Positioned(
            child: Transform(
              alignment: Alignment.center,
              origin: const Offset(((-480 / 2) - 240) * 0.8, 0),
              transform: Matrix4.identity()
                //旋转-37.2度
                ..rotateY(-60.9201 * 3.1415926 / 180),
              child: OverflowBox(
                maxWidth: double.infinity,
                alignment: Alignment.topLeft,
                child: Container(
                  clipBehavior: Clip.none,
                  color: Colors.blue.withAlpha(50),
                  child: const SizedBox(
                    width: 4800 * 0.8,
                    //height: 200,
                    child: Center(
                      child: Text(
                        '3D Rotation Test',
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
