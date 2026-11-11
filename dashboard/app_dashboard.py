# dashboard/app_dashboard.py
import dash
from dash import html, dcc, Input, Output, State
import plotly.express as px
import requests

app = dash.Dash(__name__, title="SecureBank Operations Center / مركز عمليات الأمان")

FASTAPI_URL = "http://127.0.0.1:8000"

# قاموس الترجمات الشامل للنظام (عربي / إنجليزي)
translations = {
    "ar": {
        "dir": "rtl",
        "lang_label": "🌍 لغة العرض:",
        "main_title": "🛡️ منصة الأمان المصرفي والذكاء الاصطناعي الهجين",
        "main_subtitle": "مراقبة التهديدات الأمنية، فحص الاحتيال المالي، وتحليل العلاقات البيانية لحظياً",
        "kpi_1": "إجمالي الاستعلامات المفحوصة",
        "kpi_2": "إجمالي التهديدات المحظورة",
        "kpi_3": "إجمالي المعاملات المالية",
        "kpi_4": "المعاملات الاحتيالية المكتشفة",
        "chart_1_title": "📊 تحليل كفاءة النموذج الهجين لأمن قواعد البيانات",
        "chart_2_title": "📈 علاقة مبلغ المعاملة بدرجة الخطورة والاحتيال",
        "insights_title": "💡 أهم الاستنتاجات والتوصيات الأمنية الآلية",
        "sqli_panel_title": "🔍 اختبار استعلامات قواعد البيانات (خبيث / آمن)",
        "fraud_panel_title": "💳 اختبار المعاملات المالية (احتيال / سليم)",
        "customer_id": "رقم العميل:",
        "query_text": "نص الاستعلام البرمجي:",
        "amount": "مبلغ المعاملة ($):",
        "location": "الموقع الجغرافي:",
        "ip_address": "عنوان الشبكة (IP):",
        "sqli_btn": "فحص الاستعلام الآن",
        "fraud_btn": "فحص المعاملة الآن",
        "safe_sqli": "✅ الاستعلام سليم وآمن تماماً (Benign)",
        "danger_sqli": "🚨 تنبيه: تم اكتشاف وحظر هجوم خبيث (Malicious)",
        "safe_fraud": "✅ المعاملة سليمة ومقبولة (Not Fraud)",
        "danger_fraud": "🚨 تحذير: تم حظر المعاملة لاحتيالها (Fraud)"
    },
    "en": {
        "dir": "ltr",
        "lang_label": "🌍 Language:",
        "main_title": "🛡️ SecureBank AI & Hybrid Security Operations Center",
        "main_subtitle": "Real-time security threat monitoring, fraud detection, and relational analytics",
        "kpi_1": "Total Checked Queries",
        "kpi_2": "Total Blocked Threats",
        "kpi_3": "Total Financial Transactions",
        "kpi_4": "Detected Fraud Transactions",
        "chart_1_title": "📊 Hybrid Model Efficiency & Database Security Analysis",
        "chart_2_title": "📈 Relation Between Transaction Amount & Risk Score",
        "insights_title": "💡 Key Automated Insights & Security Recommendations",
        "sqli_panel_title": "🔍 Database Query Testing (Malicious / Benign)",
        "fraud_panel_title": "💳 Financial Transaction Testing (Fraud / Not Fraud)",
        "customer_id": "Customer ID:",
        "query_text": "SQL Query Text / Payload:",
        "amount": "Transaction Amount ($):",
        "location": "Geographic Location:",
        "ip_address": "IP Address:",
        "sqli_btn": "Analyze Query Now",
        "fraud_btn": "Check Transaction Now",
        "safe_sqli": "✅ Benign Query (Safe & Secure)",
        "danger_sqli": "🚨 Malicious Threat Detected & Blocked",
        "safe_fraud": "✅ Benign Transaction (Approved)",
        "danger_fraud": "🚨 Fraud Transaction Blocked!"
    }
}

