<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Events\SdpEvent;

class SdpController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'sdp' => 'required',
            'socket_id' => 'required',
            'type' => 'required|in:offer,answer'
        ]);

        broadcast(new SdpEvent($request->all()))->toOthers();

        return 'success';
    }
}
