#!/usr/bin/env python3
"""Build an optimized consumer, verify output, and scan its executable for plaintext.

Extra SwiftPM options may follow -- (for example --scratch-path /tmp/obscured-check).
Exit 1 means plaintext was found or a control failed; build/run failures also fail.
"""
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
PRODUCT = "VAObscuredBinaryCheck"
PROBES = [
    "VAObscured_probe_default_53A7F219",
    "VAObscured_probe_addition_6C82E130",
    "VAObscured_probe_subtraction_794DB520",
    "VAObscured_probe_multiple_8EF06341",
    "VAObscured_probe_multi_add_90AB7425",
    "VAObscured_probe_multi_sub_A1BC8536",
]
CONTROL = "VAObscured_plaintext_control_B2CD9647"


def main():
    extra = sys.argv[1:]
    if extra[:1] == ["--"]:
        extra = extra[1:]
    build = ["swift", "build", "--package-path", str(ROOT), *extra,
             "--configuration", "release", "--product", PRODUCT]
    subprocess.run(["swift", "--version"], check=True)
    subprocess.run(build, check=True)
    directory = subprocess.check_output([*build, "--show-bin-path"], text=True).strip()
    binary = pathlib.Path(directory) / PRODUCT
    output = subprocess.check_output([str(binary)], text=True).splitlines()
    if output != [*PROBES, CONTROL]:
        raise SystemExit("FAIL: optimized executable did not decode the expected probes")
    data = binary.read_bytes()
    if CONTROL.encode() not in data:
        raise SystemExit("FAIL: plaintext positive control was not found; scan is inconclusive")
    found = [probe for probe in PROBES
             if any(probe.encode(encoding) in data for encoding in ("utf-8", "utf-16-le", "utf-16-be"))]
    print(f"Scanned {binary} ({len(data)} bytes); runtime output and positive control verified.")
    if found:
        raise SystemExit("FAIL: plaintext probe(s) found: " + ", ".join(found))
    print("PASS: no complete plaintext probes found as UTF-8 or UTF-16 in this optimized executable.")
    print("This is a check of this build only; embedded keys and runtime decoding remain reversible.")


if __name__ == "__main__":
    main()
