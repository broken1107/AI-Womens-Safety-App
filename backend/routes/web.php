<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\AdminDashboardController;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
*/

Route::get('/', function () {
    return redirect('/admin/login');
});

// Admin Auth Routes
Route::get('/admin/login', [AdminAuthController::class, 'showLoginForm'])->name('login');
Route::post('/admin/login', [AdminAuthController::class, 'login']);
Route::post('/admin/logout', [AdminAuthController::class, 'logout']);

// Protected Admin Dashboard Routes
Route::middleware(['auth:admin'])->group(function () {
    Route::get('/admin/dashboard', [AdminDashboardController::class, 'index']);
    
    // Users Management
    Route::get('/admin/users', [AdminDashboardController::class, 'usersIndex']);
    Route::post('/admin/users/{id}/activate', [AdminDashboardController::class, 'activateUser']);
    Route::post('/admin/users/{id}/suspend', [AdminDashboardController::class, 'suspendUser']);

    // SOS Alerts
    Route::get('/admin/alerts', [AdminDashboardController::class, 'alertsIndex']);
    Route::post('/admin/alerts/{id}/resolve', [AdminDashboardController::class, 'resolveAlert']);

    // Incidents Verification
    Route::get('/admin/incidents', [AdminDashboardController::class, 'incidentsIndex']);
    Route::post('/admin/incidents/{id}/verify', [AdminDashboardController::class, 'verifyIncident']);
    Route::post('/admin/incidents/{id}/resolve', [AdminDashboardController::class, 'resolveIncident']);

    // Crime Dataset & Model training
    Route::get('/admin/crime', [AdminDashboardController::class, 'crimeIndex']);
    Route::post('/admin/crime/import', [AdminDashboardController::class, 'importCrimeCsv']);
    Route::post('/admin/crime/retrain', [AdminDashboardController::class, 'triggerModelRetraining']);

    // Audit logs
    Route::get('/admin/logs', [AdminDashboardController::class, 'logsIndex']);
});
