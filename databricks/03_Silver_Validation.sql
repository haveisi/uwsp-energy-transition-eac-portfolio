-- Databricks notebook source
USE CATALOG uwsp_energy_transition_eac;
USE SCHEMA silver;

-- COMMAND ----------

CREATE OR REPLACE TABLE solar_asset_validated AS

SELECT

    solar_record_id,
    source_id,
    site_name,

    installed_capacity_kw,
    lifetime_generation_mwh,
    generation_start_date,
    source_last_updated,

    monitoring_platform,
    rec_ownership_status,
    evidence_status,

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

    DATEDIFF(
        CURRENT_DATE(),
        CAST(source_last_updated AS DATE)
    ) AS source_age_days,

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
    END AS performance_qa_status,

    CASE
        WHEN DATEDIFF(
            CURRENT_DATE(),
            CAST(source_last_updated AS DATE)
        ) <= 30
        THEN 'CURRENT'

        WHEN DATEDIFF(
            CURRENT_DATE(),
            CAST(source_last_updated AS DATE)
        ) <= 90
        THEN 'AGING'

        ELSE 'STALE'
    END AS source_freshness_status,

    notes,

    CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM uwsp_energy_transition_eac.bronze.solar_generation_raw

WHERE installed_capacity_kw IS NOT NULL;

-- COMMAND ----------

SELECT
    site_name,
    installed_capacity_kw,
    lifetime_generation_mwh,
    lifetime_capacity_factor,
    performance_qa_status,
    source_age_days,
    source_freshness_status,
    rec_ownership_status

FROM uwsp_energy_transition_eac.silver.solar_asset_validated;

-- COMMAND ----------

SELECT
    site_name,
    source_last_updated,
    source_age_days,
    source_freshness_status,
    performance_qa_status,
    rec_ownership_status

FROM uwsp_energy_transition_eac.silver.solar_asset_validated;

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.solar_claim_readiness AS

SELECT

    solar_record_id,
    source_id,
    site_name,

    installed_capacity_kw,
    lifetime_generation_mwh,
    lifetime_capacity_factor,

    performance_qa_status,
    source_freshness_status,

    rec_ownership_status,

    CASE

        WHEN performance_qa_status <> 'PLAUSIBLE'
        THEN 'NOT_READY_TECHNICAL_QA'

        WHEN source_freshness_status = 'STALE'
        THEN 'NOT_READY_STALE_SOURCE'

        WHEN rec_ownership_status = 'VERIFY'
        THEN 'NOT_READY_REC_OWNERSHIP'

        WHEN rec_ownership_status = 'SOLD'
        THEN 'NOT_CLAIMABLE_RECS_SOLD'

        WHEN rec_ownership_status = 'TRANSFERRED'
        THEN 'NOT_CLAIMABLE_RECS_TRANSFERRED'

        WHEN rec_ownership_status = 'RETAINED'
        THEN 'CLAIM_READY_SUBJECT_TO_RETIREMENT'

        ELSE 'REVIEW_REQUIRED'

    END AS renewable_claim_status,

    CASE

        WHEN rec_ownership_status = 'RETAINED'
        THEN lifetime_generation_mwh

        ELSE 0

    END AS potentially_claimable_mwh,

    CURRENT_TIMESTAMP() AS processed_timestamp

FROM uwsp_energy_transition_eac.silver.solar_asset_validated;

-- COMMAND ----------

SELECT
    site_name,
    performance_qa_status,
    source_freshness_status,
    rec_ownership_status,
    renewable_claim_status,
    potentially_claimable_mwh

FROM uwsp_energy_transition_eac.silver.solar_claim_readiness;

-- COMMAND ----------

USE CATALOG uwsp_energy_transition_eac;
USE SCHEMA silver;

-- COMMAND ----------

CREATE OR REPLACE TABLE eac_transactions_validated AS

SELECT

    transaction_id,
    source_id,
    reporting_year,
    certificate_type,
    registry_name,
    certificate_id,
    generation_source,
    generation_location,
    generation_vintage_year,
    certificate_mwh,
    unit_price_usd_per_mwh,
    total_cost_usd,
    purchase_date,
    retirement_date,
    retirement_status,
    beneficiary,
    ownership_status,
    evidence_status,
    source_document,

    CASE
        WHEN certificate_mwh IS NULL
        THEN 1
        ELSE 0
    END AS flag_volume_missing,

    CASE
        WHEN unit_price_usd_per_mwh IS NULL
        THEN 1
        ELSE 0
    END AS flag_unit_price_missing,

    CASE
        WHEN registry_name IS NULL
        THEN 1
        ELSE 0
    END AS flag_registry_missing,

    CASE
        WHEN certificate_id IS NULL
        THEN 1
        ELSE 0
    END AS flag_certificate_id_missing,

    CASE
        WHEN generation_vintage_year IS NULL
        THEN 1
        ELSE 0
    END AS flag_vintage_missing,

    CASE
        WHEN retirement_status IS NULL
             OR retirement_status = 'VERIFY'
        THEN 1
        ELSE 0
    END AS flag_retirement_unverified,

    CASE
        WHEN ownership_status IS NULL
             OR ownership_status = 'VERIFY'
        THEN 1
        ELSE 0
    END AS flag_ownership_unverified,

    CASE
        WHEN retirement_date IS NULL
        THEN 1
        ELSE 0
    END AS flag_retirement_date_missing,

    notes,

    CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM uwsp_energy_transition_eac.bronze.eac_transactions_raw;

