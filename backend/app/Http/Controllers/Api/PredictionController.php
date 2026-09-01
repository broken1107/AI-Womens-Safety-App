<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\PredictionService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class PredictionController extends Controller
{
    protected $predictionService;

    public function __construct(PredictionService $predictionService)
    {
        $this->predictionService = $predictionService;
    }

    public function predict(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'area' => 'required|string',
            'hour' => 'required|integer|between:0,23',
            'crime_category' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $prediction = $this->predictionService->predictRisk(
            $request->user()->id,
            $request->latitude,
            $request->longitude,
            $request->area,
            $request->hour,
            $request->crime_category
        );

        return response()->json([
            'success' => true,
            'prediction' => $prediction,
        ]);
    }
}