# الهيكل الأساسي للوحة التحكم
app.layout = html.Div(id="main-container", style={
    "fontFamily": "Cairo, Segoe UI, Tahoma, sans-serif", 
    "backgroundColor": "#f1f5f9", 
    "padding": "25px",
    "minHeight": "100vh"
}, children=[
    
    # شريط اختيار اللغة العلوي
    html.Div(style={"display": "flex", "justifyContent": "flex-end", "marginBottom": "15px"}, children=[
        html.Div(style={"backgroundColor": "white", "padding": "8px 15px", "borderRadius": "8px", "boxShadow": "0 2px 4px rgba(0,0,0,0.05)", "display": "flex", "alignItems": "center", "gap": "10px"}, children=[
            html.Span(id="lang-label-text", children="🌍 لغة العرض:", style={"fontWeight": "600", "fontSize": "13px", "color": "#334155"}),
            dcc.Dropdown(
                id="language-dropdown",
                options=[
                    {"label": "العربية", "value": "ar"},
                    {"label": "English", "value": "en"}
                ],
                value="ar",
                clearable=False,
                style={"width": "120px"}
            )
        ])
    ]),
    
    # رأس الصفحة (Header)
    html.Div(style={"textAlign": "center", "marginBottom": "30px", "backgroundColor": "white", "padding": "20px", "borderRadius": "12px", "boxShadow": "0 2px 4px rgba(0,0,0,0.05)"}, children=[
        html.H1(id="header-title", style={"color": "#0f172a", "fontWeight": "700", "fontSize": "26px"}),
        html.P(id="header-subtitle", style={"color": "#64748b", "fontSize": "15px", "marginTop": "5px"})
    ]),
    
    # 1. لوحة المؤشرات الحيوية (KPI Cards)
    html.Div(style={"display": "grid", "gridTemplateColumns": "repeat(auto-fit, minmax(220px, 1fr))", "gap": "20px", "marginBottom": "30px"}, children=[
        html.Div(style={"backgroundColor": "white", "padding": "20px", "borderRadius": "10px", "boxShadow": "0 2px 4px rgba(0,0,0,0.05)", "borderRight": "5px solid #2563eb"}, children=[
            html.H4(id="kpi-1-title", style={"color": "#64748b", "fontSize": "14px", "margin": "0"}),
            html.H2(id="kpi-total-queries", children="0", style={"color": "#1e293b", "margin": "10px 0 0 0"})
        ]),
        html.Div(style={"backgroundColor": "white", "padding": "20px", "borderRadius": "10px", "boxShadow": "0 2px 4px rgba(0,0,0,0.05)", "borderRight": "5px solid #dc2626"}, children=[
            html.H4(id="kpi-2-title", style={"color": "#64748b", "fontSize": "14px", "margin": "0"}),
            html.H2(id="kpi-total-threats", children="0", style={"color": "#dc2626", "margin": "10px 0 0 0"})
        ]),
        html.Div(style={"backgroundColor": "white", "padding": "20px", "borderRadius": "10px", "boxShadow": "0 2px 4px rgba(0,0,0,0.05)", "borderRight": "5px solid #059669"}, children=[
            html.H4(id="kpi-3-title", style={"color": "#64748b", "fontSize": "14px", "margin": "0"}),
            html.H2(id="kpi-total-transactions", children="0", style={"color": "#059669", "margin": "10px 0 0 0"})
        ]),
        html.Div(style={"backgroundColor": "white", "padding": "20px", "borderRadius": "10px", "boxShadow": "0 2px 4px rgba(0,0,0,0.05)", "borderRight": "5px solid #d97706"}, children=[
            html.H4(id="kpi-4-title", style={"color": "#64748b", "fontSize": "14px", "margin": "0"}),
            html.H2(id="kpi-total-frauds", children="0", style={"color": "#d97706", "margin": "10px 0 0 0"})
        ]),
    ]),

    # 2. قسم التحليلات والرسوم البيانية وعلاقات المتغيرات
    html.Div(style={"display": "grid", "gridTemplateColumns": "repeat(auto-fit, minmax(500px, 1fr))", "gap": "25px", "marginBottom": "30px"}, children=[
        html.Div(style={"backgroundColor": "white", "padding": "20px", "borderRadius": "12px", "boxShadow": "0 2px 4px rgba(0,0,0,0.05)"}, children=[
            html.H3(id="chart-1-title", style={"color": "#1e293b", "fontSize": "16px", "marginBottom": "15px"}),
            dcc.Graph(id="chart-sqli-distribution")
        ]),
        html.Div(style={"backgroundColor": "white", "padding": "20px", "borderRadius": "12px", "boxShadow": "0 2px 4px rgba(0,0,0,0.05)"}, children=[
            html.H3(id="chart-2-title", style={"color": "#1e293b", "fontSize": "16px", "marginBottom": "15px"}),
            dcc.Graph(id="chart-fraud-relation")
        ])
    ]),

    # 3. قسم الاستنتاجات والتوصيات الذكية
    html.Div(style={"backgroundColor": "white", "padding": "25px", "borderRadius": "12px", "boxShadow": "0 2px 4px rgba(0,0,0,0.05)", "marginBottom": "30px"}, children=[
        html.H3(id="insights-header", style={"color": "#1e293b", "fontSize": "18px", "marginBottom": "15px", "borderBottom": "2px solid #e2e8f0", "paddingBottom": "8px"}),
        html.Div(id="insights-container", style={"color": "#334155", "fontSize": "14px", "lineHeight": "1.8"})
    ]),

    # 4. أدوات الاختبار التفاعلي الحي
    html.Div(style={"display": "grid", "gridTemplateColumns": "repeat(auto-fit, minmax(500px, 1fr))", "gap": "25px"}, children=[
        
        # اختبار استعلامات SQLi
        html.Div(style={"backgroundColor": "white", "padding": "25px", "borderRadius": "12px", "boxShadow": "0 2px 4px rgba(0,0,0,0.05)"}, children=[
            html.H3(id="sqli-panel-title", style={"color": "#1e293b", "fontSize": "16px", "marginBottom": "10px"}),
            html.Label(id="label-cid-1", children="رقم العميل:", style={"fontWeight": "600", "display": "block", "marginBottom": "5px"}),
            dcc.Input(id="sqli-customer-id", type="number", value=1, style={"width": "100%", "padding": "10px", "borderRadius": "6px", "border": "1px solid #cbd5e1", "marginBottom": "15px"}),
            
            html.Label(id="label-qtext", children="نص الاستعلام البرمجي:", style={"fontWeight": "600", "display": "block", "marginBottom": "5px"}),
            dcc.Textarea(id="sqli-query-text", value="SELECT * FROM users WHERE id = 1 OR 1=1 --", style={"width": "100%", "height": "90px", "padding": "10px", "borderRadius": "6px", "border": "1px solid #cbd5e1", "marginBottom": "15px", "fontFamily": "monospace"}),
            
            html.Button(id="sqli-btn", children="فحص الاستعلام الآن", n_clicks=0, style={"backgroundColor": "#2563eb", "color": "white", "border": "none", "padding": "12px", "borderRadius": "6px", "cursor": "pointer", "fontWeight": "bold", "width": "100%"}),
            html.Div(id="sqli-result-output", style={"marginTop": "15px"})
        ]),
        
        # اختبار المعاملات المالية
        html.Div(style={"backgroundColor": "white", "padding": "25px", "borderRadius": "12px", "boxShadow": "0 2px 4px rgba(0,0,0,0.05)"}, children=[
            html.H3(id="fraud-panel-title", style={"color": "#1e293b", "fontSize": "16px", "marginBottom": "10px"}),
            html.Div(style={"display": "flex", "gap": "10px", "marginBottom": "15px"}, children=[
                html.Div(style={"flex": "1"}, children=[
                    html.Label(id="label-cid-2", children="رقم العميل:", style={"fontWeight": "600", "display": "block", "marginBottom": "5px"}),
                    dcc.Input(id="fraud-customer-id", type="number", value=1, style={"width": "100%", "padding": "10px", "borderRadius": "6px", "border": "1px solid #cbd5e1"})
                ]),
                html.Div(style={"flex": "1"}, children=[
                    html.Label(id="label-amt", children="مبلغ المعاملة ($):", style={"fontWeight": "600", "display": "block", "marginBottom": "5px"}),
                    dcc.Input(id="fraud-amount", type="number", value=75000.0, style={"width": "100%", "padding": "10px", "borderRadius": "6px", "border": "1px solid #cbd5e1"})
                ])
            ]),
            
            html.Label(id="label-loc", children="الموقع الجغرافي:", style={"fontWeight": "600", "display": "block", "marginBottom": "5px"}),
            dcc.Input(id="fraud-location", type="text", value="Unknown-IP-Region", style={"width": "100%", "padding": "10px", "borderRadius": "6px", "border": "1px solid #cbd5e1", "marginBottom": "15px"}),
            
            html.Label(id="label-ip", children="عنوان الشبكة (IP):", style={"fontWeight": "600", "display": "block", "marginBottom": "5px"}),
            dcc.Input(id="fraud-ip", type="text", value="192.168.1.50", style={"width": "100%", "padding": "10px", "borderRadius": "6px", "border": "1px solid #cbd5e1", "marginBottom": "15px"}),
            
            html.Button(id="fraud-btn", children="فحص المعاملة الآن", n_clicks=0, style={"backgroundColor": "#dc2626", "color": "white", "border": "none", "padding": "12px", "borderRadius": "6px", "cursor": "pointer", "fontWeight": "bold", "width": "100%"}),
            html.Div(id="fraud-result-output", style={"marginTop": "15px"})
        ])
    ])
])

