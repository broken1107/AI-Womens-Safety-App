<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class LoginChallenge extends Model
{
    use HasFactory;

    protected $fillable = [
        'challenge_token',
        'user_id',
        'ip_address',
        'user_agent',
        'status',
        'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function otps(): HasMany
    {
        return $this->hasMany(LoginOtp::class);
    }

    public function latestOtp(): HasOne
    {
        return $this->hasOne(LoginOtp::class)->latestOfMany();
    }

    public function isExpired(): bool
    {
        return now()->isAfter($this->expires_at);
    }

    public function isValid(): bool
    {
        return $this->status === 'pending' && !$this->isExpired();
    }
}
