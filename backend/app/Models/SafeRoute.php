<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SafeRoute extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'start_latitude',
        'start_longitude',
        'destination_latitude',
        'destination_longitude',
        'distance_km',
        'duration_minutes',
        'polyline',
        'risk_score',
        'risk_level',
    ];

    protected $casts = [
        'start_latitude' => 'double',
        'start_longitude' => 'double',
        'destination_latitude' => 'double',
        'destination_longitude' => 'double',
        'distance_km' => 'double',
        'risk_score' => 'double',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
