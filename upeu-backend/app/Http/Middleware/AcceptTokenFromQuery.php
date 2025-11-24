<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AcceptTokenFromQuery
{
    public function handle(Request $request, Closure $next): Response
    {
        // Si viene un token en la query, agregarlo al header
        if ($request->has('token')) {
            $token = $request->query('token');
            $request->headers->set('Authorization', "Bearer {$token}");
        }

        return $next($request);
    }
}
