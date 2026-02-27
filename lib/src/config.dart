const gameWidth  = 400.0;
const gameHeight = 700.0;

// 鳥
const birdRadius   = gameWidth * 0.07;
const gravity      = gameHeight * 1.25;
const flapImpulse  = -gameHeight * 0.65;

// パイプ
const pipeWidth    = gameWidth * 0.18;
const pipeGap      = gameHeight * 0.26;  // 隙間の高さ
const pipeSpeed    = gameWidth * 0.55;   // デフォルト速度（JSON で上書き）

// 地面
const groundHeight = gameHeight * 0.12;
const groundSpeed  = pipeSpeed;          // パイプと同速
