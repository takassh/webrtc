<?php

use App\Events\CheckEvent;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function () {
    return view('welcome');
});

Route::get('/send', function () {
    broadcast(new CheckEvent);
    return 'check receive page';
});

Route::get('/receive', function () {
    return view('receive');
});