const gameWidth  = 400.0;
const gameHeight = 700.0;

// 鳥
const birdRadius       = gameWidth * 0.07;
const gravity          = gameHeight * 1.25;
const maxFlapHoldTime  = 0.5;              // 最大長押し時間 (秒)
const flapLiftBase     = gravity * 2.0;   // 長押し開始時の上昇加速度
const flapLiftExtra    = gravity * 1.3;   // 最大長押し時の追加上昇加速度

// パイプ
const pipeWidth    = gameWidth * 0.10;
const pipeSpeed    = gameWidth * 0.55;   // デフォルト速度（JSON で上書き）

// 地面
const groundHeight = gameHeight * 0.12;
const groundSpeed  = pipeSpeed;          // パイプと同速
