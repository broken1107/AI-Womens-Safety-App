import os
import joblib
import pandas as pd
import numpy as np

# Global model cache
_model_payload = None

def get_model():
    global _model_payload
    if _model_payload is None:
        model_path = os.path.join(os.path.dirname(__file__), 'model.pkl')
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file not found at {model_path}. Please run train.py first.")
        _model_payload = joblib.load(model_path)
    return _model_payload

def predict_risk(latitude, longitude, area, hour, crime_category):
    """
    Predict risk score and safety class.
    Outputs:
        risk_score: float (0.0 to 1.0)
        risk_label: string ('Low Risk', 'Medium Risk', 'High Risk')
        recommendation: string
    """
    payload = get_model()
    model = payload['model']
    scaler = payload['scaler']
    le_area = payload['le_area']
    le_category = payload['le_category']
    
    # Preprocess categorical features safely
    try:
        area_encoded = le_area.transform([area])[0]
    except ValueError:
        # Fallback for unseen areas (e.g. use first class or mode)
        area_encoded = 0
        
    try:
        category_encoded = le_category.transform([crime_category])[0]
    except ValueError:
        # Fallback to 'Safe' or similar if unknown category
        category_encoded = 0

    features_df = pd.DataFrame([{
        'latitude': latitude,
        'longitude': longitude,
        'area_encoded': area_encoded,
        'hour': hour,
        'category_encoded': category_encoded
    }])
    
    # Scale features
    features_scaled = scaler.transform(features_df)
    
    # Predict probabilities and label
    proba = model.predict_proba(features_scaled)[0] # probabilities for class 0, 1, 2
    label_idx = model.predict(features_scaled)[0]
    
    labels = ['Low Risk', 'Medium Risk', 'High Risk']
    risk_label = labels[label_idx]
    
    # Risk Score derived from probability of Medium and High Risk
    # Low=0, Medium=1, High=2
    # Weighted average:
    risk_score = float(0.0 * proba[0] + 0.5 * proba[1] + 1.0 * proba[2])
    
    # Generate recommendations
    if risk_label == 'Low Risk':
        recommendation = "Area appears safe. Normal precautions apply."
    elif risk_label == 'Medium Risk':
        recommendation = "Moderate risk. Travel with a companion if possible, and keep GPS tracking active."
    else:
        recommendation = "High risk zone detected. Avoid isolated routes, share live tracking, and stay in well-lit areas."
        
    return {
        'risk_score': round(risk_score, 4),
        'crime_probability': round(float(proba[label_idx]), 4),
        'risk_label': risk_label,
        'recommendation': recommendation,
        'probabilities': {
            'Low Risk': round(float(proba[0]), 4),
            'Medium Risk': round(float(proba[1]), 4),
            'High Risk': round(float(proba[2]), 4)
        }
    }
