<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CrimeData extends Model
{
    use HasFactory;

    protected $table = 'crime_data';

    protected $fillable = [
        'latitude',
        'longitude',
        'area',
        'hour',
        'crime_category',
        'risk_score',
        'risk_label',
    ];

    protected $casts = [
        'latitude' => 'double',
        'longitude' => 'double',
        'risk_score' => 'double',
    ];
}
