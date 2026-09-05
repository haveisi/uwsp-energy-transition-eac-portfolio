-- Databricks notebook source
# 02 — Bronze Ingestion

## Purpose

Create the raw evidence layer for the UWSP Energy Transition & EAC Portfolio.

The Bronze layer preserves source information as reported and records:

- source provenance
- evidence type
- data ownership
- collection status
- validation status
- source reliability
- ingestion timestamp

No conflicting values are deleted or silently overwritten at this stage.

## Principle

Raw evidence first → validation second → calculations third.

This allows every downstream Scope 2, EAC, solar, efficiency, financial, and transition-risk result to be traced back to its source.

-- COMMAND ----------

USE CATALOG uwsp_energy_transition_eac;
USE SCHEMA bronze;

-- COMMAND ----------

SELECT
    current_catalog(),
    current_schema();

-- COMMAND ----------

CREATE OR REPLACE TABLE source_evidence_registry (

    source_id STRING,

    source_category STRING,

    source_name STRING,

    organization STRING,

    source_url STRING,

    evidence_type STRING,

    data_domain STRING,

    reporting_year INT,

    source_status STRING,

    reliability_tier STRING,

    validation_status STRING,

    notes STRING,

    ingestion_timestamp TIMESTAMP

)
USING DELTA;

-- COMMAND ----------

INSERT INTO source_evidence_registry
VALUES

(
    'SRC_SOLAR_001',
    'SOLAR_MONITORING',
    'UWSP AlsoEnergy Solar Portal 1',
    'University of Wisconsin-Stevens Point',
    'https://pubdisplay.alsoenergy.com/kiosk/18014398509546623?dashkey=2a5669734b65472f4443413d3d&tag=8626480',
    'LIVE_MONITORING_PORTAL',
    'SOLAR',
    NULL,
    'ACTIVE',
    'TIER_1_PRIMARY',
    'TO_VALIDATE',
    'Public solar monitoring portal. Generation and system characteristics should be captured from the monitoring data.',
    current_timestamp()
),

(
    'SRC_SOLAR_002',
    'SOLAR_MONITORING',
    'UWSP AlsoEnergy Solar Portal 2',
    'University of Wisconsin-Stevens Point',
    'https://pubdisplay.alsoenergy.com/kiosk/18014398509546622?dashkey=2a5669734b65472f4443513d3d&tag=8626479',
    'LIVE_MONITORING_PORTAL',
    'SOLAR',
    NULL,
    'ACTIVE',
    'TIER_1_PRIMARY',
    'TO_VALIDATE',
    'Public solar monitoring portal. Generation and system characteristics should be captured from the monitoring data.',
    current_timestamp()
),

(
    'SRC_SOLAR_003',
    'SOLAR_MONITORING',
    'UWSP SolarEdge Solar Portal',
    'University of Wisconsin-Stevens Point',
    'https://monitoring.solaredge.com/mfe/flutter/kiosk/index.html?guid=732bfe9b-f1ac-4286-a25c-6211be56d97e',
    'LIVE_MONITORING_PORTAL',
    'SOLAR',
    NULL,
    'ACTIVE',
    'TIER_1_PRIMARY',
    'TO_VALIDATE',
    'Public SolarEdge monitoring portal. Generation and system characteristics should be captured from monitoring data.',
    current_timestamp()
);

-- COMMAND ----------

INSERT INTO source_evidence_registry
VALUES

(
    'SRC_EE_001',
    'ENERGY_EFFICIENCY',
    'UWSP Sustainability Highlights 2026',
    'University of Wisconsin-Stevens Point',
    'https://www.uwsp.edu/news/article/sustainability-highlights-2026/',
    'PUBLIC_INSTITUTIONAL_REPORT',
    'ENERGY_EFFICIENCY',
    2026,
    'ACTIVE',
    'TIER_2_REPORTED',
    'TO_VALIDATE',
    'Documents UWSP energy-efficiency initiatives, Focus on Energy recognition, building improvements, and renewable-energy developments.',
    current_timestamp()
);

-- COMMAND ----------

INSERT INTO source_evidence_registry
VALUES

