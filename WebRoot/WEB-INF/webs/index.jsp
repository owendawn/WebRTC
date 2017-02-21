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
    <script type="application/javascript">
        function SoundMeter(context) {
            this.context = context;
            this.instant = 0.0;
            this.slow = 0.0;
            this.clip = 0.0;
            this.script = context.createScriptProcessor(2048, 1, 1);
            var that = this;
            this.script.onaudioprocess = function (event) {
                var input = event.inputBuffer.getChannelData(0);
                var i;
                var sum = 0.0;
                var clipcount = 0;
                for (i = 0; i < input.length; ++i) {
                    sum += input[i] * input[i];
                    if (Math.abs(input[i]) > 0.99) {
                        clipcount += 1;
                    }
                }
                that.instant = Math.sqrt(sum / input.length);
                that.slow = 0.95 * that.slow + 0.05 * that.instant;
                that.clip = clipcount / input.length;
            };
        }

        SoundMeter.prototype.connectToSource = function (stream, callback) {
            console.log('SoundMeter connecting');
            try {
                this.mic = this.context.createMediaStreamSource(stream);
                this.mic.connect(this.script);
                // necessary to make sample run, but should not be.
                this.script.connect(this.context.destination);
                if (typeof callback !== 'undefined') {
                    callback(null);
                }
            } catch (e) {
                console.error(e);
                if (typeof callback !== 'undefined') {
                    callback(e);
                }
            }
        };
        SoundMeter.prototype.stop = function () {
            this.mic.disconnect();
            this.script.disconnect();
        };
    </script>
</head>

<body>
hello world index<br>
base forward<br>
${returnMsg}
<div>
    <video id="video" width="50%" muted="false" autoplay></video>
    <video id="video2" style="float: right;" width="50%"></video>
</div>

