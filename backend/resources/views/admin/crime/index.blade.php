@extends('layouts.admin')

@section('title', 'Crime Dataset Management')

@section('content')
<div class="row g-4 mb-4">
    <!-- Main Listing -->
    <div class="col-md-8">
        <div class="card card-custom p-4">
            <h3 class="mb-4 font-weight-bold"><i class="fa-solid fa-database text-danger me-2"></i> Crime Database logs</h3>
            <div class="table-responsive">
                <table class="table table-hover align-middle">
                    <thead>
                        <tr>
                            <th>Coordinates</th>
                            <th>Area</th>
                            <th>Hour</th>
                            <th>Crime Category</th>
                            <th>Calculated Risk</th>
                            <th>Risk Class</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($crimeData as $data)
                            <tr>
                                <td>({{ round($data->latitude, 4) }}, {{ round($data->longitude, 4) }})</td>
                                <td>{{ $data->area }}</td>
                                <td>{{ $data->hour }}:00</td>
                                <td><span class="badge bg-secondary">{{ $data->crime_category }}</span></td>
                                <td>{{ number_format($data->risk_score, 2) }}</td>
                                <td>
                                    @if($data->risk_label === 'High Risk')
                                        <span class="badge badge-high">High</span>
                                    @elseif($data->risk_label === 'Medium Risk')
                                        <span class="badge badge-medium">Medium</span>
                                    @else
                                        <span class="badge badge-low">Low</span>
                                    @endif
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="6" class="text-center py-4 text-secondary">No crime logs present. Seed the database to load records.</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
            <div class="mt-3">
                {{ $crimeData->links('pagination::bootstrap-5') }}
            </div>
        </div>
    </div>

    <!-- Upload CSV and AI Train Form -->
    <div class="col-md-4">
        <div class="card card-custom p-4 mb-4">
            <h4 class="mb-3 font-weight-bold"><i class="fa-solid fa-file-csv text-success me-2"></i> Import CSV Dataset</h4>
            <p class="text-secondary small">Upload custom CSV coordinates log files to expand the dataset. Format required: latitude, longitude, area, hour, crime_category, risk_score, risk_label.</p>
            <form action="{{ url('/admin/crime/import') }}" method="POST" enctype="multipart/form-data">
                @csrf
                <div class="mb-3">
                    <input class="form-control" type="file" name="csv_file" accept=".csv" required>
                </div>
                <button class="btn btn-success w-100" type="submit">
                    <i class="fa-solid fa-upload me-1"></i> Upload & Parse
                </button>
            </form>
        </div>

        <div class="card card-custom p-4">
            <h4 class="mb-3 font-weight-bold"><i class="fa-solid fa-cogs text-primary me-2"></i> ML Model Actions</h4>
            <p class="text-secondary small">Submit a command to trigger training/retraining of Scikit-Learn Random Forest models on the Python Flask Service.</p>
            <form action="{{ url('/admin/crime/retrain') }}" method="POST">
                @csrf
                <button class="btn btn-primary w-100" type="submit">
                    <i class="fa-solid fa-arrows-rotate me-1 animate-spin"></i> Trigger Retraining
                </button>
            </form>
        </div>
    </div>
</div>
@endsection
