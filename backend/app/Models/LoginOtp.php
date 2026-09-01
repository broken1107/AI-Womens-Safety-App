<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Hash;

class LoginOtp extends Model
{
    use HasFactory;

    protected $fillable = [
        'login_challenge_id',
        'user_id',
        'delivery_method',
        'otp_hash',
        'attempts',
        'max_attempts',
        'expires_at',
        'verified_at',
    ];

    protected $hidden = [
        'otp_hash',
    ];

    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
            'verified_at' => 'datetime',
            'attempts' => 'integer',
            'max_attempts' => 'integer',
        ];
    }

    public function challenge(): BelongsTo
    {
        return $this->belongsTo(LoginChallenge::class, 'login_challenge_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isExpired(): bool
    {
        return now()->isAfter($this->expires_at);
    }

    public function isVerified(): bool
    {
        return $this->verified_at !== null;
    }

    public function hasExceededAttempts(): bool
    {
        return $this->attempts >= $this->max_attempts;
    }

    public function verify(string $otp): bool
    {
        return Hash::check($otp, $this->otp_hash);
    }
}
