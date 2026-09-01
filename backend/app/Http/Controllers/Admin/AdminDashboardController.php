<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\SosAlert;
use App\Models\IncidentReport;
use App\Models\CrimeData;
use App\Models\PredictionLog;
use App\Models\AuditLog;
use App\Services\SosAlertService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AdminDashboardController extends Controller
{
    protected $sosService;

    public function __construct(SosAlertService $sosService)
    {
        $this->sosService = $sosService;
    }

    public function index()
    {
        $activeSosCount = SosAlert::where('status', 'active')->count();
        $totalUsers = User::count();
        $pendingIncidents = IncidentReport::where('status', 'pending')->count();
        $predictionQueries = PredictionLog::count();

        $activeAlerts = SosAlert::with('user')->where('status', 'active')->orderBy('created_at', 'desc')->get();

        // Group incidents by category for ChartJS
        $incidentChartData = IncidentReport::selectRaw('category, count(*) as count')
            ->groupBy('category')
            ->pluck('count', 'category');

        return view('admin.dashboard', compact(
            'activeSosCount',
            'totalUsers',
            'pendingIncidents',
            'predictionQueries',
            'activeAlerts',
            'incidentChartData'
        ));
    }

    public function usersIndex(Request $request)
    {
        $search = $request->input('search');
        $query = User::query();

        if ($search) {
            $query->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%");
        }

        $users = $query->orderBy('created_at', 'desc')->paginate(10);

        return view('admin.users.index', compact('users'));
    }

    public function activateUser($id, Request $request)
    {
        $user = User::findOrFail($id);
        $user->update(['status' => 'active']);

        AuditLog::create([
            'admin_id' => Auth::guard('admin')->id(),
            'action' => 'ACTIVATE_USER',
            'description' => "Activated user {$user->name} (ID: {$user->id}).",
            'ip_address' => $request->ip(),
        ]);

        return back()->with('success', "User account {$user->name} has been activated.");
    }

    public function suspendUser($id, Request $request)
    {
        $user = User::findOrFail($id);
        $user->update(['status' => 'suspended']);

        // Revoke active sanctum tokens
        $user->tokens()->delete();

        AuditLog::create([
            'admin_id' => Auth::guard('admin')->id(),
            'action' => 'SUSPEND_USER',
            'description' => "Suspended user {$user->name} (ID: {$user->id}).",
            'ip_address' => $request->ip(),
        ]);

        return back()->with('success', "User account {$user->name} has been suspended.");
    }

    public function alertsIndex(Request $request)
    {
        $status = $request->input('status');
        $query = SosAlert::with('user');

        if ($status) {
            $query->where('status', $status);
        }

        $alerts = $query->orderBy('created_at', 'desc')->paginate(10)->withQueryString();

        return view('admin.alerts.index', compact('alerts'));
    }

    public function resolveAlert($id, Request $request)
    {
        try {
            $this->sosService->resolveSos($id, 'ADMIN_BYPASS');

            $alert = SosAlert::findOrFail($id);
            $user = User::find($alert->user_id);

            AuditLog::create([
                'admin_id' => Auth::guard('admin')->id(),
                'action' => 'RESOLVE_SOS',
                'description' => "Resolved SOS Alert for user {$user->name} (SOS ID: {$alert->id}).",
                'ip_address' => $request->ip(),
            ]);

            return back()->with('success', "SOS alert has been resolved successfully.");
        } catch (\Exception $e) {
            return back()->with('error', $e->getMessage());
        }
    }

    public function incidentsIndex(Request $request)
    {
        $status = $request->input('status');
        $query = IncidentReport::with('user');

        if ($status) {
            $query->where('status', $status);
        }

        $incidents = $query->orderBy('created_at', 'desc')->get();

        return view('admin.incidents.index', compact('incidents'));
    }

    public function verifyIncident($id, Request $request)
    {
        $incident = IncidentReport::findOrFail($id);
        $incident->update(['status' => 'verified']);

        AuditLog::create([
            'admin_id' => Auth::guard('admin')->id(),
            'action' => 'VERIFY_INCIDENT',
            'description' => "Verified incident report ID: {$incident->id}.",
            'ip_address' => $request->ip(),
        ]);

        return back()->with('success', 'Incident report marked as verified.');
    }

    public function resolveIncident($id, Request $request)
    {
        $incident = IncidentReport::findOrFail($id);
        $incident->update([
            'status' => 'resolved',
            'resolved_at' => now()
        ]);

        AuditLog::create([
            'admin_id' => Auth::guard('admin')->id(),
            'action' => 'RESOLVE_INCIDENT',
            'description' => "Resolved incident report ID: {$incident->id}.",
            'ip_address' => $request->ip(),
        ]);

        return back()->with('success', 'Incident report marked as resolved.');
    }

    public function crimeIndex()
    {
        $crimeData = CrimeData::orderBy('created_at', 'desc')->paginate(15);
        return view('admin.crime.index', compact('crimeData'));
    }

    public function importCrimeCsv(Request $request)
    {
        $request->validate([
            'csv_file' => 'required|file|mimes:csv,txt|max:10240', // max 10MB
        ]);

        try {
            $path = $request->file('csv_file')->getRealPath();
            $file = fopen($path, 'r');

            // Skip header row
            $header = fgetcsv($file);

            $rowsImported = 0;
            while (($row = fgetcsv($file)) !== FALSE) {
                if (count($row) < 7) continue;

                CrimeData::create([
                    'latitude' => doubleval($row[0]),
                    'longitude' => doubleval($row[1]),
                    'area' => strval($row[2]),
                    'hour' => intval($row[3]),
                    'crime_category' => strval($row[4]),
                    'risk_score' => doubleval($row[5]),
                    'risk_label' => strval($row[6]),
                ]);
                $rowsImported++;
            }

            fclose($file);

            AuditLog::create([
                'admin_id' => Auth::guard('admin')->id(),
                'action' => 'IMPORT_CRIME_CSV',
                'description' => "Imported {$rowsImported} crime rows via CSV upload.",
                'ip_address' => $request->ip(),
            ]);

            return back()->with('success', "Imported {$rowsImported} crime log records successfully!");

        } catch (\Exception $e) {
            return back()->with('error', "Import failed: " . $e->getMessage());
        }
    }

    public function triggerModelRetraining(Request $request)
    {
        $flaskUrl = config('services.ml_service.url', 'http://127.0.0.1:5000');

        try {
            $response = Http::timeout(30)->post("{$flaskUrl}/train");

            if ($response->successful()) {
                AuditLog::create([
                    'admin_id' => Auth::guard('admin')->id(),
                    'action' => 'TRAIN_ML_MODEL',
                    'description' => 'Triggered Random Forest ML model retraining.',
                    'ip_address' => $request->ip(),
                ]);

                return back()->with('success', 'Machine Learning model retrained successfully on Flask!');
            }
        } catch (\Exception $e) {
            Log::error("Failed to trigger retraining: " . $e->getMessage());
        }

        return back()->with('error', 'Flask ML service is offline or training request timed out.');
    }

    public function logsIndex()
    {
        $logs = AuditLog::with('admin')->orderBy('created_at', 'desc')->paginate(20);
        return view('admin.logs.index', compact('logs'));
    }
}
