@extends('layouts.admin')

@section('title', 'SOS Alerts Management')

@section('content')
<div class="card card-custom p-4">
    <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
        <h3 class="m-0 font-weight-bold">
            <i class="fa-solid fa-triangle-exclamation text-danger me-2"></i> SOS Alerts Management
        </h3>
        <div class="btn-group">
            <a href="{{ url('/admin/alerts') }}" class="btn btn-outline-secondary btn-sm {{ !request('status') ? 'active' : '' }}">
                <i class="fa-solid fa-list me-1"></i> All Alerts
            </a>
            <a href="{{ url('/admin/alerts?status=active') }}" class="btn btn-outline-danger btn-sm {{ request('status') == 'active' ? 'active' : '' }}">
                <i class="fa-solid fa-satellite-dish me-1"></i> Active
            </a>
            <a href="{{ url('/admin/alerts?status=resolved') }}" class="btn btn-outline-success btn-sm {{ request('status') == 'resolved' ? 'active' : '' }}">
                <i class="fa-solid fa-circle-check me-1"></i> Resolved
            </a>
        </div>
    </div>

    <div class="table-responsive">
        <table class="table table-hover align-middle">
            <thead class="table-light">
                <tr>
                    <th>ID</th>
                    <th>User</th>
                    <th>Contact</th>
                    <th>Initial Location</th>
                    <th>Live Tracking Location</th>
                    <th>Code</th>
                    <th>Status</th>
                    <th>Triggered Time</th>
                    <th>Resolved Time</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @forelse($alerts as $alert)
                    <tr>
                        <td><strong>#{{ $alert->id }}</strong></td>
                        <td>
                            <strong>{{ $alert->user ? $alert->user->name : 'Unknown User' }}</strong>
                            @if($alert->user)
                                <br><small class="text-muted">{{ $alert->user->email }}</small>
                            @endif
                        </td>
                        <td>{{ $alert->user ? $alert->user->phone : '-' }}</td>
                        <td>
                            @if($alert->start_latitude && $alert->start_longitude)
                                <a href="https://maps.google.com/?q={{ $alert->start_latitude }},{{ $alert->start_longitude }}" target="_blank" class="text-decoration-none">
                                    <i class="fa-solid fa-location-dot text-secondary me-1"></i>
                                    ({{ round($alert->start_latitude, 4) }}, {{ round($alert->start_longitude, 4) }})
                                </a>
                            @else
                                <span class="text-secondary">-</span>
                            @endif
                        </td>
                        <td>
                            @if($alert->current_latitude && $alert->current_longitude)
                                <a href="https://maps.google.com/?q={{ $alert->current_latitude }},{{ $alert->current_longitude }}" target="_blank" class="text-decoration-none {{ $alert->status === 'active' ? 'text-danger font-weight-bold' : 'text-primary' }}">
                                    @if($alert->status === 'active')
                                        <i class="fa-solid fa-location-crosshairs fa-spin me-1"></i>
                                    @else
                                        <i class="fa-solid fa-map-pin me-1"></i>
                                    @endif
                                    ({{ round($alert->current_latitude, 4) }}, {{ round($alert->current_longitude, 4) }})
                                </a>
                            @else
                                <span class="text-secondary">Not updated</span>
                            @endif
                        </td>
                        <td>
                            @if($alert->verification_code)
                                <code>{{ $alert->verification_code }}</code>
                            @else
                                <span class="text-secondary">-</span>
                            @endif
                        </td>
                        <td>
                            @if($alert->status === 'active')
                                <span class="badge bg-danger">
                                    <i class="fa-solid fa-circle-exclamation me-1"></i> Active
                                </span>
                            @else
                                <span class="badge bg-success">
                                    <i class="fa-solid fa-circle-check me-1"></i> Resolved
                                </span>
                            @endif
                        </td>
                        <td>
                            <span>{{ $alert->created_at ? $alert->created_at->diffForHumans() : '-' }}</span>
                            <br>
                            <small class="text-muted">{{ $alert->created_at ? $alert->created_at->format('Y-m-d H:i') : '' }}</small>
                        </td>
                        <td>
                            @if($alert->resolved_at)
                                <span>{{ $alert->resolved_at->format('Y-m-d H:i') }}</span>
                                <br>
                                <small class="text-muted">{{ $alert->resolved_at->diffForHumans() }}</small>
                            @else
                                <span class="text-secondary">-</span>
                            @endif
                        </td>
                        <td>
                            @if($alert->status === 'active')
                                <form action="{{ url('/admin/alerts/'.$alert->id.'/resolve') }}" method="POST" class="d-inline" onsubmit="return confirm('Are you sure you want to resolve this SOS alert?');">
                                    @csrf
                                    <button class="btn btn-sm btn-success text-nowrap" type="submit">
                                        <i class="fa-solid fa-check me-1"></i> Resolve
                                    </button>
                                </form>
                            @else
                                <span class="badge bg-light text-muted border">Completed</span>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="10" class="text-center py-5 text-secondary">
                            <i class="fa-solid fa-shield-halved fa-3x text-muted mb-3 d-block"></i>
                            <p class="m-0 fs-5">No SOS alerts found matching the selected filter.</p>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">
        {{ $alerts->links() }}
    </div>
</div>
@endsection
