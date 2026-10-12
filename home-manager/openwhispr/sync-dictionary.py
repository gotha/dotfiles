"""Add managed words through OpenWhispr's local CLI bridge."""

import http.client
import json
import sys
from pathlib import Path


def sync(words, bridge_path):
    try:
        bridge = json.loads(Path(bridge_path).read_text())
    except FileNotFoundError:
        return 0
    if bridge.get("version") != 1:
        raise ValueError("Unsupported OpenWhispr CLI bridge version")
    port = bridge["port"]
    if type(port) is not int or not 1 <= port <= 65535:
        raise ValueError("Invalid OpenWhispr CLI bridge port")
    connection = http.client.HTTPConnection("127.0.0.1", port, timeout=5)

    def request(method, path, body=None):
        connection.request(
            method,
            "/v1/dictionary/" + path,
            body=json.dumps(body) if body is not None else None,
            headers={
                "Authorization": "Bearer " + bridge["token"],
                "Content-Type": "application/json",
            },
        )
        response = connection.getresponse()
        data = response.read()
        if response.status != 200:
            raise RuntimeError(f"OpenWhispr dictionary API returned {response.status}")
        return json.loads(data)["data"]

    try:
        existing = {word.strip().lower() for word in request("GET", "list")}
        missing = []
        for word in words:
            word = word.strip()
            if word and word.lower() not in existing:
                missing.append(word)
                existing.add(word.lower())
        if not missing:
            return 0
        result = request("POST", "update", {"add": missing, "remove": []})
        return result["added"]
    except ConnectionRefusedError:
        return 0
    finally:
        connection.close()


if __name__ == "__main__":
    try:
        added = sync(json.loads(Path(sys.argv[1]).read_text()), sys.argv[2])
        if added:
            print(f"OpenWhispr: added {added} dictionary words")
    except (
        OSError,
        ValueError,
        KeyError,
        RuntimeError,
        http.client.HTTPException,
    ) as error:
        print(f"OpenWhispr dictionary sync failed: {error}", file=sys.stderr)
        sys.exit(1)
