<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class AdminAuthController extends Controller
{
    public function showLoginForm()
    {
        if (Auth::guard('admin')->check()) {
            return redirect('/admin/dashboard');
        }
        return view('admin.login');
    }

    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return back()->withErrors($validator)->withInput();
        }

        $credentials = $request->only('email', 'password');

        if (Auth::guard('admin')->attempt($credentials)) {
            $request->session()->regenerate();
            
            // Log audit trace
            \App\Models\AuditLog::create([
                'admin_id' => Auth::guard('admin')->id(),
                'action' => 'LOGIN',
                'description' => 'Administrator logged in to dashboard console.',
                'ip_address' => $request->ip(),
            ]);

            return redirect()->intended('/admin/dashboard');
        }

        return back()->withErrors([
            'email' => 'The provided credentials do not match our administrative records.',
        ])->withInput();
    }

    public function logout(Request $request)
    {
        if (Auth::guard('admin')->check()) {
            \App\Models\AuditLog::create([
                'admin_id' => Auth::guard('admin')->id(),
                'action' => 'LOGOUT',
                'description' => 'Administrator logged out of dashboard console.',
                'ip_address' => $request->ip(),
            ]);

            Auth::guard('admin')->logout();
        }

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect('/admin/login');
    }
}
