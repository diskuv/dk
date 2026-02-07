#!/usr/bin/env python3
"""Generate CommonsBase_Std/Msitools.Msiextract.Bundle.values.jsonc.

This file captures Homebrew bottle blobs for msitools (contains msiextract).
We use Homebrew's formula API to discover the per-platform bottle blob digests,
then query GHCR for the blob size (Content-Length) so dk0 validation passes.

Notes:
- GHCR often requires an Authorization header even for public blobs.
- By default we use the "minimal" header value used elsewhere in this repo's
  maintenance workflows: Bearer QQ==

Usage examples:
  python3 ext/dk/etc/maintenance/msitools/generate_msiextract_bundle_values.py \
    --version 0.106.0

  DK_GHCR_AUTHORIZATION='Bearer QQ==' \
    python3 ext/dk/etc/maintenance/msitools/generate_msiextract_bundle_values.py \
    --version 0.106.0

By default writes to:
  ext/dk/etc/dk/v/CommonsBase_Std/Msitools.Msiextract.Bundle.values.jsonc
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from typing import NoReturn


HOMEBREW_FORMULA_URL = "https://formulae.brew.sh/api/formula/msitools.json"
GHCR_BLOBS_BASE = "https://ghcr.io/v2/homebrew/core/msitools/blobs"
DEFAULT_OUT_PATH = (
    Path(__file__).resolve().parent
    / ".."
    / ".."
    / "dk"
    / "v"
    / "CommonsBase_Std"
    / "Msitools.Msiextract.Bundle.values.jsonc"
).resolve()
DEFAULT_OUT = str(DEFAULT_OUT_PATH)

# Platforms we package (macOS only)
PLATFORM_KEYS = [
    "arm64_sonoma",  # macOS arm64
    "sonoma",  # macOS x86_64
]


@dataclass(frozen=True)
class BottleInfo:
    key: str
    url: str
    sha256: str


def _die(msg: str) -> NoReturn:
    print(f"error: {msg}", file=sys.stderr)
    raise SystemExit(2)


def fetch_json(url: str) -> Any:
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        raw = resp.read()
    return json.loads(raw.decode("utf-8"))


_digest_re = re.compile(r"/blobs/sha256:([0-9a-fA-F]{64})$")


def extract_bottles(formula_json: Any) -> dict[str, BottleInfo]:
    if not isinstance(formula_json, dict):
        _die("unexpected Homebrew JSON shape: top-level is not an object")
    bottle = formula_json.get("bottle")
    if not isinstance(bottle, dict):
        _die("unexpected Homebrew JSON shape: bottle is not an object")
    stable = bottle.get("stable")
    if not isinstance(stable, dict):
        _die("unexpected Homebrew JSON shape: bottle.stable is not an object")
    files = stable.get("files")
    if not isinstance(files, dict):
        _die("unexpected Homebrew JSON shape: bottle.stable.files is not an object")

    bottles: dict[str, BottleInfo] = {}
    for key in PLATFORM_KEYS:
        if key not in files:
            _die(f"Homebrew formula JSON missing bottle key: {key}")
        entry = files[key]
        url = entry.get("url")
        sha256 = entry.get("sha256")
        if not isinstance(url, str) or not isinstance(sha256, str):
            _die(f"Homebrew formula JSON has invalid url/sha256 for {key}")

        sha256 = sha256.strip().lower()
        if not re.fullmatch(r"[0-9a-f]{64}", sha256):
            _die(f"invalid sha256 for {key}: {sha256}")

        # Sanity-check that URL ends with the same digest.
        m = _digest_re.search(url)
        if m is None:
            _die(f"unexpected GHCR blob url format for {key}: {url}")
        url_digest = m.group(1).lower()
        if url_digest != sha256:
            _die(
                f"digest mismatch for {key}: url has {url_digest} but sha256 field is {sha256}"
            )

        bottles[key] = BottleInfo(key=key, url=url, sha256=sha256)

    return bottles


def ghcr_blob_size_bytes(*, digest: str, authorization: str, curl: str) -> int:
    # We prefer curl because it reliably supports HEAD with auth and HTTP/2.
    # We do not follow redirects; GHCR responds 200 for blobs with proper auth.
    url = f"{GHCR_BLOBS_BASE}/sha256:{digest}"

    cmd = [curl, "-sSI"]
    if authorization:
        cmd += ["-H", f"Authorization: {authorization}"]
    cmd.append(url)

    proc = subprocess.run(
        cmd,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if proc.returncode != 0:
        _die(f"curl HEAD failed for {url}: {proc.stderr.strip()}")

    # Find the last Content-Length header in case of proxies.
    content_length: str | None = None
    for line in proc.stdout.splitlines():
        if line.lower().startswith("content-length:"):
            content_length = line.split(":", 1)[1].strip()

    if content_length is None or content_length == "":
        _die(f"missing Content-Length for {url}; headers were:\n{proc.stdout}")

    content_length_str: str = content_length

    try:
        size = int(content_length_str)
    except (TypeError, ValueError):
        _die(f"invalid Content-Length '{content_length_str}' for {url}")

    if size <= 0:
        _die(f"unexpected Content-Length {size} for {url}")

    return size


def render_values_jsonc(*, version: str, assets: list[dict[str, Any]]) -> str:
    doc = {
        "$schema": "https://github.com/diskuv/dk/raw/refs/heads/V2_5/etc/jsonschema/dk-values.json",
        "schema_version": {"major": 1, "minor": 0},
        "bundles": [
            {
                "id": f"CommonsBase_Std.Msitools.Msiextract.Bundle@{version}",
                "listing": {
                    "origins": [
                        {
                            "name": "homebrew-ghcr-msitools",
                            "mirrors": [GHCR_BLOBS_BASE],
                        }
                    ]
                },
                "assets": assets,
            }
        ],
    }

    # Keep formatting stable and compatible with jsonc.
    return json.dumps(doc, indent=2, sort_keys=False) + "\n"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--version",
        default="0.106.0",
        help="SemVer version for CommonsBase_Std.Msitools.Msiextract.Bundle@VERSION",
    )
    ap.add_argument(
        "--out",
        default=DEFAULT_OUT,
        help=f"Output file (default: {DEFAULT_OUT})",
    )
    ap.add_argument(
        "--homebrew-url",
        default=HOMEBREW_FORMULA_URL,
        help="Homebrew formula JSON URL",
    )
    ap.add_argument(
        "--curl",
        default=os.environ.get("DK_GHCR_CURL", "/usr/bin/curl"),
        help="curl executable path (default: /usr/bin/curl; override with DK_GHCR_CURL)",
    )
    ap.add_argument(
        "--ghcr-authorization",
        default=os.environ.get("DK_GHCR_AUTHORIZATION", "Bearer QQ=="),
        help="Value for Authorization header (default: env DK_GHCR_AUTHORIZATION or 'Bearer QQ==')",
    )
    args = ap.parse_args()

    # Fetch Homebrew formula metadata.
    formula = fetch_json(args.homebrew_url)
    bottles = extract_bottles(formula)

    # Compute sizes.
    # Asset order: macOS x86_64, macOS arm64
    order = ["sonoma", "arm64_sonoma"]
    assets: list[dict[str, Any]] = []
    for key in order:
        info = bottles[key]
        size = ghcr_blob_size_bytes(
            digest=info.sha256,
            authorization=args.ghcr_authorization,
            curl=args.curl,
        )
        assets.append(
            {
                "origin": "homebrew-ghcr-msitools",
                "path": f"sha256:{info.sha256}",
                "size": size,
                "checksum": {"sha256": info.sha256},
            }
        )

    out_text = render_values_jsonc(version=args.version, assets=assets)

    out_path = args.out
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(out_text)

    print(f"Wrote {out_path}")
    for a in assets:
        print(f"- {a['path']} size={a['size']}")


if __name__ == "__main__":
    main()
