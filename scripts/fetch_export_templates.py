#!/usr/bin/env python3
"""Installs selected Godot export templates without downloading the 1.3 GB bundle.

The official templates bundle (.tpz) is a zip file. This reads its central
directory with HTTP range requests and extracts only the members asked for
(by default the single-threaded web templates).

    scripts/fetch_export_templates.py                 # web templates
    scripts/fetch_export_templates.py android_release.apk ...
"""
import io
import os
import sys
import urllib.request
import zipfile

VERSION = os.environ.get("GODOT_VERSION", "4.7.2")
URL = (
    "https://downloads.godotengine.org/?version=%s&flavor=stable"
    "&slug=export_templates.tpz&platform=templates" % VERSION
)
DEFAULT_MEMBERS = ["web_nothreads_release.zip", "web_nothreads_debug.zip"]
# The download mirror rejects Python's default User-Agent.
HEADERS = {"User-Agent": "marbls-build/1.0"}


class HttpRangeFile(io.RawIOBase):
    """A read-only, seekable file backed by HTTP range requests."""

    def __init__(self, url: str) -> None:
        # Resolve the mirror redirect once so every range request hits the file.
        with urllib.request.urlopen(urllib.request.Request(url, method="HEAD", headers=HEADERS)) as response:
            self.url = response.geturl()
            self.size = int(response.headers["Content-Length"])
        self.position = 0

    def seekable(self) -> bool:
        return True

    def readable(self) -> bool:
        return True

    def tell(self) -> int:
        return self.position

    def seek(self, offset: int, whence: int = io.SEEK_SET) -> int:
        base = {io.SEEK_SET: 0, io.SEEK_CUR: self.position, io.SEEK_END: self.size}[whence]
        self.position = base + offset
        return self.position

    def readinto(self, buffer) -> int:
        if self.position >= self.size:
            return 0
        end = min(self.position + len(buffer), self.size) - 1
        request = urllib.request.Request(self.url, headers={**HEADERS, "Range": "bytes=%d-%d" % (self.position, end)})
        with urllib.request.urlopen(request) as response:
            data = response.read()
        buffer[: len(data)] = data
        self.position += len(data)
        return len(data)


def main() -> None:
    members = sys.argv[1:] or DEFAULT_MEMBERS
    data_home = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
    dest = os.path.join(data_home, "godot", "export_templates", "%s.stable" % VERSION)
    missing = [m for m in members if not os.path.exists(os.path.join(dest, m))]
    if not missing:
        print(dest)
        return
    os.makedirs(dest, exist_ok=True)
    raw = io.BufferedReader(HttpRangeFile(URL), buffer_size=1 << 20)
    with zipfile.ZipFile(raw) as bundle:
        for member in missing:
            info = bundle.getinfo("templates/" + member)
            with bundle.open(info) as source, open(os.path.join(dest, member), "wb") as target:
                while chunk := source.read(1 << 20):
                    target.write(chunk)
        version_file = os.path.join(dest, "version.txt")
        if not os.path.exists(version_file):
            with bundle.open("templates/version.txt") as source, open(version_file, "wb") as target:
                target.write(source.read())
    print(dest)


if __name__ == "__main__":
    main()
