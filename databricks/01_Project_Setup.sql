-- Databricks notebook source
# UWSP Energy Transition & EAC Portfolio

## Purpose
Develop an auditable energy-transition decision-support model for UW-Stevens Point integrating:

- campus electricity demand
- energy-efficiency measures
- on-site solar generation
- Environmental Attribute Certificates (EACs / RECs)
- Scope 2 electricity emissions
- certificate ownership and retirement controls
- transition-risk scenarios
- financial and portfolio decision support

## Analytical architecture
Source Evidence → Bronze → Silver → Gold → Power BI

## Core business question
How should UWSP combine energy efficiency, on-site renewable generation, and EAC procurement to reduce electricity-related emissions while managing cost, data quality, claims, and transition risk?

## Project status
Phase 1 — source evidence and Bronze data architecture

-- COMMAND ----------

create catalog if not exists uwsp_energy_transition_eac;

-- COMMAND ----------

CREATE SCHEMA IF NOT EXISTS uwsp_energy_transition_eac.bronze;
CREATE SCHEMA IF NOT EXISTS uwsp_energy_transition_eac.silver;
CREATE SCHEMA IF NOT EXISTS uwsp_energy_transition_eac.gold;

-- COMMAND ----------

SHOW SCHEMAS IN uwsp_energy_transition_eac;