# -------------------------------------------------------------
# دالة موحدة لتحديث كافة النصوص، الاتجاهات، والرسوم البيانية عند تغيير اللغة
# -------------------------------------------------------------
@app.callback(
    [
        Output("main-container", "style"),
        Output("header-title", "children"),
        Output("header-subtitle", "children"),
        Output("kpi-1-title", "children"),
        Output("kpi-2-title", "children"),
        Output("kpi-3-title", "children"),
        Output("kpi-4-title", "children"),
        Output("chart-1-title", "children"),
        Output("chart-2-title", "children"),
        Output("insights-header", "children"),
        Output("sqli-panel-title", "children"),
        Output("fraud-panel-title", "children"),
        Output("label-cid-1", "children"),
        Output("label-cid-2", "children"),
        Output("label-qtext", "children"),
        Output("label-amt", "children"),
        Output("label-loc", "children"),
        Output("label-ip", "children"),
        Output("sqli-btn", "children"),
        Output("fraud-btn", "children"),
        Output("kpi-total-queries", "children"),
        Output("kpi-total-threats", "children"),
        Output("kpi-total-transactions", "children"),
        Output("kpi-total-frauds", "children"),
        Output("chart-sqli-distribution", "figure"),
        Output("chart-fraud-relation", "figure"),
        Output("insights-container", "children")
    ],
    [
        Input("language-dropdown", "value"),
        Input("sqli-btn", "n_clicks"),
        Input("fraud-btn", "n_clicks")
    ]
)
def update_entire_dashboard(lang, n1, n2):
    t = translations.get(lang, translations["ar"])
    
    # تحديث تنسيق الاتجاه (RTL للعربية و LTR للإنجليزية)
    container_style = {
        "fontFamily": "Cairo, Segoe UI, Tahoma, sans-serif", 
        "backgroundColor": "#f1f5f9", 
        "padding": "25px",
        "minHeight": "100vh",
        "direction": t["dir"]
    }
    
    # جلب الإحصائيات الحية من الـ Backend
    try:
        res = requests.get(f"{FASTAPI_URL}/api/v1/analytics/summary").json()
    except:
        res = {"total_queries": 0, "total_threats": 0, "total_transactions": 0, "total_frauds": 0}
        
    t_q = res.get("total_queries", 0)
    t_t = res.get("total_threats", 0)
    t_tr = res.get("total_transactions", 0)
    t_f = res.get("total_frauds", 0)
    
    # الرسوم البيانية مع دعم اللغات
    safe_label = "Benign Queries" if lang == "en" else "استعلامات سليمة (آمنة)"
    threat_label = "Blocked Threats" if lang == "en" else "تهديدات محظورة (خبيثة)"
    
    fig_sqli = px.bar(
        x=[safe_label, threat_label],
        y=[max(0, t_q - t_t), t_t],
        color=[safe_label, threat_label],
        color_discrete_map={safe_label: "#059669", threat_label: "#dc2626"}
    )
    fig_sqli.update_layout(margin=dict(t=20, b=20, l=20, r=20), paper_bgcolor="white", plot_bgcolor="white")

    normal_trans = "Approved Transactions" if lang == "en" else "معاملات مقبولة (سليمة)"
    fraud_trans = "Detected Frauds" if lang == "en" else "محاولات احتيال مرصودة"
    
    fig_fraud = px.bar(
        x=[normal_trans, fraud_trans],
        y=[max(0, t_tr - t_f), t_f],
        color=[normal_trans, fraud_trans],
        color_discrete_map={normal_trans: "#2563eb", fraud_trans: "#d97706"}
    )
    fig_fraud.update_layout(margin=dict(t=20, b=20, l=20, r=20), paper_bgcolor="white", plot_bgcolor="white")

    # الاستنتاجات الذكية مترجمة
    threat_ratio = (t_t / t_q * 100) if t_q > 0 else 0
    fraud_ratio = (t_f / t_tr * 100) if t_tr > 0 else 0
    
    if lang == "en":
        insights = [
            html.P(f"• Database intrusion attempts reached ({round(threat_ratio, 1)}%) of total monitored queries, verifying hybrid model efficiency."),
            html.P(f"• Recorded financial fraud transactions reached ({round(fraud_ratio, 1)}%), focusing on high amounts from untrusted regions."),
            html.P("• Security Recommendation: Continue feeding the 'Isolation Forest' model with additional anomaly patterns to catch zero-day threats.")
        ]
    else:
        insights = [
            html.P(f"• معدل محاولات الاختراق عبر قواعد البيانات بلغ ({round(threat_ratio, 1)}%) من إجمالي الاستعلامات المرصودة، مما يؤكد فعالية النموذج الهجين."),
            html.P(f"• نسبة المعاملات المالية الاحتيالية المسجلة وصلت إلى ({round(fraud_ratio, 1)}%)، مع التركيز على المبالغ الضخمة الواردة من مناطق غير موثوقة."),
            html.P("• التوصية الأمنية: الاستمرار في تغذية خوارزمية 'Isolation Forest' بأنماط بيانات إضافية لرفع دقة اكتشاف التهديدات المستحدثة.")
        ]

    return (
        container_style,
        t["main_title"], t["main_subtitle"],
        t["kpi_1"], t["kpi_2"], t["kpi_3"], t["kpi_4"],
        t["chart_1_title"], t["chart_2_title"], t["insights_title"],
        t["sqli_panel_title"], t["fraud_panel_title"],
        t["customer_id"], t["customer_id"], t["query_text"],
        t["amount"], t["location"], t["ip_address"],
        t["sqli_btn"], t["fraud_btn"],
        str(t_q), str(t_t), str(t_tr), str(t_f),
        fig_sqli, fig_fraud, insights
    )

