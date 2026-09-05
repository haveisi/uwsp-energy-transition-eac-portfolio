# Assumptions and Limitations

This repository is an independent analytical portfolio case study.

It is not an official UWSP energy, financial, climate, or REC accounting system.

## Data Limitations

- Actual annual campus electricity load was not independently verified from a complete public source.
- Onsite solar REC ownership was not confirmed from certificate-level evidence.
- Historical public EAC evidence did not include all registry-level fields required for independent assurance.
- A defensible public commodity REC price was not available for use in cost modeling.
- Solar annual generation was annualized from verified lifetime generation rather than taken from a complete annual production dataset.

## Emissions Limitations

- The WPS emissions factor is used for analytical modeling.
- It should not automatically be interpreted as the formal market-based Scope 2 factor for institutional reporting.
- Reported and modeled GHG reductions differ because the underlying boundaries and methods may not be identical.

## Financial Assumptions

- LOW, BASE, and HIGH financial scenarios are analyst-defined.
- Discount rates, analysis horizon, and energy-price escalation assumptions are not presented as UWSP financing terms.
- NPV results are intended for sensitivity analysis, not as an official investment recommendation.

## EAC Assurance Interpretation

Statuses such as:

- `INSUFFICIENT_EVIDENCE`
- `OWNERSHIP_EVIDENCE_REQUIRED`
- `COMMODITY_PRICE_EVIDENCE_REQUIRED`

describe the evidence currently assembled in this project.

They do not prove that UWSP lacked valid certificates, ownership records, or procurement documentation.

## Purpose of the Analysis

The purpose is to demonstrate an end-to-end decision-support workflow combining:

- source evidence
- data governance
- Databricks medallion architecture
- QA/QC
- EAC assurance
- emissions analysis
- financial scenario modeling
- Power BI executive reporting