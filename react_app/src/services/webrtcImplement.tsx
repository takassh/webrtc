import axios, { AxiosRequestConfig } from "axios";
import Echo from "laravel-echo";
import { Sdp, WebrtcInterface } from "./webrtcInterface";

declare global {
    interface Window {
        io: Function;
    }
}

window.io = require("socket.io-client");

export default class WebrtcImplement implements WebrtcInterface {
    private readonly _ip: string = 'localhost';
    private _peerConnection?: RTCPeerConnection;
    private _echo?: Echo;

    constructor(public remoteRenderer: HTMLVideoElement, public localRenderer: HTMLVideoElement) {
        this.makePeerConnection(remoteRenderer, localRenderer);
        this.createClient();
    }

    async makePeerConnection(remoteRenderer: HTMLVideoElement, localRenderer: HTMLVideoElement): Promise<void> {
        this._peerConnection = await new RTCPeerConnection();
        // Media contrains
        const constraints = {
            'audio': false,
            'video': {
                'facingMode': 'user',
            }
        };

        try {
            const localStream = await navigator.mediaDevices
                .getUserMedia(constraints);

            localRenderer.srcObject = localStream;
            localRenderer.play();

            const tracks = localStream.getTracks();
            for (var i = 0; i < tracks.length; i++) {
                this._peerConnection!.addTrack(tracks[i], localStream);
            }
        } catch (e) {
            console.log(e);
        }

        this._peerConnection!.ontrack = (event) => {
            console.log('addTrack');
            remoteRenderer.srcObject = event.streams[0];
            remoteRenderer.play();
        };
    }

    createClient(): void {
        this._echo = new Echo({
            broadcaster: "socket.io",
            host: "http://localhost",
        });

        this._echo.channel('check-channel').listen('CheckEvent', (e: any) => {
            console.log(e);
        });

        this._echo.channel('sdp-channel').listen('SdpEvent', (map: { [key: string]: any }) => {
            const sdp = new Sdp(map['socket_id'], map['sdp'], map['type']);

            if (this._echo!.socketId() !== sdp.socketId) {
                //自分のは受け取らない
                if (sdp.type === 'offer') {
                    this.receiveOffer(`${sdp.sdp}\n`);
                } else if (sdp.type === 'answer') {
                    this.receiveAnswer(`${sdp.sdp}\n`);
                }
            }
        });
    }
    async sendLocalSdp(): Promise<void> {

        const localSdp = this._peerConnection!.localDescription;

        const uri = new URL('api/v0/sdp', `http://${this._ip}`);

        const options: AxiosRequestConfig = {
            headers: {
                'Content-type': 'application/json',
                'Accept': 'application/json',
            },
        };

        const body = {
            'socket_id': this._echo!.socketId(),
            'sdp': localSdp!.sdp,
            'type': localSdp!.type,
        };

        try {
            await axios.post(uri.href, body, options);
        } catch (e) {
            console.log(e);
        }
    }
    async makeOffer(): Promise<void> {
        if (this._peerConnection === undefined) {
            await this.makePeerConnection(this.remoteRenderer, this.localRenderer);
        }
        const localSessionDescription = await this._peerConnection!.createOffer();
        await this._peerConnection!.setLocalDescription(localSessionDescription);
        await this.sendLocalSdp();
    }
    async receiveOffer(remoteSdp: string): Promise<void> {
        const remoteSessionDescription = new RTCSessionDescription({ sdp: remoteSdp, type: 'offer' });
        if (this._peerConnection != null) {
            console.log('already connection exist');
        } else {
            await this.makePeerConnection(this.remoteRenderer, this.localRenderer);
        }

        await this._peerConnection!.setRemoteDescription(remoteSessionDescription);

        console.log('sending Answer. Creating remote session description...');
        if (this._peerConnection == null) {
            console.log('peerConnection NOT exist!');
            return;
        }

        const localSessionDescription = await this._peerConnection!.createAnswer();
        await this._peerConnection!.setLocalDescription(localSessionDescription);
        await this.sendLocalSdp();
    }
    async receiveAnswer(remoteSdp: string): Promise<void> {
        const remoteSessionDescription = new RTCSessionDescription({ sdp: remoteSdp, type: 'answer' });

        if (this._peerConnection == null) {
            console.log('_peerConnection NOT exist!');
            return;
        }

        await this._peerConnection!.setRemoteDescription(remoteSessionDescription);

        console.log('receive answer!');
    }
    async disconnect(): Promise<void> {
        await this._peerConnection!.close();
        this._peerConnection = undefined;
        console.log('disconnected');
    }
}