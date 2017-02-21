<%@ page language="java" import="java.util.*" pageEncoding="UTF-8" %>
<%
    String host=request.getServerName();
    int port=request.getServerPort();
    String path = request.getContextPath();
//String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path+"/";
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
    <%--<base href="<%=basePath%>">--%>
    <title>My JSP 'index.jsp' starting page</title>
    <meta http-equiv="pragma" content="no-cache">
    <meta http-equiv="cache-control" content="no-cache">
    <meta http-equiv="expires" content="0">
    <meta http-equiv="keywords" content="keyword1,keyword2,keyword3">
    <meta http-equiv="description" content="This is my page">
    <%--<script type="application/javascript" src="js/soundmeter.js"></script>--%>
    <!--
    <link rel="stylesheet" type="text/css" href="styles.css">
    -->

</head>

<body>
<%=path%>
<video id="video" autoplay></video>
<audio id="audio" controller autoplay></audio>
<br>
<meter id="m1" hight="0.25" max="1" value="0"></meter>
<br>
<meter id="m2" hight="0.25" max="1" value="0"></meter>
<br>
<meter id="m3" hight="0.25" max="1" value="0"></meter>
<br>
<select id="rooms"></select>

</body>
<script src="http://libs.baidu.com/jquery/2.0.0/jquery.min.js"></script>
<script src="<%=path%>/resource/js/Notification.js"></script>
<script type="text/javascript">
    window.RTCPeerConnection = window.webkitRTCPeerConnection||window.mozRTCPeerConnection ;
    window.RTCSessionDescription = window.mozRTCSessionDescription || window.RTCSessionDescription;
    window.RTCIceCandidate = window.mozRTCIceCandidate || window.RTCIceCandidate;
    window.URL=window.URL||webkitURL;

    navigator.getUserMedia = navigator.mozGetUserMedia || navigator.webkitGetUserMedia;

    var pc,socket,
        localVideo=document.getElementById("video");
    var pc_config = {
            "iceServers" : [ {
                "url" : "stun:stun.ideasip.com"
            } ]
        };
    $.post("<%=path%>/user/getRooms",function (data) {
        initWebSocket();

        var ops="<option value='-1'>please select</option>";
        data=data.data;
        for (var i = 0; i < data.length; i++) {
            var k = data[i];
            if(k.status==true)ops+="<option value='"+encodeURIComponent(k.address)+"'>"+k.address+"</option>";
        }
        $("#rooms").html(ops);
    },"json");

    function initWebSocket() {
        // 创建一个Socket实例
        socket = new WebSocket('ws://<%=host%>:<%=port%><%=path%>/video');
        // 打开Socket
        socket.onopen = function (event) {
            $("#rooms").on("change",function () {
                var value=$(this).val();
                if(value=="-1"){
                    socket.send(JSON.stringify({
                        event: "leave_room"
                    }));
                    pc.close();
                }else {
                    if(pc.iceConnectionState==="closed")initAnswer();
                    socket.send(JSON.stringify({
                        event: "join_room",
                        address: decodeURIComponent(value)
                    }));
                    socket.send(JSON.stringify({event:"client_join"}));
                }
            });
            initAnswer();
            // 发送一个初始化消息socket.send("hello");
            // 监听消息
            socket.onmessage = function (event) {
//                console.log('Client received a message', event);
                if(event.type=="message"){
                    handleMessage(JSON.parse(event.data));
                }
            };
            // 监听Socket的关闭
            socket.onclose = function (event) {
                console.log('Client notified socket has closed', event);
            };
            // 关闭Socket....socket.close()
        };
    }
    function initAnswer() {
        pc = new RTCPeerConnection(pc_config);
        pc.onicecandidate = function iceCallback2(event) {
            if (!event || !event.candidate) return;
            if (event.candidate) {
                socket.send(JSON.stringify({
                    event:"candidate_back_cfg",
                    cfg:event.candidate
                }));
            }
        };
        pc.onaddstream = function gotRemoteStream(e) {
            localVideo.srcObject = e.stream;
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
    }

    function handleMessage(msg) {
        if(msg.event==="candidate_cfg_reply"){
            console.log("candidate reply")
            var candidate = new RTCIceCandidate(JSON.parse(msg.cfg));
            pc.addIceCandidate(candidate).then(function () {},function (e) {console.log(e);});
        }else if(msg.event==="offer_cfg_reply") {
            if(pc.iceConnectionState!="new"&&pc.iceGatheringState!="new"&&pc.signalingState==="stable"){
                console.log("视频已经开始播放");
                return;
            }
            var cfg=JSON.parse(msg.cfg);
            console.log("setRemoteDescription : ",cfg)
            pc.setRemoteDescription(new RTCSessionDescription(cfg)).then(function () {},function (e) {console.log(e);});
            pc.createAnswer().then(
                function gotDescription3(desc) {
                    // Final answer, setting a=recvonly & sdp type to answer.
                    desc.sdp = desc.sdp.replace(/a=inactive/g, 'a=recvonly');
                    desc.type = 'answer';
                    pc.setLocalDescription(desc).then(function () {},function (e) {console.log(e);});
                    socket.send(JSON.stringify({
                        event:"answer_cfg",
                        cfg:desc
                    }));

                },
                function (e) {console.log(e);}
            );
        }else if(msg.event=="desc") {
            NotificationHelper.showNotification(msg.desc);
        }
    }
</script>

</html>