(
    'SRC_EAC_001',
    'ENVIRONMENTAL_ATTRIBUTE_CERTIFICATE',
    'UWSP Goes 100 Percent Renewable',
    'Wisconsin Academy',
    'https://www.wisconsinacademy.org/magazine/summer-2016/happenings/uwsp-goes-100-renewable',
    'PUBLIC_SECONDARY_REPORT',
    'EAC',
    2016,
    'HISTORICAL',
    'TIER_3_SECONDARY',
    'TO_VALIDATE',
    'Historical article reports UWSP renewable electricity strategy and expenditures for environmental attributes. Certificate volume, registry, vintage and retirement evidence are not available from this source alone.',
    current_timestamp()
);

-- COMMAND ----------

INSERT INTO source_evidence_registry
VALUES

(
    'SRC_GRID_001',
    'UTILITY_EMISSIONS',
    'WPS Greenhouse Gas Emission Rates',
    'Wisconsin Public Service',
    'https://www.wisconsinpublicservice.com/company/epa-greenhouse',
    'UTILITY_PUBLISHED_DATA',
    'SCOPE_2',
    2025,
    'ACTIVE',
    'TIER_1_PRIMARY',
    'TO_VALIDATE',
    'Utility-published electricity emission factors. Factor selection must later distinguish location-based versus market-based Scope 2 accounting requirements.',
    current_timestamp()
);

-- COMMAND ----------

SELECT
    source_id,
    source_category,
    source_name,
    data_domain,
    reporting_year,
    reliability_tier,
    validation_status

FROM source_evidence_registry

ORDER BY source_id;

-- COMMAND ----------

SELECT

    data_domain,

    COUNT(*) AS source_count,

    SUM(
        CASE
            WHEN validation_status = 'TO_VALIDATE'
            THEN 1
            ELSE 0
        END
    ) AS sources_requiring_validation

FROM source_evidence_registry

GROUP BY data_domain

ORDER BY data_domain;

-- COMMAND ----------

SELECT
    current_catalog(),
    current_schema();

-- COMMAND ----------

CREATE OR REPLACE TABLE solar_generation_raw (

    solar_record_id STRING,

    source_id STRING,

    site_name STRING,

    reporting_date DATE,

    reporting_year INT,

    reporting_month INT,

    installed_capacity_kw DOUBLE,

    generation_mwh DOUBLE,

    monitoring_platform STRING,

    rec_ownership_status STRING,

    evidence_status STRING,

    notes STRING,

    ingestion_timestamp TIMESTAMP

)
USING DELTA;

-- COMMAND ----------

SHOW TABLES IN uwsp_energy_transition_eac.bronze;

-- COMMAND ----------

DESCRIBE TABLE solar_generation_raw;

-- COMMAND ----------

INSERT INTO uwsp_energy_transition_eac.bronze.solar_generation_raw
VALUES
(
    'SOLAR_REC_001',
    'SRC_SOLAR_001',
    'UWSP Solar Site - AlsoEnergy 1',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    'AlsoEnergy',
    'VERIFY',
    'SOURCE_REGISTERED',
    'Public UWSP solar monitoring source registered. Generation, capacity, and REC ownership have not yet been validated.',
    current_timestamp()
);

-- COMMAND ----------

SELECT *
FROM uwsp_energy_transition_eac.bronze.solar_generation_raw;

-- COMMAND ----------

SELECT
    solar_record_id,
    source_id,
    site_name,
    installed_capacity_kw,
    generation_mwh,
    rec_ownership_status,
    evidence_status,
    notes
FROM uwsp_energy_transition_eac.bronze.solar_generation_raw
WHERE source_id = 'SRC_SOLAR_001';

-- COMMAND ----------

UPDATE uwsp_energy_transition_eac.bronze.solar_generation_raw

SET

    site_name = 'Collins Classroom Center (CCC) Solar',

    installed_capacity_kw = 50,

    monitoring_platform = 'AlsoEnergy',

    rec_ownership_status = 'VERIFY',

    evidence_status = 'PORTAL_VERIFIED',

    notes = 'Primary AlsoEnergy monitoring portal verified. System size = 50 kW. Generating since July 19, 2023. Lifetime production displayed = 195.22 MWh. Instantaneous production displayed = 1.7 kW. Portal last updated May 19, 2026 at 9:32 AM. Lifetime production is not entered into generation_mwh because it is cumulative rather than a defined reporting-period value. REC ownership remains unverified.'

