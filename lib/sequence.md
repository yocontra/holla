# Offer from Chrome

```
v=0
o=- 1196243851 2 IN IP4 127.0.0.1
s=-
t=0 0
a=group:BUNDLE audio video
a=msid-semantic: WMS ZiNUtAFWWumqt0tovX6AWjSj540TU2dTxoVT
m=audio 1 RTP/SAVPF 111 104  0 8 106 13 126
c=IN IP4 0.0.0.0
a=rtcp:1 IN IP4 0.0.0.0
a=ice-ufrag:oWdWJcVO8aIJAiqu
a=ice-pwd:qETFnPXhDkDbiLPAwtEHuh8q
a=fingerprint:sha-256 89:EB:6B:92:D6:9A:64:4F:CC:78:B1:BA:99:A6:4B:3E:DB:B1:6F:0C:FE:5E:10:4D:2F:95:6D:C6:74:7C:80:DB
a=sendrecv
a=mid:audio
a=rtcp-mux
a=crypto:1 AES_CM_128_HMAC_SHA1_80 inline:OgW6XsC5w75ftvs2bDHB2IM2sj5o03q0QHPYMrpE
a=rtpmap:103 ISAC/16000
a=rtpmap:104 ISAC/32000
a=rtpmap:111 opus/48000/2
a=rtpmap:0 PCMU/8000
a=rtpmap:8 PCMA/8000
a=rtpmap:106 CN/32000
a=rtpmap:13 CN/8000
a=rtpmap:126 telephone-event/8000
a=ssrc:1216895321 cname:lGlprdoJnf8ppmQc
a=ssrc:1216895321 msid:ZiNUtAFWWumqt0tovX6AWjSj540TU2dTxoVT a0
a=ssrc:1216895321 mslabel:ZiNUtAFWWumqt0tovX6AWjSj540TU2dTxoVT
a=ssrc:1216895321 label:ZiNUtAFWWumqt0tovX6AWjSj540TU2dTxoVTa0
m=video 1 RTP/SAVPF 100 116 117
c=IN IP4 0.0.0.0
a=rtcp:1 IN IP4 0.0.0.0
a=ice-ufrag:oWdWJcVO8aIJAiqu
a=ice-pwd:qETFnPXhDkDbiLPAwtEHuh8q
a=fingerprint:sha-256 89:EB:6B:92:D6:9A:64:4F:CC:78:B1:BA:99:A6:4B:3E:DB:B1:6F:0C:FE:5E:10:4D:2F:95:6D:C6:74:7C:80:DB
a=sendrecv
a=mid:video
a=rtcp-mux
a=crypto:1 AES_CM_128_HMAC_SHA1_80 inline:OgW6XsC5w75ftvs2bDHB2IM2sj5o03q0QHPYMrpE
a=rtpmap:100 VP8/90000
a=rtpmap:116 red/90000
a=rtpmap:117 ulpfec/90000
a=ssrc:1989440299 cname:lGlprdoJnf8ppmQc
a=ssrc:1989440299 msid:ZiNUtAFWWumqt0tovX6AWjSj540TU2dTxoVT v0
a=ssrc:1989440299 mslabel:ZiNUtAFWWumqt0tovX6AWjSj540TU2dTxoVT
a=ssrc:1989440299 label:ZiNUtAFWWumqt0tovX6AWjSj540TU2dTxoVTv0
```


# Offer from FF

```
v=0
o=Mozilla-SIPUA 13019 0 IN IP4 0.0.0.0
s=SIP Call
t=0 0
a=ice-ufrag:08ea3118
a=ice-pwd:9461ee1123a4a0378624117018042460
a=fingerprint:sha-256 D2:3F:8A:AB:B5:A1:CE:DC:E5:64:95:BD:9B:C3:23:CF:5F:6D:BD:13:FA:24:61:58:2C:64:53:9A:10:26:D4:F5
m=audio 63274 RTP/SAVPF 109 0 8 101
a=crypto:1 AES_CM_128_HMAC_SHA1_80 inline:BAADBAADBAADBAADBAADBAADBAADBAADBAADBAAD
c=IN IP4 38.104.206.46
a=rtpmap:109 opus/48000/2
a=ptime:20
a=rtpmap:0 PCMU/8000
a=rtpmap:8 PCMA/8000
a=rtpmap:101 telephone-event/8000
a=fmtp:101 0-15
a=sendrecv
a=candidate:0 1 UDP 2113667327 192.168.23.176 64731 typ host
a=candidate:1 1 UDP 1694264319 38.104.206.46 63274 typ srflx raddr 192.168.23.176 rport 64731
a=candidate:2 1 UDP 2113339647 10.199.16.117 63268 typ host
a=candidate:0 2 UDP 2113667326 192.168.23.176 63625 typ host
a=candidate:1 2 UDP 1694264318 38.104.206.46 1088 typ srflx raddr 192.168.23.176 rport 63625
a=candidate:2 2 UDP 2113339646 10.199.16.117 60279 typ host
m=video 28074 RTP/SAVPF 120
a=crypto:1 AES_CM_128_HMAC_SHA1_80 inline:BAADBAADBAADBAADBAADBAADBAADBAADBAADBAAD
c=IN IP4 38.104.206.46
a=rtpmap:120 VP8/90000
a=sendrecv
a=candidate:0 1 UDP 2113667327 192.168.23.176 52585 typ host
a=candidate:1 1 UDP 1694264319 38.104.206.46 28074 typ srflx raddr 192.168.23.176 rport 52585
a=candidate:2 1 UDP 2113339647 10.199.16.117 60568 typ host
a=candidate:0 2 UDP 2113667326 192.168.23.176 52095 typ host
a=candidate:1 2 UDP 1694264318 38.104.206.46 10636 typ srflx raddr 192.168.23.176 rport 52095
a=candidate:2 2 UDP 2113339646 10.199.16.117 54253 typ host
m=application 3085 SCTP/DTLS 5000 
a=crypto:1 AES_CM_128_HMAC_SHA1_80 inline:BAADBAADBAADBAADBAADBAADBAADBAADBAADBAAD
c=IN IP4 38.104.206.46
a=fmtp:5000 protocol=webrtc-datachannel;streams=16
a=sendrecv
a=candidate:0 1 UDP 2113667327 192.168.23.176 63476 typ host
a=candidate:1 1 UDP 1694264319 38.104.206.46 3085 typ srflx raddr 192.168.23.176 rport 63476
a=candidate:2 1 UDP 2113339647 10.199.16.117 56979 typ host
a=candidate:0 2 UDP 2113667326 192.168.23.176 62303 typ host
a=candidate:1 2 UDP 1694264318 38.104.206.46 9813 typ srflx raddr 192.168.23.176 rport 62303
a=candidate:2 2 UDP 2113339646 10.199.16.117 54226 typ host
```
