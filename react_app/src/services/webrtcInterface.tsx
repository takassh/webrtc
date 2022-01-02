export type OnTrack = (event: RTCTrackEvent) => void;

export interface WebrtcInterface {
    makePeerConnection(remoteRenderer: HTMLVideoElement, localRenderer: HTMLVideoElement): Promise<void>;
    createClient(): void;
    sendLocalSdp(): Promise<void>;
    makeOffer(): Promise<void>;
    receiveOffer(remoteSdp: string): Promise<void>;
    receiveAnswer(remoteSdp: string): Promise<void>;
    disconnect(): Promise<void>;
}

export class Sdp {
    constructor(public socketId: string, public sdp: string, public type: string) { };
}
