<%@ page language="java" import="java.util.*" pageEncoding="UTF-8" %>
<%
    String host=request.getServerName();
    int port=request.getServerPort();
    String path = request.getContextPath();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="description" content="WebRTC code samples">
    <meta name="viewport" content="width=device-width, user-scalable=yes, initial-scale=1, maximum-scale=1">
    <meta itemprop="description" content="Client-side WebRTC code samples">
    <meta itemprop="name" content="WebRTC code samples">
    <meta name="mobile-web-app-capable" content="yes">
    <meta id="theme-color" name="theme-color" content="#ffffff">
    <base target="_blank">
    <title>Peer connection</title>
    <link rel="stylesheet" href="<%=path%>/resource/css/main.css" />
<style>
    button {
        margin: 0 20px 0 0;
        width: 83px;
    }
    button#hangupButton {
        margin: 0;
    }
    video {
        height: 225px;
        margin: 0 0 20px 0;
        vertical-align: top;
        width: calc(50% - 12px);
    }
    video#localVideo {
        margin: 0 20px 20px 0;
    }
    @media screen and (max-width: 400px) {
        button {
            width: 83px;
        }
        button {
            margin: 0 11px 10px 0;
        }
        video {
            height: 90px;
            margin: 0 0 10px 0;
            width: calc(50% - 7px);
        }
        video#localVideo {
            margin: 0 10px 20px 0;
        }
    }
</style>
</head>

<body>

<div id="container">
    <div class="highlight">
        该模式仅支持一对一直播，是否本地直播本地查看：<br>
        <input type="radio" value="Y" name="localwatchradio" onclick="toggleLocalWatch(this)">本地查看
        <input type="radio" value="N" name="localwatchradio" onclick="toggleLocalWatch(this)" checked>本地不查看
    </div>
    <video id="localVideo" autoplay muted></video>
    <video id="remoteVideo" autoplay  style="float: right;"></video>

</div>

<script src="<%=path%>/resource/js/adapter-latest.js"></script>
<script>
    // 创建一个Socket实例
    var socket = new WebSocket('ws://<%=host%>:<%=port%><%=path%>/websocket');
    // 打开Socket
    socket.onopen = function (event) {
        init();
        // 监听消息
        socket.onmessage = function (event) {
            handleMessage(JSON.parse(event.data));
        };
        // 监听Socket的关闭
        socket.onclose = function (event) {
            console.log('Client notified socket has closed', event);
        };
        // 发送一个初始化消息socket.send('I am the client and I\'m listening!');
        // 关闭Socket....socket.close()
    };
