<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\EmergencyContactController;
use App\Http\Controllers\Api\SosController;
use App\Http\Controllers\Api\PredictionController;
use App\Http\Controllers\Api\RouteController;
use App\Http\Controllers\Api\IncidentController;
use App\Http\Controllers\Api\NotificationController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public Authentication
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/verify-otp', [AuthController::class, 'verifyOtp']);

// Protected APIs (Laravel Sanctum)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    // User Profile
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);

    // Emergency Contacts (Supports both /contacts and /emergency-contacts)
    Route::apiResource('contacts', EmergencyContactController::class);
    Route::apiResource('emergency-contacts', EmergencyContactController::class);

    // SOS Emergency Alerts & SMS Dispatch (Rate-limited to protect against duplicate spam)
    Route::post('/sos', [SosController::class, 'trigger'])->middleware('throttle:10,1');
    Route::post('/sos/trigger', [SosController::class, 'trigger'])->middleware('throttle:10,1');
    Route::post('/sos/{sosId}/track', [SosController::class, 'track']);
    Route::post('/sos/{sosId}/resolve', [SosController::class, 'resolve']);

    // Incident Reporting
    Route::get('/incidents', [IncidentController::class, 'index']);
    Route::post('/incidents', [IncidentController::class, 'store']);

    // Crime Prediction & Safety Routes
    Route::post('/predict-risk', [PredictionController::class, 'predict']);
    Route::post('/routes/safe-recommendation', [RouteController::class, 'recommendSafeRoute']);

    // Push Notifications
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::put('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
});
