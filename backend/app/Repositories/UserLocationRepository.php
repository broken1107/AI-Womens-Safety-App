<?php

namespace App\Repositories;

use App\Models\UserLocation;

class UserLocationRepository
{
    public function logLocation($userId, $lat, $lon, $speed = null)
    {
        return UserLocation::create([
            'user_id' => $userId,
            'latitude' => $lat,
            'longitude' => $lon,
            'speed' => $speed,
        ]);
    }

    public function getRecentHistory($userId, $limit = 50)
    {
        return UserLocation::where('user_id', $userId)
            ->orderBy('created_at', 'desc')
            ->limit($limit)
            ->get();
    }
}
