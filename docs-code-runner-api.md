# Code Runner API Documentation

> **Base URL:** `/api/code-runner`  
> **Engine:** [JDoodle Compiler API](https://www.jdoodle.com/)  
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
