<?php

namespace Database\Seeders;

use App\Models\CrimeData;
use Illuminate\Database\Seeder;

class CrimeDataSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $areas = ['Downtown', 'Suburbs', 'Industrial Area', 'Residential Area', 'Park/Isolation Zone'];
        $categories = ['Safe', 'Harassment', 'Theft', 'Stalking', 'Assault'];
        
        // Seed 100 entries
        for ($i = 0; $i < 100; $i++) {
            $lat = 12.90 + (rand(0, 20000) / 100000);
            $lon = 77.50 + (rand(0, 20000) / 100000);
            $area = $areas[array_rand($areas)];
            $hour = rand(0, 23);
            $category = $categories[array_rand($categories)];

            // Derive score
            $score = 0.1;
            if ($area === 'Park/Isolation Zone') $score += 0.25;
            elseif ($area === 'Industrial Area') $score += 0.2;
            elseif ($area === 'Downtown') $score += 0.15;

            if ($hour >= 22 || $hour < 4) $score += 0.3;
            elseif ($hour >= 18 || $hour < 22) $score += 0.15;

            if ($category === 'Assault') $score += 0.35;
            elseif ($category === 'Stalking') $score += 0.25;
            elseif ($category === 'Theft') $score += 0.15;
            elseif ($category === 'Harassment') $score += 0.2;

            $score = min($score, 1.0);

            if ($score < 0.35) {
                $label = 'Low Risk';
            } elseif ($score < 0.65) {
                $label = 'Medium Risk';
            } else {
                $label = 'High Risk';
            }

            CrimeData::create([
                'latitude' => $lat,
                'longitude' => $lon,
                'area' => $area,
                'hour' => $hour,
                'crime_category' => $category,
                'risk_score' => $score,
                'risk_label' => $label,
            ]);
        }
    }
}
