# UWSP Energy Transition & EAC Portfolio

This project started with a simple question:

**How can an institution make better energy-transition decisions when the technical, financial, and renewable-attribute evidence are scattered across different sources?**

I used public UWSP-related energy, solar, emissions, and renewable-energy information to build an end-to-end workflow in Databricks and Power BI.

The project connects:

**public evidence → data validation → emissions and financial analysis → EAC/REC assurance → management reporting**

![Architecture](assets/architecture.png)

---

## What I wanted to understand

I focused on four connected questions:

- How much electricity can be reduced through energy-efficiency measures?
- What does onsite solar contribute?
- Are the renewable attributes behind that electricity actually supported by the evidence available?
- How does the financial case change under different assumptions?

A big part of the work was making sure I did not mix reported facts, modeled values, and assumptions.

When something could not be verified, I kept it visible as a gap instead of filling it in.

---

## Energy Transition Decision Dashboard

![Executive Dashboard](assets/executive-dashboard.png)

The first Power BI page focuses on the energy and financial side of the analysis.

### Results

| Metric | Result |
|---|---:|
| Electricity reduction | 4,229 MWh/year |
| Modeled avoided emissions | 2,385 tCO2e/year |
| Annualized onsite solar generation | 68.89 MWh/year |
| Simple payback | 14.66 years |

I also tested the efficiency investment under three financial scenarios:

| Scenario | NPV |
|---|---:|
| LOW | +$0.87M |
| BASE | -$1.94M |
| HIGH | -$2.94M |

The result changes a lot depending on the discount rate and energy-price assumptions.

That was one of the main reasons I built the scenario selector in Power BI instead of presenting one NPV as the answer.

---

## EAC Assurance & Transition Risk

![EAC Assurance Dashboard](assets/eac-assurance-dashboard.png)

The second page looks at a different issue: whether the renewable-electricity position can be supported by the evidence currently available.

### Current findings

- Annualized physical solar generation: **68.89 MWh**
- Claimable renewable electricity based on currently verified ownership evidence: **0 MWh**
- Historical EAC assurance status: `INSUFFICIENT_EVIDENCE`
- EAC price readiness: `COMMODITY_PRICE_EVIDENCE_REQUIRED`
- Transition-risk status: `HIGH_DEPENDENCE_ON_PURCHASED_EACS`

The key lesson here is that these are not the same thing:

**physical renewable generation → ownership of the environmental attribute → retirement → claim eligibility**

A solar system can physically generate electricity without automatically proving who owns the REC or EAC associated with that generation.

For that reason, I treated unverified ownership conservatively.

`INSUFFICIENT_EVIDENCE` does not mean UWSP did not have valid RECs. It means the public evidence I assembled for this case study was not sufficient for certificate-level verification.

---

### Two-Sided Transition Risk

The transition-risk model tests both supportive and adverse transition conditions.

Scenarios include:

- `POLICY_SUPPORT`
- `CURRENT_PATH`
- `GREEN_HEADWIND`
- `CARBON_CONSTRAINT`

This allows the analysis to test both:

- the risk of delaying or underinvesting in the transition, and
- the risk that renewable investments themselves become financially challenged under weaker policy support, higher financing costs, or changing market conditions.

The Power BI page compares NPV across all four scenarios while allowing the user to inspect scenario-specific exposure in solar, purchased EACs, and efficiency.
---

## How I structured the data

I used a Bronze / Silver / Gold approach in Databricks.

### Bronze

Bronze keeps the source evidence close to what was actually reported.

Examples include:

- solar monitoring information
- energy-efficiency project data
- historical renewable-energy evidence
- electricity emissions factors
- financial assumptions

I intentionally kept missing fields as missing.

### Silver

Silver is where I added the analytical controls.

This includes:

- solar plausibility checks
- source freshness checks
- EAC / REC ownership and retirement checks
- evidence completeness
- emissions calculations
- financial scenario analysis
- reconciliation of reported and modeled emissions
- transition-risk logic

### Gold

Gold contains the small set of metrics needed by Power BI.

The goal was to keep the reporting layer simple and push the validation and business logic upstream.

---

## Management actions that came out of the analysis

The project also highlighted several practical follow-up actions:

1. Verify who owns the renewable attributes associated with onsite solar.
2. Obtain certificate-level REC / EAC retirement evidence.
3. Reconcile annual EAC procurement volume with electricity consumption.
4. Obtain actual REC / EAC commodity pricing or contract evidence.
5. Review the difference between reported GHG reductions and the electricity-only emissions model.

This was important to me because I did not want the project to stop at identifying data gaps. I wanted the gaps to translate into specific next steps.

---

## Tools

Databricks, Delta Lake, SQL, Power BI, DAX, Power Query

---

## Repository structure

```text
.
├── README.md
├── assets/
│   ├── architecture.png
│   ├── executive-dashboard.png
│   └── eac-assurance-dashboard.png
├── databricks/
│   ├── 01_Project_Setup.sql
│   ├── 02_Bronze_Ingestion.sql
│   ├── 03_Silver_Validation.sql
│   └── 10_PowerBI_Gold.sql
├── methodology/
│   ├── assumptions-and-limitations.md
│   ├── data-lineage.md
│   ├── eac-assurance-methodology.md
│   └── financial-scenarios.md
├── power-bi/
└── sources/
    └── source-register.md
````

---

## Important note

This is an independent portfolio case study built from public information and clearly identified analytical assumptions.

It is not an official UWSP energy, financial, GHG, or REC reporting system.

Where I could not verify a value or claim from the available evidence, I kept that uncertainty visible rather than presenting an unsupported number as fact.
```
