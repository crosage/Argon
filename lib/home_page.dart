import 'package:fluent_ui/fluent_ui.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}



class _MyHomePageState extends State<HomePage> {
  int currentIndex = 0;  // 当前选择的Tab索引
  List<Tab> tabs = [];    // 存储Tab的列表

  void createTabForScript(int scriptIndex) {
    switch(scriptIndex) {
      case 0: // 首页脚本
        createTabForHomeScript();
        break;
      case 1: // 设置脚本
        createTabForSettingsScript();
        break;
      case 2: // 文件管理脚本
        createTabForFileScript();
        break;
    }
  }
  // 定义一个图标列表与ListTile按钮匹配
  final List<Icon> icons = [
    Icon(FluentIcons.home),
    Icon(FluentIcons.settings),
    Icon(FluentIcons.file_request),
  ];

  void createTabForHomeScript() {
    setState(() {
      final newIndex = tabs.length;
      tabs.add(generateTabForHome(newIndex)); // 创建首页 Tab
      currentIndex = newIndex;
    });
  }

  void createTabForSettingsScript() {
    setState(() {
      final newIndex = tabs.length;
      tabs.add(generateTabForSettings(newIndex)); // 创建设置 Tab
      currentIndex = newIndex;
    });
  }

  void createTabForFileScript() {
    setState(() {
      final newIndex = tabs.length;
      tabs.add(generateTabForFile(newIndex)); // 创建文件管理 Tab
      currentIndex = newIndex;
    });
  }

// 每个 generateTab 方法生成不同的 Tab 页面

  Tab generateTabForHome(int index) {
    return Tab(
      key: Key('tab_$index'),
      text: Text('首页脚本'),
      icon: Icon(FluentIcons.home),
      body: Column(
        children: [
          Text('这是首页脚本的内容。'),
          FilledButton(
            onPressed: () {
              print("运行首页脚本");
              // 运行首页的脚本
            },
            child: Text('运行首页脚本'),
          ),
        ],
      ),
      onClosed: () {
        setState(() {
          tabs.removeAt(index);
          if (tabs.isEmpty) {
            currentIndex = 0;
          } else if (currentIndex >= tabs.length) {
            currentIndex = tabs.length - 1;
          }
        });
      },
    );
  }

  Tab generateTabForSettings(int index) {
    return Tab(
      key: Key('tab_$index'),
      text: Text('设置脚本'),
      icon: Icon(FluentIcons.settings),
      body: Column(
        children: [
          Text('这是设置脚本的内容。'),
          FilledButton(
            onPressed: () {
              print("运行设置脚本");
              // 运行设置脚本的逻辑
            },
            child: Text('运行设置脚本'),
          ),
        ],
      ),
      onClosed: () {
        setState(() {
          tabs.removeAt(index);
          if (tabs.isEmpty) {
            currentIndex = 0;
          } else if (currentIndex >= tabs.length) {
            currentIndex = tabs.length - 1;
          }
        });
      },
    );
  }

  Tab generateTabForFile(int index) {
    return Tab(
      key: Key('tab_$index'),
      text: Text('文件管理脚本'),
      icon: Icon(FluentIcons.file_request),
      body: Column(
        children: [
          Text('这是文件管理脚本的内容。'),
          FilledButton(
            onPressed: () {
              print("运行文件管理脚本");
              // 运行文件管理脚本的逻辑
            },
            child: Text('运行文件管理脚本'),
          ),
        ],
      ),
      onClosed: () {
        setState(() {
          tabs.removeAt(index);
          if (tabs.isEmpty) {
            currentIndex = 0;
          } else if (currentIndex >= tabs.length) {
            currentIndex = tabs.length - 1;
          }
        });
      },
    );
  }

// 默认 Tab 页面
  Tab generateDefaultTab(int index) {
    return Tab(
      key: Key('tab_$index'),
      text: Text('默认脚本'),
      icon: Icon(FluentIcons.more),
      body: Column(
        children: [
          Text('这是默认脚本的内容。'),
          FilledButton(
            onPressed: () {
              print("运行默认脚本");
              // 运行默认脚本的逻辑
            },
            child: Text('运行默认脚本'),
          ),
        ],
      ),
      onClosed: () {
        setState(() {
          tabs.removeAt(index);
          if (tabs.isEmpty) {
            currentIndex = 0;
          } else if (currentIndex >= tabs.length) {
            currentIndex = tabs.length - 1;
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: Row(
        children: [
          // 侧边栏区域
          Column(
            children: [
              // 自定义的简单侧边栏
              Container(
                width: 200,
                color: Colors.grey[50],
                child: Column(
                  children: [
                    // 首页按钮，传入对应的图标索引
                    ListTile(
                      leading: Icon(FluentIcons.home),
                      title: Text('首页'),
                      onPressed: () => createTabForScript(0),  // 图标索引为0
                    ),
                    // 设置按钮，传入对应的图标索引
                    ListTile(
                      leading: Icon(FluentIcons.settings),
                      title: Text('设置'),
                      onPressed: () => createTabForScript(1),  // 图标索引为1
                    ),
                    // 文件管理按钮，传入对应的图标索引
                    ListTile(
                      leading: Icon(FluentIcons.file_request),
                      title: Text('文件管理'),
                      onPressed: () => createTabForScript(2),  // 图标索引为2
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 主内容区域
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: TabView(
                    tabs: tabs,
                    currentIndex: currentIndex,
                    onChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    tabWidthBehavior: TabWidthBehavior.equal,
                    closeButtonVisibility: CloseButtonVisibilityMode.always,
                    showScrollButtons: true,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final item = tabs.removeAt(oldIndex);
                        tabs.insert(newIndex, item);

                        // 更新 currentIndex 以避免越界
                        if (currentIndex == oldIndex) {
                          currentIndex = newIndex;
                        } else if (currentIndex == newIndex) {
                          currentIndex = oldIndex;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