-- COMMAND ----------

SELECT
    transaction_id,
    reporting_year,
    total_cost_usd,

    flag_volume_missing,
    flag_unit_price_missing,
    flag_registry_missing,
    flag_certificate_id_missing,
    flag_vintage_missing,
    flag_retirement_unverified,
    flag_ownership_unverified,
    flag_retirement_date_missing

FROM uwsp_energy_transition_eac.silver.eac_transactions_validated;

-- COMMAND ----------

CREATE OR REPLACE TABLE eac_evidence_quality AS

SELECT

    *,

    (
        flag_volume_missing
        + flag_unit_price_missing
        + flag_registry_missing
        + flag_certificate_id_missing
        + flag_vintage_missing
        + flag_retirement_unverified
        + flag_ownership_unverified
        + flag_retirement_date_missing
    ) AS total_control_gaps,

    ROUND(
        (
            8
            -
            (
                flag_volume_missing
                + flag_unit_price_missing
                + flag_registry_missing
                + flag_certificate_id_missing
                + flag_vintage_missing
                + flag_retirement_unverified
                + flag_ownership_unverified
                + flag_retirement_date_missing
            )
        ) / 8.0,
        3
    ) AS evidence_completeness_score

FROM uwsp_energy_transition_eac.silver.eac_transactions_validated;

-- COMMAND ----------

SELECT
    transaction_id,
    reporting_year,
    total_control_gaps,
    evidence_completeness_score

FROM uwsp_energy_transition_eac.silver.eac_evidence_quality;

-- COMMAND ----------

CREATE OR REPLACE TABLE eac_assurance_status AS

SELECT

    transaction_id,
    reporting_year,
    total_cost_usd,
    total_control_gaps,
    evidence_completeness_score,

    CASE
        WHEN evidence_completeness_score >= 0.875
        THEN 'HIGH_ASSURANCE'

        WHEN evidence_completeness_score >= 0.625
        THEN 'MODERATE_ASSURANCE'

        WHEN evidence_completeness_score >= 0.375
        THEN 'LOW_ASSURANCE'

        ELSE 'INSUFFICIENT_EVIDENCE'

    END AS assurance_status

FROM uwsp_energy_transition_eac.silver.eac_evidence_quality;

-- COMMAND ----------

SELECT
    transaction_id,
    reporting_year,
    total_control_gaps,
    evidence_completeness_score,
    assurance_status

FROM uwsp_energy_transition_eac.silver.eac_assurance_status;

-- COMMAND ----------

USE CATALOG uwsp_energy_transition_eac;
USE SCHEMA silver;

-- COMMAND ----------

CREATE OR REPLACE TABLE climate_action_measures_validated AS

SELECT

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

    CASE
        WHEN annual_energy_reduction_mwh IS NULL
        THEN 1
        ELSE 0
    END AS flag_energy_savings_missing,

    CASE
        WHEN capex_usd IS NULL
        THEN 1
        ELSE 0
    END AS flag_capex_missing,

    CASE
        WHEN annual_cost_savings_usd IS NULL
        THEN 1
        ELSE 0
    END AS flag_cost_savings_missing,

    CASE
        WHEN annual_energy_reduction_mwh IS NOT NULL
             AND evidence_status = 'PUBLIC_REPORTED_QUANTIFIED'
        THEN 'PROJECTED_QUANTIFIED'

        WHEN annual_energy_reduction_mwh IS NULL
        THEN 'UNQUANTIFIED'

        ELSE 'REVIEW_REQUIRED'
    END AS measure_quantification_status,

    notes,

    CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM uwsp_energy_transition_eac.bronze.climate_action_measures_raw;

-- COMMAND ----------

SELECT
    measure_id,
    measure_name,
    annual_energy_reduction_mwh,
    flag_energy_savings_missing,
    flag_capex_missing,
    flag_cost_savings_missing,
    measure_quantification_status

FROM uwsp_energy_transition_eac.silver.climate_action_measures_validated

ORDER BY measure_id;

-- COMMAND ----------

CREATE OR REPLACE TABLE measure_decision_readiness AS

