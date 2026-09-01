<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Repositories\IncidentReportRepository;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class IncidentController extends Controller
{
    protected $incidentRepository;

    public function __construct(IncidentReportRepository $incidentRepository)
    {
        $this->incidentRepository = $incidentRepository;
    }

    public function index(Request $request)
    {
        $reports = $this->incidentRepository->getForUser($request->user()->id);

        return response()->json([
            'success' => true,
            'incidents' => $reports,
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'category' => 'required|string|max:100',
            'area' => 'required|string|max:255',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'image' => 'sometimes|image|mimes:jpeg,png,jpg,webp|max:5120', // max 5MB
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $mediaUrl = null;
        if ($request->hasFile('image')) {
            try {
                $path = $request->file('image')->store('incidents', 'public');
                $mediaUrl = Storage::disk('public')->url($path);
            } catch (\Exception $e) {
                return response()->json(['success' => false, 'message' => 'Failed to upload incident media.'], 500);
            }
        }

        $report = $this->incidentRepository->create([
            'user_id' => $request->user()->id,
            'title' => $request->title,
            'description' => $request->description,
            'category' => $request->category,
            'area' => $request->area,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'media_url' => $mediaUrl,
            'status' => 'pending',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Incident reported successfully!',
            'incident' => $report,
        ], 201);
    }
}
