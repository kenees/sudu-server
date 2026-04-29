-- Drop existing tables to start fresh
DROP TABLE IF EXISTS game_records;
DROP TABLE IF EXISTS puzzles;

-- Create puzzles table
CREATE TABLE puzzles (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    difficulty INT NOT NULL DEFAULT 1,
    cages_json TEXT NOT NULL,
    solution_json TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create game_records table with new schema
CREATE TABLE game_records (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    openid VARCHAR(255) NOT NULL,
    puzzle_id BIGINT NOT NULL,
    difficulty INT,
    cell_values_json TEXT NOT NULL,
    elapsed_seconds BIGINT NOT NULL DEFAULT 0,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    disabled_hints_json TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_openid (openid),
    INDEX idx_puzzle_id (puzzle_id)
);

-- Insert sample killer sudoku puzzles

-- Easy puzzle (difficulty 1) - 3 days ago
INSERT INTO puzzles (id, difficulty, cages_json, created_at) VALUES
(1, 1, '[
  {"id":1,"sum":3,"cells":[{"row":0,"col":0},{"row":0,"col":1}]},
  {"id":2,"sum":15,"cells":[{"row":0,"col":2},{"row":0,"col":3},{"row":0,"col":4}]},
  {"id":3,"sum":22,"cells":[{"row":0,"col":5},{"row":1,"col":5},{"row":1,"col":6}]},
  {"id":4,"sum":11,"cells":[{"row":0,"col":6},{"row":0,"col":7},{"row":0,"col":8}]},
  {"id":5,"sum":9,"cells":[{"row":1,"col":0},{"row":1,"col":1},{"row":2,"col":1}]},
  {"id":6,"sum":8,"cells":[{"row":1,"col":2},{"row":2,"col":2}]},
  {"id":7,"sum":20,"cells":[{"row":1,"col":3},{"row":1,"col":4},{"row":2,"col":4}]},
  {"id":8,"sum":6,"cells":[{"row":1,"col":7},{"row":1,"col":8},{"row":2,"col":8}]},
  {"id":9,"sum":14,"cells":[{"row":2,"col":0},{"row":3,"col":0}]},
  {"id":10,"sum":12,"cells":[{"row":2,"col":3},{"row":3,"col":3}]},
  {"id":11,"sum":13,"cells":[{"row":2,"col":5},{"row":3,"col":5}]},
  {"id":12,"sum":17,"cells":[{"row":2,"col":6},{"row":2,"col":7},{"row":3,"col":7}]},
  {"id":13,"sum":10,"cells":[{"row":3,"col":1},{"row":4,"col":1}]},
  {"id":14,"sum":11,"cells":[{"row":3,"col":2},{"row":4,"col":2}]},
  {"id":15,"sum":24,"cells":[{"row":3,"col":4},{"row":3,"col":5},{"row":4,"col":4},{"row":4,"col":5}]},
  {"id":16,"sum":9,"cells":[{"row":3,"col":6},{"row":3,"col":7},{"row":3,"col":8}]},
  {"id":17,"sum":7,"cells":[{"row":4,"col":0},{"row":5,"col":0}]},
  {"id":18,"sum":15,"cells":[{"row":4,"col":3},{"row":5,"col":3}]},
  {"id":19,"sum":16,"cells":[{"row":4,"col":6},{"row":4,"col":7},{"row":4,"col":8}]},
  {"id":20,"sum":14,"cells":[{"row":5,"col":1},{"row":5,"col":2},{"row":6,"col":2}]},
  {"id":21,"sum":23,"cells":[{"row":5,"col":4},{"row":5,"col":5},{"row":5,"col":6}]},
  {"id":22,"sum":13,"cells":[{"row":5,"col":7},{"row":6,"col":7},{"row":6,"col":8}]},
  {"id":23,"sum":18,"cells":[{"row":6,"col":0},{"row":6,"col":1},{"row":7,"col":1}]},
  {"id":24,"sum":10,"cells":[{"row":6,"col":3},{"row":7,"col":3}]},
  {"id":25,"sum":17,"cells":[{"row":6,"col":4},{"row":6,"col":5},{"row":7,"col":5}]},
  {"id":26,"sum":6,"cells":[{"row":6,"col":6},{"row":7,"col":6}]},
  {"id":27,"sum":8,"cells":[{"row":7,"col":0},{"row":8,"col":0}]},
  {"id":28,"sum":12,"cells":[{"row":7,"col":2},{"row":7,"col":3},{"row":8,"col":2}]},
  {"id":29,"sum":21,"cells":[{"row":7,"col":4},{"row":7,"col":7},{"row":7,"col":8},{"row":8,"col":7}]},
  {"id":30,"sum":19,"cells":[{"row":8,"col":1},{"row":8,"col":3},{"row":8,"col":4}]},
  {"id":31,"sum":11,"cells":[{"row":8,"col":5},{"row":8,"col":6}]},
  {"id":32,"sum":5,"cells":[{"row":8,"col":8},{"row":7,"col":8}]}
]', DATE_SUB(NOW(), INTERVAL 3 DAY));

-- Medium puzzle (difficulty 5) - 2 days ago
INSERT INTO puzzles (id, difficulty, cages_json, created_at) VALUES
(2, 5, '[
  {"id":1,"sum":10,"cells":[{"row":0,"col":0},{"row":0,"col":1},{"row":1,"col":1}]},
  {"id":2,"sum":14,"cells":[{"row":0,"col":2},{"row":0,"col":3}]},
  {"id":3,"sum":18,"cells":[{"row":0,"col":4},{"row":0,"col":5},{"row":1,"col":5}]},
  {"id":4,"sum":9,"cells":[{"row":0,"col":6},{"row":0,"col":7},{"row":0,"col":8}]},
  {"id":5,"sum":12,"cells":[{"row":1,"col":0},{"row":2,"col":0}]},
  {"id":6,"sum":17,"cells":[{"row":1,"col":2},{"row":1,"col":3},{"row":1,"col":4}]},
  {"id":7,"sum":6,"cells":[{"row":1,"col":6},{"row":1,"col":7},{"row":2,"col":7}]},
  {"id":8,"sum":15,"cells":[{"row":1,"col":8},{"row":2,"col":8}]},
  {"id":9,"sum":11,"cells":[{"row":2,"col":1},{"row":2,"col":2},{"row":3,"col":2}]},
  {"id":10,"sum":20,"cells":[{"row":2,"col":3},{"row":2,"col":4},{"row":3,"col":4}]},
  {"id":11,"sum":8,"cells":[{"row":2,"col":5},{"row":2,"col":6}]},
  {"id":12,"sum":13,"cells":[{"row":3,"col":0},{"row":3,"col":1}]},
  {"id":13,"sum":16,"cells":[{"row":3,"col":3},{"row":4,"col":3}]},
  {"id":14,"sum":7,"cells":[{"row":3,"col":5},{"row":3,"col":6},{"row":3,"col":7}]},
  {"id":15,"sum":21,"cells":[{"row":3,"col":8},{"row":4,"col":8},{"row":5,"col":8}]},
  {"id":16,"sum":14,"cells":[{"row":4,"col":0},{"row":4,"col":1},{"row":4,"col":2}]},
  {"id":17,"sum":5,"cells":[{"row":4,"col":4},{"row":5,"col":4}]},
  {"id":18,"sum":19,"cells":[{"row":4,"col":5},{"row":4,"col":6},{"row":4,"col":7}]},
  {"id":19,"sum":9,"cells":[{"row":5,"col":0},{"row":6,"col":0}]},
  {"id":20,"sum":12,"cells":[{"row":5,"col":1},{"row":5,"col":2},{"row":6,"col":2}]},
  {"id":21,"sum":15,"cells":[{"row":5,"col":3},{"row":5,"col":4},{"row":5,"col":5}]},
  {"id":22,"sum":11,"cells":[{"row":5,"col":6},{"row":5,"col":7}]},
  {"id":23,"sum":23,"cells":[{"row":6,"col":1},{"row":6,"col":3},{"row":7,"col":3}]},
  {"id":24,"sum":6,"cells":[{"row":6,"col":4},{"row":7,"col":4}]},
  {"id":25,"sum":18,"cells":[{"row":6,"col":5},{"row":6,"col":6},{"row":6,"col":7}]},
  {"id":26,"sum":13,"cells":[{"row":6,"col":8},{"row":7,"col":8}]},
  {"id":27,"sum":8,"cells":[{"row":7,"col":0},{"row":7,"col":1},{"row":8,"col":1}]},
  {"id":28,"sum":16,"cells":[{"row":7,"col":2},{"row":7,"col":3},{"row":7,"col":4},{"row":7,"col":5}]},
  {"id":29,"sum":10,"cells":[{"row":7,"col":6},{"row":7,"col":7}]},
  {"id":30,"sum":12,"cells":[{"row":8,"col":0},{"row":8,"col":2}]},
  {"id":31,"sum":14,"cells":[{"row":8,"col":3},{"row":8,"col":4},{"row":8,"col":5}]},
  {"id":32,"sum":17,"cells":[{"row":8,"col":6},{"row":8,"col":7},{"row":8,"col":8}]}
]', DATE_SUB(NOW(), INTERVAL 2 DAY));

-- Hard puzzle (difficulty 8) - yesterday
INSERT INTO puzzles (id, difficulty, cages_json, created_at) VALUES
(3, 8, '[
  {"id":1,"sum":14,"cells":[{"row":0,"col":0},{"row":1,"col":0}]},
  {"id":2,"sum":12,"cells":[{"row":0,"col":1},{"row":0,"col":2}]},
  {"id":3,"sum":21,"cells":[{"row":0,"col":3},{"row":0,"col":4},{"row":1,"col":4}]},
  {"id":4,"sum":9,"cells":[{"row":0,"col":5},{"row":1,"col":5},{"row":1,"col":6}]},
  {"id":5,"sum":10,"cells":[{"row":0,"col":6},{"row":0,"col":7},{"row":0,"col":8}]},
  {"id":6,"sum":16,"cells":[{"row":1,"col":1},{"row":1,"col":2},{"row":2,"col":1}]},
  {"id":7,"sum":15,"cells":[{"row":1,"col":3},{"row":2,"col":3}]},
  {"id":8,"sum":13,"cells":[{"row":1,"col":7},{"row":2,"col":7}]},
  {"id":9,"sum":7,"cells":[{"row":1,"col":8},{"row":2,"col":8}]},
  {"id":10,"sum":23,"cells":[{"row":2,"col":0},{"row":3,"col":0}]},
  {"id":11,"sum":11,"cells":[{"row":2,"col":2},{"row":3,"col":2}]},
  {"id":12,"sum":8,"cells":[{"row":2,"col":4},{"row":3,"col":4}]},
  {"id":13,"sum":12,"cells":[{"row":2,"col":5},{"row":2,"col":6},{"row":3,"col":6}]},
  {"id":14,"sum":19,"cells":[{"row":2,"col":7},{"row":3,"col":7},{"row":3,"col":8}]},
  {"id":15,"sum":4,"cells":[{"row":3,"col":1},{"row":4,"col":1}]},
  {"id":16,"sum":7,"cells":[{"row":3,"col":3},{"row":4,"col":3}]},
  {"id":17,"sum":17,"cells":[{"row":3,"col":5},{"row":4,"col":5},{"row":4,"col":6}]},
  {"id":18,"sum":5,"cells":[{"row":4,"col":0},{"row":5,"col":0}]},
  {"id":19,"sum":18,"cells":[{"row":4,"col":2},{"row":5,"col":2},{"row":5,"col":1}]},
  {"id":20,"sum":24,"cells":[{"row":4,"col":4},{"row":5,"col":4},{"row":5,"col":3}]},
  {"id":21,"sum":15,"cells":[{"row":4,"col":7},{"row":4,"col":8},{"row":5,"col":8}]},
  {"id":22,"sum":13,"cells":[{"row":5,"col":5},{"row":6,"col":5},{"row":6,"col":4}]},
  {"id":23,"sum":10,"cells":[{"row":5,"col":6},{"row":6,"col":6}]},
  {"id":24,"sum":16,"cells":[{"row":5,"col":7},{"row":6,"col":7}]},
  {"id":25,"sum":12,"cells":[{"row":6,"col":0},{"row":7,"col":0}]},
  {"id":26,"sum":28,"cells":[{"row":6,"col":1},{"row":6,"col":2},{"row":6,"col":3},{"row":7,"col":3}]},
  {"id":27,"sum":14,"cells":[{"row":6,"col":8},{"row":7,"col":8}]},
  {"id":28,"sum":9,"cells":[{"row":7,"col":1},{"row":8,"col":1}]},
  {"id":29,"sum":20,"cells":[{"row":7,"col":2},{"row":8,"col":2},{"row":8,"col":0}]},
  {"id":30,"sum":11,"cells":[{"row":7,"col":4},{"row":8,"col":4},{"row":8,"col":3}]},
  {"id":31,"sum":27,"cells":[{"row":7,"col":5},{"row":7,"col":6},{"row":7,"col":7},{"row":8,"col":7},{"row":8,"col":8}]},
  {"id":32,"sum":6,"cells":[{"row":8,"col":5},{"row":8,"col":6}]}
]', DATE_SUB(NOW(), INTERVAL 1 DAY));

-- Today's puzzles (difficulty 2 and 7)
INSERT INTO puzzles (id, difficulty, cages_json, created_at) VALUES
(4, 2, '[
  {"id":1,"sum":4,"cells":[{"row":0,"col":0},{"row":0,"col":1}]},
  {"id":2,"sum":16,"cells":[{"row":0,"col":2},{"row":0,"col":3},{"row":0,"col":4}]},
  {"id":3,"sum":20,"cells":[{"row":0,"col":5},{"row":1,"col":5},{"row":1,"col":6}]},
  {"id":4,"sum":7,"cells":[{"row":0,"col":6},{"row":0,"col":7},{"row":0,"col":8}]},
  {"id":5,"sum":11,"cells":[{"row":1,"col":0},{"row":1,"col":1},{"row":2,"col":1}]},
  {"id":6,"sum":9,"cells":[{"row":1,"col":2},{"row":2,"col":2}]},
  {"id":7,"sum":18,"cells":[{"row":1,"col":3},{"row":1,"col":4},{"row":2,"col":4}]},
  {"id":8,"sum":8,"cells":[{"row":1,"col":7},{"row":1,"col":8},{"row":2,"col":8}]},
  {"id":9,"sum":13,"cells":[{"row":2,"col":0},{"row":3,"col":0}]},
  {"id":10,"sum":14,"cells":[{"row":2,"col":3},{"row":3,"col":3}]},
  {"id":11,"sum":11,"cells":[{"row":2,"col":5},{"row":3,"col":5}]},
  {"id":12,"sum":16,"cells":[{"row":2,"col":6},{"row":2,"col":7},{"row":3,"col":7}]},
  {"id":13,"sum":8,"cells":[{"row":3,"col":1},{"row":4,"col":1}]},
  {"id":14,"sum":12,"cells":[{"row":3,"col":2},{"row":4,"col":2}]},
  {"id":15,"sum":22,"cells":[{"row":3,"col":4},{"row":3,"col":5},{"row":4,"col":4},{"row":4,"col":5}]},
  {"id":16,"sum":10,"cells":[{"row":3,"col":6},{"row":3,"col":7},{"row":3,"col":8}]},
  {"id":17,"sum":5,"cells":[{"row":4,"col":0},{"row":5,"col":0}]},
  {"id":18,"sum":17,"cells":[{"row":4,"col":3},{"row":5,"col":3}]},
  {"id":19,"sum":14,"cells":[{"row":4,"col":6},{"row":4,"col":7},{"row":4,"col":8}]},
  {"id":20,"sum":16,"cells":[{"row":5,"col":1},{"row":5,"col":2},{"row":6,"col":2}]},
  {"id":21,"sum":21,"cells":[{"row":5,"col":4},{"row":5,"col":5},{"row":5,"col":6}]},
  {"id":22,"sum":15,"cells":[{"row":5,"col":7},{"row":6,"col":7},{"row":6,"col":8}]},
  {"id":23,"sum":19,"cells":[{"row":6,"col":0},{"row":6,"col":1},{"row":7,"col":1}]},
  {"id":24,"sum":9,"cells":[{"row":6,"col":3},{"row":7,"col":3}]},
  {"id":25,"sum":14,"cells":[{"row":6,"col":4},{"row":6,"col":5},{"row":7,"col":5}]},
  {"id":26,"sum":7,"cells":[{"row":6,"col":6},{"row":7,"col":6}]},
  {"id":27,"sum":6,"cells":[{"row":7,"col":0},{"row":8,"col":0}]},
  {"id":28,"sum":13,"cells":[{"row":7,"col":2},{"row":7,"col":3},{"row":8,"col":2}]},
  {"id":29,"sum":24,"cells":[{"row":7,"col":4},{"row":7,"col":7},{"row":7,"col":8},{"row":8,"col":7}]},
  {"id":30,"sum":18,"cells":[{"row":8,"col":1},{"row":8,"col":3},{"row":8,"col":4}]},
  {"id":31,"sum":9,"cells":[{"row":8,"col":5},{"row":8,"col":6}]},
  {"id":32,"sum":3,"cells":[{"row":8,"col":8},{"row":7,"col":8}]}
]', NOW());

INSERT INTO puzzles (id, difficulty, cages_json, created_at) VALUES
(5, 7, '[
  {"id":1,"sum":12,"cells":[{"row":0,"col":0},{"row":1,"col":0}]},
  {"id":2,"sum":11,"cells":[{"row":0,"col":1},{"row":0,"col":2}]},
  {"id":3,"sum":17,"cells":[{"row":0,"col":3},{"row":0,"col":4},{"row":1,"col":4}]},
  {"id":4,"sum":7,"cells":[{"row":0,"col":5},{"row":1,"col":5},{"row":1,"col":6}]},
  {"id":5,"sum":13,"cells":[{"row":0,"col":6},{"row":0,"col":7},{"row":0,"col":8}]},
  {"id":6,"sum":19,"cells":[{"row":1,"col":1},{"row":1,"col":2},{"row":2,"col":1}]},
  {"id":7,"sum":13,"cells":[{"row":1,"col":3},{"row":2,"col":3}]},
  {"id":8,"sum":15,"cells":[{"row":1,"col":7},{"row":2,"col":7}]},
  {"id":9,"sum":8,"cells":[{"row":1,"col":8},{"row":2,"col":8}]},
  {"id":10,"sum":21,"cells":[{"row":2,"col":0},{"row":3,"col":0}]},
  {"id":11,"sum":13,"cells":[{"row":2,"col":2},{"row":3,"col":2}]},
  {"id":12,"sum":9,"cells":[{"row":2,"col":4},{"row":3,"col":4}]},
  {"id":13,"sum":10,"cells":[{"row":2,"col":5},{"row":2,"col":6},{"row":3,"col":6}]},
  {"id":14,"sum":16,"cells":[{"row":2,"col":7},{"row":3,"col":7},{"row":3,"col":8}]},
  {"id":15,"sum":6,"cells":[{"row":3,"col":1},{"row":4,"col":1}]},
  {"id":16,"sum":4,"cells":[{"row":3,"col":3},{"row":4,"col":3}]},
  {"id":17,"sum":15,"cells":[{"row":3,"col":5},{"row":4,"col":5},{"row":4,"col":6}]},
  {"id":18,"sum":6,"cells":[{"row":4,"col":0},{"row":5,"col":0}]},
  {"id":19,"sum":14,"cells":[{"row":4,"col":2},{"row":5,"col":2},{"row":5,"col":1}]},
  {"id":20,"sum":20,"cells":[{"row":4,"col":4},{"row":5,"col":4},{"row":5,"col":3}]},
  {"id":21,"sum":20,"cells":[{"row":4,"col":7},{"row":4,"col":8},{"row":5,"col":8}]},
  {"id":22,"sum":11,"cells":[{"row":5,"col":5},{"row":6,"col":5},{"row":6,"col":4}]},
  {"id":23,"sum":14,"cells":[{"row":5,"col":6},{"row":6,"col":6}]},
  {"id":24,"sum":11,"cells":[{"row":5,"col":7},{"row":6,"col":7}]},
  {"id":25,"sum":11,"cells":[{"row":6,"col":0},{"row":7,"col":0}]},
  {"id":26,"sum":27,"cells":[{"row":6,"col":1},{"row":6,"col":2},{"row":6,"col":3},{"row":7,"col":3}]},
  {"id":27,"sum":12,"cells":[{"row":6,"col":8},{"row":7,"col":8}]},
  {"id":28,"sum":10,"cells":[{"row":7,"col":1},{"row":8,"col":1}]},
  {"id":29,"sum":21,"cells":[{"row":7,"col":2},{"row":8,"col":2},{"row":8,"col":0}]},
  {"id":30,"sum":9,"cells":[{"row":7,"col":4},{"row":8,"col":4},{"row":8,"col":3}]},
  {"id":31,"sum":26,"cells":[{"row":7,"col":5},{"row":7,"col":6},{"row":7,"col":7},{"row":8,"col":7},{"row":8,"col":8}]},
  {"id":32,"sum":7,"cells":[{"row":8,"col":5},{"row":8,"col":6}]}
]', NOW());

-- Insert sample game records (replace test_openid_123 with real openid when testing)
INSERT INTO game_records (openid, puzzle_id, difficulty, cell_values_json, elapsed_seconds, completed, disabled_hints_json, created_at) VALUES
('test_openid_123', 1, 1, '[[[3],[7]],[[2],[5]],[[1]],[[4]],[[6]],[[8]],[[9]],[[5]],[[2]]]', 332, 1, '[]', DATE_SUB(NOW(), INTERVAL 3 DAY));

INSERT INTO game_records (openid, puzzle_id, difficulty, cell_values_json, elapsed_seconds, completed, disabled_hints_json, created_at) VALUES
('test_openid_123', 2, 5, '[[[5],[3]],[[2],[7]],[[1]],[[6]],[[4]],[[9]],[[8]],[[1]],[[3]]]', 780, 0, '[]', DATE_SUB(NOW(), INTERVAL 2 DAY));

INSERT INTO game_records (openid, puzzle_id, difficulty, cell_values_json, elapsed_seconds, completed, disabled_hints_json, created_at) VALUES
('test_openid_456', 1, 1, '[[[1]],[[2]],[[3]],[[4]],[[5]],[[6]],[[7]],[[8]],[[9]]]', 245, 1, '[]', DATE_SUB(NOW(), INTERVAL 1 DAY));

INSERT INTO game_records (openid, puzzle_id, difficulty, cell_values_json, elapsed_seconds, completed, disabled_hints_json, created_at) VALUES
('test_openid_123', 3, 8, '[[[4]],[[6]],[[2]],[[8]],[[1]],[[3]],[[7]],[[5]],[[9]]]', 1200, 0, '[]', DATE_SUB(NOW(), INTERVAL 1 DAY));