SELECT

    measure_id,
    measure_name,
    measure_category,
    implementation_status,

    annual_energy_reduction_mwh,
    annual_ghg_reduction_tco2e,
    capex_usd,
    annual_cost_savings_usd,
    incentive_or_funding_usd,

    flag_energy_savings_missing,
    flag_capex_missing,
    flag_cost_savings_missing,

    (
        flag_energy_savings_missing
        + flag_capex_missing
        + flag_cost_savings_missing
    ) AS total_core_data_gaps,

    ROUND(
        (
            3
            -
            (
                flag_energy_savings_missing
                + flag_capex_missing
                + flag_cost_savings_missing
            )
        ) / 3.0,
        3
    ) AS decision_readiness_score,

    CASE
        WHEN
            (
                flag_energy_savings_missing
                + flag_capex_missing
                + flag_cost_savings_missing
            ) = 0
        THEN 'DECISION_READY'

        WHEN
            (
                flag_energy_savings_missing
                + flag_capex_missing
                + flag_cost_savings_missing
            ) = 1
        THEN 'PARTIALLY_READY'

        ELSE 'DATA_GAPS'

    END AS decision_readiness_status

FROM uwsp_energy_transition_eac.silver.climate_action_measures_validated;

-- COMMAND ----------

SELECT
    measure_id,
    measure_name,
    total_core_data_gaps,
    decision_readiness_score,
    decision_readiness_status

FROM uwsp_energy_transition_eac.silver.measure_decision_readiness

ORDER BY measure_id;

-- COMMAND ----------

CREATE OR REPLACE TABLE measure_emissions_impact AS

SELECT

    m.measure_id,
    m.measure_name,
    m.measure_category,

    m.annual_energy_reduction_mwh,

    ef.factor_id,
    ef.reporting_year AS emission_factor_year,
    ef.utility_provider,
    ef.factor_tco2e_per_mwh,

    ROUND(
        m.annual_energy_reduction_mwh
        * ef.factor_tco2e_per_mwh,
        2
    ) AS annual_avoided_emissions_tco2e,

    m.measure_quantification_status,

    CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM uwsp_energy_transition_eac.silver.climate_action_measures_validated m

CROSS JOIN (
    SELECT *
    FROM uwsp_energy_transition_eac.bronze.electricity_emission_factors_raw
    WHERE factor_id = 'EF_WPS_2025_001'
) ef

WHERE m.annual_energy_reduction_mwh IS NOT NULL;

-- COMMAND ----------

SELECT
    measure_id,
    measure_name,
    annual_energy_reduction_mwh,
    factor_tco2e_per_mwh,
    annual_avoided_emissions_tco2e

FROM uwsp_energy_transition_eac.silver.measure_emissions_impact;

-- COMMAND ----------

CREATE OR REPLACE TABLE measure_eac_demand_impact AS

SELECT

    m.measure_id,
    m.measure_name,

    m.annual_energy_reduction_mwh,

    1.0 AS renewable_coverage_target_fraction,

    ROUND(
        m.annual_energy_reduction_mwh * 1.0,
        3
    ) AS avoided_eac_requirement_mwh,

    '100_PERCENT_RENEWABLE_COVERAGE_SCENARIO'
        AS coverage_scenario,

    CASE
        WHEN m.annual_energy_reduction_mwh IS NOT NULL
        THEN 'QUANTIFIED'
        ELSE 'DATA_GAP'
    END AS calculation_status,

    CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM uwsp_energy_transition_eac.silver.climate_action_measures_validated m

WHERE m.annual_energy_reduction_mwh IS NOT NULL;

-- COMMAND ----------

SELECT
    measure_id,
    measure_name,
    annual_energy_reduction_mwh,
    renewable_coverage_target_fraction,
    avoided_eac_requirement_mwh,
    coverage_scenario,
    calculation_status

FROM uwsp_energy_transition_eac.silver.measure_eac_demand_impact;

-- COMMAND ----------

UPDATE uwsp_energy_transition_eac.bronze.climate_action_measures_raw

SET
    capex_usd = 8900000,
    annual_cost_savings_usd = 607000,
    notes = 'UWSP Facility Services reports an estimated $8.9 million first cost after incentives, anticipated annual total energy cost savings of approximately $607,000, annual electricity reduction of 4,229,377 kWh, and a published simple payback of approximately 14.7 to 15.2 years. Values are public reported estimates and should not be interpreted as audited realized savings.'

WHERE measure_id = 'MEASURE_EE_002';

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.climate_action_measures_validated AS

SELECT

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

    CASE
        WHEN annual_energy_reduction_mwh IS NULL
        THEN 1
        ELSE 0
    END AS flag_energy_savings_missing,

    CASE
        WHEN capex_usd IS NULL
        THEN 1
        ELSE 0
    END AS flag_capex_missing,

    CASE
        WHEN annual_cost_savings_usd IS NULL
        THEN 1
        ELSE 0
    END AS flag_cost_savings_missing,

    CASE
        WHEN annual_energy_reduction_mwh IS NOT NULL
             AND evidence_status = 'PUBLIC_REPORTED_QUANTIFIED'
        THEN 'PROJECTED_QUANTIFIED'

        WHEN annual_energy_reduction_mwh IS NULL
        THEN 'UNQUANTIFIED'

        ELSE 'REVIEW_REQUIRED'
    END AS measure_quantification_status,

    notes,

    CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM uwsp_energy_transition_eac.bronze.climate_action_measures_raw;

-- COMMAND ----------

SELECT
    measure_id,
    measure_name,
    capex_usd,
    annual_cost_savings_usd,

    ROUND(
        capex_usd / annual_cost_savings_usd,
        2
    ) AS calculated_simple_payback_years

