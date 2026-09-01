@extends('layouts.admin')

@section('title', 'System Audit Logs')

@section('content')
<div class="card card-custom p-4">
    <h3 class="mb-4 font-weight-bold"><i class="fa-solid fa-receipt text-secondary me-2"></i> System Audit Logs</h3>

    <div class="table-responsive">
        <table class="table table-hover align-middle">
            <thead>
                <tr>
                    <th>Time</th>
                    <th>Administrator</th>
                    <th>Action</th>
                    <th>Details</th>
                    <th>IP Address</th>
                </tr>
            </thead>
            <tbody>
                @forelse($logs as $log)
                    <tr>
                        <td>{{ $log->created_at->format('Y-m-d H:i:s') }}</td>
                        <td><strong>{{ $log->admin ? $log->admin->name : 'System' }}</strong></td>
                        <td><span class="badge bg-dark">{{ $log->action }}</span></td>
                        <td>{{ $log->description }}</td>
                        <td><code>{{ $log->ip_address }}</code></td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="5" class="text-center py-4 text-secondary">No audit logs found.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-3">
        {{ $logs->links() }}
    </div>
</div>
@endsection
