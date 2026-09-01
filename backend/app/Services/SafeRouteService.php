<?php

namespace App\Services;

use App\Models\SafeRoute;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class SafeRouteService
{
    protected $predictionService;
    protected $googleApiKey;

    public function __construct(PredictionService $predictionService)
    {
        $this->predictionService = $predictionService;
        $this->googleApiKey = config('services.google.maps_api_key', env('GOOGLE_MAPS_API_KEY'));
    }

    public function getSafeRoutes($userId, $startLat, $startLon, $destLat, $destLon)
    {
        // 1. Fetch directions from Google Directions API
        // If Google Key is missing, or request fails, we fall back to a mock routing response
        $routes = [];
        
        if ($this->googleApiKey) {
            try {
                $response = Http::get('https://maps.googleapis.com/maps/api/directions/json', [
                    'origin' => "{$startLat},{$startLon}",
                    'destination' => "{$destLat},{$destLon}",
                    'alternatives' => 'true',
                    'key' => $this->googleApiKey,
                ]);

                if ($response->successful()) {
                    $json = $response->json();
                    $routes = $json['routes'] ?? [];
                }
            } catch (\Exception $e) {
                Log::error("Google Directions API failed: " . $e->getMessage());
            }
        }

        // 2. If no routes fetched, build Mock routes for testing/demo
        if (empty($routes)) {
            Log::info("Using mock routes for safe route recommendations.");
            $routes = $this->getMockGoogleRoutes($startLat, $startLon, $destLat, $destLon);
        }

        $processedRoutes = [];
        $recommendedIndex = 0;
        $lowestRiskScore = 9999.0;

        foreach ($routes as $index => $route) {
            $leg = $route['legs'][0];
            $distanceKm = ($leg['distance']['value'] ?? 0) / 1000.0;
            $durationMin = intval(round(($leg['duration']['value'] ?? 0) / 60.0));
            $polyline = $route['overview_polyline']['points'] ?? '';

            // Sample lat/lon coordinates from steps to evaluate risk
            $coordinates = $this->decodePolyline($polyline);
            $sampledCoords = $this->sampleCoordinates($coordinates, 5); // sample up to 5 points

            // Assess average risk score
            $totalRisk = 0.0;
            $sampleCount = count($sampledCoords);
            $hour = intval(date('H'));

            foreach ($sampledCoords as $coord) {
                // Query prediction service (hour, category as 'Safe' for routing purposes)
                $pred = $this->predictionService->predictRisk($userId, $coord['lat'], $coord['lon'], 'Downtown', $hour, 'Safe');
                $totalRisk += $pred['risk_score'];
            }

            $avgRisk = $sampleCount > 0 ? ($totalRisk / $sampleCount) : 0.1;

            if ($avgRisk < 0.35) {
                $riskLevel = 'Low';
                $warnings = [];
            } elseif ($avgRisk < 0.65) {
                $riskLevel = 'Medium';
                $warnings = ['Route passes near crime-prone zones. Travel with caution.'];
            } else {
                $riskLevel = 'High';
                $warnings = ['Avoid this route if traveling alone at night. High crime density detected nearby.'];
            }

            $processedRoutes[] = [
                'polyline' => $polyline,
                'distance_km' => $distanceKm,
                'duration_minutes' => $durationMin,
                'average_risk_score' => $avgRisk,
                'risk_level' => $riskLevel,
                'warnings' => $warnings,
            ];

            // Safest route is chosen
            if ($avgRisk < $lowestRiskScore) {
                $lowestRiskScore = $avgRisk;
                $recommendedIndex = $index;
            }

            // Save in database
            SafeRoute::create([
                'user_id' => $userId,
                'start_latitude' => $startLat,
                'start_longitude' => $startLon,
                'destination_latitude' => $destLat,
                'destination_longitude' => $destLon,
                'distance_km' => $distanceKm,
                'duration_minutes' => $durationMin,
                'polyline' => $polyline,
                'risk_score' => $avgRisk,
                'risk_level' => $riskLevel,
            ]);
        }

        return [
            'routes' => $processedRoutes,
            'recommended_index' => $recommendedIndex,
        ];
    }

    private function sampleCoordinates($coords, $numSamples)
    {
        $count = count($coords);
        if ($count <= $numSamples) {
            return $coords;
        }

        $samples = [];
        $step = intval($count / $numSamples);
        for ($i = 0; $i < $numSamples; $i++) {
            $samples[] = $coords[$i * $step];
        }
        // Always include last coordinate
        if (!in_array($coords[$count - 1], $samples)) {
            $samples[] = $coords[$count - 1];
        }

        return $samples;
    }

    /**
     * Decodes a Google overview polyline string into coordinates list.
     */
    private function decodePolyline($encoded)
    {
        $length = strlen($encoded);
        $index = 0;
        $points = [];
        $lat = 0;
        $lng = 0;

        while ($index < $length) {
            $b = 0;
            $shift = 0;
            $result = 0;
            do {
                $b = ord($encoded[$index++]) - 63;
                $result |= ($b & 0x1f) << $shift;
                $shift += 5;
            } while ($b >= 0x20);
            $dlat = (($result & 1) ? ~($result >> 1) : ($result >> 1));
            $lat += $dlat;

            $shift = 0;
            $result = 0;
            do {
                $b = ord($encoded[$index++]) - 63;
                $result |= ($b & 0x1f) << $shift;
                $shift += 5;
            } while ($b >= 0x20);
            $dlng = (($result & 1) ? ~($result >> 1) : ($result >> 1));
            $lng += $dlng;

            $points[] = [
                'lat' => $lat * 1e-5,
                'lon' => $lng * 1e-5,
            ];
        }

        return $points;
    }

    private function getMockGoogleRoutes($startLat, $startLon, $destLat, $destLon)
    {
        // Simple straight polyline strings
        return [
            [
                'legs' => [
                    [
                        'distance' => ['value' => 5200], // 5.2 km
                        'duration' => ['value' => 720], // 12 mins
                    ]
                ],
                'overview_polyline' => [
                    // Mock encoded polyline
                    'points' => '_p~iF~ps|U_ulLnnqC_ga|@ntxF'
                ]
            ],
            [
                'legs' => [
                    [
                        'distance' => ['value' => 6400], // 6.4 km
                        'duration' => ['value' => 960], // 16 mins
                    ]
                ],
                'overview_polyline' => [
                    'points' => '_p~iF~ps|U_a~L__qC_hb|@_txF'
                ]
            ]
        ];
    }
}
