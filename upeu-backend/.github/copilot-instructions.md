# UPEU Backend - Academic Event Management System

## Architecture Overview

This is a **Laravel 12 API** for managing academic presentations with a three-role system: **Admin**, **Juror** (evaluator), and **Student** (ponente/presenter or oyente/attendee). The frontend is separate (not in this repo).

### Core Domain Model
- **Students** have two types: `ponente` (presenter with one article) or `oyente` (attendee who scans QR codes)
- **Articles** are presentations assigned to ponentes, evaluated by exactly 2 jurors, and attended by oyentes
- **Jurors** evaluate articles on 5 criteria (0-20 points each): introducción, metodología, desarrollo, conclusiones, presentación
- **Evaluations** auto-calculate `promedio` (average) from the 5 scores
- **Attendances** are tracked via QR code system (ponentes generate, oyentes scan)

### Key Relationships
```
User (polymorphic role: admin/student/juror)
  ├─> Student (user_id) → Article (many-to-many via article_juror) → Juror
  └─> Juror (user_id) → Evaluation → Article
```

## Critical Patterns & Conventions

### Authentication & Authorization
- Uses **Laravel Sanctum** for API token auth
- Routes grouped by role: `/api/admin/*`, `/api/juror/*`, `/api/student/*`
- All protected routes require `auth:sanctum` middleware
- Default passwords = user's DNI (8-digit national ID)
- Test credentials: `admin@upeu.edu.pe` / `admin123` (see `AdminSeeder.php`)

### Import/Export System
- **maatwebsite/excel** package for Excel operations
- Import classes in `app/Imports/` handle validation + error collection
- Imports track errors per row and return `imported` count + `errors` array
- Column normalization: headers converted to lowercase, trimmed (see `StudentsImport::collection()`)
- Expected columns: `dni`, `codigo`, `nombres`, `apellidos`, `tipo`, `email` (for students)
- Exports in `app/Exports/` generate dated filenames: `estudiantes_2025-10-28.xlsx`
- Full report export creates multi-sheet workbook (5 sheets)

### QR Code Attendance Flow
1. **Ponente** calls `POST /api/student/generate-qr` → creates temporary record in `article_qr_codes` table with 10-min expiry
2. **Oyente** scans QR and calls `POST /api/student/scan-qr` with `qr_code` param
3. System validates: QR not expired, oyente hasn't already attended, article exists
4. Creates `Attendance` record linking oyente to article

### Evaluation Business Rules
- Each article must have exactly **2 jurors assigned** (enforced in `ArticleController@assignJurors`)
- Jurors can only evaluate articles assigned to them
- One evaluation per juror per article (checked in `JurorDashboardController@storeEvaluation`)
- Score range: **0-20** per criterion (matches Peruvian grading system)
- Average calculation: `(sum of 5 scores) / 5`, rounded to 2 decimals

### Model Helpers (Not Accessors)
Models use public methods for computed values (not `getXAttribute()`):
- `Student::fullName()` → concatenates first_name + last_name
- `Article::averageScore()` → queries evaluations avg
- `Article::totalAttendances()` → counts attendance records

## Developer Workflows

### Setup & Development
```bash
# Initial setup (automated)
composer setup

# Development with hot reload (runs 4 concurrent processes)
composer dev  # Starts: server, queue, logs (pail), vite

# Testing
composer test
```

**Important**: The `composer dev` script uses `npx concurrently` to run PHP Artisan server, queue worker, Pail logs, and Vite simultaneously. If one process fails, all are killed (`--kill-others`).

### Database Migrations
- Migration naming: `YYYY_MM_DD_HHMMSS_action_table_name.php`
- Two QR code migrations exist (2025_10_28_073850 and 083545) - likely the second supersedes the first
- Pivot table: `article_juror` with unique composite key `[article_id, juror_id]`

### API Response Format
All endpoints return consistent JSON structure:
```json
{
  "success": true|false,
  "message": "Human-readable message",
  "data": { ... },  // or paginated object
  "error": "Exception message"  // only on failure
}
```

