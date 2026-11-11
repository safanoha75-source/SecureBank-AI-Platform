# backend/app.py
import os
import joblib
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import pyodbc

from backend.ML.feature_extractor import extract_sqli_features

app = FastAPI(title="SecureBank AI & Hybrid Security Core", version="2.0")

DB_SERVER = "DESKTOP-1G3V897"
DB_NAME = "SecureBank_DB"
DB_CONNECTION_STRING = (
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={DB_SERVER};"
    f"DATABASE={DB_NAME};"
    f"Trusted_Connection=yes;"
)

# تحميل نموذج الذكاء الاصطناعي عند بدء السيرفر
MODEL_PATH = os.path.join(os.path.dirname(__file__), "models", "sqli_isolation_model.joblib")
try:
    ml_model = joblib.load(MODEL_PATH)
    print("[+] تم تحميل عقل الذكاء الاصطناعي (Isolation Forest) بنجاح!")
except Exception as e:
    print(f"[-] تحذير: لم يتم تحميل نموذج الـ AI: {e}")
    ml_model = None

class SecurityQueryInput(BaseModel):
    customer_id: int
    query_text: str

@app.get("/")
def home():
    return {"status": "online", "system": "SecureBank Hybrid AI & Fraud Intelligence Platform"}

@app.post("/api/v1/security/check-sqli")
def check_sqli_hybrid(data: SecurityQueryInput):
    try:
        query_upper = data.query_text.upper()
        
        is_attack = False
        risk_score = 0.01
        threat_type = "Normal"
        detection_engine = "Safe"

        # -------------------------------------------------------------
        # الطبقة الأولى: القواعد السريعة للحيل المعروفة (Rule-based Filter)
        # -------------------------------------------------------------
        known_signatures = ["OR 1=1", "UNION SELECT", "DROP TABLE", "XP_CMDSHELL", "SLEEP(", "--"]
        rule_triggered = any(sig in query_upper for sig in known_signatures)

        if rule_triggered:
            is_attack = True
            risk_score = 0.99
            threat_type = "SQLi"
            detection_engine = "Rule-based Engine (Fast Filter)"
        
        # -------------------------------------------------------------
        # الطبقة الثانية: نموذج الذكاء الاصطناعي للشذوذ (AI Core / Anomaly Detection)
        # -------------------------------------------------------------
        elif ml_model:
            features = extract_sqli_features(data.query_text)
            prediction = ml_model.predict([features])[0]
            
            if prediction == -1:
                is_attack = True
                risk_score = 0.92
                threat_type = "SQLi"
                detection_engine = "AI Core (Isolation Forest Anomaly)"
            else:
                is_attack = False
                risk_score = 0.05
                threat_type = "Normal"
                detection_engine = "AI Core & Rules (Passed)"

        # -------------------------------------------------------------
        # تسجيل النتيجة في قاعدة بيانات SQL Server
        # -------------------------------------------------------------
        conn = pyodbc.connect(DB_CONNECTION_STRING)
        cursor = conn.cursor()
        
        insert_query = """
        INSERT INTO Security_Logs (CustomerID, ThreatType, QueryText, RiskScore, IsAttack, DetectedAt)
        VALUES (?, ?, ?, ?, ?, GETDATE())
        """
        cursor.execute(insert_query, (data.customer_id, threat_type, data.query_text, risk_score, 1 if is_attack else 0))
        conn.commit()
        cursor.close()
        conn.close()

        # إرجاع التقرير الشامل للعميل
        return {
            "status": "success",
            "customer_id": data.customer_id,
            "is_attack": is_attack,
            "risk_score": risk_score,
            "engine_used": detection_engine,
            "message": "🚨 Critical Threat Blocked by Hybrid Security Engine!" if is_attack else "✅ Query evaluated as safe."
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


from pydantic import BaseModel

# نموذج بيانات المعاملة المالية الواردة
class TransactionInput(BaseModel):
    customer_id: int
    amount: float
    location: str
    ip_address: str

@app.post("/api/v1/fraud/check-transaction")
def check_transaction_fraud(data: TransactionInput):
    try:
        risk_score = 0.05
        is_fraud = False
        fraud_reasons = []

        # -------------------------------------------------------------
        # قواعد كشف الاحتيال المالي (Fraud Detection Rules & Heuristics)
        # -------------------------------------------------------------
        
        # 1. فحص ضخامة المبلغ (مثلاً المبالغ فوق 50,000 تعتبر عالية الخطورة)
        if data.amount > 50000:
            risk_score += 0.50
            fraud_reasons.append("Unusually high transaction amount.")

        # 2. فحص الموقع الجغرافي المشبوه (مثلاً معاملات من خارج النطاق المعتاد)
        trusted_locations = ["cairo", "port said", "alexandria", "giza"]
        if data.location.strip().lower() not in trusted_locations:
            risk_score += 0.35
            fraud_reasons.append("Access from an untrusted or foreign geographic location.")

        # تحديد نهائي لحالة الاحتيال إذا تجاوزت الخطورة 0.5
        if risk_score >= 0.5:
            is_fraud = True
        else:
            risk_score = round(risk_score, 2)

        # -------------------------------------------------------------
        # تخزين سجل التدقيق الهيكلي المتقدم في SQL Server
        # -------------------------------------------------------------
        conn = pyodbc.connect(DB_CONNECTION_STRING)
        cursor = conn.cursor()
        
        insert_audit_query = """
        INSERT INTO Transaction_Fraud_Logs (CustomerID, Amount, Location, IPAddress, RiskScore, IsFraud, DetectedAt)
        VALUES (?, ?, ?, ?, ?, ?, GETDATE())
        """
        cursor.execute(insert_audit_query, (
            data.customer_id, 
            data.amount, 
            data.location, 
            data.ip_address, 
            risk_score, 
            1 if is_fraud else 0
        ))
        conn.commit()
        cursor.close()
        conn.close()

        # إرجاع التقرير الأمني الكامل للعمليات
        return {
            "status": "success",
            "customer_id": data.customer_id,
            "transaction_amount": data.amount,
            "is_fraud": is_fraud,
            "risk_score": risk_score,
            "audit_details": {
                "ip_address": data.ip_address,
                "location": data.location,
                "reasons": fraud_reasons if fraud_reasons else ["Transaction behavior is normal."]
            },
            "message": "🚨 Fraud Alert: Suspicious transaction blocked!" if is_fraud else "✅ Transaction approved successfully."
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))



    
@app.get("/api/v1/analytics/summary")
def get_analytics_summary():
    try:
        conn = pyodbc.connect(DB_CONNECTION_STRING)
        cursor = conn.cursor()
        
        # إحصائيات الأمان واكتشاف الهجمات
        cursor.execute("SELECT COUNT(*), SUM(CAST(IsAttack AS INT)), ISNULL(AVG(RiskScore), 0) FROM Security_Logs")
        sec_res = cursor.fetchone()
        
        # إحصائيات المعاملات والاحتيال المالي
        cursor.execute("SELECT COUNT(*), SUM(CAST(IsFraud AS INT)), ISNULL(AVG(RiskScore), 0), ISNULL(SUM(Amount), 0) FROM Transaction_Fraud_Logs")
        fraud_res = cursor.fetchone()
        
        cursor.close()
        conn.close()
        
        return {
            "total_queries": sec_res[0] or 0,
            "total_threats": sec_res[1] or 0,
            "avg_sqli_risk": round(float(sec_res[2]), 2),
            "total_transactions": fraud_res[0] or 0,
            "total_frauds": fraud_res[1] or 0,
            "avg_fraud_risk": round(float(fraud_res[2]), 2),
            "total_amount": round(float(fraud_res[3]), 2)
        }
    except Exception as e:
        return {
            "total_queries": 0, "total_threats": 0, "avg_sqli_risk": 0.0,
            "total_transactions": 0, "total_frauds": 0, "avg_fraud_risk": 0.0, "total_amount": 0.0
        }