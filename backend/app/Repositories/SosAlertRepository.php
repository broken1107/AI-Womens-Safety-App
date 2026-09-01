<?php

namespace App\Repositories;

use App\Models\SosAlert;

class SosAlertRepository
{
    public function create(array $data)
    {
        return SosAlert::create($data);
    }

    public function find($id)
    {
        return SosAlert::findOrFail($id);
    }

    public function findActiveByUserId($userId)
    {
        return SosAlert::where('user_id', $userId)
            ->where('status', 'active')
            ->first();
    }

    public function update($id, array $data)
    {
        $alert = SosAlert::findOrFail($id);
        $alert->update($data);
        return $alert;
    }

    public function getActiveAlerts()
    {
        return SosAlert::with('user')
            ->where('status', 'active')
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public function getAlertHistory($userId = null)
    {
        $query = SosAlert::with('user')->orderBy('created_at', 'desc');
        if ($userId) {
            $query->where('user_id', $userId);
        }
        return $query->get();
    }
}
