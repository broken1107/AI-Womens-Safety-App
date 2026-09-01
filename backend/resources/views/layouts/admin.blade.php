<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title') - Women's Safety Admin Panel</title>
    
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- FontAwesome Icons -->
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css" rel="stylesheet">
    <!-- Google Fonts Outfit -->
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700&display=swap" rel="stylesheet">

    <style>
        body {
            font-family: 'Outfit', sans-serif;
            background-color: #f4f6f9;
        }

        /* Sidebar Styling */
        #sidebar {
            min-width: 250px;
            max-width: 250px;
            min-height: 100vh;
            background: linear-gradient(180deg, #1e1b29 0%, #110e1b 100%);
            color: #fff;
            transition: all 0.3s;
        }

        #sidebar .sidebar-header {
            padding: 20px;
            background: rgba(255, 255, 255, 0.05);
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }

        #sidebar ul.components {
            padding: 20px 0;
        }

        #sidebar ul li a {
            padding: 12px 20px;
            font-size: 1.1em;
            display: block;
            color: rgba(255, 255, 255, 0.7);
            text-decoration: none;
            transition: all 0.2s;
            border-left: 4px solid transparent;
        }

        #sidebar ul li a:hover {
            color: #ff3366;
            background: rgba(255, 255, 255, 0.02);
            border-left-color: #ff3366;
        }

        #sidebar ul li.active > a {
            color: #fff;
            background: rgba(255, 255, 255, 0.05);
            border-left-color: #ff3366;
            font-weight: 600;
        }

        #sidebar ul li a i {
            margin-right: 10px;
            width: 20px;
            text-align: center;
        }

        /* Navbar & Content Area */
        .navbar-custom {
            background-color: #fff;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05);
            padding: 15px 30px;
        }

        .content-container {
            padding: 30px;
        }

        .card-custom {
            border: none;
            border-radius: 12px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            background: #fff;
            transition: transform 0.2s;
        }

        .card-custom:hover {
            transform: translateY(-2px);
        }

        /* Badge Risk styling */
        .badge-high {
            background-color: #ff3366;
            color: #fff;
        }

        .badge-medium {
            background-color: #ff9900;
            color: #fff;
        }

        .badge-low {
            background-color: #00cc66;
            color: #fff;
        }
    </style>
    @yield('styles')
</head>
<body>

<div class="d-flex">
    <!-- Sidebar -->
    <nav id="sidebar">
        <div class="sidebar-header d-flex align-items-center">
            <i class="fa-solid fa-shield-halved fa-2x text-danger me-2"></i>
            <h4 class="m-0 font-weight-bold">Guardian Safety</h4>
        </div>

        <ul class="list-unstyled components">
            <li class="{{ Request::is('admin/dashboard') ? 'active' : '' }}">
                <a href="{{ url('/admin/dashboard') }}"><i class="fa-solid fa-chart-line"></i> Dashboard</a>
            </li>
            <li class="{{ Request::is('admin/users*') ? 'active' : '' }}">
                <a href="{{ url('/admin/users') }}"><i class="fa-solid fa-users"></i> Users</a>
            </li>
            <li class="{{ Request::is('admin/alerts*') ? 'active' : '' }}">
                <a href="{{ url('/admin/alerts') }}"><i class="fa-solid fa-triangle-exclamation"></i> SOS Alerts</a>
            </li>
            <li class="{{ Request::is('admin/incidents*') ? 'active' : '' }}">
                <a href="{{ url('/admin/incidents') }}"><i class="fa-solid fa-file-invoice"></i> Incident Reports</a>
            </li>
            <li class="{{ Request::is('admin/crime*') ? 'active' : '' }}">
                <a href="{{ url('/admin/crime') }}"><i class="fa-solid fa-database"></i> Crime Dataset</a>
            </li>
            <li class="{{ Request::is('admin/logs*') ? 'active' : '' }}">
                <a href="{{ url('/admin/logs') }}"><i class="fa-solid fa-receipt"></i> Audit Logs</a>
            </li>
        </ul>
    </nav>

    <!-- Main Content Area -->
    <div class="flex-grow-1">
        <!-- Top Navbar -->
        <nav class="navbar navbar-expand-lg navbar-custom d-flex justify-content-between align-items-center">
            <h4 class="m-0 font-weight-bold">Admin Portal</h4>
            <div class="d-flex align-items-center">
                <span class="me-3 text-secondary"><i class="fa-regular fa-user-circle me-1"></i> Admin User</span>
                <form action="{{ url('/admin/logout') }}" method="POST" class="m-0">
                    @csrf
                    <button class="btn btn-outline-danger btn-sm" type="submit">
                        <i class="fa-solid fa-right-from-bracket"></i> Logout
                    </button>
                </form>
            </div>
        </nav>

        <!-- Dynamic Content -->
        <div class="content-container">
            @if(session('success'))
                <div class="alert alert-success alert-dismissible fade show" role="alert">
                    {{ session('success') }}
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            @endif

            @if(session('error'))
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    {{ session('error') }}
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            @endif

            @yield('content')
        </div>
    </div>
</div>

<!-- Bootstrap JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<!-- ChartJS for Analytics Charts -->
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
@yield('scripts')
</body>
</html>
