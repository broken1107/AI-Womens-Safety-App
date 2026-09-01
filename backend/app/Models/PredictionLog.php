<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PredictionLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'latitude',
        'longitude',
        'area',
        'hour',
        'crime_category',
        'risk_score',
        'risk_label',
        'recommendation',
    ];

    protected $casts = [
        'latitude' => 'double',
        'longitude' => 'double',
        'risk_score' => 'double',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
