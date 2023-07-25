import 'dart:ui';

import 'package:dino_run/main.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:hive/hive.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';

import '/game/dino.dart';
import '/widgets/hud.dart';
import '/models/settings.dart';
import '/game/audio_manager.dart';
import '/game/enemy_manager.dart';
import '/models/player_data.dart';
import '/widgets/pause_menu.dart';
import '/widgets/game_over_menu.dart';



// This is the main flame game class.
class DinoRun extends FlameGame with TapDetector, HasCollisionDetection {

  double? width;
  double? height;

  DinoRun({this.width,this.height});


  ///所有图像资产的列表。
  static const _imageAssets = [
    'DinoSprites - tard.png',//小恐龙
    'AngryPig/Walk (36x30).png',//猪(固定)
    'Bat/Flying (46x30).png',//蝙蝠(天上飞)
    'Rino/Run (52x34).png',//犀牛(地上移动)
    'parallax/plx-1.png',//背景图
    'parallax/plx-2.png',
    'parallax/plx-3.png',
    'parallax/plx-4.png',
    'parallax/plx-5.png',
    'parallax/plx-6.png',
  ];

  ///所有音频资产的列表
  static const _audioAssets = [
    '8BitPlatformerLoop.wav',//背景循环音效
    'hurt7.wav',//伤害音效
    'jump14.wav',//跳起来音效
  ];

  late Dino _dino;
  late Settings settings;
  late PlayerData playerData;
  late EnemyManager _enemyManager;

  ///当 Flame 准备这个游戏时会调用此方法。
  @override
  Future<void> onLoad() async {
    /// Read [PlayerData] and [Settings] from hive.
    playerData = await _readPlayerData();
    settings = await _readSettings();

    /// Initilize [AudioManager].
    await AudioManager.instance.init(_audioAssets, settings);

    ///开始播放背景音乐。内部负责检查用户设置
    AudioManager.instance.startBgm('8BitPlatformerLoop.wav');

    ///缓存所有图像
    await images.loadAll(_imageAssets);


    ///设置固定视口以避免手动缩放和处理不同的屏幕尺寸
    if(isLandscape){
      //横向屏幕固定
       camera.viewport = FixedResolutionViewport(Vector2(360, 180));
    }else{
      //竖屏固定
      final width = window.physicalSize.width;
      final height = window.physicalSize.height;
      camera.viewport = FixedResolutionViewport(Vector2((width??0)/10, (height??0)/10));
    }


    ///游戏背后的背景(树林图片)
    final parallaxBackground = await loadParallaxComponent(
      [
        ParallaxImageData('parallax/plx-1.png'),
        ParallaxImageData('parallax/plx-2.png'),
        ParallaxImageData('parallax/plx-3.png'),
        ParallaxImageData('parallax/plx-4.png'),
        ParallaxImageData('parallax/plx-5.png'),
        ParallaxImageData('parallax/plx-6.png'),

       // ParallaxImageData('background.png'),
      ],
      baseVelocity: Vector2(10, 0),///游戏基本速度（控制背景移动的快慢）
      velocityMultiplierDelta: Vector2(1.4, 0),///速度
    );
    add(parallaxBackground);

    return super.onLoad();
  }

  /// This method add the already created [Dino]
  /// and [EnemyManager] to this game.
  void startGamePlay() {
    _dino = Dino(images.fromCache('DinoSprites - tard.png'), playerData);
    _enemyManager = EnemyManager();

    add(_dino);
    add(_enemyManager);
  }

  ///此方法从游戏中删除所有演员
  void _disconnectActors() {
    _dino.removeFromParent();
    _enemyManager.removeAllEnemies();
    _enemyManager.removeFromParent();
  }

  ///此方法将整个游戏世界重置为初始状态
  void reset() {
    ///首先断开游戏世界中的所有操作。
    _disconnectActors();

    ///将玩家数据重置为初始值
    playerData.currentScore = 0;
    playerData.lives = 5;
  }

  // This method gets called for each tick/frame of the game.
  @override
  void update(double dt) {
    ///如果生命数为 0 或更少，则游戏结束
    if (playerData.lives <= 0) {
      overlays.add(GameOverMenu.id);
      overlays.remove(Hud.id);
      pauseEngine();
      AudioManager.instance.pauseBgm();
    }
    super.update(dt);
  }

  ///每次点击屏幕都会调用此方法。
  @override
  void onTapDown(TapDownInfo info) {
     ///仅在游戏进行时使恐龙跳跃。当游戏处于运行状态时，只有 Hud 才是活动的叠加层。
    if (overlays.isActive(Hud.id)) {
      _dino.jump();
    }
    super.onTapDown(info);
  }

  /// This method reads [PlayerData] from the hive box.
  Future<PlayerData> _readPlayerData() async {
    final playerDataBox =
        await Hive.openBox<PlayerData>('DinoRun.PlayerDataBox');
    final playerData = playerDataBox.get('DinoRun.PlayerData');

    // If data is null, this is probably a fresh launch of the game.
    if (playerData == null) {
      // In such cases store default values in hive.
      await playerDataBox.put('DinoRun.PlayerData', PlayerData());
    }

    // Now it is safe to return the stored value.
    return playerDataBox.get('DinoRun.PlayerData')!;
  }

  /// This method reads [Settings] from the hive box.
  Future<Settings> _readSettings() async {
    final settingsBox = await Hive.openBox<Settings>('DinoRun.SettingsBox');
    final settings = settingsBox.get('DinoRun.Settings');

    // If data is null, this is probably a fresh launch of the game.
    if (settings == null) {
      // In such cases store default values in hive.
      await settingsBox.put(
        'DinoRun.Settings',
        Settings(bgm: true, sfx: true),
      );
    }

    // Now it is safe to return the stored value.
    return settingsBox.get('DinoRun.Settings')!;
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // On resume, if active overlay is not PauseMenu,
        // resume the engine (lets the parallax effect play).
        if (!(overlays.isActive(PauseMenu.id)) &&
            !(overlays.isActive(GameOverMenu.id))) {
          resumeEngine();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        // If game is active, then remove Hud and add PauseMenu
        // before pausing the game.
        if (overlays.isActive(Hud.id)) {
          overlays.remove(Hud.id);
          overlays.add(PauseMenu.id);
        }
        pauseEngine();
        break;
    }
    super.lifecycleStateChange(state);
  }
}
