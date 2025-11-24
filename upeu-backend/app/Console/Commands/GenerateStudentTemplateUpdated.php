<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;

class GenerateStudentTemplateUpdated extends Command
{
    protected $signature = 'students:generate-template-updated';
    protected $description = 'Generar plantilla Excel ACTUALIZADA para importación de estudiantes (13 columnas)';

    public function handle()
    {
        try {
            $spreadsheet = new Spreadsheet();
            $sheet = $spreadsheet->getActiveSheet();

            // Establecer nombre de la hoja
            $sheet->setTitle('Estudiantes');

            // Headers (13 columnas)
            $headers = [
                'DNI',
                'Codigo',
                'Nombres',
                'Apellidos',
                'Tipo',
                'Email',
                'Sede',
                'Escuela Profesional',
                'Programa Estudio',
                'Ciclo',
                'Grupo',
                'Usuario',
                'Foto'
            ];

            $sheet->fromArray($headers, null, 'A1');

            // Estilo del header
            $headerStyle = [
                'font' => [
                    'bold' => true,
                    'color' => ['rgb' => 'FFFFFF'],
                    'size' => 11,
                ],
                'fill' => [
                    'fillType' => Fill::FILL_SOLID,
                    'startColor' => ['rgb' => '4472C4'],
                ],
                'alignment' => [
                    'horizontal' => Alignment::HORIZONTAL_CENTER,
                    'vertical' => Alignment::VERTICAL_CENTER,
                ],
                'borders' => [
                    'allBorders' => [
                        'borderStyle' => Border::BORDER_THIN,
                        'color' => ['rgb' => '000000'],
                    ],
                ],
            ];

            $sheet->getStyle('A1:M1')->applyFromArray($headerStyle);

            // Ajustar ancho de columnas
            $sheet->getColumnDimension('A')->setWidth(12);  // DNI
            $sheet->getColumnDimension('B')->setWidth(15);  // Codigo
            $sheet->getColumnDimension('C')->setWidth(25);  // Nombres
            $sheet->getColumnDimension('D')->setWidth(25);  // Apellidos
            $sheet->getColumnDimension('E')->setWidth(12);  // Tipo
            $sheet->getColumnDimension('F')->setWidth(30);  // Email
            $sheet->getColumnDimension('G')->setWidth(20);  // Sede
            $sheet->getColumnDimension('H')->setWidth(30);  // Escuela Profesional
            $sheet->getColumnDimension('I')->setWidth(30);  // Programa Estudio
            $sheet->getColumnDimension('J')->setWidth(10);  // Ciclo
            $sheet->getColumnDimension('K')->setWidth(10);  // Grupo
            $sheet->getColumnDimension('L')->setWidth(20);  // Usuario
            $sheet->getColumnDimension('M')->setWidth(40);  // Foto

            // Datos de ejemplo
            $exampleData = [
                [
                    '12345678',
                    '2023001',
                    'Juan Carlos',
                    'García López',
                    'ponente',
                    'juan.garcia@univ.edu.pe',
                    'Filial Juliaca',
                    'Facultad de Ingeniería y Arquitectura',
                    'EP Ingeniería de Sistemas',
                    '1',
                    '1',
                    'juan.garcia',
                    'https://ejemplo.com/fotos/juan.jpg'
                ],
                [
                    '87654321',
                    '2023002',
                    'María Elena',
                    'Rodríguez Pérez',
                    'oyente',
                    'maria.rodriguez@univ.edu.pe',
                    'Filial Juliaca',
                    'Facultad de Ingeniería y Arquitectura',
                    'EP Ingeniería de Sistemas',
                    '1',
                    'unico',
                    'maria.rodriguez',
                    'https://ejemplo.com/fotos/maria.jpg'
                ],
                [
                    '11223344',
                    '2023003',
                    'Pedro Antonio',
                    'Martínez Silva',
                    'ponente',
                    'pedro.martinez@univ.edu.pe',
                    'Filial Juliaca',
                    'Facultad de Ingeniería y Arquitectura',
                    'EP Ingeniería de Sistemas',
                    '1',
                    '2',
                    'pedro.martinez',
                    ''
                ],
            ];

            $sheet->fromArray($exampleData, null, 'A2');

            // Estilo para los datos de ejemplo
            $dataStyle = [
                'borders' => [
                    'allBorders' => [
                        'borderStyle' => Border::BORDER_THIN,
                        'color' => ['rgb' => 'D0D0D0'],
                    ],
                ],
            ];

            $sheet->getStyle('A2:M4')->applyFromArray($dataStyle);

            // Agregar una hoja de instrucciones
            $instructionsSheet = $spreadsheet->createSheet(1);
            $instructionsSheet->setTitle('Instrucciones');

            $instructions = [
                ['INSTRUCCIONES PARA IMPORTAR ESTUDIANTES - VERSIÓN ACTUALIZADA'],
                [''],
                ['1. Formato de Archivo:'],
                ['   - El archivo debe ser Excel (.xlsx o .xls) o CSV'],
                ['   - La primera fila debe contener los encabezados'],
                ['   - No modifique los nombres de las columnas'],
                ['   - El archivo ahora tiene 13 columnas en total'],
                [''],
                ['2. Campos Requeridos:'],
                ['   - DNI: Exactamente 8 dígitos numéricos'],
                ['   - Codigo: Código único del estudiante (máx. 20 caracteres)'],
                ['   - Nombres: Nombres completos del estudiante'],
                ['   - Apellidos: Apellidos completos del estudiante'],
                ['   - Tipo: "ponente" u "oyente" (sin distinguir mayúsculas)'],
                ['   - Email: Email válido y único'],
                ['   - Sede: Sede o filial (máx. 100 caracteres)'],
                ['   - Escuela Profesional: Nombre de la escuela (máx. 150 caracteres)'],
                ['   - Programa Estudio: Programa académico (máx. 150 caracteres)'],
                ['   - Ciclo: Ciclo académico (puede ser número o romano: "1", "I", etc)'],
                ['   - Grupo: Grupo del estudiante (puede ser letra o número: "A", "1", etc)'],
                ['   - Usuario: Username único (solo letras, números, puntos, guiones)'],
                ['   - Foto: URL de la foto del estudiante (OPCIONAL)'],
                [''],
                ['3. Notas Importantes:'],
                ['   - El DNI será usado como contraseña por defecto'],
                ['   - No puede haber DNIs, códigos, emails o usernames duplicados'],
                ['   - Los nombres y apellidos se capitalizarán automáticamente'],
                ['   - El email y username se convertirán a minúsculas automáticamente'],
                ['   - La foto es OPCIONAL, puede dejarse vacía'],
                ['   - Si se proporciona foto, debe ser una URL válida'],
                ['   - IMPORTANTE: Debe seleccionar un periodo antes de importar'],
                ['   - Opcionalmente puede seleccionar un evento específico'],
                [''],
                ['4. Ejemplos Válidos:'],
                ['   DNI: 12345678'],
                ['   Codigo: 2023001, EST-001, A2023-001'],
                ['   Tipo: ponente, Ponente, PONENTE, oyente, Oyente, OYENTE'],
                ['   Email: estudiante@universidad.edu.pe'],
                ['   Sede: Filial Juliaca, Sede Principal'],
                ['   Escuela: Facultad de Ingeniería y Arquitectura'],
                ['   Programa: EP Ingeniería de Sistemas'],
                ['   Ciclo: 1, I, 2, II, III, IV, etc'],
                ['   Grupo: A, B, 1, 2, unico'],
                ['   Usuario: juan.garcia, maria_rodriguez, pedro123'],
                ['   Foto: https://ejemplo.com/foto.jpg, http://cdn.com/imagen.png'],
                [''],
                ['5. Proceso de Importación:'],
                ['   1. Complete el archivo Excel con los datos'],
                ['   2. En el sistema, seleccione el PERIODO académico'],
                ['   3. Opcionalmente seleccione un EVENTO específico'],
                ['   4. Suba el archivo Excel'],
                ['   5. Revise el resumen de importación'],
                ['   6. Si hay errores, descargue el reporte y corrija'],
            ];

            $instructionsSheet->fromArray($instructions, null, 'A1');
            $instructionsSheet->getColumnDimension('A')->setWidth(90);

            // Estilo del título
            $instructionsSheet->getStyle('A1')->applyFromArray([
                'font' => [
                    'bold' => true,
                    'size' => 14,
                    'color' => ['rgb' => '4472C4'],
                ],
            ]);

            // Guardar el archivo
            $templatePath = storage_path('app/templates');

            if (!file_exists($templatePath)) {
                mkdir($templatePath, 0755, true);
            }

            $filePath = $templatePath . '/plantilla_estudiantes_actualizada.xlsx';

            $writer = new Xlsx($spreadsheet);
            $writer->save($filePath);

            $this->info('✅ Plantilla ACTUALIZADA generada exitosamente en: ' . $filePath);
            $this->info('📋 La plantilla ahora incluye 13 columnas con los nuevos campos.');

            return Command::SUCCESS;

        } catch (\Exception $e) {
            $this->error('❌ Error al generar plantilla: ' . $e->getMessage());
            return Command::FAILURE;
        }
    }
}
