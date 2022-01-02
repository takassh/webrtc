import 'dart:convert';

import 'package:app/webrtc_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:laravel_echo/laravel_echo.dart';
import 'package:socket_io_client/socket_io_client.dart';

const ip = '192.168.0.8';

class WebrtcImplement implements WebrtcInterface {
  RTCPeerConnection? _peerConnection;
  late final Echo _echo;

  final OnTrack onTrack;
  final RTCVideoRenderer localRenderer;
  final VoidCallback initializedCallback;

  WebrtcImplement(
    this.onTrack,
    this.localRenderer,
    this.initializedCallback,
  ) {
    makePeerConnection(onTrack, localRenderer, initializedCallback);
    createClient();
  }

  @override
  Future<void> makePeerConnection(
    OnTrack onTrack,
    RTCVideoRenderer localRenderer,
    VoidCallback initializedCallback,
  ) async {
    _peerConnection = await createPeerConnection({});

    final mediaConstraints = <String, dynamic>{
      'audio': false,
      'video': {
        // 'mandatory': {
        //   'minWidth':
        //       '1280', // Provide your own width, height and frame rate here
        //   'minHeight': '720',
        //   'minFrameRate': '30',
        // },
        'facingMode': 'user',
        'optional': [],
      }
    };
    try {
      final localStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);

      await localRenderer.initialize();
      localRenderer.srcObject = localStream;
      initializedCallback();

      final tracks = localStream.getTracks();
      for (var i = 0; i < tracks.length; i++) {
        await _peerConnection!.addTrack(tracks[i], localStream);
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    _peerConnection!
      ..onAddStream = (stream) {
        debugPrint('onAddStream');
      }
      ..onAddTrack = (stream, track) {
        debugPrint('onAddTrack');
      }
      ..onConnectionState = (state) {
        debugPrint('onConnectionState');
      }
      ..onDataChannel = (dataChannel) {
        debugPrint('onDataChannel');
      }
      ..onIceCandidate = (candidate) {
        debugPrint('onIceCandidate');
      }
      ..onIceConnectionState = (state) {
        debugPrint('onIceConnectionState');
      }
      ..onIceGatheringState = (state) {
        debugPrint('onIceGatheringState');
      }
      ..onRemoveStream = (stream) {
        debugPrint('onRemoveStream');
      }
      ..onRemoveTrack = (stream, track) {
        debugPrint('onRemoveTrack');
      }
      ..onRenegotiationNeeded = () {
        debugPrint('onRenegotiationNeeded');
      }
      ..onSignalingState = (state) {
        debugPrint('onSignalingState');
      }
      ..onTrack = (track) {
        debugPrint('onTrack');
        onTrack(track);
      };
  }

  @override
  void createClient() {
    final socket = io(
      'http://$ip',
      OptionBuilder().disableAutoConnect().setTransports(['websocket']).build(),
    );
    _echo = Echo(
      broadcaster: EchoBroadcasterType.SocketIO,
      client: socket,
    );

    // Listening public channel
    _echo.channel('check-channel').listen('CheckEvent', (e) {
      debugPrint(e.toString());
    });

    _echo.connector.socket.on('connect', (_) => debugPrint('connected'));
    _echo.connector.socket.on('disconnect', (_) => debugPrint('disconnected'));

    _echo.channel('sdp-channel').listen('SdpEvent', (e) {
      final map = Map.from(e as Map);
      final sdp = Sdp(
        socketId: map['socket_id'] as String,
        sdp: map['sdp'] as String,
        type: map['type'] as String,
      );

      if (_echo.socketId() != sdp.socketId) {
        //自分のは受け取らない
        if (sdp.type == 'offer') {
          receiveOffer('${sdp.sdp}\n');
        } else if (sdp.type == 'answer') {
          receiveAnswer('${sdp.sdp}\n');
        }
      }
    });
  }

  @override
  Future<void> sendLocalSdp() async {
    final localSdp = await _peerConnection!.getLocalDescription();

    Uri uri;
    final headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };

    uri = Uri.http(ip, 'api/v0/sdp');

    final body = {
      'socket_id': _echo.socketId(),
      'sdp': localSdp!.sdp,
      'type': localSdp.type
    };

    try {
      await http.post(uri, headers: headers, body: json.encode(body));
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Future<void> makeOffer() async {
    if (_peerConnection == null) {
      await makePeerConnection(onTrack, localRenderer, initializedCallback);
    }
    final localSessionDescription = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(localSessionDescription);
    await sendLocalSdp();
  }

  @override
  Future<void> receiveOffer(String remoteSdp) async {
    final remoteSessionDescription = RTCSessionDescription(remoteSdp, 'offer');
    if (_peerConnection != null) {
      debugPrint('already connection exist');
    } else {
      await makePeerConnection(onTrack, localRenderer, initializedCallback);
    }

    await _peerConnection!.setRemoteDescription(remoteSessionDescription);

    debugPrint('sending Answer. Creating remote session description...');
    if (_peerConnection == null) {
      debugPrint('peerConnection NOT exist!');
      return;
    }

    final localSessionDescription = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(localSessionDescription);
    await sendLocalSdp();
  }

  @override
  Future<void> receiveAnswer(String remoteSdp) async {
    final remoteSessionDescription = RTCSessionDescription(remoteSdp, 'answer');

    if (_peerConnection == null) {
      debugPrint('_peerConnection NOT exist!');
      return;
    }

    await _peerConnection!.setRemoteDescription(remoteSessionDescription);

    debugPrint('receive answer!');
  }

  @override
  Future<void> disconnect() async {
    await _peerConnection!.close();
    await _peerConnection!.dispose();
    _peerConnection = null;
    debugPrint('disconnected');
  }
}
