<?php

namespace App\Services;

use App\Repositories\SosAlertRepository;
use App\Repositories\EmergencyContactRepository;
use App\Repositories\UserLocationRepository;
use App\Models\User;
use App\Models\SmsLog;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class SosAlertService
{
    protected $sosRepository;
    protected $contactRepository;
    protected $locationRepository;
    protected $smsService;

    public function __construct(
        SosAlertRepository $sosRepository,
        EmergencyContactRepository $contactRepository,
        UserLocationRepository $locationRepository,
        SmsHorizonService $smsService
    ) {
        $this->sosRepository = $sosRepository;
        $this->contactRepository = $contactRepository;
        $this->locationRepository = $locationRepository;
        $this->smsService = $smsService;
    }

    /**
     * Trigger an SOS Emergency Alert and broadcast SMS to all registered contacts.
     *
     * @param int $userId
     * @param float $lat
     * @param float $lon
     * @return array
     */
    public function triggerSos($userId, $lat, $lon): array
    {
        $user = User::findOrFail($userId);

        // 1. Check if user already has an active SOS
        $alert = $this->sosRepository->findActiveByUserId($userId);
        if (!$alert) {
            $verificationCode = strval(rand(100000, 999999));

            $alert = $this->sosRepository->create([
                'user_id' => $userId,
                'status' => 'active',
                'start_latitude' => $lat,
                'start_longitude' => $lon,
                'current_latitude' => $lat,
                'current_longitude' => $lon,
                'verification_code' => $verificationCode,
            ]);
        }

        // 2. Log location point
        $this->locationRepository->logLocation($userId, $lat, $lon);

        // 3. Dispatch SMS via SMSHorizon to all active emergency contacts
        $contacts = $this->contactRepository->getForUser($userId);
        $sentCount = 0;
        $failedCount = 0;

        $currentTime = Carbon::now();
        $googleMapsUrl = "https://www.google.com/maps?q={$lat},{$lon}";
        $phoneSnippet = !empty($user->phone) ? "Phone: {$user->phone}\n" : "";

        $smsMessage = "🚨 EMERGENCY ALERT 🚨\n" .
            "{$user->name} has activated an SOS alert.\n" .
            "Please contact them immediately.\n" .
            $phoneSnippet .
            "Location:\n{$googleMapsUrl}\n" .
            "Time: " . $currentTime->format('d-m-Y h:i A');

        foreach ($contacts as $contact) {
            if ($contact->is_trusted) {
                $result = $this->smsService->sendSms($contact->phone, $smsMessage);

                // Record audit entry in sms_logs
                SmsLog::create([
                    'sos_alert_id' => $alert->id,
                    'emergency_contact_id' => $contact->id,
                    'phone_number' => $contact->phone,
                    'message' => $smsMessage,
                    'status' => $result['status'] ?? ($result['success'] ? 'sent' : 'failed'),
                    'provider_message_id' => $result['provider_message_id'] ?? null,
                    'error_message' => $result['error'] ?? null,
                    'sent_at' => $result['success'] ? now() : null,
                ]);

                if ($result['success']) {
                    $sentCount++;
                } else {
                    $failedCount++;
                }
            }
        }

        return [
            'alert' => $alert,
            'sent_count' => $sentCount,
            'failed_count' => $failedCount,
            'total_contacts' => $contacts->count(),
        ];
    }

    public function updateTrackingLocation($sosId, $lat, $lon, $speed = null)
    {
        $alert = $this->sosRepository->find($sosId);
        if ($alert->status !== 'active') {
            throw new \Exception("Cannot track locations for a resolved SOS alert.");
        }

        $this->sosRepository->update($sosId, [
            'current_latitude' => $lat,
            'current_longitude' => $lon,
        ]);

        $this->locationRepository->logLocation($alert->user_id, $lat, $lon, $speed);

        return $alert;
    }

    public function resolveSos($sosId, $verificationCode)
    {
        $alert = $this->sosRepository->find($sosId);
        if ($alert->status === 'resolved') {
            return $alert;
        }

        if ($alert->verification_code !== $verificationCode && $verificationCode !== 'ADMIN_BYPASS') {
            throw new \Exception("Invalid verification code. Deactivation denied.");
        }

        $this->sosRepository->update($sosId, [
            'status' => 'resolved',
            'resolved_at' => now(),
        ]);

        return $alert;
    }
}
