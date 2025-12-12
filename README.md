# TechTrove Project Files

Below are all generated files for your project.

---

## README.md

```markdown
# TechTrove
A 3-tier architecture demo application featuring:
- **SQLite Database Layer**
- **Node.js + Express API Layer**
- **Client-Side SPA (Vanilla JS)**

TechTrove is a themed Q&A forum focused on Web Development, Mobile Development, and DevOps.

---
## 1. Features
### Users
- Register
- Login (JWT)
- Authenticated question & answer posting

### Topics
- Web Development
- Mobile Development
- DevOps

### Questions & Answers
- Create questions under topics
- Post answers to questions
- View all questions by topic
- View all answers to a question

---
## 2. Project Structure
```

techtrove/
├─ server/
│  ├─ server.js
│  ├─ package.json
│  ├─ scripts/
│  │  └─ init_db.js
│  └─ db/
├─ client/
│  ├─ index.html
│  └─ package.json (optional)
├─ db/
│  └─ database.sql
├─ .github/
│  └─ workflows/
│     ├─ node-ci.yml
│     └─ deploy-client.yml
├─ .gitignore
└─ README.md

```

---
## 3. Running the Project Locally
### 3.1 Initialize DB
```

cd server
npm install
npm run init-db

```

### 3.2 Start Server
```

npm run dev

# server runs at [http://localhost:3000](http://localhost:3000)

```

### 3.3 Run Client
Open `client/index.html` in your browser.

---
## 4. API Endpoints
### Auth
POST /api/register  
POST /api/login

### Topics
GET /api/topics

### Questions
GET /api/questions/:topicId  
POST /api/questions

### Answers
GET /api/answers/:questionId  
POST /api/answers

---
## 5. Deployment
### Client (GitHub Pages)
Uses GitHub Actions workflow `deploy-client.yml`.

### Server (Railway / Render)
Deploy `server/` folder. Set environment variables:
- JWT_SECRET
- NODE_ENV
- PORT

---
## 6. License
This project is for educational/demo purposes.
```

---

## .gitignore

```gitignore
node_modules/
server/node_modules/
client/node_modules/
*.log
*.sqlite
*.db
db/*.db
.env
.vscode/
dist/
```

---

## db/database.sql

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

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

CREATE TABLE answers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    body TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT INTO topics (name) VALUES ('Web Development'), ('Mobile Development'), ('DevOps');

INSERT INTO users (username, password_hash) VALUES
('alice', 'hashed_pw_demo'),
('bob', 'hashed_pw_demo');

INSERT INTO questions (user_id, topic_id, title, body) VALUES
(1, 1, 'How does React state work?', 'I want to understand useState...'),
(2, 3, 'What is CI/CD?', 'Can someone explain CI/CD pipelines?');

INSERT INTO answers (question_id, user_id, body) VALUES
(1, 2, 'React state triggers re-renders when updated.'),
(2, 1, 'CI/CD automates testing and deployment.');
```

---

## server/scripts/init_db.js

```js
const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

const sql = fs.readFileSync(path.join(__dirname, '../../db/database.sql'), 'utf8');
const dbFile = path.join(__dirname, '../db/techtrove.db');

const db = new sqlite3.Database(dbFile);
db.exec(sql, (err) => {
  if (err) {
    console.error('Failed to init DB:', err);
    process.exit(1);
  } else {
    console.log('Database initialized.');
    db.close();
  }
});
```

---

## server/server.js

```js
const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const sqlite3 = require("sqlite3").verbose();
const cors = require("cors");
const dotenv = require("dotenv");
dotenv.config();

const app = express();
app.use(express.json());
app.use(cors());

const db = new sqlite3.Database("./server/db/techtrove.db");
const JWT_SECRET = process.env.JWT_SECRET || "SUPER_SECRET_CHANGE_ME";

// Register
app.post("/api/register", (req, res) => {
    const { username, password } = req.body;
    const hash = bcrypt.hashSync(password, 10);

    db.run(
        "INSERT INTO users (username, password_hash) VALUES (?, ?)",
        [username, hash],
        function (err) {
            if (err) return res.status(400).json({ error: "User exists" });
            res.json({ id: this.lastID, username });
        }
    );
});

// Login
app.post("/api/login", (req, res) => {
    const { username, password } = req.body;

    db.get("SELECT * FROM users WHERE username = ?", [username], (err, user) => {
        if (!user) return res.status(400).json({ error: "Invalid credentials" });

        if (!bcrypt.compareSync(password, user.password_hash))
            return res.status(400).json({ error: "Invalid credentials" });

        const token = jwt.sign({ id: user.id }, JWT_SECRET);
        res.json({ token, username });
    });
});

