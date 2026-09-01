@extends('layouts.admin')

@section('title', 'User Management')

@section('content')
<div class="card card-custom p-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h3 class="m-0 font-weight-bold"><i class="fa-solid fa-users text-primary me-2"></i> User Management</h3>
        <form action="{{ url('/admin/users') }}" method="GET" class="d-flex w-25">
            <input class="form-control me-2" type="search" name="search" placeholder="Search by name, email..." value="{{ request('search') }}">
            <button class="btn btn-outline-primary" type="submit">Search</button>
        </form>
    </div>

    <div class="table-responsive">
        <table class="table table-hover align-middle">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Phone</th>
                    <th>Status</th>
                    <th>Registered At</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @forelse($users as $user)
                    <tr>
                        <td>{{ $user->id }}</td>
                        <td><strong>{{ $user->name }}</strong></td>
                        <td>{{ $user->email }}</td>
                        <td>{{ $user->phone }}</td>
                        <td>
                            @if($user->status === 'active')
                                <span class="badge bg-success">Active</span>
                            @elseif($user->status === 'suspended')
                                <span class="badge bg-danger">Suspended</span>
                            @else
                                <span class="badge bg-warning">Pending</span>
                            @endif
                        </td>
                        <td>{{ $user->created_at->format('Y-m-d H:i') }}</td>
                        <td>
                            @if($user->status === 'suspended')
                                <form action="{{ url('/admin/users/'.$user->id.'/activate') }}" method="POST" class="d-inline">
                                    @csrf
                                    <button class="btn btn-sm btn-outline-success" type="submit">Activate</button>
                                </form>
                            @else
                                <form action="{{ url('/admin/users/'.$user->id.'/suspend') }}" method="POST" class="d-inline">
                                    @csrf
                                    <button class="btn btn-sm btn-outline-danger" type="submit">Suspend</button>
                                </form>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="7" class="text-center py-4 text-secondary">No users found matching query.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-3">
        {{ $users->links() }}
    </div>
</div>
@endsection
