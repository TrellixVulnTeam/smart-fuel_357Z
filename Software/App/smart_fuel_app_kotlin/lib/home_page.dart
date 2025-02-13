import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';


import 'widgets/main_widget.dart';
import 'widgets/circular_status.dart';
import 'drink_stats/drink_stats.dart';
import 'drink_stats/data.dart';
import 'background_service/notification.dart';
import 'main.dart';

import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

import 'package:background_fetch/background_fetch.dart';
import 'package:home_widget/home_widget.dart';
import "package:smart_fuel_app_kotlin/Database/database.dart";
import "package:smart_fuel_app_kotlin/Database/stats.dart";

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double drunken_water = 0;
  List<List<int>> lists = [];

  bool callbackRegistered = false;
  int receivingPacket = 1;

  int _status = 0;
  List<DateTime> _events = [];
  int _counter = 0;


  void loadData() async {
    await HomeWidget.getWidgetData<int>('_counter', defaultValue: 0).then((value) {
      _counter = value!;
    });
    setState(() {});
  }

  Future<void> updateAppWidget(int drunkenWater) async {
    await HomeWidget.saveWidgetData<int>('_counter', drunkenWater);
    await HomeWidget.updateWidget(name: 'AppWidgetProvider', iOSName: 'AppWidgetProvider');
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    int status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            startOnBoot: true,
            requiredNetworkType: NetworkType.NONE), (String taskId) async {
      // <-- Event handler
     MyApp.backgroundConnect();
      BackgroundFetch.finish(taskId);

    }, (String taskId) async {
      // <-- Task timeout handler.
      // This task has exceeded its allowed running-time.  You must stop what you're doing and immediately .finish(taskId)
      print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      BackgroundFetch.finish(taskId);
    });
    print('[BackgroundFetch] configure success: $status');
    setState(() {
      _status = status;
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    BackgroundFetch.start().then((int status) {
      print('[BackgroundFetch] start success: $status');
    }).catchError((e) {
      print('[BackgroundFetch] start FAILURE: $e');
    });
  }

  @override
  void initState() {
    NotificationService().init();
    initPlatformState();
    updateAppWidget(drunken_water.toInt());
  }

  void PushDrinkStatsWidget() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) =>
              DrinkStats(inputData: lists.expand((i) => i).toList())),
    );
  }

  Future<Null> _refreshLocalGallery() async {

 DayStats dayStats = await MyApp.getDrinkData();

 if(dayStats.avgGulpSize != -1) {
   drunken_water = dayStats.sumOfWater.toDouble();
   //DBProvider.db.newClient(Client(id: 2, firstName: "Nici", lastName: "Walter"));
   Client c = await DBProvider.db.getClient(2);
  print(c.firstName);
   await HomeWidget.saveWidgetData<int>('_counter', dayStats.sumOfWater);
   await HomeWidget.updateWidget(
       name: 'AppWidgetProvider', iOSName: 'AppWidgetProvider');

   setState(() {
   });
  } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Gerät konnte nicht gefunden werden"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: Text(widget.title, style: const TextStyle(fontSize: 23))),
      ),
      body: LiquidPullToRefresh(
        onRefresh: _refreshLocalGallery,
        showChildOpacityTransition: false,
        springAnimationDurationInMilliseconds: 600,
        height: 70,
        color: const Color(0x2216B9ED),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularStatus(
                      progress: 2400,
                      height: 70,
                      padding: 5,
                      width: 50,
                      child: const Text("M")),
                  CircularStatus(
                      progress: 800,
                      height: 70,
                      padding: 5,
                      width: 50,
                      child: const Text("D")),
                  CircularStatus(
                      progress: 1000,
                      height: 70,
                      padding: 5,
                      width: 50,
                      child: const Text("M")),
                  CircularStatus(
                      progress: 1200,
                      height: 70,
                      padding: 5,
                      width: 50,
                      child: const Text("D")),
                  CircularStatus(
                      progress: 1400,
                      height: 70,
                      padding: 5,
                      width: 50,
                      child: const Text("F")),
                  CircularStatus(
                      progress: 100,
                      height: 70,
                      padding: 5,
                      width: 50,
                      child: const Text("S")),
                  // CircularStatus(
                  //     progress: 30, height: 50, padding:10, child: const Text("M")),
                ],
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Heute",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              CircularStatus(
                progress: drunken_water,
                height: 200,
                width: 180,
                padding: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        height: 50,
                        child: SvgPicture.asset("assets/glass_icon.svg"),
                      ),
                    ),
                    Text(drunken_water.round().toString(),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text("ml",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 100,
                  child: MainWidget(
                    title: "Trinkgewohnheiten",
                    subTitle: "Betrachte deine Trends",
                    iconPath: "assets/stats_icon.svg",
                    onPressedFunction: PushDrinkStatsWidget,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 100,
                  child: MainWidget(
                    title: "Wiegen",
                    subTitle: "Deine Flasche als Waage",
                    iconPath: "assets/waage_icon.svg",
                    onPressedFunction: () {
                      NotificationService().showNotificationWithNoBadge(
                          "Trinkerinnerung", "Hey! Trink mal wieder etwas...");
                      print('notify');
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 100,
                  child: MainWidget(
                    title: "Flasche",
                    subTitle: "Personalisiere deine Flasche",
                    iconPath: "assets/bottle_icon.svg",
                    onPressedFunction: PushDrinkStatsWidget,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 100,
                  child: MainWidget(
                    title: "Einstellungen",
                    subTitle: "Konto, Benachrichtigungen ...",
                    iconPath: "assets/setting_icon.svg",
                    onPressedFunction: () async {
                      BackgroundFetch.start().then((int status) {
                        print('[BackgroundFetch] start success: $status');
                      }).catchError((e) {
                        print('[BackgroundFetch] start FAILURE: $e');
                      });
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
