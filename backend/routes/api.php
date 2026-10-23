<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ExpenseController;
use App\Http\Controllers\Api\SettlementController;
use App\Http\Controllers\Api\TabController;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::patch('/me', [AuthController::class, 'updateProfile']);

    Route::get('/tabs', [TabController::class, 'index']);
    Route::post('/tabs', [TabController::class, 'store']);
    Route::get('/tabs/{tab}', [TabController::class, 'show']);
    Route::get('/tabs/{tab}/balances', [TabController::class, 'balances']);
    Route::post('/tabs/{tab}/members', [TabController::class, 'addMember']);

    Route::get('/tabs/{tab}/expenses', [ExpenseController::class, 'index']);
    Route::post('/tabs/{tab}/expenses', [ExpenseController::class, 'store']);
    Route::get('/tabs/{tab}/expenses/{expense}', [ExpenseController::class, 'show']);
    Route::put('/tabs/{tab}/expenses/{expense}', [ExpenseController::class, 'update']);
    Route::delete('/tabs/{tab}/expenses/{expense}', [ExpenseController::class, 'destroy']);

    Route::get('/tabs/{tab}/settlements', [SettlementController::class, 'index']);
    Route::post('/tabs/{tab}/settlements', [SettlementController::class, 'store']);
    Route::get('/tabs/{tab}/settlements/suggestions', [SettlementController::class, 'suggestions']);
});
