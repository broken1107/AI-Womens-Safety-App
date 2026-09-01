<?php

namespace App\Services;

use App\Models\PredictionLog;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PredictionService
{
    private $flaskUrl;

    public function __construct()
    {
        // Default Flask server port
        $this->flaskUrl = config('services.ml_service.url', 'http://127.0.0.1:5000');
    }

    public function predictRisk($userId, $lat, $lon, $area, $hour, $crimeCategory)
    {
        $payload = [
            'latitude' => $lat,
            'longitude' => $lon,
            'area' => $area,
            'hour' => $hour,
            'crime_category' => $crimeCategory,
        ];

        try {
            // Call the python microservice
            $response = Http::timeout(5)->post("{$this->flaskUrl}/predict", $payload);

            if ($response->successful()) {
                $data = $response->json();
                $pred = $data['prediction'];

                // Log the prediction in DB
                PredictionLog::create([
                    'user_id' => $userId,
                    'latitude' => $lat,
                    'longitude' => $lon,
                    'area' => $area,
                    'hour' => $hour,
                    'crime_category' => $crimeCategory,
                    'risk_score' => $pred['risk_score'],
                    'risk_label' => $pred['risk_label'],
                    'recommendation' => $pred['recommendation'],
                ]);

                return $pred;
            }
        } catch (\Exception $e) {
            Log::error("Flask ML Service request failed: " . $e->getMessage());
        }

        // Graceful Local Fallback: when Flask is offline
        $fallback = $this->calculateFallbackRisk($area, $hour, $crimeCategory);

        // Log fallback prediction
        PredictionLog::create([
            'user_id' => $userId,
            'latitude' => $lat,
            'longitude' => $lon,
            'area' => $area,
            'hour' => $hour,
            'crime_category' => $crimeCategory,
            'risk_score' => $fallback['risk_score'],
            'risk_label' => $fallback['risk_label'],
            'recommendation' => $fallback['recommendation'],
        ]);

        return $fallback;
    }

    private function calculateFallbackRisk($area, $hour, $crimeCategory)
    {
        $score = 0.1;

        if ($area === 'Park/Isolation Zone') $score += 0.25;
        elseif ($area === 'Industrial Area') $score += 0.2;
        elseif ($area === 'Downtown') $score += 0.15;

        if ($hour >= 22 || $hour < 4) $score += 0.3;
        elseif ($hour >= 18 || $hour < 7) $score += 0.15;

        if ($crimeCategory === 'Assault') $score += 0.35;
        elseif ($crimeCategory === 'Stalking') $score += 0.25;
        elseif ($crimeCategory === 'Theft') $score += 0.15;
        elseif ($crimeCategory === 'Harassment') $score += 0.2;

        $score = min($score, 1.0);

        if ($score < 0.35) {
            $label = 'Low Risk';
            $rec = "Area appears safe. Normal precautions apply. (Fallback Engine)";
        } elseif ($score < 0.65) {
            $label = 'Medium Risk';
            $rec = "Moderate risk. Travel with a companion if possible, and keep GPS tracking active. (Fallback Engine)";
        } else {
            $label = 'High Risk';
            $rec = "High risk zone detected. Avoid isolated routes, share live tracking, and stay in well-lit areas. (Fallback Engine)";
        }

        return [
            'risk_score' => $score,
            'crime_probability' => $score, // simple proxy
            'risk_label' => $label,
            'recommendation' => $rec,
            'probabilities' => [
                'Low Risk' => $score < 0.35 ? 0.8 : 0.1,
                'Medium Risk' => ($score >= 0.35 && $score < 0.65) ? 0.8 : 0.1,
                'High Risk' => $score >= 0.65 ? 0.8 : 0.1,
            ]
        ];
    }
}
