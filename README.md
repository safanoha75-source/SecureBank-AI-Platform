# 🛡️ SecureBank AI & Fraud Intelligence Platform

An enterprise-grade, hybrid security and financial fraud intelligence platform designed to protect modern banking infrastructures. It combines rule-based high-speed filters, unsupervised machine learning (Isolation Forest), real-time financial transaction monitoring, and a fully bilingual interactive Operations Center (SOC) dashboard.

---

## 🚀 Key Features

* **Hybrid SQL Injection Defense:** 
  * *Layer 1:* Fast-matching rule filters for known attack signatures.
  * *Layer 2:* Scikit-learn `Isolation Forest` AI model for zero-day anomaly detection.
* **Financial Fraud Intelligence:** Real-time transaction risk scoring based on amount thresholds, untrusted geographic locations, and IP behavior.
* **Bilingual SOC Dashboard (Dash / Plotly):** Interactive operations center supporting full **Arabic (RTL)** and **English (LTR)** switching with live KPIs, analytical charts, and automated security insights.
* **Structured Audit Logging:** Complete transactional and security event persistence in Microsoft SQL Server (`SecureBank_DB`).
* **High-Performance Backend:** Built with FastAPI, Pyodbc, and asynchronous data processing.

---

## 📊 System Architecture & Tech Stack

* **Backend API:** Python, FastAPI, Uvicorn, Pyodbc
* **AI & Machine Learning:** Scikit-learn (Isolation Forest), Joblib, Pandas, NumPy
* **Database:** Microsoft SQL Server (SSMS)
* **Frontend & Visualization:** Plotly Dash, HTML5, CSS3

---

## 📁 Project Structure

```text
SecureBank/
│
├── backend/
│   ├── ML/
│   │   ├── feature_extractor.py      # SQL feature extraction pipeline
│   │   └── train_model.py            # Isolation Forest training script
│   ├── models/
│   │   └── sqli_isolation_model.joblib # Serialized AI model
│   └── app.py                        # FastAPI core server & endpoints
│
├── dashboard/
│   └── app_dashboard.py              # Bilingual Plotly Dash SOC UI
│
├── requirements.txt                  # Project dependencies
└── README.md                         # Project documentation