WHERE solar_record_id = 'SOLAR_REC_001';

-- COMMAND ----------

SELECT
    solar_record_id,
    source_id,
    site_name,
    installed_capacity_kw,
    generation_mwh,
    monitoring_platform,
    rec_ownership_status,
    evidence_status,
    notes
FROM uwsp_energy_transition_eac.bronze.solar_generation_raw
WHERE solar_record_id = 'SOLAR_REC_001';

-- COMMAND ----------

ALTER TABLE uwsp_energy_transition_eac.bronze.solar_generation_raw
ADD COLUMNS (
    lifetime_generation_mwh DOUBLE,
    generation_start_date DATE,
    source_last_updated TIMESTAMP
);

-- COMMAND ----------

DESCRIBE TABLE uwsp_energy_transition_eac.bronze.solar_generation_raw;

-- COMMAND ----------

UPDATE uwsp_energy_transition_eac.bronze.solar_generation_raw

SET
    lifetime_generation_mwh = 195.22,
    generation_start_date = DATE('2023-07-19'),
    source_last_updated = TIMESTAMP('2026-05-19 09:32:00')

WHERE solar_record_id = 'SOLAR_REC_001';

-- COMMAND ----------

SELECT
    solar_record_id,
    site_name,
    installed_capacity_kw,
    lifetime_generation_mwh,
    generation_start_date,
    source_last_updated,
    generation_mwh,
    rec_ownership_status,
    evidence_status

FROM uwsp_energy_transition_eac.bronze.solar_generation_raw

WHERE solar_record_id = 'SOLAR_REC_001';

-- COMMAND ----------

SELECT
    solar_record_id,
    site_name,
    installed_capacity_kw,
    lifetime_generation_mwh,
    generation_start_date,
    source_last_updated,

    ROUND(
        lifetime_generation_mwh
        /
        (
            installed_capacity_kw
            * 24
            * DATEDIFF(source_last_updated, generation_start_date)
            / 1000
        ),
        4
    ) AS lifetime_capacity_factor

FROM uwsp_energy_transition_eac.bronze.solar_generation_raw

WHERE solar_record_id = 'SOLAR_REC_001';

-- COMMAND ----------

SELECT
    solar_record_id,
    site_name,

    ROUND(
        lifetime_generation_mwh
        /
        (
            installed_capacity_kw
            * 24
            * DATEDIFF(source_last_updated, generation_start_date)
            / 1000
        ),
        4
    ) AS lifetime_capacity_factor,

    CASE
        WHEN
            lifetime_generation_mwh
            /
            (
                installed_capacity_kw
                * 24
                * DATEDIFF(source_last_updated, generation_start_date)
                / 1000
            )
            BETWEEN 0.10 AND 0.25
        THEN 'PLAUSIBLE'

        ELSE 'REVIEW_REQUIRED'
    END AS performance_qa_status

FROM uwsp_energy_transition_eac.bronze.solar_generation_raw

WHERE solar_record_id = 'SOLAR_REC_001';

-- COMMAND ----------

USE CATALOG uwsp_energy_transition_eac;
USE SCHEMA bronze;

-- COMMAND ----------

SELECT
    current_catalog(),
    current_schema();

-- COMMAND ----------

CREATE OR REPLACE TABLE eac_transactions_raw (

    transaction_id STRING,

    source_id STRING,

    reporting_year INT,

    certificate_type STRING,

    registry_name STRING,

    certificate_id STRING,

    generation_source STRING,

    generation_location STRING,

    generation_vintage_year INT,

    certificate_mwh DOUBLE,

    unit_price_usd_per_mwh DOUBLE,

    total_cost_usd DOUBLE,

    purchase_date DATE,

    retirement_date DATE,

    retirement_status STRING,

    beneficiary STRING,

    ownership_status STRING,

    evidence_status STRING,

    source_document STRING,

    notes STRING,

    ingestion_timestamp TIMESTAMP

)
USING DELTA;

-- COMMAND ----------

DESCRIBE TABLE
uwsp_energy_transition_eac.bronze.eac_transactions_raw;

