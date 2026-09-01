@extends('layouts.admin')

@section('title', 'Incident Reports')

@section('content')
<div class="card card-custom p-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h3 class="m-0 font-weight-bold"><i class="fa-solid fa-file-invoice text-warning me-2"></i> Incident Reports</h3>
        <div class="btn-group">
            <a href="{{ url('/admin/incidents') }}" class="btn btn-outline-secondary btn-sm {{ !request('status') ? 'active' : '' }}">All</a>
            <a href="{{ url('/admin/incidents?status=pending') }}" class="btn btn-outline-secondary btn-sm {{ request('status') == 'pending' ? 'active' : '' }}">Pending</a>
            <a href="{{ url('/admin/incidents?status=verified') }}" class="btn btn-outline-secondary btn-sm {{ request('status') == 'verified' ? 'active' : '' }}">Verified</a>
            <a href="{{ url('/admin/incidents?status=resolved') }}" class="btn btn-outline-secondary btn-sm {{ request('status') == 'resolved' ? 'active' : '' }}">Resolved</a>
        </div>
    </div>

    <div class="table-responsive">
        <table class="table table-hover align-middle">
            <thead>
                <tr>
                    <th>Reporter</th>
                    <th>Title</th>
                    <th>Category</th>
                    <th>Area</th>
                    <th>Coordinates</th>
                    <th>Media</th>
                    <th>Status</th>
                    <th>Reported At</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @forelse($incidents as $incident)
                    <tr>
                        <td><strong>{{ $incident->user->name }}</strong></td>
                        <td>
                            <span class="d-block"><strong>{{ $incident->title }}</strong></span>
                            <small class="text-secondary">{{ Str::limit($incident->description, 50) }}</small>
                        </td>
                        <td><span class="badge bg-secondary">{{ $incident->category }}</span></td>
                        <td>{{ $incident->area }}</td>
                        <td><a href="https://maps.google.com/?q={{ $incident->latitude }},{{ $incident->longitude }}" target="_blank">({{ round($incident->latitude,4) }}, {{ round($incident->longitude,4) }})</a></td>
                        <td>
                            @if($incident->media_url)
                                <a href="{{ $incident->media_url }}" target="_blank" class="btn btn-sm btn-outline-info"><i class="fa-regular fa-image"></i> View File</a>
                            @else
                                <span class="text-secondary">-</span>
                            @endif
                        </td>
                        <td>
                            @if($incident->status === 'pending')
                                <span class="badge bg-warning">Pending</span>
                            @elseif($incident->status === 'verified')
                                <span class="badge bg-primary">Verified</span>
                            @else
                                <span class="badge bg-success">Resolved</span>
                            @endif
                        </td>
                        <td>{{ $incident->created_at->diffForHumans() }}</td>
                        <td>
                            @if($incident->status === 'pending')
                                <form action="{{ url('/admin/incidents/'.$incident->id.'/verify') }}" method="POST" class="d-inline">
                                    @csrf
                                    <button class="btn btn-sm btn-outline-primary" type="submit">Verify</button>
                                </form>
                            @endif

                            @if($incident->status !== 'resolved')
                                <form action="{{ url('/admin/incidents/'.$incident->id.'/resolve') }}" method="POST" class="d-inline">
                                    @csrf
                                    <button class="btn btn-sm btn-success" type="submit">Resolve</button>
                                </form>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="9" class="text-center py-4 text-secondary">No incidents reported matching criteria.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
