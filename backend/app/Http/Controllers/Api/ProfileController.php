<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Repositories\UserRepository;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ProfileController extends Controller
{
    protected $userRepository;

    public function __construct(UserRepository $userRepository)
    {
        $this->userRepository = $userRepository;
    }

    public function show(Request $request)
    {
        return response()->json([
            'success' => true,
            'user' => $request->user(),
        ]);
    }

    public function update(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|string|email|max:255|unique:users,email,' . $user->id,
            'phone' => 'sometimes|string|max:15|unique:users,phone,' . $user->id,
            'avatar_url' => 'sometimes|nullable|string',
            'fcm_token' => 'sometimes|nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $updatedUser = $this->userRepository->update($user->id, $request->only([
            'name', 'email', 'phone', 'avatar_url', 'fcm_token'
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully!',
            'user' => $updatedUser,
        ]);
    }
}