-- COMMAND ----------

INSERT INTO uwsp_energy_transition_eac.bronze.eac_transactions_raw
VALUES
(
    'EAC_HIST_2016_001',
    'SRC_EAC_001',
    2016,
    'REC / Renewable Environmental Attribute',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    136400,
    NULL,
    NULL,
    'VERIFY',
    'University of Wisconsin-Stevens Point',
    'VERIFY',
    'AGGREGATE_PUBLIC_EVIDENCE',
    'Wisconsin Academy public article',
    'Public source reports approximately $136,400 spent on environmental attributes in connection with UWSP renewable electricity strategy. Certificate volume, registry, vintage, certificate IDs, unit price, ownership chain, and retirement evidence are not available from this source alone.',
    current_timestamp()
);

-- COMMAND ----------

SELECT
    transaction_id,
    reporting_year,
    certificate_type,
    certificate_mwh,
    unit_price_usd_per_mwh,
    total_cost_usd,
    retirement_status,
    ownership_status,
    evidence_status,
    source_document

FROM uwsp_energy_transition_eac.bronze.eac_transactions_raw;

-- COMMAND ----------

SELECT
    transaction_id,
    reporting_year,
    total_cost_usd,
    certificate_mwh,
    unit_price_usd_per_mwh,
    retirement_status,
    ownership_status,
    evidence_status,

    CASE
        WHEN total_cost_usd IS NOT NULL
             AND certificate_mwh IS NULL
        THEN 'VOLUME_MISSING'

        WHEN retirement_status = 'VERIFY'
        THEN 'RETIREMENT_UNVERIFIED'

        WHEN ownership_status = 'VERIFY'
        THEN 'OWNERSHIP_UNVERIFIED'

        ELSE 'OK'
    END AS primary_data_gap

FROM uwsp_energy_transition_eac.bronze.eac_transactions_raw;

-- COMMAND ----------

USE CATALOG uwsp_energy_transition_eac;
USE SCHEMA bronze;

-- COMMAND ----------

CREATE OR REPLACE TABLE electricity_load_raw (

    load_record_id STRING,

    source_id STRING,

    facility_name STRING,

    reporting_year INT,

    reporting_month INT,

    electricity_mwh DOUBLE,

    electricity_cost_usd DOUBLE,

    utility_provider STRING,

    meter_id STRING,

    evidence_status STRING,

    notes STRING,

    ingestion_timestamp TIMESTAMP

)
USING DELTA;

-- COMMAND ----------

DESCRIBE TABLE
uwsp_energy_transition_eac.bronze.electricity_load_raw;

-- COMMAND ----------

INSERT INTO uwsp_energy_transition_eac.bronze.source_evidence_registry
VALUES

(
    'SRC_LOAD_001',
    'ELECTRICITY_LOAD',
    'UWSP Climate Commitment',
    'University of Wisconsin-Stevens Point',
    'https://www.uwsp.edu/sustainability/climate-commitment/',
    'PUBLIC_INSTITUTIONAL_REPORT',
    'ELECTRICITY_LOAD',
    2026,
    'ACTIVE',
    'TIER_2_REPORTED',
    'TO_VALIDATE',
    'UWSP reports 100 percent renewable electricity purchased and states that since 2016 it has purchased Green-e certified RECs to address purchased-electricity Scope 2 emissions. This source does not provide annual campus electricity MWh and therefore cannot yet populate electricity_load_raw.',
    current_timestamp()
),

(
    'SRC_EE_002',
    'ENERGY_EFFICIENCY',
    'UWSP Facility Services Energy Conservation',
    'University of Wisconsin-Stevens Point',
    'https://www3.uwsp.edu/facsv/Pages/EnergyConservation.aspx',
    'PUBLIC_INSTITUTIONAL_REPORT',
    'ENERGY_EFFICIENCY',
    NULL,
    'ACTIVE',
    'TIER_2_REPORTED',
    'TO_VALIDATE',
    'UWSP Facility Services reports projected annual electricity reduction of 4,229,377 kWh from identified energy conservation measures. This is an efficiency-savings quantity, not total campus electricity consumption.',
    current_timestamp()
);

-- COMMAND ----------