// Middleware for auth
function auth(req, res, next) {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(403).json({ error: "No token" });

    try {
        req.user = jwt.verify(token, JWT_SECRET);
        next();
    } catch {
        res.status(403).json({ error: "Invalid token" });
    }
}

// Get topics
app.get("/api/topics", (req, res) => {
    db.all("SELECT * FROM topics", (err, rows) => res.json(rows));
});

// Get questions
app.get("/api/questions/:topicId", (req, res) => {
    db.all(
        "SELECT * FROM questions WHERE topic_id = ?",
        [req.params.topicId],
        (err, rows) => res.json(rows)
    );
});

// Create question
app.post("/api/questions", auth, (req, res) => {
    const { topic_id, title, body } = req.body;

    db.run(
        "INSERT INTO questions (user_id, topic_id, title, body) VALUES (?, ?, ?, ?)",
        [req.user.id, topic_id, title, body],
        function (err) {
            res.json({ id: this.lastID });
        }
    );
});

// Get answers
app.get("/api/answers/:questionId", (req, res) => {
    db.all(
        "SELECT * FROM answers WHERE question_id = ?",
        [req.params.questionId],
        (err, rows) => res.json(rows)
    );
});

// Post answer
app.post("/api/answers", auth, (req, res) => {
    const { question_id, body } = req.body;

    db.run(
        "INSERT INTO answers (question_id, user_id, body) VALUES (?, ?, ?)",
        [question_id, req.user.id, body],
        function (err) {
            res.json({ id: this.lastID });
        }
    );
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
```

---

## server/package.json

```json
{
  "name": "techtrove-server",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "init-db": "node scripts/init_db.js",
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "echo 'no tests' && exit 0"
  },
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.18.2",
    "jsonwebtoken": "^9.0.0",
    "sqlite3": "^5.1.6"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  }
}
```

---

## client/index.html

```html
<!DOCTYPE html>
<html>
<head>
    <title>TechTrove Forum</title>
    <style>
        body { font-family: Arial; margin: 20px; }
        .card { border: 1px solid #ddd; padding: 12px; margin: 8px 0; }
    </style>
</head>
<body>
<h1>TechTrove Forum</h1>

<div id="auth">
    <h2>Login</h2>
    <input id="username" placeholder="Username">
    <input id="password" placeholder="Password" type="password">
    <button onclick="login()">Login</button>
    <button onclick="register()">Register</button>
</div>
<hr>
<div id="topics"></div>
<div id="questions"></div>
<div id="answers"></div>
<script>
const API = "http://localhost:3000/api";
let TOKEN = null;
async function register() {
    const res = await fetch(`${API}/register`, {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({ username: username.value, password: password.value })
    });
    alert("Registered!");
}
async function login() {
    const res = await fetch(`${API}/login`, {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({ username: username.value, password: password.value })
    });
    const data = await res.json();
    TOKEN = data.token;
    loadTopics();
}
async function loadTopics() {
    const res = await fetch(`${API}/topics`);
    const topics = await res.json();
    topicsDiv = document.getElementById("topics");
    topicsDiv.innerHTML = "<h2>Topics</h2>";
    topics.forEach(t => {
        const btn = document.createElement("button");
        btn.innerText = t.name;
        btn.onclick = () => loadQuestions(t.id);
        topicsDiv.appendChild(btn);
    });
}
async function loadQuestions(topicId) {
    const res = await fetch(`${API}/questions/${topicId}`);
    const qs = await res.json();
    const questionsDiv = document.getElementById("questions");
    questionsDiv.innerHTML = "<h2>Questions</h2>";
    qs.forEach(q => {
        const el = document.createElement("div");
        el.className = "card";
        el.innerHTML = `<b>${q.title}</b><br>${q.body}<br><button onclick=\"loadAnswers(${q.id})\">View Answers</button>`;
        questionsDiv.appendChild(el);
    });
}
async function loadAnswers(questionId) {
    const res = await fetch(`${API}/answers/${questionId}`);
    const ans = await res.json();
    const ansDiv = document.getElementById("answers");
    ansDiv.innerHTML = "<h2>Answers</h2>";
    ans.forEach(a => {
        const el = document.createElement("div");
        el.className = "card";
        el.innerHTML = a.body;
        ansDiv.appendChild(el);
    });
}
</script>
</body>
</html>
```

---

## .github/workflows/node-ci.yml

```yaml
name: Node CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18.x]
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
      - name: Install server deps
        run: |
          cd server
          npm ci
      - name: Init database
        run: |
          cd server
          npm run init-db
      - name: Run server tests
        run: |
          cd server
          npm test
```

---

## .github/workflows/deploy-client.yml

```yaml
name: Deploy Client to GitHub Pages

on:
  push:
    branches:
      - main

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 18
      - name: Build client
        run: |
          cd client
          if [ -f package.json ]; then npm ci; npm run build || true; fi
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./client
```
