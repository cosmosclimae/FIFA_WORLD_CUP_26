# FIFA 2026 Climate Risk Pipeline

This repository contains the data-processing workflow used to assess climate-related risks for the 2026 FIFA World Cup. The pipeline links match-level information, host-city locations, local kick-off times, and climate indicators to quantify the uneven distribution of environmental exposure across teams, venues, and tournament stages.

The workflow is designed to support an event-based assessment of outdoor sport exposure, where each match is evaluated according to its specific venue, date, and local time. It provides reproducible scripts to extract, process, and summarise climate indicators relevant to football performance, player safety, spectator exposure, and event operations.

## Scientific objective

The objective of this pipeline is to quantify how the 2026 FIFA World Cup schedule interacts with local climate conditions across host cities. Instead of assessing host cities only as static locations, the workflow evaluates exposure at the match level by combining climate data with the tournament calendar.

The pipeline supports analyses such as:

* comparison of climate exposure between host cities;
* identification of high-risk matches and venues;
* assessment of heat, humidity, rainfall, wind, and multi-risk exposure;
* comparison of exposure between teams and groups;
* evaluation of whether kick-off time modifies climate risk;
* production of maps, tables, and figure-ready outputs for scientific publication.

## Input data

The workflow uses gridded climate data and tournament metadata. Required inputs include:

* host-city or stadium coordinates;
* match schedule, including date, venue, teams, group/stage, and local kick-off time;
* climate indicators or meteorological variables extracted from ERA5-Land, ERA5, or processed climate indicator datasets;
* optional event metadata used to classify matches, venues, or teams.

The original raw climate datasets are not redistributed in this repository. Users must obtain them from the relevant data providers.

## Main indicators

The pipeline is designed to process and summarise climate indicators relevant to football and outdoor sport, including:

* Wet-Bulb Globe Temperature (WBGT), used to assess heat stress under outdoor conditions;
* Heat Index or Humidex-type indicators, representing combined heat and humidity exposure;
* heavy rainfall indicators, including daily or antecedent rainfall thresholds;
* wind indicators, where relevant for match conditions and event operations;
* multi-risk indicators combining simultaneous exposure to several hazards.

The exact indicators and thresholds can be adjusted in the configuration files depending on the analysis.

## Workflow

The pipeline is structured around a match-based climate extraction approach:

1. prepare tournament metadata, including teams, venues, dates, and local kick-off times;
2. harmonise host-city or stadium coordinates;
3. extract climate indicators for each match location and time window;
4. compute match-level exposure metrics;
5. aggregate exposure by team, group, venue, tournament stage, and risk category;
6. generate summary tables, maps, and figure-ready outputs.

The workflow is intended to be reproducible and modular, allowing additional indicators, tournaments, or sport-specific thresholds to be added later.

## Repository structure

```text
.
├── config/              # Configuration files, thresholds, and paths
├── metadata/            # Match schedule, host cities, stadium coordinates
├── scripts/             # Processing and analysis scripts
├── workflow/            # Snakemake workflow files, if applicable
├── results/             # Derived match-level and aggregated outputs
 
└── README.md            # Repository documentation
```

## Reproducibility

This repository provides the scripts and workflow required to reproduce the processed match-level indicators, summary tables, and figures used in the associated manuscript. Large input climate files are not included and must be downloaded or generated separately.

Users should update the configuration files to specify:

* local paths to climate input files;
* the tournament schedule file;
* host-city or stadium coordinates;
* selected climate indicators and thresholds;
* output directories.

## Associated manuscript

This pipeline is associated with a manuscript assessing climate-related exposure during the 2026 FIFA World Cup. The repository provides transparency on the event-based data-processing workflow and supports reproducibility of the reported results.

## Citation

If you use or adapt this workflow, please cite the associated manuscript and the archived software release once available.

## License

Code license: MIT License.

Input climate data and tournament metadata are not necessarily redistributed in this repository and remain subject to the terms and conditions of their original providers.
