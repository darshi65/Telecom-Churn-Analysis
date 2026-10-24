# 📊 Telecom Customer Churn Analysis — SQL Server · Power BI · Python

An end-to-end churn analytics project: customer data is validated and stored in **SQL Server**, explored through an interactive **Power BI** dashboard, and used to train a **scikit-learn** model that flags which new customers are most likely to churn.

> **Headline result:** 1,732 of 6,418 customers churned (**26.99%**), representing **3.41M in lost revenue**. Contract type is by far the strongest segment signal — month-to-month customers churn at **47%** versus **3%** for two-year contracts.

---

## 📑 Table of Contents

1. [Business Problem](#-business-problem)
2. [Tech Stack](#-tech-stack)
3. [Architecture](#-architecture)
4. [Dataset](#-dataset)
5. [Part 1 — SQL Server](#-part-1--sql-server)
6. [Part 2 — Power BI Dashboard](#-part-2--power-bi-dashboard)
7. [Part 3 — Python Churn Model](#-part-3--python-churn-model)
8. [Key Findings](#-key-findings)
9. [Prediction Results](#-prediction-results)
10. [Limitations & Honest Caveats](#-limitations--honest-caveats)
11. [Business Recommendations](#-business-recommendations)
12. [Challenges Faced & How I Solved Them](#-challenges-faced--how-i-solved-them)
13. [Repository Structure](#-repository-structure)
14. [How to Run](#-how-to-run)
15. [Future Improvements](#-future-improvements)
16. [Author](#-author)

---

## 🎯 Business Problem

A telecom company is losing customers but lacks a clear, data-driven view of:

1. **Who** is churning
2. **Why** they are churning
3. **Which newly joined customers** are most at risk next

This project answers all three and turns the answers into retention recommendations.

---

## 🛠 Tech Stack

| Layer | Tools |
|---|---|
| Database / ETL | Microsoft SQL Server, SSMS, T-SQL (typed schema, constraints, views, quality checks, load log) |
| Business Intelligence | Power BI Desktop |
| Machine Learning | Python 3, pandas, NumPy, scikit-learn, matplotlib, seaborn, joblib |
| Environment | Jupyter Notebook / Anaconda |
| Version Control | Git, GitHub |

---

## 🏗 Architecture

```
 Raw CSV ──► SQL Server ──────────────────────────────────────────┐
             • stg_Churn (staging)                                │
             • prod_Churn (typed table + PK + constraints)        │
             • etl_log (load audit)                               │
             • vw_ChurnData  (Churned + Stayed)                   │
             • vw_JoinData   (Joined = new customers)             │
                  │                          │                    │
                  ▼                          ▼                    │
         Power BI dashboard        Python (Random Forest)         │
         (historical churn)        trains on vw_ChurnData         │
                  ▲                scores  vw_JoinData            │
                  │                          │                    │
                  └──── Prediction page ◄────┘  Predictions.csv ◄─┘
```

---

## 📂 Dataset

Telecom customer records covering:

- **Demographics:** gender, age, marital status, state
- **Account:** tenure, contract, payment method, paperless billing, value deal, referrals
- **Services:** phone, multiple lines, internet service/type, online security, online backup, device protection, premium support, streaming TV/movies/music, unlimited data
- **Financials:** monthly charge, total charges, refunds, extra data charges, long-distance charges, total revenue
- **Outcome fields:** customer status (`Stayed`, `Churned`, `Joined`), churn category, churn reason

`Churned` + `Stayed` customers (6,418) form the historical set. `Joined` customers (411) are the new customers scored by the model.

The raw data is not included in this repo.

---

## 🗄 Part 1 — SQL Server

Scripts live in [`/sql`](sql) and are meant to be run in order.

| Script | What it does |
|---|---|
| `01 load_tables.sql` | Loads staging → production, replaces NULLs with sensible defaults |
| `02 create_etl_logs.sql` | Creates an `etl_log` audit table |
| `03 data_quality_checks.sql` | Duplicate IDs, unexpected status values, zero-tenure "Stayed" customers, negative monthly charges, revenue reconciliation, staging-vs-production row counts |
| `04_views.sql` | `vw_ChurnData` (Churned/Stayed) and `vw_JoinData` (Joined) |


---

## 📊 Part 2 — Power BI Dashboard

### Page 1 — Telecom Churn Dashboard

<img width="960" height="598" alt="Dashboard_summary" src="https://github.com/user-attachments/assets/cac6458a-58b3-4a25-8ae6-f12afd3bca82" />

- **KPI cards:** Total Customers (6,418), New Joiners (411), Total Churn (1,732), Churn Rate (26.99%), Revenue Lost to Churn (3.41M)
- **Slicers:** Monthly Charge Range, Marital Status
- **Churn breakdowns:** gender, age group, state, churn category, payment method, tenure group, internet type, contract type, and churn by subscribed services

### Page 2 — Telecom Churn: Prediction

<img width="960" height="542" alt="Dashboard_prediction" src="https://github.com/user-attachments/assets/cab8e3bf-0d69-4b90-ae8d-89a27f98cc4e" />

A profile of customers the model predicts will churn (age, gender, marital status, tenure, contract, state, payment method) plus a customer-level table with monthly charge, total revenue and refunds, so a retention team can see who they are and how much revenue is involved.

---

## 🤖 Part 3 — Python Churn Model

Code: [`python/churn_modeling.py`](python/churn_modeling.py).

**Pipeline**

1. **Load** the historical view (`vw_ChurnData`) from Excel.
2. **Clean:** drop identifier/leakage-prone columns (`Customer_ID`, `Churn_Category`, `Churn_Reason`); validate the target before mapping it (`Stayed → 0`, `Churned → 1`) with explicit assertions.
3. **Encode** categorical features with `LabelEncoder`; keep the fitted encoders to reuse when scoring.
4. **Split** 80/20, **stratified** so train and test keep the same churn ratio.
5. **Train** a `RandomForestClassifier(class_weight='balanced')` — the balanced weighting stops the model from defaulting to the majority "Stayed" class.
6. **Compare** against a `LogisticRegression` baseline.
7. **Evaluate** on precision, recall, F1 (churned class) and ROC-AUC — not accuracy alone, which is misleading on imbalanced data.
8. **Explain** with Random Forest feature importances.
9. **Score** the new joiners and export predicted churners with a **churn probability**, ranked highest risk first.

### Model performance

> Fill these in from your own run (`python python/churn_modeling.py`).

| Model | Precision (Churned) | Recall (Churned) | F1 (Churned) | ROC-AUC |
|---|---|---|---|---|
| Random Forest (class-weighted) | 0.89 | 0.87 | 0.88 | 0.879 |
| Logistic Regression (baseline) | 0.91 | 0.71 | 0.80 | - |

---

## 🔍 Key Findings

Figures below are read directly from the dashboard.

- **Overall:** 26.99% churn rate — 1,732 customers, 3.41M in revenue lost.
- **Contract is the dominant driver:** month-to-month **47%**, one-year **11%**, two-year **3%**.
- **Competitors are the #1 reason (761 customers, ~44% of all churn).** Attitude (301) and dissatisfaction (300) together account for another ~35%, price for 196 (~11%).
- **Internet type:** fiber optic customers churn at **41%**, versus 26% for cable, 19% for DSL and 8% for customers with no internet service.
- **Payment method:** mailed check **38%** and bank withdrawal **34%** versus credit card **15%**.
- **Age:** customers over 50 churn most (~31.5%) versus ~23–24% for the 20–35 and 36–50 groups.
- **Geography:** Jammu & Kashmir has by far the highest state churn rate (57%), followed by Assam (38%) and Jharkhand (35%).
- **Support/security add-ons:** among churned customers, ~85% had no Online Security and ~83% had no Premium Support.
- **Tenure alone is *not* a strong separator here:** churn sits in a narrow 26–27.5% band across every tenure group, so contract type and service mix matter more than how long someone has been a customer.

> These are associations, not proven causes. For example, the add-on figures describe churned customers only and should be compared with the base population before concluding that add-ons reduce churn.

---

## 🔮 Prediction Results

The model scored the 411 new joiners and flagged **378** as likely churners.

| Dimension | Predicted churners |
|---|---|
| Contract | Month-to-month 360 · One-year 13 · Two-year 5 |
| Gender | Female 245 · Male 133 |
| Payment method | Credit card 195 · Bank withdrawal 146 · Mailed check 37 |
| Top states | Uttar Pradesh 44 · Maharashtra 40 · Tamil Nadu 35 · Karnataka 30 |
| Revenue in scope | 43,171 total revenue · 15,908 combined monthly charge |

---

## ⚠️ Limitations & Honest Caveats

- **The model flags 92% of new joiners (378 / 411), versus a historical churn rate of ~27%.** That is higher than expected. Likely contributors: new joiners are a different population from the training data (almost all month-to-month, very short history), and a default 0.5 cut-off combined with balanced class weights tends to over-flag the minority class. Treat the output as a **risk ranking, not a literal forecast**: `Predictions.csv` includes `Churn_Probability` so outreach can start with the highest-scoring customers.
- Labels are encoded with `LabelEncoder`, which imposes an arbitrary numeric order on nominal categories. It works acceptably for tree models but is not ideal; one-hot encoding is a better choice for the logistic regression baseline.
- Feature importance shows *what the model used*, not *why customers leave*.
- Model quality was assessed on a single train/test split, without cross-validation or hyperparameter tuning.

---

## 💡 Business Recommendations

1. **Convert month-to-month customers to longer contracts** with a discount or perk — this is the single largest lever (47% → 11% / 3%).
2. **Address competitor-driven churn (~44%)** with competitive benchmarking, price-match offers and win-back campaigns.
3. **Fix service and support experience:** attitude and dissatisfaction explain roughly a third of churn — invest in support training and first-contact resolution.
4. **Investigate fiber-optic quality and pricing** (41% churn — the highest of any internet type).
5. **Encourage auto-pay by credit card**, which is associated with much lower churn (15%) than mailed check (38%).
6. **Bundle Online Security and Premium Support** into retention offers.
7. **Prioritise outreach by predicted probability and revenue**, not by a binary flag.
8. **Run a regional review in Jammu & Kashmir** (57% churn) to find network, pricing or competitor issues.

---

## 🧩 Challenges Faced & How I Solved Them

| Problem | Root cause | Fix |
|---|---|---|
| `PermissionError` reading the Excel file | File was open in Excel / locked by OneDrive sync | Closed Excel, let OneDrive finish syncing |
| `ValueError: Input y contains NaN` | `.map()` silently turns any value outside `{'Stayed','Churned'}` into NaN | Inspected `value_counts(dropna=False)`, stripped whitespace, filtered to valid statuses |
| `train_test_split` error: `n_samples=0` | A filter/mapping cell was re-run in the same kernel; the second pass filtered an already-mapped column to zero rows | Restarted the kernel; made the mapping conditional on the column still being text |
| `could not convert string to float: '94918-MAD'` | `Customer_ID` was still in the feature matrix because the `drop` line had been commented out | Restored the drop; added a check that raises if any text column survives encoding |
| Exported predictions CSV was **empty** | The dtype check silently skipped the mapping, so the model trained on the strings `'Churned'`/`'Stayed'` and `predictions == 1` never matched | Switched to `is_numeric_dtype`, added assertions on the target, and printed `model.classes_` (must be `[0 1]`) |

The common lesson: validate the data at every stage with explicit checks instead of trusting transformations to fail loudly.

---

## 📁 Repository Structure

```
telecom-churn-analysis/
├── README.md
├── requirements.txt
├── .gitignore
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_load_data.sql
│   ├── 03_data_quality_checks.sql
│   └── 04_views.sql
├── python/
│   ├── churn_modeling.py
│   └── churn_modeling.ipynb          # add your notebook
├── powerbi/
│   ├── README.md
│   └── Telecom_Churn_Dashboard.pbix  # add your report
├── data/
│   └── README.md
└── screenshots/
    ├── dashboard_summary.png
    └── dashboard_prediction.png
```

---

## ▶️ How to Run

**1. Database**
```text
Run sql/01_create_tables.sql  (creates db_Churn and tables)
Import the raw CSV as dbo.stg_Churn   (SSMS: Tasks > Import Flat File)
Run sql/03_data_quality_checks.sql    (staging checks)
Run sql/02_load_data.sql
Run sql/04_views.sql
```
Export `vw_ChurnData` and `vw_JoinData` to `data/Prediction_data.xlsx` (one sheet each).

**2. Model**
```bash
python -m venv .venv
.venv\Scripts\activate          # Windows  (macOS/Linux: source .venv/bin/activate)
pip install -r requirements.txt
python python/churn_modeling.py
```
Outputs are written to `output/`: `Predictions.csv`, `feature_importance.png`, `churn_model_bundle.pkl`.

**3. Dashboard**
Open `powerbi/Telecom_Churn_Dashboard.pbix`, update the data source settings to your SQL Server instance and the `Predictions.csv` path, then refresh.

---

## 🚀 Future Improvements

- Cross-validation and hyperparameter tuning; add XGBoost for comparison
- Calibrate probabilities and choose the decision threshold using the cost of a missed churner versus a wasted retention offer
- One-hot encode categoricals for the linear model
- Add SHAP values for per-customer explanations
- Automate scoring by connecting Python directly to SQL Server instead of the Excel hand-off
- Add a Power BI what-if parameter and decomposition tree for interactive driver analysis
- Model time-to-churn with survival analysis

---

## 👤 Author

**[Darshi Shah]** · [LinkedIn](https://www.linkedin.com/in/darshi-shah-791633346) · [Email](mailto:darshishah65@gmail.com)

