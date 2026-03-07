# Code Runner API Documentation

> **Base URL:** `/api/code-runner`  
> **Engine:** [JDoodle Compiler API](https://www.jdoodle.com/) + [Google Gemini AI](https://ai.google.dev/)  
> **Auth:** No token needed — API keys are stored server-side.

---

## 1. Execute Code

Run code in any supported language.

### `POST /api/code-runner/execute`

#### Request Body

| Field          | Type     | Required | Description |
|----------------|----------|----------|-------------|
| `code`         | `string` | ✅ Yes   | The source code to execute |
| `fileName`     | `string` | ⚡ Either this or `language` | File name with extension (e.g. `app.py`, `main.js`). Language is auto-detected from the extension. |
| `language`     | `string` | ⚡ Either this or `fileName` | JDoodle language key (e.g. `python3`, `nodejs`, `java`). See supported languages below. |
| `versionIndex` | `string` | ❌ No    | JDoodle version index. Defaults to a sensible value per language. |
| `stdin`        | `string` | ❌ No    | Input to pass via stdin. Defaults to empty string. |

> **Note:** You must provide either `fileName` OR `language`. If both are given, `language` takes priority.

#### Example Request — Using `fileName`

```json
POST /api/code-runner/execute
Content-Type: application/json

{
  "fileName": "app.py",
  "code": "name = input()\nprint(f'Hello, {name}!')",
  "stdin": "Campus++"
}
```

#### Example Request — Using `language`

```json
POST /api/code-runner/execute
Content-Type: application/json

{
  "language": "nodejs",
  "code": "console.log('Hello from Node.js!');",
  "stdin": ""
}
```

#### Success Response — `200 OK`

```json
{
  "output": "Hello, Campus++!\n",
  "statusCode": 200,
  "memory": "7168",
  "cpuTime": "0.01",
  "language": "python3",
  "versionIndex": "4"
}
```

| Field          | Type     | Description |
|----------------|----------|-------------|
| `output`       | `string` | Combined stdout + stderr from the program |
| `statusCode`   | `number` | JDoodle status code (`200` = success) |
| `memory`       | `string` | Memory used in KB |
| `cpuTime`      | `string` | CPU time in seconds |
| `language`     | `string` | Language key that was used |
| `versionIndex` | `string` | Version index that was used |

#### Error Response — `400 Bad Request`

```json
{
  "message": "Unsupported file extension \".xyz\". Supported: .py, .js, .ts, .java, .c, .cpp, .cc, .cs, .rb, .go, .rs, .php, .sh, .bash, .kt, .swift, .r, .lua, .pl, .scala, .sql"
}
```

#### Error Response — `502 Bad Gateway`

```json
{
  "message": "Failed to execute code via JDoodle",
  "error": "fetch failed"
}
```

---

## 2. Get Supported Languages

Returns the list of all supported languages for building the frontend dropdown.

### `GET /api/code-runner/languages`

#### Example Response — `200 OK`

```json
[
  { "language": "python3",    "display": "Python 3",    "ext": ".py"    },
  { "language": "nodejs",     "display": "Node.js",     "ext": ".js"    },
  { "language": "typescript", "display": "TypeScript",   "ext": ".ts"    },
  { "language": "java",       "display": "Java",         "ext": ".java"  },
  { "language": "c",          "display": "C",            "ext": ".c"     },
  { "language": "cpp17",      "display": "C++ 17",       "ext": ".cpp"   },
  { "language": "csharp",     "display": "C#",           "ext": ".cs"    },
  { "language": "ruby",       "display": "Ruby",         "ext": ".rb"    },
  { "language": "go",         "display": "Go",           "ext": ".go"    },
  { "language": "rust",       "display": "Rust",         "ext": ".rs"    },
  { "language": "php",        "display": "PHP",          "ext": ".php"   },
  { "language": "bash",       "display": "Bash",         "ext": ".sh"    },
  { "language": "kotlin",     "display": "Kotlin",       "ext": ".kt"    },
  { "language": "swift",      "display": "Swift",        "ext": ".swift" },
  { "language": "r",          "display": "R",            "ext": ".r"     },
  { "language": "lua",        "display": "Lua",          "ext": ".lua"   },
  { "language": "perl",       "display": "Perl",         "ext": ".pl"    },
  { "language": "scala",      "display": "Scala",        "ext": ".scala" },
  { "language": "sql",        "display": "SQL",          "ext": ".sql"   }
]
```

---

## 3. Check Credit Usage

Check how many JDoodle API credits have been used today.

### `GET /api/code-runner/credit-spent`

#### Example Response — `200 OK`

```json
{
  "used": 12
}
```

> JDoodle free tier allows **200 credits/day**.

---

## 4. Explain Code (AI)

AI explains the code step-by-step for students.

### `POST /api/code-runner/explain`

#### Request Body

| Field      | Type     | Required | Description |
|------------|----------|----------|-------------|
| `code`     | `string` | ✅ Yes   | The source code to explain |
| `language` | `string` | ❌ No    | Language name (e.g. `python3`, `java`). Defaults to `unknown`. |

#### Example Request

```json
POST /api/code-runner/explain
Content-Type: application/json

{
  "code": "for i in range(5):\n    print(i * 2)",
  "language": "python3"
}
```

#### Success Response — `200 OK`

```json
{
  "explanation": "## Purpose\nThis code prints even numbers from 0 to 8...\n\n## Step-by-step\n1. `range(5)` generates numbers 0–4...\n..."
}
```

| Field         | Type     | Description |
|---------------|----------|-------------|
| `explanation` | `string` | Markdown-formatted explanation |

---

## 5. Debug Code (AI)

AI finds bugs and returns a suggested fix. The frontend can show **Accept / Reject** buttons.

### `POST /api/code-runner/debug`

#### Request Body

| Field      | Type     | Required | Description |
|------------|----------|----------|-------------|
| `code`     | `string` | ✅ Yes   | The source code to debug |
| `language` | `string` | ❌ No    | Language name |
| `error`    | `string` | ❌ No    | Error output from running the code (helps AI pinpoint the issue) |

#### Example Request

```json
POST /api/code-runner/debug
Content-Type: application/json

{
  "code": "print(f\"Hello {name}",
  "language": "python3",
  "error": "SyntaxError: EOL while scanning string literal"
}
```

#### Success Response — `200 OK`

```json
{
  "suggestion": {
    "original": "print(f\"Hello {name}\"",
    "fixed": "print(f\"Hello {name}\")",
    "changes": [
      { "line": 1, "description": "Added missing closing parenthesis and fixed f-string quote" }
    ],
    "explanation": "The f-string was missing a closing quote and the print() call was missing its closing parenthesis."
  }
}
```

| Field                       | Type       | Description |
|-----------------------------|------------|-------------|
| `suggestion.original`       | `string`   | The original code sent |
| `suggestion.fixed`          | `string`   | The complete corrected code |
| `suggestion.changes`        | `array`    | List of `{ line, description }` changes made |
| `suggestion.explanation`    | `string`   | Summary of what was fixed |

#### Frontend Usage

```javascript
const data = await res.json();
const { fixed, changes } = data.suggestion;

// Show changes to user, then on "Accept":
editor.value = fixed;

// On "Reject": do nothing
```

---

## 6. Review Code (AI)

AI reviews code quality, best practices, performance, and security.

### `POST /api/code-runner/review`

#### Request Body

| Field      | Type     | Required | Description |
|------------|----------|----------|-------------|
| `code`     | `string` | ✅ Yes   | The source code to review |
| `language` | `string` | ❌ No    | Language name |

#### Example Request

```json
POST /api/code-runner/review
Content-Type: application/json

{
  "code": "x = input()\nprint(int(x) / 0)",
  "language": "python3"
}
```

#### Success Response — `200 OK`

```json
{
  "review": "## Code Quality: 2/10\n\n## Issues Found\n- **Line 2:** Division by zero...\n\n## Suggestions\n- Add error handling...\n\n## Summary\n..."
}
```

| Field    | Type     | Description |
|----------|----------|-------------|
| `review` | `string` | Markdown-formatted code review |

---

## 7. Explain + Debug (AI — Auto Error Flow)

Combined endpoint: explains the error **and** provides a fix in one call. Used automatically when code throws an error.

### `POST /api/code-runner/explain-and-debug`

#### Request Body

| Field      | Type     | Required | Description |
|------------|----------|----------|-------------|
| `code`     | `string` | ✅ Yes   | The source code |
| `language` | `string` | ❌ No    | Language name |
| `error`    | `string` | ✅ Yes   | The error output from execution |

#### Example Request

```json
POST /api/code-runner/explain-and-debug
Content-Type: application/json

{
  "code": "name = input(\"Name? \")\nprint(f\"Hello {name}",
  "language": "python3",
  "error": "SyntaxError: EOL while scanning string literal"
}
```

#### Success Response — `200 OK`

```json
{
  "errorExplanation": "### What happened?\nThe `SyntaxError: EOL while scanning string literal` means Python reached the end of a line while still inside a string...",
  "suggestion": {
    "original": "name = input(\"Name? \")\nprint(f\"Hello {name}\"",
    "fixed": "name = input(\"Name? \")\nprint(f\"Hello {name}\")",
    "changes": [
      { "line": 2, "description": "Added missing closing parenthesis for print()" }
    ],
    "explanation": "The print statement was missing its closing parenthesis."
  }
}
```

| Field               | Type     | Description |
|---------------------|----------|-------------|
| `errorExplanation`  | `string` | Markdown explanation of the error (student-friendly) |
| `suggestion`        | `object` | Same structure as the Debug endpoint |

#### Frontend Auto-Trigger Flow

```
Write Code → Run → Error Detected → Auto AI Panel Opens:
  1. 🔴 Error Explanation (why it happened)
  2. 🛠 Suggested Fix (line-by-line changes + fixed code)
  3. ✓ Accept Fix → replaces editor code
     ✗ Reject   → keeps original code
```

---

## 8. Improve / Refactor Code (AI)

AI refactors code — improves readability, performance, and best practices while preserving behaviour.

### `POST /api/code-runner/improve`

#### Request Body

| Field      | Type     | Required | Description |
|------------|----------|----------|-------------|
| `code`     | `string` | ✅ Yes   | The source code to improve |
| `language` | `string` | ❌ No    | Language name (e.g. `python3`, `java`). Defaults to `unknown`. |

#### Example Request

```json
POST /api/code-runner/improve
Content-Type: application/json

{
  "code": "x = []; \nfor i in range(10):\n    x.append(i*i)",
  "language": "python3"
}
```

#### Success Response — `200 OK`

```json
{
  "improved": "x = [i * i for i in range(10)]",
  "explanation": "## Improvements\n\n1. **List comprehension** — Replaced the explicit `for` loop + `append` with a Pythonic list comprehension. This is more readable and slightly faster.\n2. **Removed unnecessary variable** — The intermediate empty list assignment was eliminated.\n"
}
```

| Field         | Type     | Description |
|---------------|----------|-------------|
| `improved`    | `string` | The complete refactored/improved code |
| `explanation` | `string` | Markdown explanation of every improvement made |

#### Error Response — `400 Bad Request`

```json
{
  "message": "`code` is required"
}
```

#### Frontend Usage

```javascript
const data = await res.json();
const { improved, explanation } = data;

// Show explanation to user, then on "Accept":
editor.value = improved;

// On "Reject": keep original code
```

---

## 9. Generate Coding Challenge (AI)

AI generates an original coding problem with examples, constraints, and hints.

### `POST /api/code-runner/generate-challenge`

#### Request Body

| Field        | Type     | Required | Description |
|--------------|----------|----------|-------------|
| `language`   | `string` | ❌ No    | Preferred language for examples (e.g. `python3`, `java`). Defaults to `any language`. |
| `difficulty` | `string` | ❌ No    | `easy`, `medium`, or `hard`. Defaults to `medium`. |
| `topic`      | `string` | ❌ No    | Topic focus (e.g. `arrays`, `recursion`, `graphs`, `dynamic programming`). |

#### Example Request

```json
POST /api/code-runner/generate-challenge
Content-Type: application/json

{
  "language": "python3",
  "difficulty": "medium",
  "topic": "arrays"
}
```

#### Success Response — `200 OK`

```json
{
  "title": "Balanced Subarray Sum",
  "problem": "## Balanced Subarray Sum\n\nGiven an array of integers, find the length of the longest subarray whose sum equals zero...\n",
  "examples": [
    {
      "input": "[1, -1, 3, 2, -2, -3, 4]",
      "output": "6",
      "explanation": "The subarray [-1, 3, 2, -2, -3, 1] from index 0-5 sums to 0."
    },
    {
      "input": "[1, 2, 3]",
      "output": "0",
      "explanation": "No subarray sums to zero."
    }
  ],
  "constraints": [
    "1 ≤ n ≤ 10^5",
    "-10^9 ≤ arr[i] ≤ 10^9",
    "Time limit: 1 second"
  ],
  "difficulty": "medium",
  "hints": [
    "Think about prefix sums.",
    "A hash map can help you find repeated prefix sums in O(1)."
  ]
}
```

| Field         | Type     | Description |
|---------------|----------|-------------|
| `title`       | `string` | Short problem title |
| `problem`     | `string` | Full problem statement in Markdown |
| `examples`    | `array`  | List of `{ input, output, explanation }` examples (at least 2) |
| `constraints` | `array`  | List of constraint strings (3-5) |
| `difficulty`  | `string` | `easy`, `medium`, or `hard` |
| `hints`       | `array`  | 1-2 hints that guide without giving the answer |

#### Error Response — `502 Bad Gateway`

```json
{
  "message": "AI challenge generation failed",
  "error": "..."
}
```

---

## 10. Push Code to GitHub

Push code directly from the Code IDE to any user's GitHub repository. Uses GitHub OAuth for authentication. Any GitHub user can connect, push code with any file name to any repo they own.

> **Auth Routes:** Mounted at both `/api/auth` and `/auth`  
> **GitHub Routes:** Under `/api/code-runner/github`

### OAuth Flow

```
Editor → "Push to GitHub" button
  → GET  /api/auth/github                   (redirect to GitHub login)
  → User authorizes Campus++ on GitHub
  → GitHub redirects → /api/auth/github/callback?code=...&state=...
  → Backend exchanges code for access_token
  → Fetches GitHub username
  → Redirects back to /code-ide#github_token=gho_xxx&github_user=johndoe
  → Frontend parses hash, stores token client-side
  → User selects repo, pushes code via API
```

> **Note:** Both `/auth/github` and `/api/auth/github` work — server mounts the auth router at both paths.

---

### `GET /api/auth/github`

Redirects the user to the GitHub OAuth consent screen. Works for **any GitHub user**.

#### Query Parameters (all optional)

| Field       | Type     | Description |
|-------------|----------|-------------|
| `fileName`  | `string` | Current file name — restored after redirect (e.g. `main.py`, `index.js`) |
| `language`  | `string` | Current language — restored after redirect (e.g. `python3`, `nodejs`) |
| `repo`      | `string` | Pre-selected repo (e.g. `user/my-repo`) |
| `returnUrl` | `string` | URL to redirect back to after auth. Defaults to `/code-ide`. |

#### Example

```
GET /api/auth/github?fileName=server.js&language=nodejs&returnUrl=/code-ide
```

→ Redirects to `https://github.com/login/oauth/authorize?client_id=...&scope=repo&state=...`

#### How State Works

The query params are base64-encoded into the `state` parameter sent to GitHub. After auth, the callback decodes them to redirect the user back with their editor context intact.

---

### `GET /api/auth/github/callback`

**This is called by GitHub automatically** — not by the developer. After the user authorises, GitHub redirects here with a `code` and `state`.

The backend:
1. Exchanges the `code` for a GitHub `access_token`
2. Fetches the user's GitHub profile (`/user`)
3. Redirects to the `returnUrl` with token + user in the URL hash

#### Redirect Result

```
/code-ide#github_token=gho_xxxxxxxxxxxx&github_user=johndoe&fileName=server.js&language=nodejs
```

#### Frontend Parsing

```javascript
const params = new URLSearchParams(window.location.hash.slice(1));
const token = params.get('github_token');   // GitHub access token
const user  = params.get('github_user');    // GitHub username
const file  = params.get('fileName');       // Restored editor state
const lang  = params.get('language');       // Restored language
```

#### Error Responses

| Status | Response |
|--------|----------|
| `400`  | `{ "message": "Missing code from GitHub" }` |
| `401`  | `{ "message": "GitHub OAuth failed", "error": "..." }` |
| `502`  | `{ "message": "GitHub OAuth callback failed", "error": "..." }` |

---

### `GET /api/code-runner/github/repos`

List the authenticated user's GitHub repositories (sorted by recently updated, up to 100).

#### Headers

| Header          | Value                      |
|-----------------|----------------------------|
| `Authorization` | `Bearer <github_token>`    |

#### Example Request

```bash
curl -H "Authorization: Bearer gho_xxxxxxxxxxxx" \
  https://campuspp-f7qx.onrender.com/api/code-runner/github/repos
```

#### Success Response — `200 OK`

```json
[
  {
    "id": 123456,
    "name": "my-project",
    "full_name": "johndoe/my-project",
    "private": false,
    "default_branch": "main",
    "html_url": "https://github.com/johndoe/my-project",
    "description": "My awesome project"
  },
  {
    "id": 789012,
    "name": "private-app",
    "full_name": "johndoe/private-app",
    "private": true,
    "default_branch": "main",
    "html_url": "https://github.com/johndoe/private-app",
    "description": null
  }
]
```

#### Error Responses

| Status | Response |
|--------|----------|
| `401`  | `{ "message": "GitHub token required" }` |
| `502`  | `{ "message": "Failed to list GitHub repos", "error": "..." }` |

---

### `POST /api/code-runner/github/repos`

Create a new GitHub repository under the authenticated user's account.

#### Headers

| Header          | Value                      |
|-----------------|----------------------------|
| `Authorization` | `Bearer <github_token>`    |

#### Request Body

| Field         | Type      | Required | Description |
|---------------|-----------|----------|-------------|
| `name`        | `string`  | ✅ Yes   | Repository name (e.g. `my-new-project`) |
| `description` | `string`  | ❌ No    | Defaults to `"Created from Campus++ Code IDE"` |
| `isPrivate`   | `boolean` | ❌ No    | Defaults to `false` (public) |

#### Example Request

```json
POST /api/code-runner/github/repos
Authorization: Bearer gho_xxxxxxxxxxxx
Content-Type: application/json

{
  "name": "campus-solutions",
  "description": "My coding solutions from Campus++ IDE",
  "isPrivate": true
}
```

#### Success Response — `201 Created`

```json
{
  "id": 789012,
  "name": "campus-solutions",
  "full_name": "johndoe/campus-solutions",
  "private": true,
  "default_branch": "main",
  "html_url": "https://github.com/johndoe/campus-solutions"
}
```

> **Note:** Repo is auto-initialized with a README (`auto_init: true`), so you can immediately push files to it.

#### Error Responses

| Status | Response |
|--------|----------|
| `400`  | `{ "message": "name is required" }` |
| `401`  | `{ "message": "GitHub token required" }` |
| `422`  | `{ "message": "Failed to create repo", "error": "Repository creation failed." }` — repo name already exists |
| `502`  | `{ "message": "Failed to create GitHub repo", "error": "..." }` |

---

### `POST /api/code-runner/github/push`

Push (create or update) a file in a GitHub repository. If the file already exists, it updates it. If it doesn't exist, it creates it. Works with **any file name and any extension**.

#### Headers

| Header          | Value                      |
|-----------------|----------------------------|
| `Authorization` | `Bearer <github_token>`    |

#### Request Body

| Field      | Type     | Required | Description |
|------------|----------|----------|-------------|
| `repo`     | `string` | ✅ Yes   | Full repo name — `"<username>/<repo>"` |
| `fileName` | `string` | ✅ Yes   | Any file name with extension (e.g. `main.py`, `App.java`, `src/utils.js`) |
| `code`     | `string` | ✅ Yes   | The file content to push |
| `message`  | `string` | ❌ No    | Commit message. Defaults to `"Update <fileName> via Campus++ Code IDE"` |
| `branch`   | `string` | ❌ No    | Target branch. Defaults to `"main"` |

#### Example Request — New File

```json
POST /api/code-runner/github/push
Authorization: Bearer gho_xxxxxxxxxxxx
Content-Type: application/json

{
  "repo": "johndoe/campus-solutions",
  "fileName": "binary_search.cpp",
  "code": "#include <iostream>\nusing namespace std;\nint main() {\n    cout << \"Binary Search\" << endl;\n    return 0;\n}",
  "message": "Add binary search solution"
}
```

#### Example Request — Update Existing File

```json
POST /api/code-runner/github/push
Authorization: Bearer gho_xxxxxxxxxxxx
Content-Type: application/json

{
  "repo": "johndoe/campus-solutions",
  "fileName": "binary_search.cpp",
  "code": "#include <iostream>\n// Updated with optimized version\nusing namespace std;\nint main() {\n    cout << \"Optimized Binary Search\" << endl;\n    return 0;\n}",
  "message": "Optimize binary search solution",
  "branch": "main"
}
```

#### Success Response — `200 OK`

```json
{
  "message": "File created successfully",
  "commit": {
    "sha": "abc123def456...",
    "message": "Add binary search solution",
    "url": "https://github.com/johndoe/campus-solutions/commit/abc123"
  },
  "file": {
    "path": "binary_search.cpp",
    "sha": "xyz789...",
    "html_url": "https://github.com/johndoe/campus-solutions/blob/main/binary_search.cpp",
    "download_url": "https://raw.githubusercontent.com/johndoe/campus-solutions/main/binary_search.cpp"
  }
}
```

> **Note:** `message` will say `"File updated successfully"` if the file already existed.

#### Error Responses

| Status | Response |
|--------|----------|
| `400`  | `{ "message": "repo is required (e.g. \"user/my-repo\")" }` |
| `400`  | `{ "message": "fileName is required (e.g. \"main.py\")" }` |
| `400`  | `{ "message": "code is required" }` |
| `401`  | `{ "message": "GitHub token required" }` |
| `404`  | `{ "message": "Failed to push code to GitHub", "error": "Not Found" }` — repo doesn't exist |
| `502`  | `{ "message": "Failed to push code to GitHub", "error": "..." }` |

---

## Quick Integration Examples

### JavaScript (fetch)

```javascript
const response = await fetch('/api/code-runner/execute', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    fileName: 'app.py',
    code: 'print("Hello!")',
    stdin: ''
  })
});

const data = await response.json();
console.log(data.output);   // "Hello!\n"
console.log(data.cpuTime);  // "0.01"
console.log(data.memory);   // "7168"
```

### React / Next.js

```jsx
const [output, setOutput] = useState('');

const runCode = async () => {
  const res = await fetch('/api/code-runner/execute', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      fileName: 'main.java',
      code: `public class Main {
    public static void main(String[] args) {
        System.out.println("Hello from Java!");
    }
}`,
    }),
  });
  const data = await res.json();
  setOutput(data.output);
};
```

### cURL

```bash
curl -X POST http://localhost:3000/api/code-runner/execute \
  -H "Content-Type: application/json" \
  -d '{
    "fileName": "app.js",
    "code": "console.log(2 + 2);",
    "stdin": ""
  }'
```

---

## Supported Languages — File Extension → Language Mapping

| Extension | Language Key  | Display Name |
|-----------|--------------|--------------|
| `.py`     | `python3`    | Python 3     |
| `.js`     | `nodejs`     | Node.js      |
| `.ts`     | `typescript` | TypeScript   |
| `.java`   | `java`       | Java         |
| `.c`      | `c`          | C            |
| `.cpp`    | `cpp17`      | C++ 17       |
| `.cc`     | `cpp17`      | C++ 17       |
| `.cs`     | `csharp`     | C#           |
| `.rb`     | `ruby`       | Ruby         |
| `.go`     | `go`         | Go           |
| `.rs`     | `rust`       | Rust         |
| `.php`    | `php`        | PHP          |
| `.sh`     | `bash`       | Bash         |
| `.bash`   | `bash`       | Bash         |
| `.kt`     | `kotlin`     | Kotlin       |
| `.swift`  | `swift`      | Swift        |
| `.r`      | `r`          | R            |
| `.lua`    | `lua`        | Lua          |
| `.pl`     | `perl`       | Perl         |
| `.scala`  | `scala`      | Scala        |
| `.sql`    | `sql`        | SQL          |

---

## Frontend Page

A ready-to-use Code IDE page is available at:

```
GET /code-ide
```

Open it in a browser at `http://localhost:3000/code-ide`

### IDE Features

- **Run Code** — Execute in 19 languages with interactive terminal input
- **💡 Explain** — AI explains your code step-by-step
- **🐛 Debug** — AI finds bugs and suggests fixes (Accept / Reject)
- **📝 Review** — AI reviews code quality, issues, and best practices
- **⚡ Auto Error Detection** — When code throws an error, AI automatically explains the error and offers a fix
- **🔧 Improve** — AI refactors your code for better readability, performance, and best practices (Accept / Reject)
- **🎯 Challenge** — AI generates a coding challenge with examples, constraints, and hints to practice
- **🚀 Push to GitHub** — Push code directly to a GitHub repo with OAuth authentication (no copy-paste needed)
