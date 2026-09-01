import os
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.tree import DecisionTreeClassifier
from sklearn.neighbors import KNeighborsClassifier
from xgboost import XGBClassifier
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
import joblib

def generate_synthetic_data(num_samples=5000):
    np.random.seed(42)
    
    # Bangalore approximate bounding box
    lat_min, lat_max = 12.90, 13.10
    lon_min, lon_max = 77.50, 77.70
    
    latitudes = np.random.uniform(lat_min, lat_max, num_samples)
    longitudes = np.random.uniform(lon_min, lon_max, num_samples)
    
    areas = ['Downtown', 'Suburbs', 'Industrial Area', 'Residential Area', 'Park/Isolation Zone']
    area_choices = np.random.choice(areas, num_samples)
    
    categories = ['Safe', 'Harassment', 'Theft', 'Stalking', 'Assault']
    category_choices = np.random.choice(categories, num_samples)
    
    hours = np.random.randint(0, 24, num_samples)
    
    data = pd.DataFrame({
        'latitude': latitudes,
        'longitude': longitudes,
        'area': area_choices,
        'hour': hours,
        'crime_category': category_choices
    })
    
    # Calculate synthetic risk score
    # High risk: isolation zones, night hours, severe categories
    risk_scores = []
    for idx, row in data.iterrows():
        score = 0.1  # base risk
        
        # Area factor
        if row['area'] == 'Park/Isolation Zone':
            score += 0.25
        elif row['area'] == 'Industrial Area':
            score += 0.2
        elif row['area'] == 'Downtown':
            score += 0.15
            
        # Hour factor (night is riskier)
        if 22 <= row['hour'] or row['hour'] < 4:
            score += 0.3
        elif 4 <= row['hour'] < 7 or 18 <= row['hour'] < 22:
            score += 0.15
            
        # Category factor
        if row['crime_category'] == 'Assault':
            score += 0.35
        elif row['crime_category'] == 'Stalking':
            score += 0.25
        elif row['crime_category'] == 'Theft':
            score += 0.15
        elif row['crime_category'] == 'Harassment':
            score += 0.2
            
        # Add slight noise
        score += np.random.normal(0, 0.05)
        score = np.clip(score, 0.0, 1.0)
        risk_scores.append(score)
        
    data['risk_score'] = risk_scores
    
    # Classify into risk label: 0=Low, 1=Medium, 2=High
    # Low: < 0.35, Medium: 0.35 to 0.65, High: > 0.65
    labels = []
    for s in risk_scores:
        if s < 0.35:
            labels.append(0)  # Low Risk
        elif s < 0.65:
            labels.append(1)  # Medium Risk
        else:
            labels.append(2)  # High Risk
            
    data['risk_label'] = labels
    return data

def main():
    print("Checking for dataset...")
    dataset_path = 'crime_dataset.csv'
    
    if not os.path.exists(dataset_path):
        print("Generating synthetic crime dataset...")
        df = generate_synthetic_data()
        df.to_csv(dataset_path, index=False)
        print(f"Dataset saved to {dataset_path}")
    else:
        print("Loading existing dataset...")
        df = pd.read_csv(dataset_path)
        
    # Feature Engineering / Preprocessing
    print("Preprocessing data...")
    le_area = LabelEncoder()
    df['area_encoded'] = le_area.fit_transform(df['area'])
    
    le_category = LabelEncoder()
    df['category_encoded'] = le_category.fit_transform(df['crime_category'])
    
    features = ['latitude', 'longitude', 'area_encoded', 'hour', 'category_encoded']
    X = df[features]
    y = df['risk_label']
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Models to compare
    models = {
        'Random Forest': RandomForestClassifier(n_estimators=100, random_state=42),
        'Decision Tree': DecisionTreeClassifier(random_state=42),
        'KNN': KNeighborsClassifier(n_neighbors=5),
        'XGBoost': XGBClassifier(use_label_encoder=False, eval_metric='mlogloss', random_state=42)
    }
    
    best_model_name = None
    best_accuracy = -1
    best_model = None
    
    print("\n--- Training & Model Comparison ---")
    for name, model in models.items():
        model.fit(X_train_scaled, y_train)
        y_pred = model.predict(X_test_scaled)
        acc = accuracy_score(y_test, y_pred)
        print(f"{name} Test Accuracy: {acc:.4f}")
        
        if acc > best_accuracy:
            best_accuracy = acc
            best_model_name = name
            best_model = model
            
    print(f"\nBest Model Chosen: {best_model_name} with Accuracy {best_accuracy:.4f}")
    
    # Generate reports on best model
    best_pred = best_model.predict(X_test_scaled)
    print("\nClassification Report (Best Model):")
    print(classification_report(y_test, best_pred, target_names=['Low Risk', 'Medium Risk', 'High Risk']))
    
    print("\nConfusion Matrix (Best Model):")
    print(confusion_matrix(y_test, best_pred))
    
    # Save best model and pre-processors
    payload = {
        'model': best_model,
        'scaler': scaler,
        'le_area': le_area,
        'le_category': le_category,
        'features': features,
        'model_name': best_model_name,
        'accuracy': best_accuracy
    }
    
    model_path = 'model.pkl'
    joblib.dump(payload, model_path)
    print(f"\nSaved best model and preprocessing objects to {model_path}")

if __name__ == '__main__':
    main()
