-- ============================================
-- Sudoku Game Database Initialization Script (MySQL)
-- ============================================
-- Run: mysql -u sudoku -p sudoku < init.sql
-- ============================================

-- Drop existing tables
DROP TABLE IF EXISTS game_records;
DROP TABLE IF EXISTS puzzles;
DROP TABLE IF EXISTS users;

-- ============================================
-- 1. Users Table
-- level: 等级
-- finish_count: 完成数量
-- average_time: 平均时间
-- finish_max_difficulty: 完成的最高等级
-- experience: 当前等级经验值， 
-- 升级采用平方增长模型 10 * level * level
-- ============================================
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    openid VARCHAR(255) NOT NULL UNIQUE,
    nick_name VARCHAR(255),
    avatar_url TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    level INT NOT NULL DEFAULT 1,
    finish_count BIGINT NOT NULL DEFAULT 0,
    average_time BIGINT NOT NULL DEFAULT 0,
    finish_max_difficulty INT NOT NULL DEFAULT 0,
    experience BIGINT NOT NULL DEFAULT 0
);

ALTER TABLE users ADD level INT NOT NULL DEFAULT 1;
ALTER TABLE users ADD finish_count BIGINT NOT NULL DEFAULT 0;
ALTER TABLE users ADD average_time BIGINT NOT NULL DEFAULT 0;
ALTER TABLE users ADD finish_max_difficulty INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD experience BIGINT NOT NULL DEFAULT 0;