SELECT
    source_id,
    source_name,
    data_domain,
    reporting_year,
    reliability_tier,
    validation_status

FROM uwsp_energy_transition_eac.bronze.source_evidence_registry

WHERE source_id IN ('SRC_LOAD_001', 'SRC_EE_002');

-- COMMAND ----------

INSERT INTO uwsp_energy_transition_eac.bronze.source_evidence_registry
VALUES

(
    'SRC_CLIMATE_PLAN_001',
    'CLIMATE_GOVERNANCE',
    'UWSP NR 441 Climate Action Planning Presentation',
    'University of Wisconsin-Stevens Point / Wisconsin Office of Sustainability and Clean Energy',
    NULL,
    'INTERNAL_PRESENTATION',
    'CLIMATE_GOVERNANCE',
    2025,
    'ARCHIVED_REFERENCE',
    'TIER_2_REPORTED',
    'VALIDATED',
    'Presentation describes Wisconsin climate-action planning, UWSP climate commitments, GHG analysis approaches, measure development requirements, implementation metrics, cost considerations, and risk planning.',
    current_timestamp()
),

(
    'SRC_RESILIENCE_001',
    'RESILIENCE_GOVERNANCE',
    'Second Nature Resilience Commitment - UWSP',
    'Second Nature / University of Wisconsin-Stevens Point',
    NULL,
    'SIGNED_COMMITMENT',
    'RESILIENCE',
    2023,
    'ACTIVE',
    'TIER_1_PRIMARY',
    'VALIDATED',
    'Signed institutional commitment requiring resilience governance, campus-community assessment, indicators, milestones, annual evaluation, public reporting, and periodic plan revision.',
    current_timestamp()
);

-- COMMAND ----------

SELECT
    source_id,
    source_name,
    data_domain,
    reporting_year,
    reliability_tier,
    validation_status

FROM uwsp_energy_transition_eac.bronze.source_evidence_registry

WHERE source_id IN (
    'SRC_CLIMATE_PLAN_001',
    'SRC_RESILIENCE_001'
);

-- COMMAND ----------

USE CATALOG uwsp_energy_transition_eac;
USE SCHEMA bronze;

-- COMMAND ----------

CREATE OR REPLACE TABLE climate_action_measures_raw (

    measure_id STRING,

    source_id STRING,

    measure_name STRING,

    measure_category STRING,

    facility_or_scope STRING,

    implementation_status STRING,

    implementation_year INT,

    annual_energy_reduction_mwh DOUBLE,

    annual_ghg_reduction_tco2e DOUBLE,

    capex_usd DOUBLE,

    annual_cost_savings_usd DOUBLE,

    incentive_or_funding_usd DOUBLE,

    funding_source STRING,

    implementing_entity STRING,

    implementation_milestone STRING,

    tracking_metric STRING,

    geographic_scope STRING,

    evidence_status STRING,

    notes STRING,

    ingestion_timestamp TIMESTAMP

)
USING DELTA;

-- COMMAND ----------

DESCRIBE TABLE
uwsp_energy_transition_eac.bronze.climate_action_measures_raw;

-- COMMAND ----------

INSERT INTO uwsp_energy_transition_eac.bronze.climate_action_measures_raw
VALUES
(
    'MEASURE_EE_001',
    'SRC_EE_001',
    'Residence Hall Lighting Upgrades',
    'ENERGY_EFFICIENCY',
    'Multiple UWSP Residence Halls',
    'IMPLEMENTED',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    'Focus on Energy',
    'UWSP Facilities / Focus on Energy',
    'Lighting upgrades across residence halls',
    'Annual electricity reduction (MWh)',
    'UWSP Campus',
    'PUBLIC_REPORTED_PROJECT',
    'UWSP public reporting describes lighting upgrades across residence halls with Focus on Energy support. Detailed project-level energy savings, CAPEX, incentives, and annual cost savings are not available from the current source and remain unpopulated.',
    current_timestamp()
);

-- COMMAND ----------

SELECT
    measure_id,
    measure_name,
    measure_category,
    implementation_status,
    annual_energy_reduction_mwh,
    capex_usd,
    annual_cost_savings_usd,
    funding_source,
    evidence_status

FROM uwsp_energy_transition_eac.bronze.climate_action_measures_raw

