@extends('layouts.admin')

@section('title', 'Dashboard')

@section('content')
<div class="row g-4 mb-4">
    <!-- Stat 1 -->
    <div class="col-md-3">
        <div class="card-custom p-4 text-center bg-white">
            <div class="d-inline-flex p-3 rounded-circle bg-danger-subtle text-danger mb-3">
                <i class="fa-solid fa-bell fa-2x"></i>
            </div>
            <h5 class="text-secondary font-weight-bold">Active SOS</h5>
            <h2 class="m-0 font-weight-bold text-danger">{{ $activeSosCount }}</h2>
        </div>
    </div>
    <!-- Stat 2 -->
    <div class="col-md-3">
        <div class="card-custom p-4 text-center bg-white">
            <div class="d-inline-flex p-3 rounded-circle bg-primary-subtle text-primary mb-3">
                <i class="fa-solid fa-users fa-2x"></i>
            </div>
            <h5 class="text-secondary">Total Users</h5>
            <h2 class="m-0 font-weight-bold text-primary">{{ $totalUsers }}</h2>
        </div>
    </div>
    <!-- Stat 3 -->
    <div class="col-md-3">
        <div class="card-custom p-4 text-center bg-white">
            <div class="d-inline-flex p-3 rounded-circle bg-warning-subtle text-warning mb-3">
                <i class="fa-solid fa-file-shield fa-2x"></i>
            </div>
            <h5 class="text-secondary">Pending Incidents</h5>
            <h2 class="m-0 font-weight-bold text-warning">{{ $pendingIncidents }}</h2>
        </div>
    </div>
    <!-- Stat 4 -->
    <div class="col-md-3">
        <div class="card-custom p-4 text-center bg-white">
            <div class="d-inline-flex p-3 rounded-circle bg-success-subtle text-success mb-3">
                <i class="fa-solid fa-brain fa-2x"></i>
            </div>
            <h5 class="text-secondary">AI Queries Logged</h5>
            <h2 class="m-0 font-weight-bold text-success">{{ $predictionQueries }}</h2>
        </div>
    </div>
</div>

<div class="row g-4 mb-4">
    <!-- Active Alerts Stream -->
    <div class="col-md-8">
        <div class="card card-custom p-4 h-100">
            <h4 class="mb-3 font-weight-bold text-danger"><i class="fa-solid fa-satellite-dish me-2 animate-pulse"></i> Active Emergency SOS Alerts</h4>
            <div class="table-responsive">
                <table class="table table-hover align-middle">
                    <thead>
                        <tr>
                            <th>User</th>
                            <th>Phone</th>
                            <th>Trigger Position</th>
                            <th>Current Tracking</th>
                            <th>Time</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($activeAlerts as $alert)
                            <tr>
                                <td><strong>{{ $alert->user->name }}</strong></td>
                                <td>{{ $alert->user->phone }}</td>
                                <td><a href="https://maps.google.com/?q={{ $alert->start_latitude }},{{ $alert->start_longitude }}" target="_blank"><i class="fa-solid fa-location-dot text-secondary"></i> ({{ round($alert->start_latitude,4) }}, {{ round($alert->start_longitude,4) }})</a></td>
                                <td>
                                    @if($alert->current_latitude)
                                        <a href="https://maps.google.com/?q={{ $alert->current_latitude }},{{ $alert->current_longitude }}" target="_blank" class="text-danger"><i class="fa-solid fa-location-crosshairs animate-spin"></i> Track Live</a>
                                    @else
                                        <span class="text-secondary">Not updated</span>
                                    @endif
                                </td>
                                <td>{{ $alert->created_at->diffForHumans() }}</td>
                                <td>
                                    <form action="{{ url('/admin/alerts/'.$alert->id.'/resolve') }}" method="POST">
                                        @csrf
                                        <button class="btn btn-sm btn-success" type="submit">Resolve</button>
                                    </form>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="6" class="text-center py-4 text-secondary">No active SOS alerts currently. System safe.</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Analytics Chart -->
    <div class="col-md-4">
        <div class="card card-custom p-4 h-100">
            <h4 class="mb-3 font-weight-bold">Incident Types</h4>
            <div class="d-flex justify-content-center">
                <canvas id="incidentChart" style="max-height: 250px;"></canvas>
            </div>
        </div>
    </div>
</div>
@endsection

@section('scripts')
<script>
    document.addEventListener("DOMContentLoaded", function() {
        const ctx = document.getElementById('incidentChart').getContext('2d');
        const categories = {!! json_encode($incidentChartData->keys()) !!};
        const counts = {!! json_encode($incidentChartData->values()) !!};

        new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: categories.length ? categories : ['No Data'],
                datasets: [{
                    label: 'Incidents Count',
                    data: counts.length ? counts : [1],
                    backgroundColor: [
                        '#ff3366',
                        '#ff9900',
                        '#3399ff',
                        '#00cc66',
                        '#9933ff'
                    ],
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });
    });
</script>
@endsection
