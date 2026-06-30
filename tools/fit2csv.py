#!/usr/bin/env python3
"""
fit2csv.py — extract FieldMark points from a Garmin FIT file into per-category CSVs.

Each marked point is recorded as a FIT *lap* carrying a developer field "category".
Laps with an empty/absent category (e.g. the trailing partial lap) are ignored.

Usage:
    python3 tools/fit2csv.py ACTIVITY.fit [-o OUTDIR]

Output: one CSV per category, e.g. A.csv, with columns:
    timestamp_utc,latitude,longitude,accuracy_m,altitude_m,notes

Requires: pip install fitparse
"""

import argparse
import csv
import os
import sys
from datetime import timezone, timedelta

try:
    from fitparse import FitFile
except ImportError:
    sys.exit("Missing dependency. Install with: pip install fitparse")

# FIT stores lat/long as "semicircles".
SEMICIRCLE_TO_DEG = 180.0 / (2 ** 31)


def to_deg(semicircles):
    if semicircles is None:
        return None
    return semicircles * SEMICIRCLE_TO_DEG


def iso_utc(dt):
    if dt is None:
        return ""
    # fitparse returns naive UTC datetimes.
    return dt.replace(tzinfo=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def collect_records(fit):
    """Track points as (timestamp, lat_deg, lon_deg, altitude_m), sorted by time."""
    recs = []
    for msg in fit.get_messages("record"):
        d = {f.name: f.value for f in msg}
        ts = d.get("timestamp")
        lat = to_deg(d.get("position_lat"))
        lon = to_deg(d.get("position_long"))
        alt = d.get("enhanced_altitude", d.get("altitude"))
        if ts is not None:
            recs.append((ts, lat, lon, alt))
    recs.sort(key=lambda r: r[0])
    return recs


def nearest_record(recs, ts):
    """Record with timestamp closest to ts (records are already time-sorted)."""
    best = None
    best_dt = None
    for r in recs:
        dt = abs((r[0] - ts).total_seconds())
        if best_dt is None or dt < best_dt:
            best, best_dt = r, dt
    return best


def main():
    ap = argparse.ArgumentParser(description="Extract FieldMark points from a FIT file.")
    ap.add_argument("fitfile", help="path to the .fit file")
    ap.add_argument("-o", "--outdir", default=".", help="output directory (default: current)")
    args = ap.parse_args()

    fit = FitFile(args.fitfile)
    records = collect_records(fit)

    # category -> list of rows
    by_cat = {}
    for lap in fit.get_messages("lap"):
        d = {f.name: f.value for f in lap}
        category = d.get("category")
        if category is None or str(category).strip() == "":
            continue  # skip empty/trailing laps

        # The lap's own `timestamp` is unreliable (the device writes the same value for
        # every lap). The point (button press) happened at the lap END, which equals
        # start_time + total_elapsed_time — and that matches end_position (the press spot).
        start_time = d.get("start_time")
        elapsed = d.get("total_elapsed_time")
        if start_time is not None and elapsed is not None:
            ts = start_time + timedelta(seconds=elapsed)
        else:
            ts = d.get("timestamp")

        lat = to_deg(d.get("end_position_lat"))
        lon = to_deg(d.get("end_position_long"))
        alt = d.get("enhanced_altitude", d.get("altitude"))

        # Fill any missing position/altitude from the nearest track record.
        if ts is not None and records and (lat is None or lon is None or alt is None):
            r = nearest_record(records, ts)
            if r:
                lat = lat if lat is not None else r[1]
                lon = lon if lon is not None else r[2]
                alt = alt if alt is not None else r[3]

        by_cat.setdefault(str(category).strip(), []).append({
            "timestamp_utc": iso_utc(ts),
            "latitude": f"{lat:.6f}" if lat is not None else "",
            "longitude": f"{lon:.6f}" if lon is not None else "",
            "accuracy_m": "",  # not available from FIT
            "altitude_m": f"{alt:.1f}" if alt is not None else "",
            "notes": "",
        })

    if not by_cat:
        print("No categorized points found in this FIT file.")
        return

    os.makedirs(args.outdir, exist_ok=True)
    fields = ["timestamp_utc", "latitude", "longitude", "accuracy_m", "altitude_m", "notes"]
    for category, rows in by_cat.items():
        path = os.path.join(args.outdir, f"{category}.csv")
        with open(path, "w", newline="") as fh:
            w = csv.DictWriter(fh, fieldnames=fields)
            w.writeheader()
            w.writerows(rows)
        print(f"{path}: {len(rows)} point(s)")


if __name__ == "__main__":
    main()
