<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Events\SdpEvent;

class SdpController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'id' => 'required',
            // 'sdp' => 'required',
            'type' => 'required|in:offer,answer,candidate'
        ]);


        broadcast(new SdpEvent($request->all()))->toOthers();
    }
}
