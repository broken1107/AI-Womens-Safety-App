<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\SafeRouteService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class RouteController extends Controller
{
    protected $routeService;

    public function __construct(SafeRouteService $routeService)
    {
        $this->routeService = $routeService;
    }

    public function recommendSafeRoute(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'start_latitude' => 'required|numeric',
            'start_longitude' => 'required|numeric',
            'destination_latitude' => 'required|numeric',
            'destination_longitude' => 'required|numeric',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $result = $this->routeService->getSafeRoutes(
            $request->user()->id,
            $request->start_latitude,
            $request->start_longitude,
            $request->destination_latitude,
            $request->destination_longitude
        );

        return response()->json([
            'success' => true,
            'routes' => $result['routes'],
            'recommended_index' => $result['recommended_index'],
        ]);
    }
}