FROM uwsp_energy_transition_eac.silver.climate_action_measures_validated

WHERE measure_id = 'MEASURE_EE_002';

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.measure_decision_readiness AS

SELECT

    measure_id,
    measure_name,
    measure_category,
    implementation_status,

    annual_energy_reduction_mwh,
    annual_ghg_reduction_tco2e,
    capex_usd,
    annual_cost_savings_usd,
    incentive_or_funding_usd,

    flag_energy_savings_missing,
    flag_capex_missing,
    flag_cost_savings_missing,

    (
        flag_energy_savings_missing
        + flag_capex_missing
        + flag_cost_savings_missing
    ) AS total_core_data_gaps,

    ROUND(
        (
            3
            -
            (
                flag_energy_savings_missing
                + flag_capex_missing
                + flag_cost_savings_missing
            )
        ) / 3.0,
        3
    ) AS decision_readiness_score,

    CASE

        WHEN
            (
                flag_energy_savings_missing
                + flag_capex_missing
                + flag_cost_savings_missing
            ) = 0
        THEN 'DECISION_READY'

        WHEN
            (
                flag_energy_savings_missing
                + flag_capex_missing
                + flag_cost_savings_missing
            ) = 1
        THEN 'PARTIALLY_READY'

        ELSE 'DATA_GAPS'

    END AS decision_readiness_status

FROM uwsp_energy_transition_eac.silver.climate_action_measures_validated;

-- COMMAND ----------

SELECT
    measure_id,
    measure_name,
    annual_energy_reduction_mwh,
    capex_usd,
    annual_cost_savings_usd,
    total_core_data_gaps,
    decision_readiness_score,
    decision_readiness_status

FROM uwsp_energy_transition_eac.silver.measure_decision_readiness

WHERE measure_id = 'MEASURE_EE_002';

-- COMMAND ----------

SELECT
    measure_id,
    total_core_data_gaps,
    decision_readiness_score,
    decision_readiness_status

FROM uwsp_energy_transition_eac.silver.measure_decision_readiness

WHERE measure_id = 'MEASURE_EE_002';

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.measure_financial_analysis AS

SELECT

    measure_id,
    measure_name,
    capex_usd,
    annual_cost_savings_usd,

    0.06 AS discount_rate,
    20 AS analysis_horizon_years,

    ROUND(
        (
            annual_cost_savings_usd *
            (
                (1 - POWER(1 + 0.06, -20))
                / 0.06
            )
        )
        - capex_usd,
        2
    ) AS npv_usd

FROM uwsp_energy_transition_eac.silver.climate_action_measures_validated

WHERE measure_id = 'MEASURE_EE_002';

-- COMMAND ----------

SELECT
    measure_id,
    measure_name,
    capex_usd,
    annual_cost_savings_usd,
    discount_rate,
    analysis_horizon_years,
    npv_usd

FROM uwsp_energy_transition_eac.silver.measure_financial_analysis;

-- COMMAND ----------

-- MAGIC %python
-- MAGIC import numpy_financial as npf
-- MAGIC
-- MAGIC capex = 8_900_000
-- MAGIC annual_savings = 607_000
-- MAGIC analysis_years = 20
-- MAGIC
-- MAGIC cash_flows = [-capex] + [annual_savings] * analysis_years
-- MAGIC
-- MAGIC irr = npf.irr(cash_flows)
-- MAGIC
-- MAGIC print(f"Project IRR: {irr:.2%}")

-- COMMAND ----------

-- MAGIC %python
-- MAGIC capex = 8_900_000
-- MAGIC annual_savings = 607_000
-- MAGIC analysis_years = 20
-- MAGIC
-- MAGIC def npv(rate):
-- MAGIC     return -capex + sum(
-- MAGIC         annual_savings / ((1 + rate) ** year)
-- MAGIC         for year in range(1, analysis_years + 1)
-- MAGIC     )
-- MAGIC
-- MAGIC low_rate = -0.99
-- MAGIC high_rate = 1.00
-- MAGIC
-- MAGIC for _ in range(200):
-- MAGIC     mid_rate = (low_rate + high_rate) / 2
-- MAGIC
-- MAGIC     if npv(mid_rate) > 0:
-- MAGIC         low_rate = mid_rate
-- MAGIC     else:
-- MAGIC         high_rate = mid_rate
-- MAGIC
-- MAGIC irr = (low_rate + high_rate) / 2
-- MAGIC
-- MAGIC print(f"Project IRR: {irr:.2%}")
-- MAGIC print(f"NPV at IRR: ${npv(irr):,.2f}")

-- COMMAND ----------

ALTER TABLE uwsp_energy_transition_eac.silver.measure_financial_analysis
ADD COLUMNS (
    irr DOUBLE
);

-- COMMAND ----------

UPDATE uwsp_energy_transition_eac.silver.measure_financial_analysis

SET irr = 0.0316

WHERE measure_id = 'MEASURE_EE_002';

-- COMMAND ----------