WHERE measure_id = 'MEASURE_EE_001';

-- COMMAND ----------

INSERT INTO uwsp_energy_transition_eac.bronze.climate_action_measures_raw
VALUES
(
    'MEASURE_EE_002',
    'SRC_EE_002',
    'UWSP Energy Conservation Program - Projected Electricity Reduction',
    'ENERGY_EFFICIENCY',
    'UWSP Campus',
    'PUBLIC_REPORTED',
    NULL,
    4229.377,
    NULL,
    NULL,
    NULL,
    NULL,
    'UWSP Facility Services / Energy Conservation Program',
    'UWSP Facilities',
    'Implement identified campus energy conservation measures',
    'Annual electricity reduction (MWh)',
    'UWSP Campus',
    'PUBLIC_REPORTED_QUANTIFIED',
    'UWSP Facility Services reports projected annual electricity reduction of 4,229,377 kWh, equivalent to 4,229.377 MWh/year. This is a program-level projected savings value and should not be interpreted as measured realized savings without additional evidence.',
    current_timestamp()
);

-- COMMAND ----------

SELECT
    measure_id,
    measure_name,
    measure_category,
    annual_energy_reduction_mwh,
    evidence_status,
    notes

FROM uwsp_energy_transition_eac.bronze.climate_action_measures_raw

WHERE measure_id = 'MEASURE_EE_002';

-- COMMAND ----------

USE CATALOG uwsp_energy_transition_eac;
USE SCHEMA bronze;

-- COMMAND ----------

CREATE OR REPLACE TABLE electricity_emission_factors_raw (

    factor_id STRING,

    source_id STRING,

    reporting_year INT,

    utility_provider STRING,

    factor_type STRING,

    factor_value DOUBLE,

    factor_unit STRING,

    factor_tco2e_per_mwh DOUBLE,

    evidence_status STRING,

    notes STRING,

    ingestion_timestamp TIMESTAMP

)
USING DELTA;

-- COMMAND ----------

INSERT INTO electricity_emission_factors_raw
VALUES
(
    'EF_WPS_2025_001',
    'SRC_GRID_001',
    2025,
    'Wisconsin Public Service',
    'CUSTOMER_LOAD_CO2E',
    1243,
    'lb CO2e/MWh',
    1243 * 0.45359237 / 1000,
    'UTILITY_PUBLISHED',
    'WPS published customer-load CO2e emission rate. Used as a training/reference factor for electricity-related emissions analysis. Formal Scope 2 market-based accounting may require a different factor hierarchy.',
    current_timestamp()
);

-- COMMAND ----------

SELECT
    factor_id,
    reporting_year,
    utility_provider,
    factor_value,
    factor_unit,
    ROUND(factor_tco2e_per_mwh, 4) AS factor_tco2e_per_mwh,
    evidence_status

FROM uwsp_energy_transition_eac.bronze.electricity_emission_factors_raw;

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.bronze.eac_price_assumptions_raw (

    assumption_id STRING,
    scenario_name STRING,
    certificate_type STRING,
    geography STRING,
    vintage_year INT,
    unit_price_usd_per_mwh DOUBLE,
    source_type STRING,
    evidence_status STRING,
    notes STRING,
    ingestion_timestamp TIMESTAMP

)
USING DELTA;

-- COMMAND ----------

USE CATALOG uwsp_energy_transition_eac;
USE SCHEMA bronze;

CREATE OR REPLACE TABLE financial_assumptions_raw (

    assumption_id STRING,

    scenario_name STRING,

    discount_rate DOUBLE,

    analysis_horizon_years INT,

    energy_price_escalation_rate DOUBLE,

    assumption_source STRING,

    evidence_status STRING,

    notes STRING,

    ingestion_timestamp TIMESTAMP

)
USING DELTA;

-- COMMAND ----------

INSERT INTO financial_assumptions_raw
VALUES
(
    'FIN_ASSUMP_BASE_001',
    'BASE',
    0.06,
    20,
    0.00,
    'ANALYST_ASSUMPTION',
    'ASSUMPTION',
    'Base-case financial assumptions used for the UWSP energy conservation analysis. Discount rate and analysis horizon are analyst-selected for scenario testing and are not reported UWSP financing terms.',
    current_timestamp()
);

