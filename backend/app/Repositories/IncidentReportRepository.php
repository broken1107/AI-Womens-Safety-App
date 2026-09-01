<?php

namespace App\Repositories;

use App\Models\IncidentReport;

class IncidentReportRepository
{
    public function create(array $data)
    {
        return IncidentReport::create($data);
    }

    public function getForUser($userId)
    {
        return IncidentReport::where('user_id', $userId)
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public function all()
    {
        return IncidentReport::with('user')->orderBy('created_at', 'desc')->get();
    }

    public function find($id)
    {
        return IncidentReport::findOrFail($id);
    }

    public function update($id, array $data)
    {
        $report = IncidentReport::findOrFail($id);
        $report->update($data);
        return $report;
    }
}
