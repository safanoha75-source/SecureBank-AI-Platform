# backend/ml/train_model.py
import os
import joblib
from sklearn.ensemble import IsolationForest
from feature_extractor import extract_sqli_features

def train_and_save_model():
    print("[*] بدء عملية تدريب نموذج كشف التهديدات (Isolation Forest)...")

    # 1. مجموعة بيانات تدريبية تجريبية (بيانات طبيعية + بيانات هجمات SQLi)
    # 1 يعني سلوك طبيعي وآمن، والهجمات تمثل حالات شاذة (Anomalies)
    training_queries = [
        # استعلامات طبيعية وآمنة تماماً
        "SELECT * FROM Customers WHERE CustomerID = 5",
        "SELECT FullName, Email FROM Customers WHERE Phone = '01000000000'",
        "SELECT * FROM Accounts WHERE AccountID = 102",
        "UPDATE Customers SET Phone = '01111111111' WHERE CustomerID = 2",
        "SELECT COUNT(*) FROM Transactions WHERE AccountID = 5",
        "SELECT * FROM Customers ORDER BY CreatedAt DESC",
        "SELECT Balance FROM Accounts WHERE CustomerID = 1",
        
        # محاولات هجمات وتحقن شاذة (SQL Injection)
        "SELECT * FROM users WHERE id = 1 OR 1=1 --",
        "SELECT * FROM accounts WHERE name = 'admin' UNION SELECT null, password FROM users",
        "DROP TABLE Customers; --",
        "SELECT * FROM users WHERE id = 1; EXEC xp_cmdshell('dir');",
        "1' OR '1'='1",
        "UNION SELECT 1, 2, 3, 4, 5",
        "SELECT * FROM items WHERE id = 1 AND SLEEP(5)"
    ]

    # 2. استخراج الميزات لكل الاستعلامات باستخدام دالة الاستخراج التي أنشأناها
    X_features = [extract_sqli_features(q) for q in training_queries]

    # 3. بناء وتدريب نموذج Isolation Forest
    # contamination=0.3 تعني أننا نتوقع أن نسبة الشذوذ/الهجمات في عينة التدريب تقارب 30%
    model = IsolationForest(contamination=0.3, random_state=42)
    model.fit(X_features)

    # 4. التأكد من إنشاء مجلد لحفظ النماذج إن لم يكن موجوداً
    models_dir = os.path.join(os.path.dirname(__file__), "../models")
    os.makedirs(models_dir, exist_ok=True)

    # 5. حفظ النموذج المدرب باستخدام joblib
    model_path = os.path.join(models_dir, "sqli_isolation_model.joblib")
    joblib.dump(model, model_path)

    print(f"[+] تم تدريب النموذج وحفظه بنجاح في المسار: {model_path}")

if __name__ == "__main__":
    train_and_save_model()