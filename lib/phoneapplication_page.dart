import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:metro_ui/button.dart';
import 'package:metro_ui/metro_page_push.dart';
import 'package:metro_ui/page.dart';
import 'package:metro_ui/page_scaffold.dart';

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
      body: Builder(
        // 使用 Builder 来获取正确的 context
        builder: (scaffoldContext) {
          return Stack(
            children: [
              //背景图片
              SizedBox(
                width: 384,
                height: 800,
                child: Image.asset(
                  'images/wp_ss_20240831_0002.png', // 替换为你的图片路径
                  fit: BoxFit.fitWidth,
                ),
              ),

              SafeArea(
                top: false, // 避让顶部刘海/状态栏
                bottom: false, // 不避让底部，因为您可能想让内容延伸到底部
                left: true, // 避让左侧（横屏时的刘海）
                right: true, // 避让右侧（横屏时的刘海）
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      //SizedBox(height: 13),
                      const Text(
                        'SETTINGS',
                        style: TextStyle(fontSize: 23),
                      ),
                      //向左移动 10px
                      Transform.translate(
                        offset: const Offset(-5, -10),
                        child: Text(
                          'ringtones+so',
                          style: TextStyle(
                              fontSize: 71,
                              fontWeight: FontWeight.w300,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Ringer',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 40),
                      MetroButton(
                        child: const Text('返回', style: TextStyle(fontSize: 30)),
                        onTap: () {
                          // 这里使用的 context 是 PhoneApplicationPage 的 context
                          // 它没有 MetroPageScaffold 作为祖先
                          Navigator.maybePop(scaffoldContext);
                        },
                      ),
                      const SizedBox(height: 20),
                      MetroButton(
                        child:
                            const Text('新一页', style: TextStyle(fontSize: 30)),
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
                ),
              )
            ],
          );

          // Center(
          //   child: Column(
          //     spacing: 20,
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: <Widget>[
          //       const Text(
          //         'Hello, World!',
          //         style: TextStyle(fontSize: 60),
          //       ),
          //       const Text(
          //         'This is a simple Flutter application.',
          //         style: TextStyle(fontSize: 24),
          //       ),
          //       MetroButton(
          //         child: const Text('返回',
          //             style: TextStyle(fontSize: 30)),
          //         onTap: () {
          //           // 这里使用的 context 是 PhoneApplicationPage 的 context
          //           // 它没有 MetroPageScaffold 作为祖先
          //           Navigator.maybePop(scaffoldContext);
          //         },
          //       ),
          //       MetroButton(
          //         child: const Text('新一页',
          //             style: TextStyle(fontSize: 30)),
          //         onTap: () {
          //           // 使用 Builder 提供的 scaffoldContext
          //           metroPagePush(
          //             scaffoldContext,
          //             MetroPageRoute(
          //               builder: (context) {
          //                 return const PhoneApplicationPage();
          //               },
          //             ),
          //           );
          //         },
          //       ),
          //     ],
          //   ),
          // );
        },
      ),
    );
  }
}
