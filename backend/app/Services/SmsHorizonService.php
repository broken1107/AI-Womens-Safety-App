<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Config;
use Carbon\Carbon;

class SmsHorizonService
{
    protected string $user;
    protected string $apiKey;
    protected string $senderId;
    protected string $apiUrl;
    protected ?string $defaultTemplateId;
    protected bool $isMock;

    public function __construct()
    {
        $this->user = (string) Config::get('services.smshorizon.user', '');
        $this->apiKey = (string) Config::get('services.smshorizon.api_key', '');
        $this->senderId = (string) Config::get('services.smshorizon.sender_id', 'SAFGRD');
        $this->apiUrl = (string) Config::get('services.smshorizon.api_url', 'https://smshorizon.co.in/api/v2/sendsms.php');
        $this->defaultTemplateId = Config::get('services.smshorizon.template_id') ?: null;
        $this->isMock = (bool) Config::get('services.smshorizon.mock', false);
    }

    /**
     * Send an SMS to a single recipient through SMSHorizon API.
     *
     * @param string $phoneNumber
     * @param string $message
     * @param string|null $templateId
     * @return array
     */
    public function sendSms(string $phoneNumber, string $message, ?string $templateId = null): array
    {
        $cleanPhone = $this->formatPhoneNumber($phoneNumber);

        if (empty($cleanPhone) || strlen($cleanPhone) < 10) {
            Log::warning("SmsHorizonService: Invalid phone number passed [{$phoneNumber}]");
            return [
                'success' => false,
                'provider_message_id' => null,
                'status' => 'failed',
                'error' => 'Invalid destination phone number format.',
                'raw_response' => null,
            ];
        }

        // Mock / Development Simulation Mode
        if ($this->isMock || empty($this->apiKey)) {
            $mockMsgId = 'MOCK_' . strtoupper(uniqid());
            Log::info("SmsHorizonService [MOCK MODE]: Simulating SMS dispatch to {$cleanPhone}: \"{$message}\" [MsgID: {$mockMsgId}]");
            return [
                'success' => true,
                'provider_message_id' => $mockMsgId,
                'status' => 'simulated',
                'error' => null,
                'raw_response' => ['status' => 'success', 'msgid' => $mockMsgId, 'simulated' => true],
            ];
        }

        $tid = $templateId ?: $this->defaultTemplateId;

        $params = [
            'user' => $this->user,
            'apikey' => $this->apiKey,
            'mobile' => $cleanPhone,
            'senderid' => $this->senderId,
            'message' => $message,
            'type' => 'txt',
        ];

        if (!empty($tid)) {
            $params['tid'] = $tid;
        }

        try {
            Log::info("SmsHorizonService: Dispatching SMS to {$cleanPhone} via {$this->apiUrl}");

            $response = Http::timeout(12)
                ->withHeaders([
                    'Authorization' => 'Bearer ' . $this->apiKey,
                    'Accept' => 'application/json',
                ])
                ->asForm()
                ->post($this->apiUrl, $params);

            $statusCode = $response->status();
            $body = $response->body();

            if ($response->successful()) {
                $json = $response->json();

                // Check JSON structure
                if (is_array($json)) {
                    $status = strtolower($json['status'] ?? '');
                    $msgId = $json['msgid'] ?? $json['message_id'] ?? $json['id'] ?? null;

                    if ($status === 'success' || $status === 'submitted' || $status === 'queued' || !empty($msgId)) {
                        Log::info("SmsHorizonService: SMS successfully sent to {$cleanPhone}. MsgID: {$msgId}");
                        return [
                            'success' => true,
                            'provider_message_id' => $msgId ? (string) $msgId : 'SENT_' . time(),
                            'status' => 'sent',
                            'error' => null,
                            'raw_response' => $json,
                        ];
                    }

                    $errorMessage = $json['error'] ?? $json['message'] ?? 'SMS delivery rejected by provider.';
                    Log::error("SmsHorizonService: SMS rejected for {$cleanPhone}: {$errorMessage}", $json);
                    return [
                        'success' => false,
                        'provider_message_id' => null,
                        'status' => 'failed',
                        'error' => $errorMessage,
                        'raw_response' => $json,
                    ];
                }

                // Handle plain-text response (older endpoints or gateway status codes)
                if (!empty($body) && !str_starts_with(trim($body), '<')) {
                    Log::info("SmsHorizonService: Raw text response for {$cleanPhone}: {$body}");
                    return [
                        'success' => true,
                        'provider_message_id' => trim($body),
                        'status' => 'sent',
                        'error' => null,
                        'raw_response' => $body,
                    ];
                }
            }

            Log::error("SmsHorizonService: HTTP error [{$statusCode}] for {$cleanPhone}: {$body}");
            return [
                'success' => false,
                'provider_message_id' => null,
                'status' => 'failed',
                'error' => "SMS Gateway HTTP error: status {$statusCode}",
                'raw_response' => $body,
            ];

        } catch (\Illuminate\Http\Client\ConnectionException $e) {
            Log::error("SmsHorizonService: Network timeout / connection error connecting to SMSHorizon: " . $e->getMessage());
            return [
                'success' => false,
                'provider_message_id' => null,
                'status' => 'failed',
                'error' => 'SMS gateway connection timed out.',
                'raw_response' => null,
            ];
        } catch (\Throwable $e) {
            Log::error("SmsHorizonService: Unexpected exception dispatching SMS: " . $e->getMessage());
            return [
                'success' => false,
                'provider_message_id' => null,
                'status' => 'failed',
                'error' => 'An internal error occurred while communicating with SMS gateway.',
                'raw_response' => null,
            ];
        }
    }

