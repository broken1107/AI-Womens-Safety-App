<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class IncidentReport extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'title',
        'description',
        'category',
        'area',
        'latitude',
        'longitude',
        'media_url',
        'status',
        'resolved_at',
    ];

    protected $casts = [
        'latitude' => 'double',
        'longitude' => 'double',
        'resolved_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