-- COMMAND ----------

SELECT
    assumption_id,
    scenario_name,
    discount_rate,
    analysis_horizon_years,
    energy_price_escalation_rate,
    assumption_source,
    evidence_status

FROM uwsp_energy_transition_eac.bronze.financial_assumptions_raw;

-- COMMAND ----------

INSERT INTO uwsp_energy_transition_eac.bronze.financial_assumptions_raw
(
    assumption_id,
    scenario_name,
    discount_rate,
    analysis_horizon_years,
    energy_price_escalation_rate,
    assumption_source,
    evidence_status,
    notes,
    ingestion_timestamp
)
VALUES

(
    'FIN_ASSUMP_LOW_001',
    'LOW',
    0.04,
    20,
    0.02,
    'ANALYST_ASSUMPTION',
    'ASSUMPTION',
    'Lower discount rate and 2 percent annual energy-price escalation for sensitivity testing. Not reported UWSP financing terms.',
    current_timestamp()
),

(
    'FIN_ASSUMP_HIGH_001',
    'HIGH',
    0.08,
    20,
    0.00,
    'ANALYST_ASSUMPTION',
    'ASSUMPTION',
    'Higher discount rate and zero energy-price escalation for downside sensitivity testing. Not reported UWSP financing terms.',
    current_timestamp()
);

-- COMMAND ----------

SELECT
    scenario_name,
    discount_rate,
    analysis_horizon_years,
    energy_price_escalation_rate,
    assumption_source,
    evidence_status

FROM uwsp_energy_transition_eac.bronze.financial_assumptions_raw

ORDER BY discount_rate;

-- COMMAND ----------

UPDATE uwsp_energy_transition_eac.bronze.climate_action_measures_raw

SET
    annual_ghg_reduction_tco2e =
        10382596 * 0.45359237 / 1000,

    notes = CONCAT(
        notes,
        ' UWSP Facility Services also reports carbon reductions of 10,382,596 lb, equivalent to approximately 4,709 metric tonnes CO2e. This reported value reflects the broader conservation program and should not automatically be treated as electricity-only avoided emissions.'
    )

WHERE measure_id = 'MEASURE_EE_002';

-- COMMAND ----------

SELECT

    m.measure_id,

    ROUND(
        m.annual_ghg_reduction_tco2e,
        2
    ) AS reported_program_reduction_tco2e,

    e.annual_avoided_emissions_tco2e
        AS modeled_electricity_reduction_tco2e,

    ROUND(
        m.annual_ghg_reduction_tco2e
        - e.annual_avoided_emissions_tco2e,
        2
    ) AS difference_tco2e,

    ROUND(
        e.annual_avoided_emissions_tco2e
        / m.annual_ghg_reduction_tco2e,
        3
    ) AS electricity_modeled_share_of_reported

FROM uwsp_energy_transition_eac.silver.climate_action_measures_validated m

LEFT JOIN uwsp_energy_transition_eac.silver.measure_emissions_impact e
    ON m.measure_id = e.measure_id

WHERE m.measure_id = 'MEASURE_EE_002';

-- COMMAND ----------

SELECT
    measure_id,
    annual_ghg_reduction_tco2e,
    notes
FROM uwsp_energy_transition_eac.bronze.climate_action_measures_raw
WHERE measure_id = 'MEASURE_EE_002';

-- COMMAND ----------

INSERT INTO uwsp_energy_transition_eac.bronze.climate_action_measures_raw
(
    measure_id,
    source_id,
    measure_name,
    measure_category,
    facility_or_scope,
    implementation_status,
    implementation_year,
    annual_energy_reduction_mwh,
    annual_ghg_reduction_tco2e,
    capex_usd,
    annual_cost_savings_usd,
    incentive_or_funding_usd,
    funding_source,
    implementing_entity,
    implementation_milestone,
    tracking_metric,
    geographic_scope,
    evidence_status,
    notes,
    ingestion_timestamp
)
VALUES
(
    'MEASURE_SOLAR_001',
    'SRC_SOLAR_001',
    'Collins Classroom Center Solar PV',
    'SOLAR',
    'Collins Classroom Center',
    'IMPLEMENTED',
    2023,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    'UWSP Facilities',
    'Solar PV system operational since July 19, 2023',
    'Annual solar generation (MWh)',
    'UWSP Campus',
    'PORTAL_VERIFIED_ASSET',
    'AlsoEnergy portal verifies a 50 kW solar PV system at Collins Classroom Center, generating since July 19, 2023, with 195.22 MWh lifetime production as of May 19, 2026. Annual generation, project CAPEX, annual savings, REC ownership, and retirement status are not yet independently verified.',
    current_timestamp()
);

