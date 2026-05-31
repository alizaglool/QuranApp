#!/usr/bin/env python3
"""
generate_quran_text.py
Downloads the complete Quran (Uthmani script) from api.alquran.cloud
and writes quran_text.json to QuranApp/Resources/.

Run once:
    python3 generate_quran_text.py
"""

import json
import urllib.request
import os

OUTPUT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                      "QuranApp", "Resources", "quran_text.json")

URL = "https://api.alquran.cloud/v1/quran/quran-uthmani"

print("Downloading full Quran text (one request)...")

req = urllib.request.Request(
    URL,
    headers={"User-Agent": "QuranApp/1.0 (iOS; data-fetch)"}
)

with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read().decode("utf-8"))

result = {}
for surah in data["data"]["surahs"]:
    surah_num = surah["number"]
    for ayah in surah["ayahs"]:
        key = f"{surah_num}_{ayah['numberInSurah']}"
        result[key] = ayah["text"]

with open(OUTPUT, "w", encoding="utf-8") as f:
    json.dump(result, f, ensure_ascii=False, separators=(",", ":"))

print(f"Done! {len(result)} verses written to:\n  {OUTPUT}")
