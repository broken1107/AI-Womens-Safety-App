<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SosAlert extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'status',
        'start_latitude',
        'start_longitude',
        'current_latitude',
        'current_longitude',
        'verification_code',
        'resolved_at',
    ];

    protected $casts = [
        'start_latitude' => 'double',
        'start_longitude' => 'double',
        'current_latitude' => 'double',
        'current_longitude' => 'double',
        'resolved_at' => 'datetime',
    ];

    protected $appends = [
        'location_url',
    ];

    public function getLocationUrlAttribute(): string
    {
        $lat = $this->current_latitude ?? $this->start_latitude;
        $lon = $this->current_longitude ?? $this->start_longitude;
        return "https://www.google.com/maps?q={$lat},{$lon}";
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function smsLogs()
    {
        return $this->hasMany(SmsLog::class);
    }
}
