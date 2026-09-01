<?php

namespace Tests\Feature;

use App\Models\LoginChallenge;
use App\Models\LoginOtp;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class LoginOtpFlowTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::create([
            'name' => 'Koushik Roy',
            'email' => 'koushik@example.com',
            'phone' => '+919876543210',
            'password' => Hash::make('Secret123!'),
            'status' => 'active',
        ]);
    }

    public function test_login_returns_challenge_and_masked_methods(): void
    {
        $response = $this->postJson('/api/login', [
            'email' => 'koushik@example.com',
            'password' => 'Secret123!',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'otp_required' => true,
                'available_methods' => ['email', 'sms'],
                'masked_email' => 'k***@example.com',
                'masked_phone' => '******3210',
            ]);

        $this->assertNotEmpty($response->json('login_challenge_id'));
        $this->assertArrayNotHasKey('access_token', $response->json());
        $this->assertArrayNotHasKey('token', $response->json());
    }

    public function test_login_fails_with_invalid_credentials(): void
    {
        $response = $this->postJson('/api/login', [
            'email' => 'koushik@example.com',
            'password' => 'WrongPassword',
        ]);

        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
                'message' => 'Invalid email or password.',
            ]);
    }

    public function test_send_login_otp_via_email(): void
    {
        $loginRes = $this->postJson('/api/login', [
            'email' => 'koushik@example.com',
            'password' => 'Secret123!',
        ]);

        $challengeId = $loginRes->json('login_challenge_id');

        $otpRes = $this->postJson('/api/send-login-otp', [
            'login_challenge_id' => $challengeId,
            'method' => 'email',
        ]);

        $otpRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'delivery_method' => 'email',
                'masked_destination' => 'k***@example.com',
            ]);

        $this->assertDatabaseHas('login_otps', [
            'user_id' => $this->user->id,
            'delivery_method' => 'email',
        ]);
    }

    public function test_send_login_otp_via_sms(): void
    {
        $loginRes = $this->postJson('/api/login', [
            'email' => 'koushik@example.com',
            'password' => 'Secret123!',
        ]);

        $challengeId = $loginRes->json('login_challenge_id');

        $otpRes = $this->postJson('/api/send-login-otp', [
            'login_challenge_id' => $challengeId,
            'method' => 'sms',
        ]);

        $otpRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'delivery_method' => 'sms',
                'masked_destination' => '******3210',
            ]);

        $this->assertDatabaseHas('login_otps', [
            'user_id' => $this->user->id,
            'delivery_method' => 'sms',
        ]);
    }

    public function test_verify_login_otp_success_issues_token(): void
    {
        $loginRes = $this->postJson('/api/login', [
            'email' => 'koushik@example.com',
            'password' => 'Secret123!',
        ]);

        $challengeId = $loginRes->json('login_challenge_id');

        $this->postJson('/api/send-login-otp', [
            'login_challenge_id' => $challengeId,
            'method' => 'email',
        ]);

        // Manually set a known OTP hash for testing
        $challenge = LoginChallenge::where('challenge_token', $challengeId)->first();
        $otpRecord = LoginOtp::where('login_challenge_id', $challenge->id)->latest()->first();
        $otpRecord->update(['otp_hash' => Hash::make('654321')]);

        $verifyRes = $this->postJson('/api/verify-login-otp', [
            'login_challenge_id' => $challengeId,
            'otp' => '654321',
        ]);

        $verifyRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'OTP verified successfully.',
                'user' => [
                    'id' => $this->user->id,
                    'email' => 'koushik@example.com',
                ],
            ]);

        $this->assertNotEmpty($verifyRes->json('access_token'));
        $this->assertNotEmpty($verifyRes->json('token'));

        $this->assertDatabaseHas('login_challenges', [
            'id' => $challenge->id,
            'status' => 'verified',
        ]);
    }

    public function test_verify_login_otp_fails_with_incorrect_code(): void
    {
        $loginRes = $this->postJson('/api/login', [
            'email' => 'koushik@example.com',
            'password' => 'Secret123!',
        ]);

        $challengeId = $loginRes->json('login_challenge_id');

        $this->postJson('/api/send-login-otp', [
            'login_challenge_id' => $challengeId,
            'method' => 'email',
        ]);

        $verifyRes = $this->postJson('/api/verify-login-otp', [
            'login_challenge_id' => $challengeId,
            'otp' => '000000',
        ]);

        $verifyRes->assertStatus(400)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_resend_login_otp_creates_new_otp(): void
    {
        $loginRes = $this->postJson('/api/login', [
            'email' => 'koushik@example.com',
            'password' => 'Secret123!',
        ]);

        $challengeId = $loginRes->json('login_challenge_id');

        $this->postJson('/api/send-login-otp', [
            'login_challenge_id' => $challengeId,
            'method' => 'sms',
        ]);

        $resendRes = $this->postJson('/api/resend-login-otp', [
            'login_challenge_id' => $challengeId,
        ]);

        $resendRes->assertStatus(200)
            ->assertJson([
                'success' => true,
                'delivery_method' => 'sms',
            ]);
    }
}
