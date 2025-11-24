<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Period;
use Illuminate\Support\Facades\DB;

class PeriodSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('periods')->truncate();

        $periods = [
            [
                'name' => '2024-1',
                'start_date' => '2024-03-01',
                'end_date' => '2024-07-31',
                'is_active' => false,
                'description' => 'Primer semestre académico 2024',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => '2024-2',
                'start_date' => '2024-08-01',
                'end_date' => '2024-12-31',
                'is_active' => false,
                'description' => 'Segundo semestre académico 2024',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => '2025-1',
                'start_date' => '2025-03-01',
                'end_date' => '2025-07-31',
                'is_active' => false,
                'description' => 'Primer semestre académico 2025',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => '2025-2',
                'start_date' => '2025-08-01',
                'end_date' => '2025-12-31',
                'is_active' => true, // Periodo activo actual
                'description' => 'Segundo semestre académico 2025',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($periods as $period) {
            Period::create($period);
        }

        $this->command->info('✅ Periodos creados exitosamente');
    }
}
