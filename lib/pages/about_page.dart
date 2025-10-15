import 'package:flutter/material.dart';
import 'package:metro_ui/stack_panel.dart';
import 'package:metro_ui/widgets/button.dart';
import 'package:metro_ui/page_scaffold.dart';

// ... 其他代码

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      //backgroundColor: Colors.blueGrey,
      stackPanel: const StackPanel(
        top: Text('FLUMETRO'),
        bottom: Text('about'),
      ),
      body: Builder(
        // 使用 Builder 来获取正确的 context
        builder: (scaffoldContext) {
          return Column(
            children: <Widget>[
              const SizedBox(height: 20),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 19.0),
                child: 
                SingleChildScrollView(
                  child: 
                Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'I’m truly proud to announce the release of this project.\nThanks to Flutter’s efficient and delightful development experience, this classic Windows Phone design language has been brought back to life.\nI hope you enjoy this project and consider using it in your own applications.\nAs an amateur developer, I know my code may still have plenty of room for improvement.\nIf you like this project, I warmly welcome your contributions to make it even better.\n\nAnd hey — if you’d like to show your support, I wouldn’t say no to a cup of coffee. XD\n\n— Canplayer, Developer',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 72.5),
                      MetroButton(
                        child: const Text('back to home'),
                        onTap: () {
                          // 这里使用的 context 是 PhoneApplicationPage 的 context
                          // 它没有 MetroPageScaffold 作为祖先
                          Navigator.maybePop(scaffoldContext);
                        },
                      ),
                    ]),
                ),
              ),),
            ],
          );
        },
      ),
    );
  }
}
