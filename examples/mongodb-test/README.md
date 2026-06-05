# MongoDB Testing in Judge0 (via mongomock)

This example shows how to test MongoDB-dependent Python code inside a Judge0
sandbox **without** a running MongoDB server. It uses
[mongomock](https://github.com/mongomock/mongomock), an in-memory pure-Python
fake of the `pymongo` API.

## What is mongomock?

`mongomock` is a small library that emulates the parts of MongoDB used by
`pymongo` (the standard Python MongoDB driver) so your test code can run
against an in-memory store instead of a real database.

```python
from mongomock import MongoClient
client = MongoClient()         # in-memory, no network, no server
db = client.test_db
col = db.test_col
col.insert_one({"name": "test", "value": 42})
```

`MongoClient` from `mongomock` is a drop-in replacement for
`pymongo.MongoClient`. The API surface is the same, so production code that
talks to a real MongoDB can be unit-tested by swapping the client.

## Why run it inside Judge0?

Judge0 sandboxes are isolated, ephemeral, and have no network access to
arbitrary services. Spinning up a real MongoDB instance inside a Judge0
sandbox is not viable, and you would not want to anyway — tests should be
hermetic.

`mongomock` fits this perfectly:

- **No external service** — the store lives in process memory.
- **Pure Python** — no system-level dependencies, no native extensions.
- **Drop-in API** — the same `pymongo` calls your code uses in production.
- **Fast** — no disk, no socket, no auth.

This is the standard pattern for testing MongoDB code in CI/CD and in any
sandboxed execution environment.

## File layout for a Judge0 submission

Judge0 multi-file submissions are uploaded as a `.zip` archive. The archive's
**root** is the working directory for `run.sh`. The `run.sh` script
determines the entry point.

For this example, the archive should contain:

```
submission.zip
├── run.sh            # entry script, invoked by Judge0
└── test_mongodb.py   # the test code
```

The contents of the two files:

`test_mongodb.py`:

```python
from mongomock import MongoClient

client = MongoClient()
db = client.test_db
col = db.test_col
col.insert_one({"name": "test", "value": 42})
doc = col.find_one({"name": "test"})
assert doc["value"] == 42, "MongoDB mock test failed"
print("All MongoDB mock tests passed!")
```

`run.sh`:

```bash
#!/bin/bash
python3 test_mongodb.py
```

The repository also keeps these files at the repo root for reference and easy
diffing (`test_mongodb.py`, `run.sh`).

## How to submit

### 1. Build the zip

From the directory containing `run.sh` and `test_mongodb.py`:

```bash
zip -r submission.zip run.sh test_mongodb.py
```

PowerShell:

```powershell
Compress-Archive -Path run.sh, test_mongodb.py -DestinationPath submission.zip
```

### 2. Submit to Judge0 (Language ID 89 = Python 3)

`language_id: 89` is Python 3 in Judge0. The `additional_files` field is
base64-encoded zip bytes.

```bash
B64=$(base64 -w 0 submission.zip)
curl -s -X POST "http://localhost:2358/submissions?wait=true" \
  -H "Content-Type: application/json" \
  -d "{
    \"language_id\": 89,
    \"stdin\": \"\",
    \"expected_output\": \"All MongoDB mock tests passed!\\n\",
    \"additional_files\": \"$B64\"
  }"
```

PowerShell:

```powershell
$bytes   = [System.IO.File]::ReadAllBytes("submission.zip")
$b64     = [Convert]::ToBase64String($bytes)
$body    = @{
  language_id     = 89
  stdin           = ""
  expected_output = "All MongoDB mock tests passed!`n"
  additional_files = $b64
} | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "http://localhost:2358/submissions?wait=true" `
  -ContentType "application/json" -Body $body
```

## Expected output

A successful run prints exactly:

```
All MongoDB mock tests passed!
```

If `mongomock` is missing from the Judge0 image you will see
`ModuleNotFoundError: No module named 'mongomock'`. If the assertion in the
test fails, the process exits with a non-zero status and an
`AssertionError` traceback.

## Image rebuild reminder

`mongomock` is pre-installed in this custom Judge0 image via the line
`"mongomock<4.0"` in `requirements/python/install-python-deps.sh`. The
`<4.0` upper bound keeps the install on the 3.x line.

If you change the `requirements/python/install-python-deps.sh` file, rebuild
the image:

```bash
docker build --target production -t mrkushalsm-judge0:full .
docker compose down && docker compose up -d
```

If you fork or rebase onto a different Judge0 image, ensure
`mongomock` is installed in the sandbox before submitting.

## Extending this example

The pattern above is a smoke test. To test real code that uses `pymongo`,
swap the client import:

```python
# in your test setup
import mongomock
from unittest.mock import patch

with patch("pymongo.MongoClient", new=mongomock.MongoClient):
    from your_app import db_layer        # imports happen inside the patch
    db_layer.do_something_that_uses_mongo()
    # ... assertions on db_layer state ...
```

Or, if your app takes the client as a dependency, pass the mongomock client
in directly:

```python
client = mongomock.MongoClient()
db_layer = MyApp(client)
db_layer.run_migration()
```
