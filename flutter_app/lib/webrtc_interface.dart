import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef OnTrack = void Function(RTCTrackEvent event);
typedef OnIceCandidate = void Function(RTCIceCandidate evt);

abstract class WebrtcInterface {
  Future<void> makePeerConnection(
    OnTrack onTrack,
    RTCVideoRenderer localRenderer,
    VoidCallback initializedCallback,
  );
  void createClient();
  Future<void> sendLocalSdp();

  Future<void> makeOffer();
  Future<void> receiveOffer(String sdp);
  Future<void> receiveAnswer(String sdp);

  Future<void> disconnect();
}

class Sdp {
  final String socketId;
  final String sdp;
  final String type;

  Sdp({required this.socketId, required this.sdp, required this.type});
}