# الدوال التفاعلية لاختبار الاستعلامات والمعاملات
@app.callback(
    Output("sqli-result-output", "children"),
    Input("sqli-btn", "n_clicks"),
    State("sqli-customer-id", "value"),
    State("sqli-query-text", "value"),
    State("language-dropdown", "value"),
    prevent_initial_call=True
)
def handle_sqli(n, cid, qtext, lang):
    try:
        res = requests.post(f"{FASTAPI_URL}/api/v1/security/check-sqli", json={"customer_id": int(cid), "query_text": qtext}).json()
        is_att = res.get("is_attack", False)
        t = translations[lang]
        bg = "#fef2f2" if is_att else "#f0fdf4"
        color = "#991b1b" if is_att else "#166534"
        title = t["danger_sqli"] if is_att else t["safe_sqli"]
        return html.Div(style={"backgroundColor": bg, "padding": "12px", "borderRadius": "6px", "border": f"1px solid {color}"}, children=[
            html.H5(title, style={"color": color, "margin": "0 0 5px 0"}),
            html.P(f"Risk Score: {res.get('risk_score')} | Engine: {res.get('engine_used')}", style={"margin": "0", "fontSize": "13px"})
        ])
    except Exception as e:
        return html.Div(f"Error: {str(e)}", style={"color": "red"})

