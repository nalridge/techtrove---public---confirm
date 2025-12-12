-- Users Table
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Topics Table
CREATE TABLE topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

-- Questions Table
CREATE TABLE questions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    topic_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);

-- Answers Table
CREATE TABLE answers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    body TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Seed Data
INSERT INTO topics (name) VALUES 
('Web Development'), 
('Mobile Development'), 
('DevOps');

INSERT INTO users (username, password_hash) VALUES
('alice', 'hashed_pw_demo'),
('bob', 'hashed_pw_demo');

INSERT INTO questions (user_id, topic_id, title, body) VALUES
(1, 1, 'How does React state work?', 'I want to understand useState...'),
(2, 3, 'What is CI/CD?', 'Can someone explain CI/CD pipelines?');

INSERT INTO answers (question_id, user_id, body) VALUES
(1, 2, 'React state triggers re-renders when updated.'),
(2, 1, 'CI/CD automates testing and deployment.');