</script>
<script>
    window.RTCPeerConnection = window.webkitRTCPeerConnection||window.mozRTCPeerConnection ;
    window.RTCSessionDescription = window.mozRTCSessionDescription || window.RTCSessionDescription;
    window.RTCIceCandidate = window.mozRTCIceCandidate || window.RTCIceCandidate;
    window.URL=window.URL||webkitURL;

    navigator.getUserMedia = navigator.mozGetUserMedia || navigator.webkitGetUserMedia;

    var pc,
        isWatchLocal=document.querySelectorAll('[name="localwatchradio"]:checked')[0].value,
        localVideo=document.getElementById("localVideo"),
        remoteVideo=document.getElementById("remoteVideo")
        ;

    var pc_config = {
            "iceServers" : [ {
                "url" : "stun:stun.ideasip.com"
            } ]
        },
        video_config={
            'audio' : true,
            'video' : true
        },
        mediaConstraints={
            offerToReceiveAudio: 1,
            offerToReceiveVideo: 1
        };

    function doMediaOperate(conf, fun) {
        if (navigator.getUserMedia) {
            navigator.mediaDevices.getUserMedia(conf).then(fun).catch(function (e) {console.log(e);});
        } else {console.warn("Your browser is not support the WebRTC!");}
    }

    function initOffer() {
        pc.createOffer(function setLocalAndSendMessage(sessionDescription) {
            pc.setLocalDescription(sessionDescription).then(function () {},function (e) {console.log(e);});
            socket.send(JSON.stringify({
                event:"offer_cfg",
                cfg:sessionDescription
            }));
        }, function () {console.log(arguments);}, mediaConstraints);
    }

    function init() {
        doMediaOperate(video_config,function (stream) {
            localVideo.srcObject=stream;
            try {
                pc = new RTCPeerConnection(pc_config);
                pc.onicecandidate = function onIceCandidate(event) {
                    if (!event || !event.candidate) return;
                    if (event.candidate) {
                        console.log("candidate");
                        socket.send(JSON.stringify({
                            event: "offer_candidate",
                            cfg: event.candidate
                        }));
                    } else {console.log("End of candidates.");}
                };
            }catch (e){console.log(e)}
            pc.onaddstream = function onRemoteStreamAdded(event) {
                console.log("Remote stream added.");
                localVideo.srcObject = event.stream;
            };
            pc.onconnecting = function onSessionConnecting(message) {
                console.log("Session connecting.");
            };
            pc.onopen = function onSessionOpened(message) {
                console.log("Session opened.");
            };
            pc.onremovestream = function onRemoteStreamRemoved(event) {
                console.log("Remote stream removed.");
            };
            pc.addStream(stream);

            if(isWatchLocal==="N")return;
            initOffer();
        });
    }

    var pc2;
    function initAnswer() {
        pc2 = new RTCPeerConnection(pc_config);
        pc2.onicecandidate = function iceCallback2(event) {
            if (event.candidate) {
                socket.send(JSON.stringify({
                    event:"candidate_back_cfg",
                    cfg:event.candidate
                }));
            }
        };
        pc2.onaddstream = function gotRemoteStream(e) {
            remoteVideo.srcObject = e.stream;
        };
    }
    function handleMessage(msg) {
        if(msg.event==="server_create_reply"){
            if(pc.iceConnectionState==="closed")init();
            initOffer();
        }else if(msg.event==="candidate_cfg_reply"){
            if(isWatchLocal==="N")return;
            console.log("candidate reply");
            var candidate = new RTCIceCandidate(JSON.parse(msg.cfg));
            pc2.addIceCandidate(candidate).then(function () {},function (e) {console.log(e);});
        }else if(msg.event==="offer_cfg_reply") {
            console.log("offer pc:",pc);
                if(pc.iceConnectionState=="connected"&&pc.iceGatheringState=="complete"&&pc.signalingState==="have-local-offer"){
                    alert("有用户在使用该连接，请稍后重试");
                    if(isWatchLocal){
                        document.querySelectorAll('[name="localwatchradio"]:checked')[0].checked=false;
                        document.querySelectorAll('[name="localwatchradio"][value="N"]')[0].checked=true;
                    }
                    return;
                }
            if(isWatchLocal==="N")return;
            var cfg=JSON.parse(msg.cfg);
            initAnswer();
            console.log("setRemoteDescription : ",cfg);
            pc2.setRemoteDescription(new RTCSessionDescription(cfg)).then(function () {},function (e) {console.log(e);});
            pc2.createAnswer().then(
                function gotDescription3(desc) {
                    // Final answer, setting a=recvonly & sdp type to answer.
                    desc.sdp = desc.sdp.replace(/a=inactive/g, 'a=recvonly');
                    desc.type = 'answer';
                    pc2.setLocalDescription(desc).then(function () {},function (e) {console.log(e);});
                    socket.send(JSON.stringify({
                        event:"answer_cfg",
                        cfg:desc
                    }));
                },
                function (e) {console.log(e);}
            );
        }else if(msg.event==="answer_cfg_reply"){
            console.log("answer reply");
            var cfg=JSON.parse(msg.cfg);
            pc.setRemoteDescription(cfg).then(function () {},function (e) {
                console.log(arguments);
                console.log(e);
            });
        }else if(msg.event==="candidate_back_cfg_reply"){
            console.log("candidate back reply");
            var cfg=JSON.parse(msg.cfg);
            pc.addIceCandidate(cfg).then(function () {},function (e) {console.log(e);});
        }else if(msg.event==="connnection_begin_reply"){
            initOffer();
        }
    }

    function toggleLocalWatch(obj) {
        isWatchLocal=document.querySelectorAll('[name="localwatchradio"]:checked')[0].value;
        if(isWatchLocal==="Y"){
            if(pc.iceConnectionState==="closed")init();
            initOffer();
        }else{

            pc2&&pc2.close();
            socket.send(JSON.stringify({
                event:"connection_close_cfg"
            }));
        }
    }
</script>
</body>
</html>
