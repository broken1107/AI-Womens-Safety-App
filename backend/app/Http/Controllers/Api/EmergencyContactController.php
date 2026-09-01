<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Repositories\EmergencyContactRepository;
use App\Models\EmergencyContact;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

class EmergencyContactController extends Controller
{
    protected $contactRepository;

    public function __construct(EmergencyContactRepository $contactRepository)
    {
        $this->contactRepository = $contactRepository;
    }

    public function index(Request $request)
    {
        $contacts = $this->contactRepository->getForUser($request->user()->id);

        return response()->json([
            'success' => true,
            'contacts' => $contacts,
        ]);
    }

    public function store(Request $request)
    {
        $userId = $request->user()->id;

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'phone' => [
                'required',
                'string',
                'regex:/^(\+91[\-\s]?)?[6789]\d{9}$/',
                Rule::unique('emergency_contacts', 'phone')->where(function ($query) use ($userId) {
                    return $query->where('user_id', $userId);
                }),
            ],
            'relationship' => 'required|string|max:100',
            'is_trusted' => 'sometimes|boolean',
        ], [
            'phone.regex' => 'Please provide a valid 10-digit Indian mobile number (e.g. 9876543210 or +919876543210).',
            'phone.unique' => 'This phone number is already registered in your emergency contacts.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
                'errors' => $validator->errors()
            ], 422);
        }

        $contact = $this->contactRepository->create([
            'user_id' => $userId,
            'name' => $request->name,
            'phone' => $request->phone,
            'relationship' => $request->relationship,
            'is_trusted' => $request->input('is_trusted', true),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Emergency contact added successfully!',
            'contact' => $contact,
        ], 201);
    }

    public function show($id, Request $request)
    {
        $contact = $this->contactRepository->find($id);

        if (!$contact || $contact->user_id !== $request->user()->id) {
            return response()->json(['success' => false, 'message' => 'Unauthorized Access or Contact not found.'], 403);
        }

        return response()->json([
            'success' => true,
            'contact' => $contact,
        ]);
    }

    public function update($id, Request $request)
    {
        $contact = $this->contactRepository->find($id);
        $userId = $request->user()->id;

        if (!$contact || $contact->user_id !== $userId) {
            return response()->json(['success' => false, 'message' => 'Unauthorized Access or Contact not found.'], 403);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'phone' => [
                'sometimes',
                'string',
                'regex:/^(\+91[\-\s]?)?[6789]\d{9}$/',
                Rule::unique('emergency_contacts', 'phone')->ignore($id)->where(function ($query) use ($userId) {
                    return $query->where('user_id', $userId);
                }),
            ],
            'relationship' => 'sometimes|string|max:100',
            'is_trusted' => 'sometimes|boolean',
        ], [
            'phone.regex' => 'Please provide a valid 10-digit Indian mobile number.',
            'phone.unique' => 'This phone number is already registered in your emergency contacts.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
                'errors' => $validator->errors()
            ], 422);
        }

        $updated = $this->contactRepository->update($id, $request->only([
            'name', 'phone', 'relationship', 'is_trusted'
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Emergency contact updated successfully!',
            'contact' => $updated,
        ]);
    }

    public function destroy($id, Request $request)
    {
        $contact = $this->contactRepository->find($id);

        if (!$contact || $contact->user_id !== $request->user()->id) {
            return response()->json(['success' => false, 'message' => 'Unauthorized Access or Contact not found.'], 403);
        }

        $this->contactRepository->delete($id);

        return response()->json([
            'success' => true,
            'message' => 'Emergency contact deleted successfully!',
        ]);
    }
}
