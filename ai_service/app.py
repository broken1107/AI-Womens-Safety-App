import os
import subprocess
import sys
from flask import Flask, request, jsonify
from predict import predict_risk, get_model

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health():
    try:
        model_payload = get_model()
        return jsonify({
            'status': 'healthy',
            'model_name': model_payload.get('model_name', 'unknown'),
            'accuracy': float(model_payload.get('accuracy', 0.0))
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e)
        }), 500

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Missing request body'}), 400
        
    required_fields = ['latitude', 'longitude', 'area', 'hour', 'crime_category']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'Missing field: {field}'}), 400
            
    try:
        lat = float(data['latitude'])
        lon = float(data['longitude'])
        area = str(data['area']).strip()

        hour_value = data['hour']

        if isinstance(hour_value, str) and ':' in hour_value:
            hour = int(hour_value.split(':')[0])
        else:
            hour = int(hour_value)

        if hour < 0 or hour > 23:
            return jsonify({
                'error': 'Hour must be between 0 and 23'
            }), 400

        crime_cat = str(data['crime_category']).strip()

        prediction = predict_risk(
            lat,
            lon,
            area,
            hour,
            crime_cat
        )

        return jsonify({
            'success': True,
            'prediction': prediction
        }), 200

    except ValueError as ve:
        return jsonify({
            'error': f'Invalid value format: {str(ve)}'
        }), 400

    except FileNotFoundError as fnf:
        return jsonify({
            'error': f'Model not trained yet: {str(fnf)}'
        }), 500

    except Exception as e:
        return jsonify({
            'error': f'Server prediction error: {str(e)}'
        }), 500

@app.route('/train', methods=['POST'])
def train():
    try:
        # Run train.py as a separate process to avoid blocking/state conflicts
        script_path = os.path.join(os.path.dirname(__file__), 'train.py')
        result = subprocess.run([sys.executable, script_path], capture_output=True, text=True, check=True)
        
        # Invalidate model cache after training
        import predict
        predict._model_payload = None
        
        return jsonify({
            'success': True,
            'message': 'Model trained successfully',
            'output': result.stdout
        }), 200
    except subprocess.CalledProcessError as cpe:
        return jsonify({
            'success': False,
            'error': 'Training script execution failed',
            'details': cpe.stderr
        }), 500
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    # Default port for ML service
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
