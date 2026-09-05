\# Data Lineage



This project follows an evidence-to-decision architecture:



Public Evidence → Bronze → Silver → Gold → Power BI



\## Source Evidence



Public institutional, utility, monitoring, registry, and planning sources are registered before use.



Each source is tracked with metadata such as:



\- source ID

\- source category

\- organization

\- source URL

\- reporting year

\- evidence type

\- reliability tier

\- validation status



\## Bronze Layer



The Bronze layer preserves source evidence and provenance.



Examples include:



\- solar monitoring evidence

\- historical EAC / REC evidence

\- energy-efficiency program data

\- electricity emission factors

\- financial assumptions

\- climate-action measures



Missing information is retained as missing rather than estimated unless an analytical assumption is explicitly required.



\## Silver Layer



The Silver layer performs validation, QA/QC, calculation, reconciliation, and assurance controls.



Examples include:



\- solar physical plausibility

\- source freshness

\- REC ownership checks

\- renewable claim-readiness

\- EAC evidence completeness

\- emissions calculations

\- financial scenario analysis

\- NPV modeling

\- transition-risk classification

\- reported-versus-modeled reconciliation



A core principle is:



\*\*Technical validity ≠ current data ≠ environmental attribute ownership ≠ claim eligibility\*\*



\## Gold Layer



The Gold layer exposes decision-ready metrics for Power BI.



The main portfolio summary includes:



\- efficiency reduction

\- avoided emissions

\- solar generation

\- solar claimable renewable MWh

\- EAC assurance status

\- EAC price readiness

\- transition-risk status

\- financial scenario NPVs

\- simple payback

\- reconciliation status



\## Power BI



Power BI provides the management-facing decision layer.



The report contains two pages:



1\. Energy Transition Decision Dashboard

2\. EAC Assurance \& Transition Risk



The dashboard converts the governed Gold-layer outputs into scenario analysis, KPI monitoring, assurance findings, and management actions.