SELECT
    measure_id,
    capex_usd,
    annual_cost_savings_usd,
    discount_rate,
    analysis_horizon_years,
    npv_usd,
    irr

FROM uwsp_energy_transition_eac.silver.measure_financial_analysis;

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.measure_financial_analysis AS

SELECT

    m.measure_id,
    m.measure_name,

    a.assumption_id,
    a.scenario_name,

    m.capex_usd,
    m.annual_cost_savings_usd,

    a.discount_rate,
    a.analysis_horizon_years,
    a.energy_price_escalation_rate,

    ROUND(
        (
            m.annual_cost_savings_usd
            *
            (
                (1 - POWER(1 + a.discount_rate, -a.analysis_horizon_years))
                / a.discount_rate
            )
        )
        - m.capex_usd,
        2
    ) AS npv_usd,

    ROUND(
        m.capex_usd / m.annual_cost_savings_usd,
        2
    ) AS simple_payback_years

FROM uwsp_energy_transition_eac.silver.climate_action_measures_validated m

CROSS JOIN uwsp_energy_transition_eac.bronze.financial_assumptions_raw a

WHERE
    m.measure_id = 'MEASURE_EE_002'
    AND a.scenario_name = 'BASE';

-- COMMAND ----------

SELECT
    measure_id,
    scenario_name,
    capex_usd,
    annual_cost_savings_usd,
    discount_rate,
    analysis_horizon_years,
    npv_usd,
    simple_payback_years

FROM uwsp_energy_transition_eac.silver.measure_financial_analysis;

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.measure_financial_scenarios AS

SELECT

    m.measure_id,
    m.measure_name,

    a.assumption_id,
    a.scenario_name,

    m.capex_usd,
    m.annual_cost_savings_usd,

    a.discount_rate,
    a.analysis_horizon_years,
    a.energy_price_escalation_rate,

    ROUND(
        SUM(
            CASE
                WHEN year_num = 0
                THEN -m.capex_usd

                ELSE
                    (
                        m.annual_cost_savings_usd
                        * POWER(1 + a.energy_price_escalation_rate, year_num - 1)
                    )
                    /
                    POWER(1 + a.discount_rate, year_num)
            END
        ),
        2
    ) AS npv_usd

FROM uwsp_energy_transition_eac.silver.climate_action_measures_validated m

CROSS JOIN uwsp_energy_transition_eac.bronze.financial_assumptions_raw a

LATERAL VIEW EXPLODE(
    SEQUENCE(0, a.analysis_horizon_years)
) years AS year_num

WHERE m.measure_id = 'MEASURE_EE_002'

GROUP BY
    m.measure_id,
    m.measure_name,
    a.assumption_id,
    a.scenario_name,
    m.capex_usd,
    m.annual_cost_savings_usd,
    a.discount_rate,
    a.analysis_horizon_years,
    a.energy_price_escalation_rate;

-- COMMAND ----------

SELECT
    scenario_name,
    discount_rate,
    energy_price_escalation_rate,
    analysis_horizon_years,
    npv_usd

FROM uwsp_energy_transition_eac.silver.measure_financial_scenarios

ORDER BY discount_rate;

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.measure_financial_scenario_decision AS

SELECT

    measure_id,
    measure_name,
    scenario_name,

    discount_rate,
    energy_price_escalation_rate,
    analysis_horizon_years,

    npv_usd,

    CASE

        WHEN npv_usd > 0
        THEN 'VALUE_CREATING'

        WHEN npv_usd BETWEEN -1000000 AND 0
        THEN 'MARGINAL'

        ELSE 'FINANCIALLY_CHALLENGED'

    END AS financial_status

FROM uwsp_energy_transition_eac.silver.measure_financial_scenarios;

-- COMMAND ----------

SELECT
    scenario_name,
    discount_rate,
    energy_price_escalation_rate,
    npv_usd,
    financial_status

FROM uwsp_energy_transition_eac.silver.measure_financial_scenario_decision

ORDER BY discount_rate;

-- COMMAND ----------

MERGE INTO uwsp_energy_transition_eac.silver.climate_action_measures_validated AS s

USING (
    SELECT
        measure_id,
        annual_ghg_reduction_tco2e
    FROM uwsp_energy_transition_eac.bronze.climate_action_measures_raw
    WHERE measure_id = 'MEASURE_EE_002'
) AS b

ON s.measure_id = b.measure_id

WHEN MATCHED THEN
UPDATE SET
    s.annual_ghg_reduction_tco2e = b.annual_ghg_reduction_tco2e;

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

MERGE INTO uwsp_energy_transition_eac.silver.climate_action_measures_validated AS s

USING (
    SELECT
        measure_id,
        annual_ghg_reduction_tco2e
    FROM uwsp_energy_transition_eac.bronze.climate_action_measures_raw
    WHERE measure_id = 'MEASURE_EE_002'
) AS b

ON s.measure_id = b.measure_id

WHEN MATCHED THEN
UPDATE SET
    s.annual_ghg_reduction_tco2e = b.annual_ghg_reduction_tco2e;

-- COMMAND ----------

