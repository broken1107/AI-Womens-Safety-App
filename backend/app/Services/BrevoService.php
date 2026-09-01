<?php

namespace App\Services;

use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class BrevoService
{
    protected string $apiKey;
    protected string $senderEmail;
    protected string $senderName;
    protected string $apiUrl;
    protected bool $isMock;

    public function __construct()
    {
        $this->apiKey = (string) Config::get('services.brevo.api_key', '');
        $this->senderEmail = (string) Config::get('services.brevo.sender_email', 'no-reply@safetyguardian.app');
        $this->senderName = (string) Config::get('services.brevo.sender_name', "AI Women's Safety App");
        $this->apiUrl = (string) Config::get('services.brevo.api_url', 'https://api.brevo.com/v3/smtp/email');
        $this->isMock = (bool) Config::get('services.brevo.mock', false);
    }

    /**
     * Send a 6-digit login verification OTP via Brevo Transactional Email API.
     *
     * @param string $recipientEmail
     * @param string $recipientName
     * @param string $otp
     * @return array
     */
    public function sendOtpEmail(string $recipientEmail, string $recipientName, string $otp): array
    {
        $cleanEmail = trim($recipientEmail);

        if (empty($cleanEmail) || !filter_var($cleanEmail, FILTER_VALIDATE_EMAIL)) {
            Log::warning("BrevoService: Invalid email address [{$recipientEmail}]");
            return [
                'success' => false,
                'provider_message_id' => null,
                'status' => 'failed',
                'error' => 'Invalid recipient email format.',
            ];
        }

        // Mock / Development simulation mode
        if ($this->isMock || empty($this->apiKey)) {
            $mockMsgId = 'BREVO_MOCK_' . strtoupper(uniqid());
            Log::info("BrevoService [MOCK MODE]: Simulating OTP email dispatch to {$cleanEmail} [MsgID: {$mockMsgId}]");
            return [
                'success' => true,
                'provider_message_id' => $mockMsgId,
                'status' => 'simulated',
                'error' => null,
            ];
        }

        $subject = "Your Login Verification Code — AI Women's Safety App";

        $textContent = "Hello {$recipientName},\n\n" .
            "Your login verification code is:\n" .
            "{$otp}\n\n" .
            "This code will expire in 5 minutes.\n\n" .
            "Do not share this code with anyone.\n\n" .
            "If you did not attempt to log in, please ignore this email.\n\n" .
            "Regards,\n" .
            "AI Women's Safety App";

        $htmlContent = "<div style=\"font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 540px; margin: 0 auto; padding: 24px; border: 1px solid #eaeaea; border-radius: 12px; background-color: #ffffff;\">" .
            "<h2 style=\"color: #1a1a1a; margin-top: 0; font-size: 20px;\">Verify Your Login</h2>" .
            "<p style=\"color: #4a4a4a; font-size: 15px; line-height: 1.5;\">Hello <strong>" . htmlspecialchars($recipientName, ENT_QUOTES, 'UTF-8') . "</strong>,</p>" .
            "<p style=\"color: #4a4a4a; font-size: 15px; line-height: 1.5;\">Your login verification code is:</p>" .
            "<div style=\"background-color: #f4f6f8; border-radius: 8px; padding: 16px; text-align: center; margin: 20px 0;\">" .
            "<span style=\"font-size: 32px; font-weight: 800; letter-spacing: 6px; color: #7c3aed;\">" . htmlspecialchars($otp, ENT_QUOTES, 'UTF-8') . "</span>" .
            "</div>" .
            "<p style=\"color: #6b7280; font-size: 13px; line-height: 1.4;\">This code will expire in <strong>5 minutes</strong>.<br>Do not share this code with anyone.</p>" .
            "<hr style=\"border: none; border-top: 1px solid #eee; margin: 20px 0;\">" .
            "<p style=\"color: #9ca3af; font-size: 12px; line-height: 1.4;\">If you did not attempt to log in, please ignore this email.<br>Regards,<br><strong>AI Women's Safety App</strong></p>" .
            "</div>";

        $payload = [
            'sender' => [
                'name' => $this->senderName,
                'email' => $this->senderEmail,
            ],
            'to' => [
                [
                    'email' => $cleanEmail,
                    'name' => $recipientName,
                ],
            ],
            'subject' => $subject,
            'htmlContent' => $htmlContent,
            'textContent' => $textContent,
        ];

        try {
            Log::info("BrevoService: Dispatching login OTP email to {$cleanEmail} via Brevo API");

            $response = Http::timeout(12)
                ->withHeaders([
                    'api-key' => $this->apiKey,
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json',
                ])
                ->post($this->apiUrl, $payload);

            $statusCode = $response->status();

            if ($response->successful()) {
                $json = $response->json();
                $messageId = $json['messageId'] ?? ('BREVO_' . time());
                Log::info("BrevoService: Email successfully sent to {$cleanEmail}. MessageID: {$messageId}");
                return [
                    'success' => true,
                    'provider_message_id' => (string) $messageId,
                    'status' => 'sent',
                    'error' => null,
                ];
            }

            $json = $response->json();
            $errorMessage = $json['message'] ?? "Brevo API HTTP error {$statusCode}";
            Log::error("BrevoService: Email rejected for {$cleanEmail}: {$errorMessage}", ['status' => $statusCode]);

            return [
                'success' => false,
                'provider_message_id' => null,
                'status' => 'failed',
                'error' => $errorMessage,
            ];
        } catch (\Illuminate\Http\Client\ConnectionException $e) {
            Log::error("BrevoService: Connection timeout while communicating with Brevo: " . $e->getMessage());
            return [
                'success' => false,
                'provider_message_id' => null,
                'status' => 'failed',
                'error' => 'Email service connection timed out.',
            ];
        } catch (\Throwable $e) {
            Log::error("BrevoService: Unexpected exception dispatching email: " . $e->getMessage());
            return [
                'success' => false,
                'provider_message_id' => null,
                'status' => 'failed',
                'error' => 'An internal error occurred while communicating with email service.',
            ];
        }
    }
}
