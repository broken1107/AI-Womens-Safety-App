<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserLocation extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'latitude',
        'longitude',
        'speed',
    ];

    protected $casts = [
        'latitude' => 'double',
        'longitude' => 'double',
        'speed' => 'double',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
