<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        User::create([
            'email' => 'admin@upeu.edu.pe',
            'password' => Hash::make('admin123'),
            'role' => 'admin',
        ]);

        $this->command->info('✅ Administrador creado: admin@upeu.edu.pe / admin123');
    }
}
