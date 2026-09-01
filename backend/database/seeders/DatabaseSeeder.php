<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Seed Admins & Crime Data
        $this->call([
            AdminSeeder::class,
            CrimeDataSeeder::class,
        ]);

        User::create([
            'name' => 'Safety Test User',
            'email' => 'test@safety.com',
            'phone' => '9876543210',
            'password' => \Illuminate\Support\Facades\Hash::make('password123'),
            'status' => 'active',
            'email_verified_at' => now(),
        ]);
    }
}
