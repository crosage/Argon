import 'dart:convert';
import 'dart:io';

import 'package:dns/tabs/active_detection_tab.dart';
import 'package:fluent_ui/fluent_ui.dart' ;
import 'dart:math';

import 'package:flutter/material.dart' show VerticalDivider;

class HomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  int currentIndex = 0;
  List<Tab> tabs = [];
  TextEditingController interfaceController = TextEditingController();
  TextEditingController dnsServerController = TextEditingController();
  TextEditingController probeDomainController = TextEditingController();
  TextEditingController probeIntervalController = TextEditingController();

  String commandOutput = ""; // 用于存储命令行输出

  void createTabForScript(int scriptIndex) {
    switch (scriptIndex) {
      case 0:
        createTabForPassiveMonitoringScript();
        break;
      case 1:
        createTabForActiveDetection();
        break;
      case 2:
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

  void createTabForPassiveMonitoringScript() {
    setState(() {
      final newIndex = tabs.length;
      print("创建了一个被动检测$newIndex");
      tabs.add(generateTabForPassiveMonitoring(newIndex)); // 创建首页 Tab
      currentIndex = newIndex;
    });
  }

  void createTabForActiveDetection() {
    setState(() {
      final newIndex = tabs.length;
      print("创建了一个主动探测$newIndex");
      tabs.add(generateTabForActiveDetection(newIndex)); // 创建设置 Tab
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



  Map<int, String> commandOutputs = {}; // 用于存储每个tab的输出
  void updateCommandOutput(String output, int tabIndex) {
    print("接收到更新$output   index为$tabIndex}");
    setState(() {
      commandOutputs[tabIndex] = (commandOutputs[tabIndex] ?? "") + output;
      print("当前 $commandOutputs");
    });
    setState(() {

    });
  }
  Future<void> runActiveDetectionScript(
      String interface,
      String dnsServer,
      String probeDomain,
      int probeInterval,
      int tabIndex
      ) async {
    try {
      Process process = await Process.start(
        'python',
        [
          "D:\\code\\dns\\lib\\python_scripts\\active_detection\\DNS_cli.py",
          '--interface', interface,
          '--dns-server', dnsServer,
          '--probe-domain', probeDomain,
          '--probe-interval', probeInterval.toString(),
        ],
        runInShell: true,
        environment: {
          'PYTHONUNBUFFERED': '1',  // 防止缓冲影响输出
        },
      );

      // 处理标准输出
      process.stdout.transform(utf8.decoder).listen((data) {
        updateCommandOutput(data, tabIndex);
      });

      // 处理标准错误输出
      process.stderr.transform(utf8.decoder).listen((data) {
        updateCommandOutput("\n[Error]: $data", tabIndex);
      });

      // 处理脚本退出码
      int exitCode = await process.exitCode;
      if (exitCode == 0) {
        updateCommandOutput("\n[Script Finished Successfully]", tabIndex);
      } else {
        updateCommandOutput("\n[Script Failed with exit code $exitCode]", tabIndex);
      }
    } catch (e) {
      updateCommandOutput("Error: $e", tabIndex);
    }
  }


  Tab generateTabForPassiveMonitoring(int index) {
    return Tab(
      key: Key('tab_$index'),
      text: Text('被动监听'),
      icon: Icon(FluentIcons.blocked_site,color: Colors.blue.darkest,),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                // 输入框
                TextBox(
                  controller: interfaceController,
                  placeholder: '请输入网络接口',
                ),
                SizedBox(height: 5,),
                TextBox(
                  controller: dnsServerController,
                  placeholder: '请输入DNS服务器',
                ),
                SizedBox(height: 5,),
                TextBox(
                  controller: probeDomainController,
                  placeholder: '请输入探测域名',
                ),
                SizedBox(height: 5,),
                TextBox(
                  controller: probeIntervalController,
                  placeholder: '请输入探测间隔时间',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 5),
                // 运行按钮
                FilledButton(
                  onPressed: () {
                    // 获取输入框中的参数
                    String interface = interfaceController.text;
                    String dnsServer = dnsServerController.text;
                    String probeDomain = probeDomainController.text;
                    int probeInterval =
                        int.tryParse(probeIntervalController.text) ?? 5;

                    print("运行脚本");
                    // 运行脚本
                    // runScript(interface, dnsServer, probeDomain, probeInterval, index);
                  },
                  child: Text('运行脚本'),
                ),
                SizedBox(height: 20),
                // 输出区域
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    commandOutputs[index] ?? "等待输出...",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      onClosed: () {
        setState(() {
          tabs.removeAt(index);
          commandOutputs.remove(index); // 移除对应tab的输出
          if (tabs.isEmpty) {
            currentIndex = 0;
          } else if (currentIndex >= tabs.length) {
            currentIndex = tabs.length - 1;
          }
        });
      },
    );
  }

  Tab generateTabForActiveDetection(int index) {
    return Tab(
      key: Key('tab_$index'),
      text: Text('主动检测'),
      icon: Icon(FluentIcons.cricket,color: Colors.teal.darker,),
      body: ActiveDetectionTab(index: index), // 使用新的 StatefulWidget 组件
      onClosed: () {
        setState(() {
          tabs.removeAt(index);
          commandOutputs.remove(index); // 移除对应tab的输出
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
                color: Colors.grey[10],
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(FluentIcons.blocked_site,color: Colors.blue.darkest,),
                      title: Text('被动监听'),
                      onPressed: () => createTabForScript(0),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(FluentIcons.cricket,color: Colors.teal.darker,),
                      title: Text('主动探测'),
                      onPressed: () => createTabForScript(1),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(FluentIcons.communication_details,color: Colors.orange.normal,),
                      title: Text('交叉验证'),
                      onPressed: () => createTabForScript(2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          VerticalDivider(),
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
