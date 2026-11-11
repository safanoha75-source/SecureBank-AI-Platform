# backend/ml/feature_extractor.py
import re

def extract_sqli_features(query: str) -> list:
    """
    استخراج الميزات العددية من نص استعلام الـ SQL لتحليل احتمالية الهجوم (SQLi).
    المدخل: نص الاستعلام (String)
    المخرج: مجموعة أرقام تعبر عن خصائص الاستعلام (List of floats/ints)
    """
    if not isinstance(query, str):
        query = str(query)
        
    # 1. طول الاستعلام (Query Length)
    # الهجمات غالباً تحتوي على نصوص طويلة ومعقدة لتجاوز الفلترة
    query_length = len(query)
    
    # 2. تكرار الرموز الخاصة الخطرة (Special Characters Count)
    # مثل: علامات التنصيص، الفاصلة المنقوطة، الشرطتين، وعلامات التعليق
    special_chars_list = ["'", '"', ";", "--", "/*", "*/", "="]
    special_chars_count = sum(query.count(char) for char in special_chars_list)
    
    # 3. تكرار الكلمات المفتاحية الخطرة (SQL Keywords Frequency)
    # الكلمات الشائعة الاستخدام في عمليات الحقن وسحب البيانات أو تعديلها
    keywords = ["UNION", "SELECT", "INSERT", "UPDATE", "DELETE", "DROP", "EXEC", "OR", "AND", "SLEEP"]
    upper_query = query.upper()
    keywords_count = sum(upper_query.count(kw) for kw in keywords)
    
    # 4. عدد الفراغات أو الرموز (Spaces & Complexity)
    spaces_count = query.count(" ")
    
    # تجميع الميزات في متجهة رقمية واحدة (Feature Vector)
    # الترتيب هنا يجب أن يكون ثابتاً ودقيقاً لأن النموذج سيتدرب عليه بنفس هذا الترتيب
    feature_vector = [
        float(query_length),
        float(special_chars_count),
        float(keywords_count),
        float(spaces_count)
    ]
    
    return feature_vector