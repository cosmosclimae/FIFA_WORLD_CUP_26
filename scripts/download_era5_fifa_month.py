import argparse
from pathlib import Path
import shutil
import zipfile

import cdsapi
import pandas as pd

VARS_ERA5 = [
    "10m_wind_gust_since_previous_post_processing",
    "convective_available_potential_energy",
    "convective_precipitation",
]


def merge_csvs_from_zip(zip_path: Path, final_csv: Path) -> None:
    tmp_dir = final_csv.parent / f".tmp_{final_csv.stem}"
    tmp_dir.mkdir(parents=True, exist_ok=True)

    extracted_files = []
    with zipfile.ZipFile(zip_path, "r") as zf:
        members = zf.namelist()
        csv_members = [m for m in members if m.lower().endswith(".csv")]
        if not csv_members:
            raise RuntimeError(
                f"No CSV found inside ZIP archive: {zip_path}\nMembers: {members}"
            )

        for member in csv_members:
            target = tmp_dir / Path(member).name
            with zf.open(member) as src, open(target, "wb") as dst:
                shutil.copyfileobj(src, dst)
            extracted_files.append(target)

    dfs = []
    for f in extracted_files:
        df = pd.read_csv(f)
        dfs.append(df)

    merged = dfs[0]
    for df in dfs[1:]:
        common = [c for c in merged.columns if c in df.columns]
        preferred_keys = [
            c for c in ["date", "time", "valid_time", "latitude", "longitude"] if c in common
        ]
        keys = preferred_keys if preferred_keys else common
        merged = merged.merge(df, on=keys, how="outer")

    merged.to_csv(final_csv, index=False)

    shutil.rmtree(tmp_dir)
    zip_path.unlink()


def main() -> None:
    ap = argparse.ArgumentParser(
        description="Download ERA5 single-levels timeseries for one stadium point."
    )
    ap.add_argument("--stadium", required=True)
    ap.add_argument("--lat", required=True, type=float)
    ap.add_argument("--lon", required=True, type=float)
    ap.add_argument("--start-date", required=True)
    ap.add_argument("--end-date", required=True)
    ap.add_argument("--output", required=True)
    args = ap.parse_args()

    final_out = Path(args.output)
    final_out.parent.mkdir(parents=True, exist_ok=True)
    tmp_out = final_out.with_suffix(".zip")

    dataset = "reanalysis-era5-single-levels-timeseries"
    request = {
        "variable": VARS_ERA5,
        "location": {
            "longitude": args.lon,
            "latitude": args.lat,
        },
        "date": [f"{args.start_date}/{args.end_date}"],
        "data_format": "csv",
    }

    print(
        f"[CDS] ERA5 single-levels | stadium={args.stadium} "
        f"| lat={args.lat} lon={args.lon} "
        f"| {args.start_date} -> {args.end_date} "
        f"| output={final_out}"
    )

    client = cdsapi.Client()
    client.retrieve(dataset, request).download(str(tmp_out))

    if zipfile.is_zipfile(tmp_out):
        merge_csvs_from_zip(tmp_out, final_out)
    else:
        tmp_out.rename(final_out)


if __name__ == "__main__":
    main()