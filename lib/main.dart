import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'widgets/hud.dart';
import 'game/dino_run.dart';
import 'models/settings.dart';
import 'widgets/main_menu.dart';
import 'models/player_data.dart';
import 'widgets/pause_menu.dart';
import 'widgets/settings_menu.dart';
import 'widgets/game_over_menu.dart';

/// This is the single instance of [DinoRun] which
/// will be reused throughout the lifecycle of the game.
DinoRun _dinoRun = DinoRun();

bool isLandscape = false;

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  ///全屏
  Flame.device.fullScreen();
  if(isLandscape){
    ///横屏模式
    Flame.device.setLandscape();
  }else{
    ///竖屏模式
    Flame.device.setPortrait();
  }


  ///初始化hive 数据库
  await initHive();
  runApp(const DinoRunApp());
}

// This function will initilize hive with apps documents directory.
// Additionally it will also register all the hive adapters.
Future<void> initHive() async {
  // For web hive does not need to be initialized.
  if (!kIsWeb) {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
  }

  Hive.registerAdapter<PlayerData>(PlayerDataAdapter());
  Hive.registerAdapter<Settings>(SettingsAdapter());
}

// The main widget for this game.
class DinoRunApp extends StatelessWidget {
  const DinoRunApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

  /*  final size = MediaQuery.of(context).size;
    final width =size.width;
    final height =size.height;*/

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dino Run',
      ///主题修改
      theme: ThemeData(
        fontFamily: 'Audiowide',
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Settings up some default theme for elevated buttons.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            fixedSize: const Size(200, 60),
          ),
        ),
      ),
      home: Scaffold(
        body: GameWidget(
          loadingBuilder: (conetxt) => loading(),
          overlayBuilderMap: {
            ///主菜单
            MainMenu.id: (_, DinoRun gameRef) => MainMenu(gameRef),
            ///暂停菜单
            PauseMenu.id: (_, DinoRun gameRef) => PauseMenu(gameRef),
            ///游戏中显示的数据界面(速度，血条，得分等)
            Hud.id: (_, DinoRun gameRef) => Hud(gameRef),
            ///游戏结束菜单
            GameOverMenu.id: (_, DinoRun gameRef) => GameOverMenu(gameRef),
            ///设置菜单
            SettingsMenu.id: (_, DinoRun gameRef) => SettingsMenu(gameRef),
          },
          ///初始化显示主菜单
          initialActiveOverlays: const [MainMenu.id],
          ///游戏
          game: _dinoRun,
        ),
      ),
    );
  }


  Widget loading() => const Center(
    child: SizedBox(
      width: 200,
      child: LinearProgressIndicator(),
    ),
  );
}
