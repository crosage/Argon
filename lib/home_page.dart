import 'dart:convert';
import 'dart:io';
import 'package:dns/tabs/active_detection_tab.dart';
import 'package:dns/tabs/pacp_validation_tab.dart';
import 'package:dns/tabs/passive_monitor_tab.dart';
import 'package:fluent_ui/fluent_ui.dart';
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

  String commandOutput = "";

  void createTabForScript(int scriptIndex) {
    switch (scriptIndex) {
      case 0:
        createTabForPassiveMonitoringScript();
        break;
      case 1:
        createTabForActiveDetectionScript();
        break;
      case 2:
        createTabForCrossValidateScript();
        break;
    }
  }

  final List<Icon> icons = [
    Icon(FluentIcons.home),
    Icon(FluentIcons.settings),
    Icon(FluentIcons.file_request),
  ];

  void createTabForPassiveMonitoringScript() {
    setState(() {
      final newIndex = tabs.length;
      print("创建了一个被动检测$newIndex");
      tabs.add(generateTabForPassiveMonitor(newIndex));
      currentIndex = newIndex;
    });
  }

  void createTabForActiveDetectionScript() {
    setState(() {
      final newIndex = tabs.length;
      print("创建了一个主动探测$newIndex");
      tabs.add(generateTabForActiveDetection(newIndex));
      currentIndex = newIndex;
    });
  }

  void createTabForCrossValidateScript() {
    setState(() {
      final newIndex = tabs.length;
      tabs.add(generateTabForCrossValidate(newIndex));
      currentIndex = newIndex;
    });
  }

  Map<int, String> commandOutputs = {};
  void updateCommandOutput(String output, int tabIndex) {
    print("接收到更新$output   index为$tabIndex}");
    setState(() {
      commandOutputs[tabIndex] = (commandOutputs[tabIndex] ?? "") + output;
      print("当前 $commandOutputs");
    });
    setState(() {});
  }

  Tab generateTabForPassiveMonitor(int index) {
    return Tab(
      key: Key('tab_$index'),
      text: Text('被动监听'),
      icon: Icon(FluentIcons.blocked_site,color: Colors.blue.darkest,),
      body: ScriptExecutionTab(index: index),
      onClosed: () {
        setState(() {
          tabs.removeAt(index);
          commandOutputs.remove(index);
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
      body: ActiveDetectionTab(index: index),
      onClosed: () {
        setState(() {
          tabs.removeAt(index);
          commandOutputs.remove(index);
          if (tabs.isEmpty) {
            currentIndex = 0;
          } else if (currentIndex >= tabs.length) {
            currentIndex = tabs.length - 1;
          }
        });
      },
    );
  }

  Tab generateTabForCrossValidate(int index) {
    return Tab(
      key: Key('tab_$index'),
      text: Text('交叉验证'),
      icon: Icon(FluentIcons.communication_details,color: Colors.orange.normal,),
      body: PcapValidationTab(index: index),
      onClosed: () {
        setState(() {
          tabs.removeAt(index);
          commandOutputs.remove(index);
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
          Column(
            children: [
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
