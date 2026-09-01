<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LoginChallenge;
use App\Models\LoginOtp;
use App\Repositories\UserRepository;
use App\Services\BrevoService;
use App\Services\SmsHorizonService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    protected UserRepository $userRepository;
    protected BrevoService $brevoService;
    protected SmsHorizonService $smsHorizonService;

    public function __construct(
        UserRepository $userRepository,
        BrevoService $brevoService,
        SmsHorizonService $smsHorizonService
    ) {
        $this->userRepository = $userRepository;
        $this->brevoService = $brevoService;
        $this->smsHorizonService = $smsHorizonService;
    }

    /**
     * User registration with verification OTP.
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'phone' => 'required|string|max:15|unique:users',
            'password' => 'required|string|min:8',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        // Generate 6 digit verification OTP
        $otp = strval(random_int(100000, 999999));
        $otpExpiresAt = now()->addMinutes(10);

        $user = $this->userRepository->create([
            'name' => $request->name,
            'email' => $request->email,
            'phone' => $request->phone,
            'password' => Hash::make($request->password),
            'otp_code' => $otp,
            'otp_expires_at' => $otpExpiresAt,
            'status' => 'pending', // awaits OTP activation
        ]);

        Log::info("User registration completed for {$user->phone}. Verification OTP created.");

        return response()->json([
            'success' => true,
            'message' => 'Registration successful! Verification OTP sent.',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'status' => $user->status,
            ],
        ], 201);
    }

    /**
     * Initial login request: Validates credentials and creates temporary login challenge.
     * Does NOT issue the final token or send OTP immediately.
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $user = $this->userRepository->findByEmail($request->email);

        // Security against enumeration: generic error message
        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid email or password.',
            ], 401);
        }

        if ($user->status === 'suspended') {
            return response()->json([
                'success' => false,
                'message' => 'Your account has been suspended by an administrator.',
            ], 403);
        }

        // Determine available OTP delivery channels
        $hasEmail = !empty($user->email) && filter_var($user->email, FILTER_VALIDATE_EMAIL);
        $cleanPhone = preg_replace('/\D/', '', (string) $user->phone);
        $hasPhone = !empty($cleanPhone) && strlen($cleanPhone) >= 10;

        $availableMethods = [];
        if ($hasEmail) {
            $availableMethods[] = 'email';
        }
        if ($hasPhone) {
            $availableMethods[] = 'sms';
        }

        if (empty($availableMethods)) {
            return response()->json([
                'success' => false,
                'message' => 'No verified email or phone number is available for OTP verification. Please contact support.',
            ], 422);
        }

        // Create secure temporary login challenge (valid for 15 minutes)
        $challengeToken = Str::random(48);
        $challenge = LoginChallenge::create([
            'challenge_token' => $challengeToken,
            'user_id' => $user->id,
            'ip_address' => $request->ip(),
            'user_agent' => substr((string) $request->userAgent(), 0, 500),
            'status' => 'pending',
            'expires_at' => now()->addMinutes(15),
        ]);

        return response()->json([
            'success' => true,
            'otp_required' => true,
            'login_challenge_id' => $challenge->challenge_token,
            'available_methods' => $availableMethods,
            'masked_email' => $hasEmail ? $this->maskEmail($user->email) : null,
            'masked_phone' => $hasPhone ? $this->maskPhone($user->phone) : null,
        ], 200);
    }

    /**
     * Dispatch login OTP via user-selected method (email or sms).
     */
    public function sendLoginOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'login_challenge_id' => 'required|string',
            'method' => 'required|string|in:email,sms',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $challenge = LoginChallenge::where('challenge_token', $request->login_challenge_id)
            ->with('user')
            ->first();

        if (!$challenge || !$challenge->isValid()) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired login session. Please sign in again.',
            ], 400);
        }

        $user = $challenge->user;
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Associated user account not found.',
            ], 404);
        }

        $method = strtolower($request->method);

        // Verify channel availability
        if ($method === 'email' && (empty($user->email) || !filter_var($user->email, FILTER_VALIDATE_EMAIL))) {
            return response()->json([
                'success' => false,
                'message' => 'Email is not available for this account. Please choose SMS.',
                'can_change_method' => true,
            ], 422);
        }

        $cleanPhone = preg_replace('/\D/', '', (string) $user->phone);
        if ($method === 'sms' && (empty($cleanPhone) || strlen($cleanPhone) < 10)) {
            return response()->json([
                'success' => false,
                'message' => 'Phone number is not available for this account. Please choose Email.',
                'can_change_method' => true,
            ], 422);
        }

        // Invalidate previous active OTPs for this challenge
        LoginOtp::where('login_challenge_id', $challenge->id)->delete();

        // Generate cryptographically secure 6-digit OTP
        $otp = str_pad((string) random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
        $otpHash = Hash::make($otp);

        $loginOtp = LoginOtp::create([
            'login_challenge_id' => $challenge->id,
            'user_id' => $user->id,
            'delivery_method' => $method,
            'otp_hash' => $otpHash,
            'attempts' => 0,
            'max_attempts' => 5,
            'expires_at' => now()->addMinutes(5),
        ]);

        // Send OTP via chosen delivery provider
        if ($method === 'email') {
            $dispatchResult = $this->brevoService->sendOtpEmail($user->email, $user->name, $otp);
            if (!$dispatchResult['success']) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unable to send OTP using Email. Please choose another verification method.',
                    'can_change_method' => true,
                ], 502);
            }
            $maskedDestination = $this->maskEmail($user->email);
        } else {
            $dispatchResult = $this->smsHorizonService->sendOtpSms($user->phone, $otp);
            if (!$dispatchResult['success']) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unable to send OTP using SMS. Please choose another verification method.',
                    'can_change_method' => true,
                ], 502);
            }
            $maskedDestination = $this->maskPhone($user->phone);
        }

        return response()->json([
            'success' => true,
            'message' => 'Verification code sent successfully.',
            'delivery_method' => $method,
            'masked_destination' => $maskedDestination,
            'expires_in_seconds' => 300,
        ], 200);
    }

    /**
     * Verify login OTP and issue final Sanctum authentication token.
     */
    public function verifyLoginOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'login_challenge_id' => 'required|string',
            'otp' => 'required|string|size:6',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $challenge = LoginChallenge::where('challenge_token', $request->login_challenge_id)
            ->with('user')
            ->first();

        if (!$challenge || $challenge->status !== 'pending' || $challenge->isExpired()) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired login session. Please sign in again.',
            ], 400);
        }

        $user = $challenge->user;
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Associated user not found.',
            ], 404);
        }

        $otpRecord = LoginOtp::where('login_challenge_id', $challenge->id)
            ->whereNull('verified_at')
            ->latest()
            ->first();

        if (!$otpRecord) {
            return response()->json([
                'success' => false,
                'message' => 'No active verification code found. Please request a new code.',
            ], 400);
        }

        if ($otpRecord->isExpired()) {
            return response()->json([
                'success' => false,
                'message' => 'The verification code has expired. Please request a new code.',
                'is_expired' => true,
            ], 400);
        }

        if ($otpRecord->hasExceededAttempts()) {
            return response()->json([
                'success' => false,
                'message' => 'Too many incorrect attempts. Please request a new code.',
                'is_locked' => true,
            ], 400);
        }

        // Verify OTP Hash securely
        if (!$otpRecord->verify($request->otp)) {
            $otpRecord->increment('attempts');
            $remaining = max(0, $otpRecord->max_attempts - $otpRecord->attempts);

            if ($remaining === 0) {
                return response()->json([
                    'success' => false,
                    'message' => 'Too many incorrect attempts. Please request a new code.',
                    'is_locked' => true,
                ], 400);
            }

            return response()->json([
                'success' => false,
                'message' => "Incorrect verification code. {$remaining} attempts remaining.",
            ], 400);
        }

        // Mark OTP & challenge verified
        $otpRecord->update(['verified_at' => now()]);
        $challenge->update(['status' => 'verified']);

        if ($user->status === 'pending') {
            $user->update([
                'status' => 'active',
                'email_verified_at' => now(),
            ]);
        }

        // Issue Sanctum Authentication Token
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'OTP verified successfully.',
            'access_token' => $token,
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'status' => $user->status,
            ],
        ], 200);
    }

    /**
     * Resend login OTP using the previously selected delivery channel.
     */
    public function resendLoginOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'login_challenge_id' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $challenge = LoginChallenge::where('challenge_token', $request->login_challenge_id)
            ->with('user')
            ->first();

        if (!$challenge || !$challenge->isValid()) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired login session. Please sign in again.',
            ], 400);
        }

        $user = $challenge->user;
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Associated user not found.',
            ], 404);
        }

        // Find previous delivery method
        $previousOtp = LoginOtp::where('login_challenge_id', $challenge->id)->latest()->first();
        $method = $previousOtp ? $previousOtp->delivery_method : 'email';

        // Invalidate old OTP
        LoginOtp::where('login_challenge_id', $challenge->id)->delete();

        // Generate new secure 6-digit OTP
        $otp = str_pad((string) random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
        $otpHash = Hash::make($otp);

        LoginOtp::create([
            'login_challenge_id' => $challenge->id,
            'user_id' => $user->id,
            'delivery_method' => $method,
            'otp_hash' => $otpHash,
            'attempts' => 0,
            'max_attempts' => 5,
            'expires_at' => now()->addMinutes(5),
        ]);

        if ($method === 'email') {
            $dispatchResult = $this->brevoService->sendOtpEmail($user->email, $user->name, $otp);
            if (!$dispatchResult['success']) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unable to send OTP using Email. Please choose another verification method.',
                    'can_change_method' => true,
                ], 502);
            }
            $maskedDestination = $this->maskEmail($user->email);
        } else {
            $dispatchResult = $this->smsHorizonService->sendOtpSms($user->phone, $otp);
            if (!$dispatchResult['success']) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unable to send OTP using SMS. Please choose another verification method.',
                    'can_change_method' => true,
                ], 502);
            }
            $maskedDestination = $this->maskPhone($user->phone);
        }

        return response()->json([
            'success' => true,
            'message' => 'A new verification code has been sent.',
            'delivery_method' => $method,
            'masked_destination' => $maskedDestination,
            'expires_in_seconds' => 300,
        ], 200);
    }

    /**
     * Backward-compatible registration OTP verification endpoint.
     */
    public function verifyOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|string|email',
            'otp' => 'required|string|size:6',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $user = $this->userRepository->findByEmail($request->email);

        if (!$user) {
            return response()->json(['success' => false, 'message' => 'User not found.'], 404);
        }

        if ($user->otp_code !== $request->otp) {
            return response()->json(['success' => false, 'message' => 'Invalid OTP code.'], 400);
        }

        if (now()->isAfter($user->otp_expires_at)) {
            return response()->json(['success' => false, 'message' => 'OTP has expired.'], 400);
        }

        // Activate user
        $user->update([
            'status' => 'active',
            'otp_code' => null,
            'otp_expires_at' => null,
            'email_verified_at' => now(),
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Account successfully verified!',
            'access_token' => $token,
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'status' => $user->status,
            ],
        ], 200);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Successfully logged out.',
        ], 200);
    }

    /**
     * Mask email (e.g. k***@gmail.com).
     */
    private function maskEmail(string $email): string
    {
        $parts = explode('@', $email);
        if (count($parts) !== 2) {
            return '***@***.com';
        }

        $name = $parts[0];
        $domain = $parts[1];

        $firstChar = substr($name, 0, 1);
        return $firstChar . '***@' . $domain;
    }

    /**
     * Mask phone number (e.g. ******1234).
     */
    private function maskPhone(string $phone): string
    {
        $digits = preg_replace('/\D/', '', $phone);
        $len = strlen($digits);

        if ($len <= 4) {
            return '******' . $digits;
        }

        $last4 = substr($digits, -4);
        return '******' . $last4;
    }
}
