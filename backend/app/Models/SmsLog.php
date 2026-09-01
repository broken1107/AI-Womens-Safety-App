<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SmsLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'sos_alert_id',
        'emergency_contact_id',
        'phone_number',
        'message',
        'status',
        'provider_message_id',
        'error_message',
        'sent_at',
    ];

    protected $casts = [
        'sent_at' => 'datetime',
    ];

    public function sosAlert()
    {
        return $this->belongsTo(SosAlert::class);
    }

    public function emergencyContact()
    {
        return $this->belongsTo(EmergencyContact::class);
    }
}
