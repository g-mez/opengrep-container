# vulnerable_example.py
"""
Vulnerable example file for static-analysis testing.
Contains many intentional insecure patterns and bad practices.
DO NOT USE IN PRODUCTION.
"""

import os
import subprocess
import pickle
import sqlite3
import hashlib
import random
import tempfile
import requests  # third-party library - demonstrates insecure TLS usage
from flask import Flask, request  # example of debug mode usage (bad in prod)

# -----------------------------------------------------------------------------
# 1) Hardcoded credentials / secrets
# -----------------------------------------------------------------------------
# BAD: secrets committed in source code
DATABASE_PASSWORD = "P@ssw0rd123!"
API_KEY = "sk_test_very_insecure_api_key_1234567890"

def connect_to_db():
    # BAD: embedding password in connection string
    conn = sqlite3.connect("/tmp/example.db")  # file-based DB for demo
    # pretend we use a password somewhere (this is illustrative)
    print("Connecting with password:", DATABASE_PASSWORD)
    return conn

# -----------------------------------------------------------------------------
# 2) SQL Injection via string concatenation
# -----------------------------------------------------------------------------
def get_user_by_name(name):
    conn = connect_to_db()
    cur = conn.cursor()
    # BAD: SQL built by concatenation -> SQL injection risk
    query = "SELECT id, username FROM users WHERE username = '%s';" % name
    cur.execute(query)
    return cur.fetchall()

# -----------------------------------------------------------------------------
# 3) Unsafe use of subprocess with shell=True and user input
# -----------------------------------------------------------------------------
def list_files(user_path):
    # BAD: passing user input to a shell command with shell=True
    cmd = "ls -la %s" % user_path
    # This will run via the shell and can be exploited if user_path contains metacharacters
    subprocess.check_output(cmd, shell=True)

# -----------------------------------------------------------------------------
# 4) Use of eval / exec on untrusted input
# -----------------------------------------------------------------------------
def evaluate_expression(expr):
    # BAD: eval on untrusted input -> remote code execution
    return eval(expr)

def execute_code(code_str):
    # BAD: exec allows arbitrary code execution
    exec(code_str, {})

# -----------------------------------------------------------------------------
# 5) Unsafe deserialization (pickle.loads)
# -----------------------------------------------------------------------------
def unsafe_unpickle(payload_bytes):
    # BAD: unpickling untrusted data -> remote code execution
    return pickle.loads(payload_bytes)

# -----------------------------------------------------------------------------
# 6) Weak cryptography: MD5 used for password hashing
# -----------------------------------------------------------------------------
def store_password_weak(password):
    # BAD: MD5 is not suitable for password hashing
    digest = hashlib.md5(password.encode()).hexdigest()
    # pretend to store digest
    print("Storing md5 password hash:", digest)
    return digest

# -----------------------------------------------------------------------------
# 7) Predictable tokens / insufficient randomness
# -----------------------------------------------------------------------------
def generate_token():
    # BAD: using random.choice for security token (predictable)
    alphabet = "abcdefghijklmnopqrstuvwxyz0123456789"
    token = "".join(random.choice(alphabet) for _ in range(20))
    return token

# -----------------------------------------------------------------------------
# 8) Insecure temp file usage
# -----------------------------------------------------------------------------
def create_temp_file_bad():
    # BAD: tempfile.mktemp is insecure (race condition)
    temp_path = tempfile.mktemp(prefix="vuln_", suffix=".tmp")
    with open(temp_path, "w") as f:
        f.write("data")
    return temp_path

# -----------------------------------------------------------------------------
# 9) Insecure HTTP/TLS usage (verify=False)
# -----------------------------------------------------------------------------
def call_insecure_api(url):
    # BAD: disabling certificate verification -> MITM risk
    resp = requests.get(url, verify=False)
    return resp.text

# -----------------------------------------------------------------------------
# 10) Insecure file permissions / world-writable
# -----------------------------------------------------------------------------
def create_world_writable_file(path):
    with open(path, "w") as f:
        f.write("important data")
    # BAD: setting 0o777 makes file world-writable
    os.chmod(path, 0o777)

# -----------------------------------------------------------------------------
# 11) Flask app in debug mode (exposes interactive debugger)
# -----------------------------------------------------------------------------
app = Flask(__name__)

@app.route("/run", methods=["POST"])
def run_command():
    # BAD: running commands based on request data
    cmd = request.form.get("cmd", "")
    # Very unsafe: executes provided command
    os.system(cmd)  # insecure; also demonstrates use of os.system with user input
    return "ran"

if __name__ == "__main__":
    # BAD: debug=True exposes Werkzeug debugger + code execution to remote clients
    app.run(debug=True, port=5000)

# -----------------------------------------------------------------------------
# 12) Path traversal example (reading user-supplied path without sanitization)
# -----------------------------------------------------------------------------
def read_user_file(user_supplied_path):
    # BAD: no validation -> path traversal possible
    with open(user_supplied_path, "r") as f:
        return f.read()

# -----------------------------------------------------------------------------
# 13) Use of insecure randomness for cryptographic needs (reiterated)
# -----------------------------------------------------------------------------
def generate_password_reset_token():
    # BAD: not using secrets module for tokens
    return generate_token()

# End of vulnerable_example.py
