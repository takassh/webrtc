import React, { useEffect, useRef, useState } from 'react';
import './App.css';
import { Box, Button, Flex } from '@chakra-ui/react'
import { Text } from '@chakra-ui/react'
import WebrtcImplement from './services/webrtcImplement';

function App() {
  const localVideoRef = useRef<HTMLVideoElement>(null);
  const remoteVideoRef = useRef<HTMLVideoElement>(null);
  const webRtcInterface = useRef<WebrtcImplement | null>(null);

  useEffect(() => {
    webRtcInterface.current = new WebrtcImplement(remoteVideoRef!.current!, localVideoRef!.current!);
    return () => { webRtcInterface.current!.disconnect() };
  }, []);

  return (
    <>
      <Flex p='4'>
        <Box flex="1" p='2'>
          <Text>You</Text>
          <video ref={localVideoRef}></video>
        </Box>
        <Box flex="1" p='2'>
          <Text>Other</Text>
          <video ref={remoteVideoRef}></video>
        </Box>
      </Flex>
      <Flex p='4'>
        <Button flex="1" m='2' onClick={() => webRtcInterface.current!.makeOffer()}>
          <Text>Call</Text>
        </Button>
        <Button flex="1" m='2' onClick={() => webRtcInterface.current!.disconnect()}>
          <Text>Disconnect</Text>
        </Button>
      </Flex>
    </>
  )
}

export default App;