    /**
     * Format and dispatch a standardized Women's Safety SOS emergency SMS.
     *
     * @param string $phoneNumber
     * @param string $userName
     * @param string|null $userPhone
     * @param float $latitude
     * @param float $longitude
     * @param Carbon|string|null $dateTime
     * @return array
     */
    public function sendEmergencySms(
        string $phoneNumber,
        string $userName,
        ?string $userPhone,
        float $latitude,
        float $longitude,
        $dateTime = null
    ): array {
        $formattedTime = $dateTime instanceof Carbon
            ? $dateTime->format('d-m-Y h:i A')
            : ($dateTime ? Carbon::parse($dateTime)->format('d-m-Y h:i A') : now()->format('d-m-Y h:i A'));

        $googleMapsUrl = "https://www.google.com/maps?q={$latitude},{$longitude}";

        $phoneSnippet = !empty($userPhone) ? "Phone: {$userPhone}\n" : "";

        $message = "🚨 EMERGENCY ALERT 🚨\n" .
            "{$userName} has activated an SOS alert.\n" .
            "Please contact them immediately.\n" .
            $phoneSnippet .
            "Location:\n{$googleMapsUrl}\n" .
            "Time: {$formattedTime}";

        return $this->sendSms($phoneNumber, $message);
    }

    /**
     * Send a 6-digit login verification OTP via SMSHorizon.
     *
     * @param string $phoneNumber
     * @param string $otp
     * @return array
     */
    public function sendOtpSms(string $phoneNumber, string $otp): array
    {
        $message = "Your AI Women's Safety App login OTP is {$otp}. This OTP will expire in 5 minutes. Do not share it with anyone.";
        return $this->sendSms($phoneNumber, $message);
    }

    /**
     * Clean and normalize Indian mobile phone numbers (10 digits).
     *
     * @param string $phone
     * @return string
     */
    public function formatPhoneNumber(string $phone): string
    {
        // Strip everything except digits
        $digits = preg_replace('/\D/', '', $phone);

        // If 12 digits starting with 91 (India country code), keep 10 digits or 12 digits as needed
        if (strlen($digits) === 12 && str_starts_with($digits, '91')) {
            return substr($digits, 2);
        }

        // If 11 digits starting with 0, strip leading 0
        if (strlen($digits) === 11 && str_starts_with($digits, '0')) {
            return substr($digits, 1);
        }

        return $digits;
    }
}