<br>
<audio id="audio" controls="controls"></audio>
<br>
<meter id="m1" hight="0.25" max="1" value="0"></meter>
<br>
<meter id="m2" hight="0.25" max="1" value="0"></meter>
<br>
<meter id="m3" hight="0.25" max="1" value="0"></meter>
<br>
<button onclick="record();">start record</button>
<button onclick="javascript:mediaRecorder.stop();">stop record</button>
<button onclick="sound();">listen record</button>
</body>
<script type="text/javascript">
    //兼容浏览器的getUserMedia写法
    var getUserMedia = (navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia);
    function doMediaOperate(conf, fun) {
        if (getUserMedia) {
//            getUserMedia.call(navigator, conf, function (localMediaStream) {
//                fun(localMediaStream);
//            }, function (e) {
//                console.log(e);
//            });
            navigator.mediaDevices.getUserMedia(conf).then(fun).catch(function (e) {
                console.log(e);
            });
        } else {
            console.warn("Your browser is not support the WebRTC!");
        }
    }
    function ConfObj() {
        this.conf = {video: true, audio: true};
        this.propertyName = {VEDIO: "video", AUDIO: "audio"};
        this.setVisible = function (key, value) {
            this.conf[key] = value;
        };
        this.getConfig = function () {
            return this.conf;
        };
    }
    
    
    var cfgObj = new ConfObj(),
        mediaRecorder,
        mediaBlobs=[],
        first=true,
        delay=1000,
        during=250,
        audioDom=document.getElementById("audio"),
        videoDom=document.getElementById("video2")
        ;
    function audioParse(stream) {
        //创建一个音频环境对像
        var AudioContext = window.AudioContext || window.webkitAudioContext;
        var audioContext = new AudioContext();
        //音频显示
        var soundMeter = window.soundMeter = new SoundMeter(audioContext);
        soundMeter.connectToSource(stream, function (e) {
            if (e) {
                alert(e);
                return;
            }
            setInterval(function () {
                document.getElementById("m1").value=soundMeter.instant.toFixed(2);
                document.getElementById("m2").value=soundMeter.slow.toFixed(2);
                document.getElementById("m3").value=soundMeter.clip.toFixed(2);
            }, 200);
        });
    }

    function record() {
        var options = {mimeType: 'video/webm;codecs=vp9'};
        if (!MediaRecorder.isTypeSupported(options.mimeType)) {
            console.log(options.mimeType + ' is not Supported');
            options = {mimeType: 'video/webm;codecs=vp8'};
            if (!MediaRecorder.isTypeSupported(options.mimeType)) {
                console.log(options.mimeType + ' is not Supported');
                options = {mimeType: 'video/webm'};
                if (!MediaRecorder.isTypeSupported(options.mimeType)) {
                    console.log(options.mimeType + ' is not Supported');
                    options = {mimeType: ''};
                }
            }
        }
        try {
            mediaRecorder = new MediaRecorder(window.stream, options);
        } catch (e) {
            console.error('Exception while creating MediaRecorder: ' + e);
            alert('Exception while creating MediaRecorder: '
                + e + '. mimeType: ' + options.mimeType);
            return;
        }
        mediaRecorder.onstop = function () {
            console.log("stop");
        };
        mediaRecorder.ondataavailable = function (event) {
            if (event.data && event.data.size > 0) {
                var blob=event.data;
                socket.send(blob);
                if(mediaRecorder.state!="inactive") {
//                        mediaRecorder.stop();
                }
            }
        };
        mediaRecorder.start(during); // collect 10ms of data
    }
    //=========================================== audio part =====================================================
    audioDom.oncanplay=function () {
        if(audioDom.stop)audioDom.stop();
        console.log("can");
        audioDom.play();
        mediaBlobs=[];
        mediaRecorder.start(during);
    };
    audioDom.addEventListener('error', function(ev) {
        console.log(ev);
        initAudio();
    }, true);
    audioDom.onended=function (data) {
        sound();
    };
    
    function sound() {
        if(mediaBlobs.length>=delay/during) {
            console.log(mediaBlobs);
            mediaRecorder.stop();
            var superBuffer = new Blob(mediaBlobs, {type: 'video/webm'});
            audioDom.src = window.URL.createObjectURL(superBuffer);
        }else{
            setTimeout("sound()",during);
        }
    }
    
    function initAudio() {
        cfgObj.setVisible(cfgObj.propertyName.VEDIO, false);
        cfgObj.setVisible(cfgObj.propertyName.AUDIO, true);
        doMediaOperate(cfgObj.getConfig(), function (stream) {
            window.stream = stream;
            audioParse(stream);
            //mediaRecorder
            record();
        })
    }
    
    //============================================== video part =========================
    videoDom.oncanplay=function () {
        if(videoDom.stop)videoDom.stop();
        console.log("can");
        videoDom.play();
        mediaBlobs=[];
        mediaRecorder.start(during);
    };
    videoDom.addEventListener('error', function(ev) {
        console.log(ev);
        function closeMedaiRecord(fun) {
            if(mediaRecorder.state!="inactive"){
                mediaRecorder.stop();
            }else{
                setTimeout(function () {
                    closeMedaiRecord(fun);
                },1000);
            }
        }

        closeMedaiRecord(function () {
            if(videoDom.stop)videoDom.stop();
            initVideo();
        });
    }, true);
    videoDom.onended=function (data) {
        movie();
    };
    function movie() {
        if(mediaBlobs.length>=delay/during) {
            console.log(mediaBlobs);
            if(mediaRecorder.state!="inactive"){
                mediaRecorder.stop();
            }else{
                setTimeout("movie()",1000);
                return;
            }
            var superBuffer = new Blob(mediaBlobs, {type: 'video/webm'});
            videoDom.src = window.URL.createObjectURL(superBuffer);
        }else{
            setTimeout("movie()",during);
        }
    }

    function initVideo() {
        cfgObj.setVisible(cfgObj.propertyName.VEDIO, true);
        cfgObj.setVisible(cfgObj.propertyName.AUDIO, true);
        doMediaOperate(cfgObj.getConfig(), function (localMediaStream) {
            var video = document.getElementById('video');
            window.stream=localMediaStream;
            if (window.URL) {
                video.src = window.URL.createObjectURL(localMediaStream);
            } else {
                video.src = localMediaStream;
            }
            video.autoplay = true;
            video.onloadedmetadata = function (e) {
                console.log(localMediaStream);
                console.log("Label: " + localMediaStream.label);
                console.log("AudioTracks", localMediaStream.getAudioTracks());
                console.log("VideoTracks", localMediaStream.getVideoTracks());
            };
            audioParse(localMediaStream);
            record();
        })
    }


    
    // 创建一个Socket实例
    var socket = new WebSocket('ws://<%=host%>:<%=port%><%=path%>/websocket');
    // 打开Socket
    socket.onopen = function (event) {

        
        initVideo();
//        initAudio();

        // 监听消息
        socket.onmessage = function (event) {
            mediaBlobs.push(event.data);
            if(first&&mediaBlobs.length>=delay/during) {
//                sound();
                movie();
                first=false;
            }
        };
        // 监听Socket的关闭
        socket.onclose = function (event) {
            console.log('Client notified socket has closed', event);
        };
        // 发送一个初始化消息socket.send('I am the client and I\'m listening!');
        // 关闭Socket....socket.close()
    };



</script>
</html>