-- ============================================
-- 2. Puzzles Table
-- ============================================
CREATE TABLE puzzles (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    difficulty INT NOT NULL DEFAULT 1,
    average_solving_time BIGINT NOT NULL DEFAULT 0,
    cages_json TEXT NOT NULL,
    answer_json TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 3. Game Records Table
-- ============================================
CREATE TABLE game_records (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    openid VARCHAR(255) NOT NULL,
    puzzle_id BIGINT NOT NULL,
    difficulty INT,
    cell_values_json TEXT NOT NULL,
    elapsed_seconds BIGINT NOT NULL DEFAULT 0,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    disabled_hints_json TEXT NOT NULL DEFAULT '[]',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_openid (openid),
    INDEX idx_puzzle_id (puzzle_id)
);

-- ============================================
-- Sample Users (for testing)
-- ============================================
-- INSERT INTO users (openid, nick_name, avatar_url) VALUES
-- ('test_openid_123', '测试用户1', 'https://example.com/avatar1.jpg'),
-- ('test_openid_456', '测试用户2', 'https://example.com/avatar2.jpg');

-- ============================================
-- Sample Puzzles
-- ============================================

-- Puzzle 1 (difficulty 2)
INSERT INTO puzzles (id, difficulty, cages_json, answer_json, created_at) VALUES
(1, 2, '[
  {"id":1,"sum":11,"cells":[{"row":0,"col":0},{"row":0,"col":1},{"row":0,"col":2}],"inner":[[1,2,8],[1,3,7],[1,4,6],[2,3,6],[2,4,5]]},
  {"id":2,"sum":10,"cells":[{"row":1,"col":0},{"row":2,"col":0}],"inner":[[1,9],[2,8],[3,7],[4,6]]},
  {"id":3,"sum":9,"cells":[{"row":1,"col":1},{"row":1,"col":2}],"inner":[[1,8],[2,7],[3,6],[4,5]]},
  {"id":4,"sum":15,"cells":[{"row":2,"col":1},{"row":2,"col":2}],"inner":[[6,9],[7,8]]},
  {"id":5,"sum":13,"cells":[{"row":0,"col":3},{"row":1,"col":3}],"inner":[[4,9],[5,8],[6,7]]},
  {"id":6,"sum":21,"cells":[{"row":0,"col":4},{"row":1,"col":4},{"row":1,"col":5}],"inner":[[4,8,9],[5,7,9],[6,7,9]]},
  {"id":7,"sum":9,"cells":[{"row":0,"col":5},{"row":0,"col":6}],"inner":[[1,8],[2,7],[3,6],[4,5]]},
  {"id":8,"sum":14,"cells":[{"row":0,"col":7},{"row":0,"col":8}],"inner":[[5,9],[6,8]]},
  {"id":9,"sum":8,"cells":[{"row":1,"col":7},{"row":1,"col":8}],"inner":[[1,7],[2,6],[3,5]]},
  {"id":10,"sum":13,"cells":[{"row":1,"col":6},{"row":2,"col":6},{"row":2,"col":7}],"inner":[[1,3,9],[1,5,7],[2,4,7],[3,4,6],[1,4,8],[2,3,8],[2,5,6]]},
  {"id":11,"sum":7,"cells":[{"row":2,"col":8},{"row":3,"col":8}],"inner":[[1,6],[2,5],[3,4]]},
  {"id":12,"sum":3,"cells":[{"row":2,"col":4},{"row":2,"col":5}],"inner":[[1,2]]},
  {"id":13,"sum":6,"cells":[{"row":2,"col":3},{"row":3,"col":3}],"inner":[[1,5],[2,4]]},
  {"id":14,"sum":21,"cells":[{"row":3,"col":0},{"row":3,"col":1},{"row":3,"col":2}],"inner":[[4,8,9],[5,7,9],[6,7,8]]},
  {"id":15,"sum":8,"cells":[{"row":4,"col":0},{"row":4,"col":1}],"inner":[[1,7],[2,6],[3,5]]},
  {"id":16,"sum":14,"cells":[{"row":3,"col":4},{"row":4,"col":4},{"row":5,"col":4}],"inner":[[1,4,9],[1,6,7],[2,4,8],[3,4,7],[1,5,8],[2,3,9],[2,5,7],[3,5,6]]},
  {"id":17,"sum":14,"cells":[{"row":3,"col":5},{"row":4,"col":5}],"inner":[[5,9],[6,8]]},
  {"id":18,"sum":10,"cells":[{"row":3,"col":6},{"row":3,"col":7},{"row":4,"col":6}],"inner":[[1,2,7],[1,3,6],[1,4,5],[2,3,5]]},
  {"id":19,"sum":9,"cells":[{"row":4,"col":7},{"row":4,"col":8}],"inner":[[1,8],[2,7],[3,6],[4,5]]},
  {"id":20,"sum":23,"cells":[{"row":5,"col":6},{"row":5,"col":7},{"row":5,"col":8}],"inner":[[6,8,9]]},
  {"id":21,"sum":12,"cells":[{"row":4,"col":3},{"row":5,"col":3}],"inner":[[3,9],[4,8],[5,7]]},
  {"id":22,"sum":15,"cells":[{"row":4,"col":2},{"row":5,"col":2},{"row":5,"col":1}],"inner":[[1,5,9],[2,4,9],[2,6,7],[3,5,7],[1,6,8],[2,5,8],[3,4,8],[4,5,6]]},
  {"id":23,"sum":6,"cells":[{"row":5,"col":0},{"row":6,"col":0}],"inner":[[1,5],[2,4]]},
  {"id":24,"sum":9,"cells":[{"row":7,"col":0},{"row":7,"col":1}],"inner":[[1,8],[2,7],[3,6],[4,5]]},
  {"id":25,"sum":5,"cells":[{"row":8,"col":0},{"row":8,"col":1}],"inner":[[1,4],[2,3]]},
  {"id":26,"sum":17,"cells":[{"row":7,"col":2},{"row":7,"col":3}],"inner":[[8,9]]},
  {"id":27,"sum":17,"cells":[{"row":6,"col":1},{"row":6,"col":2},{"row":7,"col":2}],"inner":[[1,7,9],[2,7,8],[3,6,8],[4,6,7],[2,6,9],[3,5,9],[4,5,8]]},
  {"id":28,"sum":7,"cells":[{"row":6,"col":3},{"row":6,"col":4}],"inner":[[1,6],[2,5],[3,4]]},
  {"id":29,"sum":17,"cells":[{"row":7,"col":3},{"row":7,"col":4},{"row":8,"col":4}],"inner":[[1,7,9],[2,7,8],[3,6,8],[4,6,7],[2,6,9],[3,5,9],[4,5,8]]},
  {"id":30,"sum":5,"cells":[{"row":5,"col":5},{"row":6,"col":5}],"inner":[[1,4],[2,3]]},
  {"id":31,"sum":12,"cells":[{"row":7,"col":5},{"row":8,"col":5}],"inner":[[3,9],[4,8],[5,7]]},
  {"id":32,"sum":15,"cells":[{"row":6,"col":6},{"row":6,"col":7}],"inner":[[6,9],[7,8]]},
  {"id":33,"sum":11,"cells":[{"row":7,"col":6},{"row":7,"col":7}],"inner":[[2,9],[3,8],[4,7],[5,6]]},
  {"id":34,"sum":10,"cells":[{"row":8,"col":6},{"row":8,"col":7},{"row":8,"col":8}],"inner":[[1,2,7],[1,3,6],[1,4,5],[2,3,5]]},
  {"id":35,"sum":9,"cells":[{"row":6,"col":8},{"row":7,"col":8}],"inner":[[1,8],[2,7],[3,6],[4,5]]}
]', '[8,2,1,7,4,3,6,5,9,3,4,5,6,8,9,2,1,7,7,9,6,5,1,2,3,8,4,9,8,4,1,5,6,7,2,3,2,6,3,9,7,8,1,4,5,1,5,7,3,2,4,8,9,6,5,7,2,4,3,1,9,6,8,6,3,8,2,9,5,4,7,1,4,1,9,8,6,7,5,3,2]', DATE_SUB(NOW(), INTERVAL 1 DAY));

-- Puzzle 2 (difficulty 2)
INSERT INTO puzzles (id, difficulty, cages_json, answer_json, created_at) VALUES
(2, 2, '[
  {"id":1,"sum":21,"cells":[{"row":0,"col":0},{"row":0,"col":1},{"row":1,"col":1}],"inner":[[4,8,9],[5,7,9],[6,7,9]]},
  {"id":2,"sum":19,"cells":[{"row":0,"col":2},{"row":0,"col":3},{"row":1,"col":2}],"inner":[[2,8,9],[3,7,9],[4,6,9],[4,7,8],[5,6,8]]},
  {"id":3,"sum":17,"cells":[{"row":1,"col":3},{"row":2,"col":3},{"row":2,"col":4}],"inner":[[1,7,9],[2,7,8],[3,6,8],[4,6,7],[2,6,9],[3,5,9],[4,5,8]]},
  {"id":4,"sum":11,"cells":[{"row":0,"col":4},{"row":1,"col":4}],"inner":[[2,9],[3,8],[4,7],[5,6]]},
  {"id":5,"sum":6,"cells":[{"row":0,"col":5},{"row":1,"col":5}],"inner":[[1,5],[2,4]]},
  {"id":6,"sum":3,"cells":[{"row":0,"col":6},{"row":1,"col":6}],"inner":[[1,2]]},
  {"id":7,"sum":18,"cells":[{"row":0,"col":7},{"row":0,"col":8},{"row":1,"col":7}],"inner":[[1,8,9],[3,6,9],[4,5,9],[5,6,9],[2,7,9],[3,7,8],[4,6,8]]},
  {"id":8,"sum":18,"cells":[{"row":2,"col":5},{"row":2,"col":6},{"row":3,"col":5}],"inner":[[1,8,9],[3,6,9],[4,5,9],[5,6,9],[2,7,9],[3,7,8],[4,6,8]]},
  {"id":9,"sum":3,"cells":[{"row":1,"col":0},{"row":2,"col":0}],"inner":[[1,2]]},
  {"id":10,"sum":11,"cells":[{"row":2,"col":1},{"row":2,"col":2}],"inner":[[2,9],[3,8],[4,7],[5,6]]},
  {"id":11,"sum":8,"cells":[{"row":1,"col":8},{"row":2,"col":8}],"inner":[[1,7],[2,6],[3,5]]},
  {"id":12,"sum":20,"cells":[{"row":2,"col":7},{"row":3,"col":6},{"row":3,"col":7}],"inner":[[3,8,9],[4,7,9],[5,6,9],[5,7,8]]},
  {"id":13,"sum":3,"cells":[{"row":3,"col":8},{"row":4,"col":8}],"inner":[[1,2]]},
  {"id":14,"sum":15,"cells":[{"row":3,"col":4},{"row":4,"col":4},{"row":5,"col":4}],"inner":[[1,5,9],[2,4,9],[2,6,7],[3,5,7],[1,6,8],[2,5,8],[3,4,8],[4,5,6]]},
  {"id":15,"sum":6,"cells":[{"row":3,"col":2},{"row":3,"col":3}],"inner":[[1,5],[2,4]]},
  {"id":16,"sum":6,"cells":[{"row":4,"col":2},{"row":4,"col":3}],"inner":[[1,5],[2,4]]},
  {"id":17,"sum":11,"cells":[{"row":3,"col":0},{"row":3,"col":1}],"inner":[[2,9],[3,8],[4,7],[5,6]]},
  {"id":18,"sum":14,"cells":[{"row":4,"col":0},{"row":4,"col":1}],"inner":[[5,9],[6,8]]},
  {"id":19,"sum":11,"cells":[{"row":4,"col":5},{"row":5,"col":5}],"inner":[[2,9],[3,8],[4,7],[5,6]]},
  {"id":20,"sum":13,"cells":[{"row":4,"col":6},{"row":5,"col":6}],"inner":[[4,9],[5,8],[6,7]]},
  {"id":21,"sum":18,"cells":[{"row":4,"col":7},{"row":5,"col":7},{"row":5,"col":8}],"inner":[[1,8,9],[3,6,9],[4,5,9],[5,6,9],[2,7,9],[3,7,8],[4,6,8]]},
  {"id":22,"sum":10,"cells":[{"row":5,"col":0},{"row":5,"col":1},{"row":6,"col":1}],"inner":[[1,2,7],[1,3,6],[1,4,5],[2,3,5]]},
  {"id":23,"sum":10,"cells":[{"row":5,"col":2},{"row":5,"col":3}],"inner":[[1,9],[2,8],[3,7],[4,6]]},
  {"id":24,"sum":8,"cells":[{"row":6,"col":2},{"row":6,"col":3}],"inner":[[1,7],[2,6],[3,5]]},
  {"id":25,"sum":8,"cells":[{"row":7,"col":6},{"row":8,"col":6}],"inner":[[1,7],[2,6],[3,5]]},
  {"id":26,"sum":21,"cells":[{"row":6,"col":0},{"row":7,"col":0},{"row":8,"col":0}],"inner":[[4,8,9],[5,7,9],[6,7,8]]},
  {"id":27,"sum":7,"cells":[{"row":7,"col":1},{"row":8,"col":1}],"inner":[[1,6],[2,5],[3,4]]},
  {"id":28,"sum":11,"cells":[{"row":7,"col":2},{"row":7,"col":3}],"inner":[[2,9],[3,8],[4,7],[5,6]]},
  {"id":29,"sum":9,"cells":[{"row":8,"col":2},{"row":8,"col":3}],"inner":[[1,8],[2,7],[3,6],[4,5]]},
  {"id":30,"sum":15,"cells":[{"row":6,"col":4},{"row":7,"col":4},{"row":8,"col":4}],"inner":[[1,5,9],[2,4,9],[2,6,7],[3,5,7],[1,6,8],[2,5,8],[3,4,8],[4,5,6]]},
  {"id":31,"sum":17,"cells":[{"row":6,"col":5},{"row":7,"col":5},{"row":8,"col":5}],"inner":[[1,7,9],[2,7,8],[3,6,8],[4,6,7],[2,6,9],[3,5,9],[4,5,8]]},
  {"id":32,"sum":12,"cells":[{"row":6,"col":6},{"row":6,"col":7},{"row":7,"col":7}],"inner":[[1,2,9],[1,4,7],[2,3,7],[3,4,5],[1,3,8],[1,5,6],[2,4,6]]},
  {"id":33,"sum":9,"cells":[{"row":8,"col":7},{"row":8,"col":8}],"inner":[[1,8],[2,7],[3,6],[4,5]]},
  {"id":34,"sum":16,"cells":[{"row":6,"col":8},{"row":7,"col":8}],"inner":[[7,9]]}
]', '[5,7,6,9,3,1,2,8,4,2,9,4,7,8,5,1,6,3,1,3,8,6,4,2,7,9,5,7,4,1,5,6,9,8,3,2,6,8,2,4,7,3,9,5,1,3,5,9,1,2,8,4,7,6,8,2,5,3,1,7,6,4,9,4,1,3,8,9,6,5,2,7,9,6,7,2,5,4,3,1,8]', NOW());

-- ============================================
-- Sample Game Records (for testing)
-- ============================================
INSERT INTO game_records (openid, puzzle_id, difficulty, cell_values_json, elapsed_seconds, completed, disabled_hints_json, created_at) VALUES
('test_openid_123', 1, 1, '[[[3],[7]],[[2],[5]],[[1]],[[4]],[[6]],[[8]],[[9]],[[5]],[[2]]]', 332, 1, '[]', DATE_SUB(NOW(), INTERVAL 3 DAY));

INSERT INTO game_records (openid, puzzle_id, difficulty, cell_values_json, elapsed_seconds, completed, disabled_hints_json, created_at) VALUES
('test_openid_123', 2, 5, '[[[5],[3]],[[2],[7]],[[1]],[[6]],[[4]],[[9]],[[8]],[[1]],[[3]]]', 780, 0, '[]', DATE_SUB(NOW(), INTERVAL 2 DAY));

INSERT INTO game_records (openid, puzzle_id, difficulty, cell_values_json, elapsed_seconds, completed, disabled_hints_json, created_at) VALUES
('test_openid_456', 1, 1, '[[[1]],[[2]],[[3]],[[4]],[[5]],[[6]],[[7]],[[8]],[[9]]]', 245, 1, '[]', DATE_SUB(NOW(), INTERVAL 1 DAY));

INSERT INTO game_records (openid, puzzle_id, difficulty, cell_values_json, elapsed_seconds, completed, disabled_hints_json, created_at) VALUES
('test_openid_123', 3, 8, '[[[4]],[[6]],[[2]],[[8]],[[1]],[[3]],[[7]],[[5]],[[9]]]', 1200, 0, '[]', DATE_SUB(NOW(), INTERVAL 1 DAY));





