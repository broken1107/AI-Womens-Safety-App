<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Login - Guardian Safety</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600&display=swap" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css" rel="stylesheet">
    
    <style>
        body {
            font-family: 'Outfit', sans-serif;
            background: linear-gradient(135deg, #1e1b29 0%, #0d0b14 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #fff;
        }

        .login-card {
            border: none;
            border-radius: 16px;
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            padding: 40px;
            width: 100%;
            max-width: 420px;
            box-shadow: 0 15px 35px rgba(0,0,0,0.5);
        }

        .form-control-custom {
            background: rgba(255, 255, 255, 0.08);
            border: 1px solid rgba(255, 255, 255, 0.1);
            color: #fff;
            padding: 12px 16px;
            border-radius: 8px;
        }

        .form-control-custom:focus {
            background: rgba(255, 255, 255, 0.12);
            border-color: #ff3366;
            color: #fff;
            box-shadow: none;
        }

        .btn-custom {
            background: linear-gradient(90deg, #ff3366 0%, #ff5e36 100%);
            border: none;
            padding: 12px;
            font-weight: 600;
            border-radius: 8px;
            transition: all 0.3s;
        }

        .btn-custom:hover {
            opacity: 0.9;
            transform: translateY(-1px);
        }
    </style>
</head>
<body>

<div class="login-card text-center">
    <div class="mb-4">
        <i class="fa-solid fa-shield-halved fa-3x text-danger mb-2"></i>
        <h3 class="font-weight-bold">Guardian Safety</h3>
        <span class="text-secondary">Administrative Console</span>
    </div>

    @if($errors->any())
        <div class="alert alert-danger py-2 text-start small">
            <ul class="m-0 pl-3">
                @foreach($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <form action="{{ url('/admin/login') }}" method="POST">
        @csrf
        <div class="mb-3 text-start">
            <label class="form-label text-secondary small">Email Address</label>
            <input type="email" name="email" class="form-control form-control-custom" placeholder="admin@guardian.com" required value="{{ old('email') }}">
        </div>

        <div class="mb-4 text-start">
            <label class="form-label text-secondary small">Password</label>
            <input type="password" name="password" class="form-control form-control-custom" placeholder="••••••••" required>
        </div>

        <button class="btn btn-primary w-100 btn-custom mb-3" type="submit">
            Sign In
        </button>
    </form>
</div>

</body>
</html>
