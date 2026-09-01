<?php

namespace App\Repositories;

use App\Models\EmergencyContact;

class EmergencyContactRepository
{
    public function getForUser($userId)
    {
        return EmergencyContact::where('user_id', $userId)->get();
    }

    public function create(array $data)
    {
        return EmergencyContact::create($data);
    }

    public function find($id)
    {
        return EmergencyContact::findOrFail($id);
    }

    public function update($id, array $data)
    {
        $contact = EmergencyContact::findOrFail($id);
        $contact->update($data);
        return $contact;
    }

    public function delete($id)
    {
        return EmergencyContact::destroy($id);
    }
}
