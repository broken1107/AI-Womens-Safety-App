<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\SosAlertService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class SosController extends Controller
{
    protected $sosService;

    public function __construct(SosAlertService $sosService)
    {
        $this->sosService = $sosService;
    }

    /**
     * Trigger Emergency SOS Alert and broadcast SMS to registered emergency contacts.
     * POST /api/sos
     * POST /api/sos/trigger
     */
    public function trigger(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid GPS coordinates provided.',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $user = $request->user();
            $result = $this->sosService->triggerSos(
                $user->id,
                (float) $request->latitude,
                (float) $request->longitude
            );

            $sentCount = $result['sent_count'] ?? 0;
            $failedCount = $result['failed_count'] ?? 0;
            $totalContacts = $result['total_contacts'] ?? 0;

            if ($totalContacts === 0) {
                $message = 'SOS Alert activated, but no active emergency contacts were found to receive SMS.';
            } elseif ($failedCount === 0) {
                $message = "Emergency alert sent successfully to {$sentCount} emergency contact" . ($sentCount > 1 ? 's' : '') . '.';
            } elseif ($sentCount > 0) {
                $message = "Emergency alert partially sent ({$sentCount} succeeded, {$failedCount} failed).";
            } else {
                $message = "SOS Alert activated. SMS delivery failed for {$failedCount} emergency contacts.";
            }

            return response()->json([
                'success' => true,
                'message' => $message,
                'sent_count' => $sentCount,
                'failed_count' => $failedCount,
                'total_contacts' => $totalContacts,
                'sos_alert' => $result['alert'],
            ], 201);
        } catch (\Throwable $e) {
            Log::error("SosController trigger error: " . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while processing emergency alert. Please call emergency services (112) immediately.',
                'error_detail' => config('app.debug') ? $e->getMessage() : null,
            ], 500);
        }
    }

    /**
     * Update continuous live GPS location stream during active SOS.
     * POST /api/sos/{sosId}/track
     */
    public function track($sosId, Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'speed' => 'sometimes|nullable|numeric',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $alert = $this->sosService->updateTrackingLocation(
                $sosId,
                (float) $request->latitude,
                (float) $request->longitude,
                $request->speed ? (float) $request->speed : null
            );

            return response()->json([
                'success' => true,
                'message' => 'Location logged successfully.',
                'sos_alert' => $alert,
            ], 200);
        } catch (\Throwable $e) {
            Log::error("SosController track error: " . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Resolve / Deactivate active SOS using PIN code.
     * POST /api/sos/{sosId}/resolve
     */
    public function resolve($sosId, Request $request)
    {
        $validator = Validator::make($request->all(), [
            'verification_code' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $alert = $this->sosService->resolveSos($sosId, (string) $request->verification_code);

            return response()->json([
                'success' => true,
                'message' => 'SOS Alert deactivated/resolved successfully.',
                'sos_alert' => $alert,
            ], 200);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 400);
        }
    }
}