-- COMMAND ----------

SELECT
    measure_id,
    measure_name,
    measure_category,
    implementation_status,
    implementation_year,
    annual_energy_reduction_mwh,
    capex_usd,
    annual_cost_savings_usd,
    evidence_status

FROM uwsp_energy_transition_eac.bronze.climate_action_measures_raw

WHERE measure_id = 'MEASURE_SOLAR_001';

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.solar_annualized_performance AS

SELECT

    solar_record_id,
    source_id,
    site_name,

    installed_capacity_kw,
    lifetime_generation_mwh,
    generation_start_date,
    source_last_updated,

    DATEDIFF(
        source_last_updated,
        generation_start_date
    ) AS operating_days,

    ROUND(
        lifetime_generation_mwh
        /
        (
            DATEDIFF(
                source_last_updated,
                generation_start_date
            ) / 365.25
        ),
        2
    ) AS annualized_generation_mwh,

    lifetime_capacity_factor,

    performance_qa_status,
    source_freshness_status,
    rec_ownership_status,

    'ANNUALIZED_FROM_LIFETIME_GENERATION'
        AS generation_estimation_method,

    CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM uwsp_energy_transition_eac.silver.solar_asset_validated

WHERE solar_record_id = 'SOLAR_REC_001';

-- COMMAND ----------

SELECT
    site_name,
    installed_capacity_kw,
    lifetime_generation_mwh,
    operating_days,
    annualized_generation_mwh,
    lifetime_capacity_factor,
    generation_estimation_method

FROM uwsp_energy_transition_eac.silver.solar_annualized_performance;

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.bronze.eac_price_evidence_raw (

    price_record_id STRING,

    price_date DATE,

    supplier_name STRING,

    certificate_type STRING,

    technology STRING,

    registry_name STRING,

    geography STRING,

    vintage_year INT,

    volume_mwh DOUBLE,

    unit_price_usd_per_mwh DOUBLE,

    certification STRING,

    source_type STRING,

    evidence_status STRING,

    source_document STRING,

    notes STRING,

    ingestion_timestamp TIMESTAMP

)
USING DELTA;

-- COMMAND ----------

DESCRIBE TABLE
uwsp_energy_transition_eac.bronze.eac_price_evidence_raw;

-- COMMAND ----------

DESCRIBE TABLE
uwsp_energy_transition_eac.bronze.eac_price_evidence_raw;

-- COMMAND ----------

INSERT INTO uwsp_energy_transition_eac.bronze.eac_price_evidence_raw
(
    price_record_id,
    price_date,
    supplier_name,
    certificate_type,
    technology,
    registry_name,
    geography,
    vintage_year,
    volume_mwh,
    unit_price_usd_per_mwh,
    certification,
    source_type,
    evidence_status,
    source_document,
    notes,
    ingestion_timestamp
)
VALUES
(
    'EAC_FEE_MRETS_001',
    DATE('2026-09-04'),
    'M-RETS',
    'REGISTRY_RETIREMENT_FEE',
    NULL,
    'M-RETS',
    'Wisconsin / MISO',
    NULL,
    NULL,
    0.020,
    NULL,
    'REGISTRY_FEE',
    'PUBLIC_VERIFIED',
    'M-RETS pricing page',
    'Publicly posted registry retirement fee of $0.020 per REC. This is a registry transaction fee only and must not be interpreted as the REC commodity purchase price.',
    current_timestamp()
);

-- COMMAND ----------

SELECT
    price_record_id,
    registry_name,
    unit_price_usd_per_mwh,
    source_type,
    evidence_status,
    notes

FROM uwsp_energy_transition_eac.bronze.eac_price_evidence_raw;