SELECT
    measure_id,
    annual_ghg_reduction_tco2e
FROM uwsp_energy_transition_eac.silver.climate_action_measures_validated
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

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.measure_emissions_reconciliation AS

SELECT

    m.measure_id,
    m.measure_name,

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
    ) AS electricity_modeled_share_of_reported,

    CASE
        WHEN m.annual_ghg_reduction_tco2e IS NULL
        THEN 'REPORTED_VALUE_MISSING'

        WHEN e.annual_avoided_emissions_tco2e IS NULL
        THEN 'MODELED_VALUE_MISSING'

        WHEN ABS(
            e.annual_avoided_emissions_tco2e
            / m.annual_ghg_reduction_tco2e
        ) BETWEEN 0.90 AND 1.10
        THEN 'RECONCILED'

        ELSE 'BOUNDARY_OR_METHOD_REVIEW'
    END AS reconciliation_status

FROM uwsp_energy_transition_eac.silver.climate_action_measures_validated m

LEFT JOIN uwsp_energy_transition_eac.silver.measure_emissions_impact e
    ON m.measure_id = e.measure_id

WHERE m.measure_id = 'MEASURE_EE_002';

-- COMMAND ----------

SELECT
    measure_id,
    reported_program_reduction_tco2e,
    modeled_electricity_reduction_tco2e,
    difference_tco2e,
    electricity_modeled_share_of_reported,
    reconciliation_status

FROM uwsp_energy_transition_eac.silver.measure_emissions_reconciliation;

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.solar_emissions_impact AS

SELECT

    s.solar_record_id,
    s.site_name,

    s.annualized_generation_mwh,

    ef.factor_id,
    ef.reporting_year AS emission_factor_year,
    ef.utility_provider,
    ef.factor_tco2e_per_mwh,

    ROUND(
        s.annualized_generation_mwh
        * ef.factor_tco2e_per_mwh,
        2
    ) AS annual_avoided_grid_emissions_tco2e,

    s.generation_estimation_method,

    s.rec_ownership_status,

    CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM uwsp_energy_transition_eac.silver.solar_annualized_performance s

CROSS JOIN (
    SELECT *
    FROM uwsp_energy_transition_eac.bronze.electricity_emission_factors_raw
    WHERE factor_id = 'EF_WPS_2025_001'
) ef;

-- COMMAND ----------

SELECT
    site_name,
    annualized_generation_mwh,
    factor_tco2e_per_mwh,
    annual_avoided_grid_emissions_tco2e,
    rec_ownership_status

FROM uwsp_energy_transition_eac.silver.solar_emissions_impact;

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.solar_eac_claim_impact AS

SELECT

    solar_record_id,
    site_name,

    annualized_generation_mwh,

    rec_ownership_status,

    CASE
        WHEN rec_ownership_status = 'RETAINED'
        THEN annualized_generation_mwh
        ELSE 0
    END AS claimable_renewable_mwh,

    CASE
        WHEN rec_ownership_status = 'RETAINED'
        THEN 0
        ELSE annualized_generation_mwh
    END AS replacement_eac_requirement_mwh,

    CASE
        WHEN rec_ownership_status = 'RETAINED'
        THEN 'ATTRIBUTE_RETAINED'

        WHEN rec_ownership_status = 'SOLD'
        THEN 'REPLACEMENT_EAC_REQUIRED'

        WHEN rec_ownership_status = 'TRANSFERRED'
        THEN 'REPLACEMENT_EAC_REQUIRED'

        WHEN rec_ownership_status = 'VERIFY'
        THEN 'OWNERSHIP_EVIDENCE_REQUIRED'

        ELSE 'REVIEW_REQUIRED'
    END AS eac_claim_status,

    CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM uwsp_energy_transition_eac.silver.solar_annualized_performance;

-- COMMAND ----------

SELECT
    site_name,
    annualized_generation_mwh,
    rec_ownership_status,
    claimable_renewable_mwh,
    replacement_eac_requirement_mwh,
    eac_claim_status

FROM uwsp_energy_transition_eac.silver.solar_eac_claim_impact;

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.portfolio_eac_demand_bridge AS

SELECT
    'ENERGY_EFFICIENCY' AS measure_type,
    measure_id,
    measure_name,
    avoided_eac_requirement_mwh AS eac_demand_reduction_mwh,
    'EFFICIENCY_REDUCES_LOAD' AS mechanism

FROM uwsp_energy_transition_eac.silver.measure_eac_demand_impact

UNION ALL

SELECT
    'SOLAR' AS measure_type,
    solar_record_id AS measure_id,
    site_name AS measure_name,

    CASE
        WHEN rec_ownership_status = 'RETAINED'
        THEN annualized_generation_mwh
        ELSE 0
    END AS eac_demand_reduction_mwh,

    CASE
        WHEN rec_ownership_status = 'RETAINED'
        THEN 'SOLAR_ATTRIBUTES_RETAINED'
        ELSE 'NO_EAC_REDUCTION_UNTIL_OWNERSHIP_VERIFIED'
    END AS mechanism

