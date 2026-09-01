<?php

namespace Database\Seeders;

use App\Models\Admin;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        Admin::create([
            'name' => 'Super Administrator',
            'email' => 'super@guardian.com',
            'password' => Hash::make('password123'),
            'role' => 'super_admin',
            'status' => 'active',
        ]);

        Admin::create([
            'name' => 'Safety Moderator',
            'email' => 'moderator@guardian.com',
            'password' => Hash::make('password123'),
            'role' => 'moderator',
            'status' => 'active',
        ]);
    }
}
