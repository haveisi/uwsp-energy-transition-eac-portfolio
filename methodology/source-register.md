# Source Register

This project uses public institutional, utility, monitoring, planning, and registry-related evidence.

| Source ID | Source | Domain | Evidence Use |
|---|---|---|---|
| SRC_SOLAR_001 | AlsoEnergy monitoring portal | Solar | System size, operating date, lifetime generation |
| SRC_SOLAR_002 | AlsoEnergy monitoring portal | Solar | Additional solar monitoring evidence |
| SRC_SOLAR_003 | SolarEdge monitoring portal | Solar | Additional solar monitoring evidence |
| SRC_EE_001 | UWSP sustainability / Focus on Energy material | Energy Efficiency | Institutional efficiency context |
| SRC_EE_002 | UWSP Facility Services energy conservation data | Energy Efficiency | Projected electricity reduction, first cost, annual savings, reported GHG reduction |
| SRC_EAC_001 | Wisconsin Academy historical UWSP renewable-energy reporting | EAC / REC | Historical public EAC evidence |
| SRC_GRID_001 | Wisconsin Public Service emissions information | Scope 2 / Emissions | Electricity emissions factor used for analytical modeling |
| SRC_LOAD_001 | UWSP climate commitment / institutional reporting | Electricity / Renewable Claims | Institutional renewable electricity context |
| SRC_CLIMATE_PLAN_001 | UWSP climate action planning material | Climate Planning | Climate-action planning methodology and measure design |
| SRC_RESILIENCE_001 | Second Nature Resilience Commitment | Resilience | Governance, resilience planning, monitoring, and public reporting context |

## Evidence Hierarchy

Sources are evaluated based on their role in the analysis.

### Tier 1 — Primary / Institutional Evidence

Examples:

- signed institutional commitments
- university facility data
- utility-published emissions information
- direct monitoring portals

### Tier 2 — Public Secondary Evidence

Examples:

- public reporting describing historical renewable-energy procurement
- third-party institutional summaries

### Analyst Assumptions

Analytical assumptions are stored separately from public evidence.

Examples include:

- discount rates
- analysis horizon
- energy-price escalation scenarios

These assumptions are not presented as institutional facts.

## Data Governance Principle

The project preserves a distinction between:

**source-reported fact → calculated metric → analyst assumption → management interpretation**

This distinction is maintained across Bronze, Silver, Gold, and Power BI layers.