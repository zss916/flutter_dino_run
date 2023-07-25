import 'dart:math';

import 'package:flame/components.dart';

import '/game/enemy.dart';
import '/game/dino_run.dart';
import '/models/enemy_data.dart';

///该类负责根据玩家当前的得分以一定的时间间隔生成随机敌人
class EnemyManager extends Component with HasGameRef<DinoRun> {
  ///保存所有敌人数据的列表。
  final List<EnemyData> _data = [];

  ///随机选择敌人类型所需的随机生成器
  final Random _random = Random();

  ///计时器决定何时生成下一个敌人
  final Timer _timer = Timer(2, repeat: true);

  EnemyManager() {
    _timer.onTick = spawnRandomEnemy;
  }

  ///此方法负责生成随机敌人。
  void spawnRandomEnemy() {
    /// Generate a random index within [_data] and get an [EnemyData].
    final randomIndex = _random.nextInt(_data.length);
    final enemyData = _data.elementAt(randomIndex);
    final enemy = Enemy(enemyData);

    ///帮助将所有敌人安置在地面上
    enemy.anchor = Anchor.bottomLeft;
    enemy.position = Vector2(
      gameRef.size.x + 32,
      gameRef.size.y - 24,
    );

    ///如果这个敌人可以飞行，则随机设置其 y 位置。
    if (enemyData.canFly) {
      final newHeight = _random.nextDouble() * 2 * enemyData.textureSize.y;
      enemy.position.y -= newHeight;
    }

    ///由于视口的大小，我们可以使用textureSize作为组件的大小。
    enemy.size = enemyData.textureSize;
    gameRef.add(enemy);
  }

  @override
  void onMount() {
    if (isMounted) {
      removeFromParent();
    }

    ///不要在每次安装时一次又一次地填写列表。
    if (_data.isEmpty) {
      ///一旦安装了该组件，就初始化所有数据
      _data.addAll([
        EnemyData(
          image: gameRef.images.fromCache('AngryPig/Walk (36x30).png'),
          nFrames: 16,
          stepTime: 0.1,
          textureSize: Vector2(36, 30),
          speedX: 80,
          canFly: false,
        ),
        EnemyData(
          image: gameRef.images.fromCache('Bat/Flying (46x30).png'),
          nFrames: 7,
          stepTime: 0.1,
          textureSize: Vector2(46, 30),
          speedX: 100,
          canFly: true,
        ),
        EnemyData(
          image: gameRef.images.fromCache('Rino/Run (52x34).png'),
          nFrames: 6,
          stepTime: 0.09,
          textureSize: Vector2(52, 34),
          speedX: 150,
          canFly: false,
        ),
      ]);
    }
    _timer.start();
    super.onMount();
  }

  @override
  void update(double dt) {
    _timer.update(dt);
    super.update(dt);
  }

  void removeAllEnemies() {
    final enemies = gameRef.children.whereType<Enemy>();
    for (var enemy in enemies) {
      enemy.removeFromParent();
    }
  }
}