### Route Organization Critical Note
**Order matters!** In `routes/api.php`, specific routes MUST precede `apiResource`:
```php
// ✅ CORRECT: Specific route first
Route::get('/jurors/available', [ArticleController::class, 'availableJurors']);
Route::apiResource('jurors', JurorController::class);

// ❌ WRONG: Would match GET /jurors/available as show(id='available')
```

## Common Tasks

### Adding a New Import
1. Create `app/Imports/XImport.php` implementing `ToCollection, WithHeadingRow`
2. Add error tracking: `protected $errors = []; protected $imported = 0;`
3. Normalize headers: `strtolower(trim($key))` for each column
4. Use `Validator::make()` for row validation, append to `$errors` array with row number
5. Check for duplicates before inserting
6. Wrap in DB transaction if creating related models
7. Add route: `POST /api/admin/import/x` → `AdminController@importX`

### Creating Related Models
Use DB transactions when creating User + Student/Juror:
```php
DB::beginTransaction();
try {
    $user = User::create([...]);
    $student = Student::create(['user_id' => $user->id, ...]);
    DB::commit();
} catch (\Exception $e) {
    DB::rollBack();
    return response()->json(['success' => false, ...], 500);
}
```

### Querying with Role Context
Always scope queries to authenticated user's role:
```php
$juror = Auth::user()->juror;
$articles = $juror->articles()->with(['student', 'evaluations'])->get();
```

## Tech Stack
- **Laravel 12** (PHP 8.2+) with Sanctum authentication
- **maatwebsite/excel 3.1** for imports/exports
- **Vite 7** + Tailwind CSS 4 (frontend assets)
- **Concurrently** for multi-process dev environment
- **Laravel Pail** for log tailing
- Database: Standard Laravel migrations (likely MySQL/PostgreSQL)

## Testing Strategy
- PHPUnit 11.5 configured (`phpunit.xml` present)
- Run via `composer test` (clears config cache first)
- Tests in `tests/Feature/` and `tests/Unit/`

## Recent Improvements (Oct 2025)

### Code Quality & Architecture
- ✅ **ArticleQRCode Model** - Replaced raw DB queries with Eloquent model including scopes (`valid()`, `expired()`, `forArticle()`)
- ✅ **Query Scopes** - Added to all models for reusable queries:
  - `Article`: `byType()`, `byShift()`, `evaluated()`, `upcoming()`, `search()`
  - `Student`: `ponentes()`, `oyentes()`, `search()`
  - `Evaluation`: `byJuror()`, `highScores()`, `orderByScore()`
  - `Juror`: `bySpecialty()`, `withArticles()`, `available()`
- ✅ **API Resources** - Consistent JSON transformation for all models (`StudentResource`, `ArticleResource`, etc.)
- ✅ **Form Requests** - Centralized validation: `StoreStudentRequest`, `UpdateStudentRequest`, `StoreEvaluationRequest`
- ✅ **ApiResponse Trait** - Standardized response methods: `successResponse()`, `errorResponse()`, `createdResponse()`, etc.

### Performance Optimizations
- ✅ **Database Indexes** - Added indexes on frequently queried columns:
  - `students`: type, [first_name, last_name]
  - `articles`: type, shift, presentation_date
  - `evaluations`: promedio, [article_id, promedio]
  - `jurors`: specialty, [first_name, last_name]
  - `attendances`: scanned_at

### New Features
- ✅ **QRCodeCleanupService** - Service class for managing QR code lifecycle
- ✅ **qr:cleanup Command** - Artisan command to clean expired QR codes: `php artisan qr:cleanup [--stats]`
- ✅ **RateLimitQRGeneration** - Middleware limiting QR generation to 5/hour per ponente

### Usage Examples
```php
// Using scopes
$articles = Article::byType('empirico')->upcoming()->get();
$ponentes = Student::ponentes()->search('García')->get();
$topEvaluations = Evaluation::highScores(16)->orderByScore()->get();

// Using API Resources
return new ArticleResource($article);
return StudentResource::collection($students);

// Using ApiResponse trait in controllers
return $this->createdResponse($data, 'Estudiante creado');
return $this->notFoundResponse('Artículo no encontrado');

// Using Form Requests
public function store(StoreStudentRequest $request) {
    // Validation already done
    $validated = $request->validated();
}
```