FROM uwsp_energy_transition_eac.silver.solar_eac_claim_impact;

-- COMMAND ----------

SELECT
    measure_type,
    measure_id,
    measure_name,
    eac_demand_reduction_mwh,
    mechanism

FROM uwsp_energy_transition_eac.silver.portfolio_eac_demand_bridge;

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.eac_transition_risk_summary AS

SELECT

    SUM(
        CASE
            WHEN measure_type = 'ENERGY_EFFICIENCY'
            THEN eac_demand_reduction_mwh
            ELSE 0
        END
    ) AS efficiency_eac_reduction_mwh,

    SUM(
        CASE
            WHEN measure_type = 'SOLAR'
            THEN eac_demand_reduction_mwh
            ELSE 0
        END
    ) AS solar_eac_reduction_mwh,

    SUM(eac_demand_reduction_mwh)
        AS total_verified_eac_demand_reduction_mwh,

    CASE
        WHEN SUM(
            CASE
                WHEN measure_type = 'SOLAR'
                THEN eac_demand_reduction_mwh
                ELSE 0
            END
        ) = 0
        THEN 'HIGH_DEPENDENCE_ON_PURCHASED_EACS'

        ELSE 'PARTIAL_PHYSICAL_RENEWABLE_COVERAGE'

    END AS transition_risk_status,

    CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM uwsp_energy_transition_eac.silver.portfolio_eac_demand_bridge;

-- COMMAND ----------

SELECT
    efficiency_eac_reduction_mwh,
    solar_eac_reduction_mwh,
    total_verified_eac_demand_reduction_mwh,
    transition_risk_status

FROM uwsp_energy_transition_eac.silver.eac_transition_risk_summary;

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.eac_transition_scenarios AS

SELECT
    'CURRENT_EVIDENCE' AS scenario_name,

    4229.377 AS efficiency_reduction_mwh,

    0.0 AS verified_solar_attribute_mwh,

    4229.377 AS total_eac_demand_reduction_mwh,

    'HIGH_DEPENDENCE_ON_PURCHASED_EACS'
        AS transition_risk_status

UNION ALL

SELECT
    'SOLAR_RECS_RETAINED' AS scenario_name,

    4229.377 AS efficiency_reduction_mwh,

    68.89 AS verified_solar_attribute_mwh,

    4229.377 + 68.89 AS total_eac_demand_reduction_mwh,

    'PARTIAL_PHYSICAL_RENEWABLE_COVERAGE'
        AS transition_risk_status;

-- COMMAND ----------

SELECT
    scenario_name,
    efficiency_reduction_mwh,
    verified_solar_attribute_mwh,
    total_eac_demand_reduction_mwh,
    transition_risk_status

FROM uwsp_energy_transition_eac.silver.eac_transition_scenarios;

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.eac_financial_exposure_scenarios AS

SELECT

    s.scenario_name,

    s.total_eac_demand_reduction_mwh,

    p.scenario_name AS price_scenario,

    p.unit_price_usd_per_mwh,

    ROUND(
        s.total_eac_demand_reduction_mwh
        * p.unit_price_usd_per_mwh,
        2
    ) AS avoided_eac_cost_usd,

    s.transition_risk_status

FROM uwsp_energy_transition_eac.silver.eac_transition_scenarios s

CROSS JOIN uwsp_energy_transition_eac.bronze.eac_price_assumptions_raw p;

-- COMMAND ----------

SELECT
    scenario_name,
    price_scenario,
    unit_price_usd_per_mwh,
    total_eac_demand_reduction_mwh,
    avoided_eac_cost_usd,
    transition_risk_status

FROM uwsp_energy_transition_eac.silver.eac_financial_exposure_scenarios

ORDER BY
    scenario_name,
    unit_price_usd_per_mwh;

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.eac_cost_sensitivity AS

SELECT

    s.scenario_name AS transition_scenario,

    p.scenario_name AS price_scenario,

    s.efficiency_reduction_mwh,
    s.verified_solar_attribute_mwh,
    s.total_eac_demand_reduction_mwh,

    p.unit_price_usd_per_mwh,

    ROUND(
        s.total_eac_demand_reduction_mwh
        * p.unit_price_usd_per_mwh,
        2
    ) AS avoided_eac_cost_usd,

    s.transition_risk_status,

    'SCENARIO_BASED_NOT_UWSP_ACTUAL_PRICE'
        AS price_evidence_note

FROM uwsp_energy_transition_eac.silver.eac_transition_scenarios s

CROSS JOIN uwsp_energy_transition_eac.bronze.eac_price_assumptions_raw p;

-- COMMAND ----------

SELECT
    transition_scenario,
    price_scenario,
    unit_price_usd_per_mwh,
    total_eac_demand_reduction_mwh,
    avoided_eac_cost_usd,
    transition_risk_status,
    price_evidence_note

FROM uwsp_energy_transition_eac.silver.eac_cost_sensitivity

ORDER BY
    transition_scenario,
    unit_price_usd_per_mwh;

-- COMMAND ----------

SELECT
    COUNT(*) AS price_record_count
