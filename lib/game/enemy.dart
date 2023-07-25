import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '/game/dino_run.dart';
import '/models/enemy_data.dart';

///这代表游戏世界中的敌人。.
class Enemy extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameRef<DinoRun> {
  // The data required for creation of this enemy.
  final EnemyData enemyData;

  Enemy(this.enemyData) {
    animation = SpriteAnimation.fromFrameData(
      enemyData.image,
      SpriteAnimationData.sequenced(
        amount: enemyData.nFrames,
        stepTime: enemyData.stepTime,
        textureSize: enemyData.textureSize,
      ),
    );
  }

  @override
  void onMount() {
    ///缩小敌人的体型，因为与恐龙相比，它们看起来太大了。
    size *= 0.6;

    ///为这个敌人添加一个命中框。
    add(
      RectangleHitbox.relative(
        Vector2.all(0.8),
        parentSize: size,
        position: Vector2(size.x * 0.2, size.y * 0.2) / 2,
      ),
    );
    super.onMount();
  }

  @override
  void update(double dt) {
    position.x -= enemyData.speedX * dt;

    ///如果敌人已经越过屏幕左端，则移除敌人并使玩家得分增加 1
    if (position.x < -enemyData.textureSize.x) {
      removeFromParent();
      gameRef.playerData.currentScore += 1;
    }

    super.update(dt);
  }
}
