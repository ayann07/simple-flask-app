import os
from flask import Flask
app=Flask(__name__)

@app.route("/")
def main():
    environment = os.getenv("APP_ENV", "local")
    return f"welcome to version 2! env={environment}"

@app.route("/how_are_you")
def hello():
    return "I am good, how about you?"

@app.route("/health")
def health():
    return {"status": "ok"}

if __name__=="__main__":
    app.run(host='0.0.0.0', port=5000)