@app.callback(
    Output("fraud-result-output", "children"),
    Input("fraud-btn", "n_clicks"),
    State("fraud-customer-id", "value"),
    State("fraud-amount", "value"),
    State("fraud-location", "value"),
    State("fraud-ip", "value"),
    State("language-dropdown", "value"),
    prevent_initial_call=True
)
def handle_fraud(n, cid, amt, loc, ip, lang):
    try:
        res = requests.post(f"{FASTAPI_URL}/api/v1/fraud/check-transaction", json={"customer_id": int(cid), "amount": float(amt), "location": str(loc), "ip_address": str(ip)}).json()
        is_fr = res.get("is_fraud", False)
        t = translations[lang]
        bg = "#fef2f2" if is_fr else "#f0fdf4"
        color = "#991b1b" if is_fr else "#166534"
        title = t["danger_fraud"] if is_fr else t["safe_fraud"]
        reasons = res.get("audit_details", {}).get("reasons", [])
        return html.Div(style={"backgroundColor": bg, "padding": "12px", "borderRadius": "6px", "border": f"1px solid {color}"}, children=[
            html.H5(title, style={"color": color, "margin": "0 0 5px 0"}),
            html.P(f"Risk Score: {res.get('risk_score')} | Reasons: {', '.join(reasons)}", style={"margin": "0", "fontSize": "13px"})
        ])
    except Exception as e:
        return html.Div(f"Error: {str(e)}", style={"color": "red"})

if __name__ == "__main__":
    app.run(debug=True, port=8050)