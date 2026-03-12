import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/metro_page_push.dart';
import 'package:metro_ui/page.dart';
import 'package:metro_ui/widgets/button.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/panorama.dart';

class PanoramaPage extends StatefulWidget {
  const PanoramaPage({super.key});

  @override
  State<PanoramaPage> createState() => _PanoramaPageState();
}

class _PanoramaPageState extends State<PanoramaPage> {
  final GlobalKey<MetroPageScaffoldState> _scaffoldKey = GlobalKey<MetroPageScaffoldState>();
  final List<MetroPanoramaItem> _items = [];

  //当前所在页数
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _items.addAll([
      MetroPanoramaItem(
        title: const Text('favorites'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 280, height: 120, color: Colors.blue.withOpacity(0.3)),
            const SizedBox(height: 10),
            Container(
                width: 280, height: 120, color: Colors.blue.withOpacity(0.3)),
          ],
        ),
      ),
      MetroPanoramaItem(
        title: const Text("what's new"),
        child: Wrap(
          spacing: 15,
          runSpacing: 15,
          children: List.generate(
              4,
              (i) => Container(
                  width: 130,
                  height: 130,
                  color: Colors.green.withOpacity(0.3))),
        ),
      ),
      MetroPanoramaItem(
        title: const Text("long view"),
        width: 800,
        child: Container(
          width: 800,
          height: 200,
          color: Colors.orange.withOpacity(0.3),
          child: const Center(
              child: Text(
                  "This is a long page\nYou can stop in the middle or swipe to trigger looping",
                  style: TextStyle(fontSize: 18))),
        ),
        // Row(
        //     children: List.generate(
        //         5,
        //         (i) => Container(
        //               width: 120,
        //               height: 120,
        //               margin: const EdgeInsets.only(right: 15),
        //               color: Colors.orange.withOpacity(0.3 + (i % 5) * 0.1),
        //               child: Center(
        //                   child: Text("Item ${i + 1}",
        //                       style: const TextStyle(fontSize: 16))),
        //             )),
        //   ),
      ),
      MetroPanoramaItem(
        title: const Text("people"),
        child: Container(
          //width: 280,
          height: 250,
          color: Colors.purple.withOpacity(0.3),
          child: const Center(
              child: Text("Contacts", style: TextStyle(fontSize: 20))),
        ),
      ),
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      key: _scaffoldKey,
      applicationBar: MetroApplicationBar(
        mini: _currentPage == 3,
        buttons: [
          if (_currentPage == 1)
            MetroAppBarButton(
              icon: Icon(Icons.add),
              label: 'new',
              onPressed: () {
                metroPagePush(
                  context,
                  MetroPageRoute(
                    builder: (context) {
                      return const PanoramaPage();
                    },
                  ),
                  scaffoldKey: _scaffoldKey
                  //提供一种便利的方法，可以将范型参数传递给onDidPushNext，主要设计目的是为了方便动画传参
                  //例如：Windows Phone中，被点击的Tile往往是最后一个飞出的，可能需要把Tile的index传递过去，然后在onDidPushNext中处理动画
                  //dataToPass: index,
                );
              },
            ),
          MetroAppBarButton(
            icon: Icon(Icons.search),
            label: 'search',
            onPressed: () {},
          ),
        ],
        menuItems: [
          MetroAppBarMenuItem(label: '设置', onPressed: () {}),
          MetroAppBarMenuItem(
              label: '返回',
              onPressed: () {
                Navigator.maybePop(context);
              }),
        ],
      ),
      body: Stack(
        children: [
          //背景贴图
          // Image.asset(
          //   'images/wp_ss_20260308_0001.png',
          //   fit: BoxFit.fitWidth,
          //   width: double.infinity,
          //   height: double.infinity,
          // ),
          //           ColorFiltered(
          //   colorFilter: ColorFilter.mode(
          //     Colors.black.withOpacity(0.6),
          //     BlendMode.darken,
          //   ),
          //   child: Image.asset(
          //     'images/wp_ss_20260308_0001.png',
          //     fit: BoxFit.cover,
          //     alignment: Alignment.topLeft,
          //   ),
          // ),
          MetroPanorama(
            onPageChange: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            title: const Text('photos'),
            background: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.1),
                BlendMode.darken,
              ),
              child: Image.asset(
                'images/sample_photo_00.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topLeft,
              ),
            ),
            items: _items,
            // onPageChange: (index) {
            //   debugPrint('Moved to page: $index');
            // },
          ),
        ],
      ),
    );
  }
}
