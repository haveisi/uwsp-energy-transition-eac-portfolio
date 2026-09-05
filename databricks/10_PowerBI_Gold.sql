-- Databricks notebook source
USE CATALOG uwsp_energy_transition_eac;
USE SCHEMA gold;

-- COMMAND ----------

CREATE OR REPLACE TABLE energy_transition_portfolio_summary AS

SELECT

    /* ENERGY EFFICIENCY */

    (
        SELECT SUM(eac_demand_reduction_mwh)
        FROM uwsp_energy_transition_eac.silver.portfolio_eac_demand_bridge
        WHERE measure_type = 'ENERGY_EFFICIENCY'
    ) AS efficiency_reduction_mwh,

    (
        SELECT annual_avoided_emissions_tco2e
        FROM uwsp_energy_transition_eac.silver.measure_emissions_impact
        WHERE measure_id = 'MEASURE_EE_002'
    ) AS efficiency_avoided_emissions_tco2e,


    /* SOLAR */

    (
        SELECT annualized_generation_mwh
        FROM uwsp_energy_transition_eac.silver.solar_annualized_performance
        WHERE solar_record_id = 'SOLAR_REC_001'
    ) AS solar_generation_mwh,

    (
        SELECT annual_avoided_grid_emissions_tco2e
        FROM uwsp_energy_transition_eac.silver.solar_emissions_impact
        WHERE solar_record_id = 'SOLAR_REC_001'
    ) AS solar_avoided_emissions_tco2e,

    (
        SELECT claimable_renewable_mwh
        FROM uwsp_energy_transition_eac.silver.solar_eac_claim_impact
        WHERE solar_record_id = 'SOLAR_REC_001'
    ) AS solar_claimable_renewable_mwh,

    (
        SELECT eac_claim_status
        FROM uwsp_energy_transition_eac.silver.solar_eac_claim_impact
        WHERE solar_record_id = 'SOLAR_REC_001'
    ) AS solar_eac_claim_status,


    /* EAC ASSURANCE */

    (
        SELECT assurance_status
        FROM uwsp_energy_transition_eac.silver.eac_assurance_status
        WHERE transaction_id = 'EAC_HIST_2016_001'
    ) AS historical_eac_assurance_status,

    (
        SELECT evidence_completeness_score
        FROM uwsp_energy_transition_eac.silver.eac_evidence_quality
        WHERE transaction_id = 'EAC_HIST_2016_001'
    ) AS historical_eac_evidence_completeness,

    (
        SELECT eac_price_readiness_status
        FROM uwsp_energy_transition_eac.silver.eac_price_readiness
    ) AS eac_price_readiness_status,


    /* TRANSITION RISK */

    (
        SELECT transition_risk_status
        FROM uwsp_energy_transition_eac.silver.eac_transition_risk_summary
    ) AS eac_transition_risk_status,


    /* FINANCIAL PERFORMANCE */

    (
        SELECT npv_usd
        FROM uwsp_energy_transition_eac.silver.measure_financial_scenarios
        WHERE scenario_name = 'BASE'
    ) AS efficiency_base_npv_usd,

    (
        SELECT npv_usd
        FROM uwsp_energy_transition_eac.silver.measure_financial_scenarios
        WHERE scenario_name = 'LOW'
    ) AS efficiency_low_npv_usd,

    (
        SELECT npv_usd
        FROM uwsp_energy_transition_eac.silver.measure_financial_scenarios
        WHERE scenario_name = 'HIGH'
    ) AS efficiency_high_npv_usd,

    (
        SELECT simple_payback_years
        FROM uwsp_energy_transition_eac.silver.measure_financial_analysis
        WHERE measure_id = 'MEASURE_EE_002'
    ) AS efficiency_simple_payback_years,


    /* GHG RECONCILIATION */

    (
        SELECT reconciliation_status
        FROM uwsp_energy_transition_eac.silver.measure_emissions_reconciliation
        WHERE measure_id = 'MEASURE_EE_002'
    ) AS ghg_reconciliation_status,


    CURRENT_TIMESTAMP() AS gold_processed_timestamp;

-- COMMAND ----------

select * from uwsp_energy_transition_eac.gold.energy_transition_portfolio_summary;