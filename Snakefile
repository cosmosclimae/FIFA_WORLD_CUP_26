shell.executable("/bin/bash")
from pathlib import Path
VENV_ACTIVATE = str(config.get("venv_activate", "~/venv_cds/bin/activate"))
STADIUMS = {
    "bc_place": {
        "lat": 49.276667,
        "lon": -123.111944,
    },
    "arrowhead_stadium": {
        "lat": 39.048889,
        "lon": -94.483889,
    },
    "bmo_field": {
        "lat": 43.632778,
        "lon": -79.418611,
    },
    "gillette_stadium": {
        "lat": 42.091111,
        "lon": -71.264444,
    },
    "metlife_stadium": {
        "lat": 40.813611,
        "lon": -74.074444,
    },
    "lincoln_financial_field": {
        "lat": 39.900833,
        "lon": -75.167500,
    },
    "lumen_field": {
        "lat": 47.595278,
        "lon": -122.331667,
    },
    "levis_stadium": {
        "lat": 37.403056,
        "lon": -121.970000,
    },
    "mercedes_benz_stadium": {
        "lat": 33.755000,
        "lon": -84.401111,
    },
    "hard_rock_stadium": {
        "lat": 25.958056,
        "lon": -80.238889,
    },
    "sofi_stadium": {
        "lat": 33.953333,
        "lon": -118.339167,
    },
    "estadio_akron": {
        "lat": 20.681667,
        "lon": -103.462778,
    },
    "bbva_stadium": {
        "lat": 25.670278,
        "lon": -100.243611,
    },
    "estadio_azteca": {
        "lat": 19.302778,
        "lon": -99.150556,
    },
    "att_stadium": {
        "lat": 32.747778,
        "lon": -97.092778,
    },
    "nrg_stadium": {
        "lat": 29.684722,
        "lon": -95.410833,
    },
}

TIMEZONES = {
    "bc_place": "America/Vancouver",
    "arrowhead_stadium": "America/Chicago",
    "bmo_field": "America/Toronto",
    "gillette_stadium": "America/New_York",
    "metlife_stadium": "America/New_York",
    "lincoln_financial_field": "America/New_York",
    "lumen_field": "America/Los_Angeles",
    "levis_stadium": "America/Los_Angeles",
    "mercedes_benz_stadium": "America/New_York",
    "hard_rock_stadium": "America/New_York",
    "sofi_stadium": "America/Los_Angeles",
    "estadio_akron": "America/Mexico_City",
    "bbva_stadium": "America/Monterrey",
    "estadio_azteca": "America/Mexico_City",
    "att_stadium": "America/Chicago",
    "nrg_stadium": "America/Chicago",
}

START_DATE = "1996-01-01"
END_DATE = "2025-12-31"

RAW_ERA5LAND_DIR = Path("/mnt/f/climae/FIFA26/raw/era5land_timeseries")
RAW_ERA5_DIR = Path("/mnt/f/climae/FIFA26/raw/era5_timeseries")
HOURLY_MASTER_DIR = Path("/mnt/f/climae/FIFA26/processed/hourly_master")
SCRIPT_ERA5LAND = Path(workflow.basedir) / "scripts" / "download_era5land_fifa_month.py"
SCRIPT_ERA5 = Path(workflow.basedir) / "scripts" / "download_era5_fifa_month.py"
SCRIPT_HOURLY_MASTER = Path(workflow.basedir) / "scripts" / "build_hourly_master.R"

rule all:
    input:
        expand(str(RAW_ERA5LAND_DIR / "{stadium}.csv"), stadium=STADIUMS.keys()),
        expand(str(RAW_ERA5_DIR / "{stadium}.csv"), stadium=STADIUMS.keys()),
        expand(str(HOURLY_MASTER_DIR / "{stadium}.csv"), stadium=STADIUMS.keys()),

rule download_era5land_timeseries:
    output:
        str(RAW_ERA5LAND_DIR / "{stadium}.csv")
    params:
        lat=lambda wc: STADIUMS[wc.stadium]["lat"],
        lon=lambda wc: STADIUMS[wc.stadium]["lon"],
        start=START_DATE,
        end=END_DATE,
    log:
        "logs/era5land/{stadium}.log"
    shell:
        r"""
        set -euo pipefail           
        mkdir -p {RAW_ERA5LAND_DIR} logs/era5land
            source {VENV_ACTIVATE} && \
            python '{SCRIPT_ERA5LAND}' \
                --stadium {wildcards.stadium} \
                --lat {params.lat} \
                --lon {params.lon} \
                --start-date {params.start} \
                --end-date {params.end} \
                --output {output} \
                > {log} 2>&1
        """

rule download_era5_gust_timeseries:
    output:
        str(RAW_ERA5_DIR / "{stadium}.csv")
    params:
        lat=lambda wc: STADIUMS[wc.stadium]["lat"],
        lon=lambda wc: STADIUMS[wc.stadium]["lon"],
        start=START_DATE,
        end=END_DATE,
    log:
        "logs/era5/{stadium}.log"
    shell:
        r"""
        set -euo pipefail           
        mkdir -p {RAW_ERA5LAND_DIR} logs/era5land
            mkdir -p {RAW_ERA5_DIR} logs/era5
            source {VENV_ACTIVATE} && \
            python '{SCRIPT_ERA5}' \
                --stadium {wildcards.stadium} \
                --lat {params.lat} \
                --lon {params.lon} \
                --start-date {params.start} \
                --end-date {params.end} \
                --output {output} \
                > {log} 2>&1
            """

rule build_hourly_master:
    input:
        land=str(RAW_ERA5LAND_DIR / "{stadium}.csv"),
        gust=str(RAW_ERA5_DIR / "{stadium}.csv"),
    output:
        str(HOURLY_MASTER_DIR / "{stadium}.csv")
    params:
        timezone=lambda wc: TIMEZONES[wc.stadium],
    log:
        "logs/hourly_master/{stadium}.log"
    shell:
        r"""
        set -euo pipefail
        mkdir -p {HOURLY_MASTER_DIR} logs/hourly_master
        Rscript {SCRIPT_HOURLY_MASTER} \
            {wildcards.stadium} \
            {params.timezone} \
            {input.land} \
            {input.gust} \
            {output} \
            > {log} 2>&1
        """