FROM uwsp_energy_transition_eac.bronze.eac_price_assumptions_raw;

-- COMMAND ----------

CREATE OR REPLACE TABLE uwsp_energy_transition_eac.silver.eac_price_evidence_validated AS

SELECT

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

    CASE
        WHEN source_type = 'REGISTRY_FEE'
        THEN 0

        WHEN source_type IN (
            'SUPPLIER_QUOTE',
            'UWSP_CONTRACT',
            'UWSP_INVOICE',
            'UTILITY_TARIFF',
            'MARKET_BENCHMARK'
        )
        THEN 1

        ELSE 0
    END AS usable_as_eac_commodity_price,

    CASE
        WHEN source_type = 'REGISTRY_FEE'
        THEN 'TRANSACTION_FEE_ONLY'

        WHEN source_type = 'SUPPLIER_QUOTE'
        THEN 'COMMODITY_PRICE_QUOTE'

        WHEN source_type IN ('UWSP_CONTRACT', 'UWSP_INVOICE')
        THEN 'UWSP_ACTUAL_PRICE_EVIDENCE'

        WHEN source_type = 'UTILITY_TARIFF'
        THEN 'UTILITY_PRICING_EVIDENCE'

        WHEN source_type = 'MARKET_BENCHMARK'
        THEN 'MARKET_REFERENCE_PRICE'

        ELSE 'REVIEW_REQUIRED'
    END AS price_evidence_class,

    CASE
        WHEN unit_price_usd_per_mwh IS NULL
        THEN 'PRICE_MISSING'

        WHEN source_type = 'REGISTRY_FEE'
        THEN 'VALID_FEE_NOT_COMMODITY_PRICE'

        WHEN evidence_status = 'PUBLIC_VERIFIED'
        THEN 'VALIDATED'

        ELSE 'REVIEW_REQUIRED'
    END AS price_validation_status,

    CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM uwsp_energy_transition_eac.bronze.eac_price_evidence_raw;

-- COMMAND ----------

SELECT
    price_record_id,
    registry_name,
    unit_price_usd_per_mwh,
    source_type,
    usable_as_eac_commodity_price,
    price_evidence_class,
    price_validation_status

FROM uwsp_energy_transition_eac.silver.eac_price_evidence_validated;

-- COMMAND ----------

CREATE OR REPLACE TABLE
uwsp_energy_transition_eac.silver.eac_price_readiness AS

SELECT

    COUNT(*) AS total_price_records,

    SUM(
        CASE
            WHEN usable_as_eac_commodity_price = 1
            THEN 1
            ELSE 0
        END
    ) AS usable_commodity_price_records,

    SUM(
        CASE
            WHEN source_type = 'REGISTRY_FEE'
            THEN 1
            ELSE 0
        END
    ) AS registry_fee_records,

    CASE
        WHEN SUM(
            CASE
                WHEN usable_as_eac_commodity_price = 1
                THEN 1
                ELSE 0
            END
        ) > 0
        THEN 'READY_FOR_EAC_COST_MODELING'

        ELSE 'COMMODITY_PRICE_EVIDENCE_REQUIRED'
    END AS eac_price_readiness_status,

    CURRENT_TIMESTAMP() AS silver_processed_timestamp

FROM
uwsp_energy_transition_eac.silver.eac_price_evidence_validated;

-- COMMAND ----------

SELECT
    total_price_records,
    usable_commodity_price_records,
    registry_fee_records,
    eac_price_readiness_status

FROM
uwsp_energy_transition_eac.silver.eac_price_readiness;

-- COMMAND ----------

CREATE OR REPLACE TABLE
uwsp_energy_transition_eac.silver.eac_procurement_data_request AS

SELECT
    'EAC_PRICE_001' AS request_id,
    'EAC commodity unit price' AS requested_item,
    'USD per MWh' AS required_unit,
    'UWSP contract, invoice, supplier quote, utility green tariff, or verified market benchmark' AS acceptable_evidence,
    'HIGH' AS priority,
    'Required to calculate actual or evidence-backed EAC procurement cost.' AS business_reason

UNION ALL

SELECT
    'EAC_VOLUME_001',
    'Annual EAC/REC volume purchased',
    'MWh',
    'UWSP procurement record, retirement report, registry statement, or invoice',
    'HIGH',
    'Required to calculate renewable coverage and reconcile EAC procurement to electricity load.'

UNION ALL

SELECT
    'EAC_RETIREMENT_001',
    'Certificate retirement evidence',
    'Registry evidence',
    'M-RETS or other registry retirement report with beneficiary and vintage',
    'HIGH',
    'Required to substantiate renewable electricity claims and prevent double counting.'

UNION ALL

SELECT
    'EAC_OWNERSHIP_001',
    'On-site solar REC ownership',
    'Ownership status',
    'PPA, project contract, procurement record, or registry evidence',
    'HIGH',
    'Required to determine whether on-site solar generation reduces purchased EAC demand.';

-- COMMAND ----------

SELECT *
FROM uwsp_energy_transition_eac.silver.eac_procurement_data_request
ORDER BY request_id;