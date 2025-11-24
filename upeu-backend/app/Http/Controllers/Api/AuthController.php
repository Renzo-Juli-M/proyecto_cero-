<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Student;
use App\Models\Juror;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    // Login para Administrador
    public function loginAdmin(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)
                    ->where('role', 'admin')
                    ->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Las credenciales son incorrectas.'],
            ]);
        }

        $token = $user->createToken('admin-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login exitoso',
            'user' => $user,
            'token' => $token,
        ]);
    }

    // Login para Estudiante
    public function loginStudent(Request $request)
    {
        $request->validate([
            'dni' => 'required|string|size:8',
            'student_code' => 'required|string',
        ]);

        $student = Student::where('dni', $request->dni)
                         ->where('student_code', $request->student_code)
                         ->with('user')
                         ->first();

        if (!$student) {
            throw ValidationException::withMessages([
                'dni' => ['Las credenciales son incorrectas.'],
            ]);
        }

        $token = $student->user->createToken('student-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login exitoso',
            'user' => $student->user,
            'student' => $student,
            'token' => $token,
        ]);
    }

    // Login para Jurado
    public function loginJuror(Request $request)
    {
        $request->validate([
            'username' => 'required|string',
            'dni' => 'required|string|size:8',
        ]);

        $juror = Juror::where('username', $request->username)
                     ->where('dni', $request->dni)
                     ->with('user')
                     ->first();

        if (!$juror) {
            throw ValidationException::withMessages([
                'username' => ['Las credenciales son incorrectas.'],
            ]);
        }

        $token = $juror->user->createToken('juror-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login exitoso',
            'user' => $juror->user,
            'juror' => $juror,
            'token' => $token,
        ]);
    }

    // Logout
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Sesión cerrada correctamente',
        ]);
    }

    // Obtener usuario autenticado
    public function me(Request $request)
    {
        $user = $request->user()->load(['student', 'juror']);

        return response()->json([
            'success' => true,
            'user' => $user,
        ]);
    }
}
