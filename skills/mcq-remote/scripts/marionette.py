#!/usr/bin/env python3
"""Drive the selected tab of a running Zen/Firefox over Marionette.

Run on the laptop, e.g. ssh laptop python3 - selected 'input[type=radio]' < marionette.py
Only WebDriver element commands are used: no script execution, no new tabs or windows.

commands:
  probe                 title and url of the selected tab
  goto <url>            load a url in the selected tab
  text <css>            numbered text of every match
  selected <css>        numbered selected state of every match
  click <css> [n]       click match n (default 0)
options:
  --frame <css>         switch into this iframe first (Canvas New Quizzes runs in one)
  --port <n>            marionette port (default 2829, the quiz window from open-quiz-window.sh)
"""
import json
import socket
import sys

ELEMENT = "element-6066-11e4-a52e-4f735466cecf"


class Marionette:
    def __init__(self, port):
        self.sock = socket.create_connection(("127.0.0.1", port), timeout=15)
        self.stream = self.sock.makefile("rb")
        self.seq = 0
        self.read()

    def read(self):
        prefix = bytearray()
        while (char := self.stream.read(1)) != b":":
            if not char or not char.isdigit() or len(prefix) > 12:
                raise ConnectionError("bad or closed marionette stream")
            prefix += char
        return json.loads(self.stream.read(int(prefix)))

    def send(self, name, params=None):
        self.seq += 1
        body = json.dumps([0, self.seq, name, params or {}]).encode()
        self.sock.sendall(str(len(body)).encode() + b":" + body)
        kind, seq, error, result = self.read()
        if kind != 1 or seq != self.seq:
            raise ValueError("unexpected marionette response")
        if error:
            raise RuntimeError(error.get("message", str(error)))
        return result.get("value", result) if isinstance(result, dict) else result

    def find_all(self, css):
        found = self.send("WebDriver:FindElements", {"using": "css selector", "value": css})
        return [e[ELEMENT] for e in found]


def main(argv):
    frame, port = None, 2829
    if "--frame" in argv:
        i = argv.index("--frame")
        frame = argv[i + 1]
        del argv[i : i + 2]
    if "--port" in argv:
        i = argv.index("--port")
        port = int(argv[i + 1])
        del argv[i : i + 2]
    if not argv:
        sys.exit(__doc__)
    cmd, args = argv[0], argv[1:]

    m = Marionette(port)
    # attaches to the already running browser and its selected tab
    m.send("WebDriver:NewSession", {"capabilities": {}})
    try:
        if frame:
            frames = m.find_all(frame)
            if not frames:
                sys.exit(f"no frame matches {frame}")
            m.send("WebDriver:SwitchToFrame", {"element": frames[0]})
        if cmd == "probe":
            print(m.send("WebDriver:GetTitle"))
            print(m.send("WebDriver:GetCurrentURL"))
        elif cmd == "goto":
            m.send("WebDriver:Navigate", {"url": args[0]})
            print(m.send("WebDriver:GetTitle"))
        elif cmd in ("text", "selected"):
            op = "WebDriver:GetElementText" if cmd == "text" else "WebDriver:IsElementSelected"
            for n, el in enumerate(m.find_all(args[0])):
                print(n, json.dumps(m.send(op, {"id": el})))
        elif cmd == "click":
            matches = m.find_all(args[0])
            n = int(args[1]) if len(args) > 1 else 0
            if n >= len(matches):
                sys.exit(f"{len(matches)} matches for {args[0]}, no index {n}")
            m.send("WebDriver:ElementClick", {"id": matches[n]})
            print("clicked", n)
        else:
            sys.exit(__doc__)
    finally:
        m.send("WebDriver:DeleteSession")
        m.sock.close()


if __name__ == "__main__":
    main(sys.argv[1:])
