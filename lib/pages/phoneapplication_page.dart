
import 'package:flutter/material.dart';
import 'package:metro_ui/widgets/switcher.dart';
import 'package:metro_ui/widgets/button.dart';
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
      //backgroundColor: Colors.blueGrey,
      body: Builder(
        // 使用 Builder 来获取正确的 context
        builder: (scaffoldContext) {
          return Stack(
            children: [
              //背景图片
              SizedBox(
                width: 384,
                height: 640,
                child: Opacity(
                  opacity: 0.2,
                  child: Image.asset(
                    'images/wp_ss_20240831_0002.png', // 替换为你的图片路径
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),

              SafeArea(
                top: true, // 避让顶部刘海/状态栏/灵动岛
                bottom: false, // 不避让底部，保持全屏效果
                left: false, // 不避让左侧
                right: false, // 不避让右侧
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    //一个50x50的红色方块
                    Container(
                      height: 25,
                      color: Colors.red.withAlpha(100),
                    ),
                    SizedBox(
                      height: 200,
                      child: Stack(
                        children: [
                          const Positioned(
                            left: 18,
                            top: 13,
                            child: Text(
                              'SETTINGS',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          const Positioned(
                            left: 15,
                            top: 28,
                            child: Text(
                              'ringtones+sources',
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                  fontSize: 57,
                                  fontWeight: FontWeight.w300,
                                  ),
                            ),
                          ),
                          Positioned(
                            right: 20,
                            top: 154,
                            child: CustomSwitch(
                              value: true,
                              onChanged: (value) {},
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 19.0),
                      
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        const Text(
                          'Ringer',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 72.5),
                        MetroButton(
                          child: const Text('Nokia Tune'),
                          onTap: () {
                            // 这里使用的 context 是 PhoneApplicationPage 的 context
                            // 它没有 MetroPageScaffold 作为祖先
                            Navigator.maybePop(scaffoldContext);
                          },
                        ),
                        const SizedBox(height: 20),
                        MetroButton(
                          child:
                              const Text('新一页'),
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
                      ]),
                    )),
                  ],
                ),
              ),
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
