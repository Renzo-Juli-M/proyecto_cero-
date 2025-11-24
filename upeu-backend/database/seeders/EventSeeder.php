<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Event;
use App\Models\Period;
use Illuminate\Support\Facades\DB;

class EventSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('events')->truncate();

        // Obtener periodos
        $period2024_1 = Period::where('name', '2024-1')->first();
        $period2024_2 = Period::where('name', '2024-2')->first();
        $period2025_1 = Period::where('name', '2025-1')->first();
        $period2025_2 = Period::where('name', '2025-2')->first();

        $events = [
            // Eventos 2024-1
            [
                'period_id' => $period2024_1->id,
                'name' => 'I Congreso de Investigación 2024-1',
                'description' => 'Primer congreso de investigación del semestre',
                'start_date' => '2024-05-15',
                'end_date' => '2024-05-17',
                'location' => 'Auditorio Principal',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'period_id' => $period2024_1->id,
                'name' => 'Feria de Proyectos 2024-1',
                'description' => 'Exposición de proyectos de investigación',
                'start_date' => '2024-06-20',
                'end_date' => '2024-06-22',
                'location' => 'Pabellón de Exposiciones',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],

            // Eventos 2024-2
            [
                'period_id' => $period2024_2->id,
                'name' => 'II Congreso de Investigación 2024-2',
                'description' => 'Segundo congreso de investigación del año',
                'start_date' => '2024-10-10',
                'end_date' => '2024-10-12',
                'location' => 'Auditorio Principal',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],

            // Eventos 2025-1
            [
                'period_id' => $period2025_1->id,
                'name' => 'I Congreso de Investigación 2025-1',
                'description' => 'Primer congreso de investigación 2025',
                'start_date' => '2025-05-15',
                'end_date' => '2025-05-17',
                'location' => 'Auditorio Principal',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],

            // Eventos 2025-2 (periodo actual activo)
            [
                'period_id' => $period2025_2->id,
                'name' => 'II Congreso de Investigación 2025-2',
                'description' => 'Segundo congreso de investigación 2025',
                'start_date' => '2025-11-15',
                'end_date' => '2025-11-17',
                'location' => 'Auditorio Principal',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'period_id' => $period2025_2->id,
                'name' => 'Simposio de Tecnología e Innovación',
                'description' => 'Simposio de nuevas tecnologías',
                'start_date' => '2025-11-20',
                'end_date' => '2025-11-22',
                'location' => 'Centro de Convenciones',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'period_id' => $period2025_2->id,
                'name' => 'Feria de Proyectos Finales',
                'description' => 'Exposición de proyectos finales del semestre',
                'start_date' => '2025-12-10',
                'end_date' => '2025-12-12',
                'location' => 'Campus Universitario',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($events as $event) {
            Event::create($event);
        }

        $this->command->info('✅ Eventos creados exitosamente');
    }
}
