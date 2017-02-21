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
</head>

<body>

<div id="container">
    <div class="highlight">
        <button onclick="watch(true);">本地查看直播</button>
        <button onclick="watch(false);">本地不查看直播</button>
    </div>
    <video id="localVideo" autoplay muted></video>
    <video id="remoteVideo" autoplay  style="float: right;"></video>

</div>

<script src="<%=path%>/resource/js/adapter-latest.js"></script>
<script src="<%=path%>/resource/js/webrtc-pan.js"></script>
<script>

    // 创建一个Socket实例
    var socket = new WebSocket('ws://<%=host%>:<%=port%><%=path%>/websocket');
    // 打开Socket
    socket.onopen = function (event) {
        webRTCLiveChannel.doMediaOperate(video_config,function (stream) {
            localVideo.srcObject = stream;
            streamResource = stream;
        });
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
    var isLocalWatch=false,
        streamResource,
        webRTCLiveChannel=new WebRTCLiveChannel(true),
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

    function init(id) {
        if(webRTCLiveChannel.getServerItem(id))return;
        webRTCLiveChannel.newServerItem({
            id: id,
            stream: streamResource,
            RTCPeerConnectionConfig: pc_config,
            onicecandidate: function (event) {
                socket.send(JSON.stringify({
                    event: "offer_candidate",
                    id: id,
                    cfg: event.candidate
                }));
            },
            onaddstream: function (event) {
                localVideo.srcObject = event.stream;
            }
        });
    }

    function initOffer(id) {
        webRTCLiveChannel.getServerItem(id).createServerOffer(mediaConstraints, function (sessionDescription) {
            socket.send(JSON.stringify({
                event: "offer_cfg",
                id: id,
                cfg: sessionDescription
            }));
        });
    }

    function initAnswer(id) {
        webRTCLiveChannel.newClientItem({
            id:id,
            RTCPeerConnectionConfig:pc_config,
            onicecandidate : function (event) {
                if (event.candidate) {
                    socket.send(JSON.stringify({
                        event:"candidate_back_cfg",
                        cfg:event.candidate
                    }));
                }
            },
            onaddstream : function (e) {
                localVideo.srcObject = e.stream;
            }
        });
    }

    function handleMessage(msg) {
         if(msg.event==="server_create_reply"){
            init(msg.id);
            initOffer(msg.id);
        }else if(msg.event==="answer_cfg_reply"){
            var cfg=JSON.parse(msg.cfg);
            webRTCLiveChannel.getServerItem(msg.id).answerBackReplyFromClient(cfg);
        }else if(msg.event==="candidate_back_cfg_reply"){
            var cfg=JSON.parse(msg.cfg);
            webRTCLiveChannel.getServerItem(msg.id).candidateBackReplyFromClient(cfg);
        }else  if(msg.event==="server_close_reply"){
            webRTCLiveChannel.removeServerItem(msg.id);
        }else if(msg.event==="offer_cfg_reply") {
             var cfg=JSON.parse(msg.cfg);
             if(isLocalWatch) {
                 webRTCLiveChannel.newClientItem({
                     id: msg.id,
                     RTCPeerConnectionConfig: pc_config,
                     onicecandidate: function (event) {
                         if (event.candidate) {
                             socket.send(JSON.stringify({
                                 event: "candidate_back_cfg",
                                 cfg: event.candidate
                             }));
                         }
                     },
                     onaddstream: function (e) {
                         remoteVideo.srcObject = e.stream;
                     }
                 });
                 webRTCLiveChannel.getClientItem(msg.id).createAnswerToServer(cfg, function (desc) {
                     socket.send(JSON.stringify({
                         event: "answer_cfg",
                         cfg: desc
                     }));
                 });
             }
//         }else if(msg.event==="client_create_reply"){
//             initAnswer(msg.id);
//             webRTCLiveChannel.getClientItem(msg.id).createAnswerToServer(cfg, function (desc) {
//                 socket.send(JSON.stringify({
//                     event: "answer_cfg",
//                     cfg: desc
//                 }));
//             });
         }else if(msg.event==="candidate_cfg_reply"){
            webRTCLiveChannel.getClientItem(msg.id).candidateReplyFromServer(JSON.parse(msg.cfg));
         }else if(msg.event==="client_close_reply"){
            webRTCLiveChannel.removeClientItem(msg.id);
        }
    }

    function watch(localWatchEnable) {
        isLocalWatch=localWatchEnable;
        if(localWatchEnable) {
            socket.send(JSON.stringify({event: "client_join"}));
        }else {
            socket.send(JSON.stringify({event: "client_leave"}));
        }
    }

</script>
</body>
</html>
