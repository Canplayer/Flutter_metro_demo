import 'package:flutter/material.dart';
import 'package:metro_ui/button.dart';
import 'package:metro_ui/metro_page_push.dart';
import 'package:metro_ui/page.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'dart:math';

// ... 其他代码

class PhoneApplicationPage extends StatefulWidget {
  const PhoneApplicationPage({super.key});

  @override
  State<PhoneApplicationPage> createState() => _PhoneApplicationPageState();
}

class _PhoneApplicationPageState extends State<PhoneApplicationPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      backgroundColor: Colors.blueGrey,
      body: Builder( // 使用 Builder 来获取正确的 context
        builder: (scaffoldContext) {
          return Center(
            child: Column(
              spacing: 20,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Hello, World!',
                  style: TextStyle(fontSize: 60, color: Colors.white),
                ),
                const Text(
                  'This is a simple Flutter application.',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                MetroButton(
                  child: const Text('返回',
                      style: TextStyle(fontSize: 30, color: Colors.white)),
                  onTap: () {
                    // 这里使用的 context 是 PhoneApplicationPage 的 context
                    // 它没有 MetroPageScaffold 作为祖先
                    Navigator.maybePop(scaffoldContext);
                  },
                ),
                MetroButton(
                  child: const Text('新一页',
                      style: TextStyle(fontSize: 30, color: Colors.white)),
                  onTap: () {
                    // 使用 Builder 提供的 scaffoldContext
                    metroPagePush(
                      scaffoldContext,
                      MetroPageRoute(
                        builder: (context) {
                          return const PhoneApplicationPage();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
