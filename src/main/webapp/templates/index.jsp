<!DOCTYPE HTML>
<html>
<head>
    <title>My JSP 'index.jsp' starting page</title>
    <meta http-equiv="pragma" content="no-cache">
    <meta http-equiv="cache-control" content="no-cache">
    <meta http-equiv="expires" content="0">
    <meta http-equiv="keywords" content="keyword1,keyword2,keyword3">
    <meta http-equiv="description" content="This is my page">
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
<h1>Websocket 自发自收版</h1>
<div>
    模式：
    <select id="model">
        <option value="video">视频模式</option>
        <option value="audio">音频模式</option>
    </select>
    <button onclick="init()">切换</button>
</div>
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


    var
        mediaRecorder,
        mediaBlobs = [],
        during = 500,
        audioDom = document.getElementById("audio"),
        videoDom = document.getElementById("video2")
    ;
    var socket;

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
                document.getElementById("m1").value = soundMeter.instant.toFixed(2);
                document.getElementById("m2").value = soundMeter.slow.toFixed(2);
                document.getElementById("m3").value = soundMeter.clip.toFixed(2);
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
            mediaRecorder.state!=="recording"&&mediaRecorder.start(during);
        };
        mediaRecorder.ondataavailable = function (event) {
            if (event.data && event.data.size > 0) {
                var blob = event.data;
                socket.send(blob);
                if (mediaRecorder.state != "inactive") {
                    mediaRecorder.stop();
                }
            }
        };
        mediaRecorder.start(during); // collect 10ms of data
    }

    function displayResource() {
        var video = document.getElementById('video');
        if (window.URL) {
            video.src = window.URL.createObjectURL(window.stream);
        } else {
            video.src = window.stream;
        }
        video.autoplay = true;
        video.onloadedmetadata = function (e) {
            console.log(window.stream);
            console.log("Label: " + window.stream.label);
            console.log("AudioTracks", window.stream.getAudioTracks());
            console.log("VideoTracks", window.stream.getVideoTracks());
        };
    }

    //=========================================== audio part =====================================================
    audioDom.oncanplay = function () {
        this.play();
    };
    audioDom.onended = function (data) {
        sound();
    };
    function sound() {
        if (mediaBlobs.length >= 2) {
            var superBuffer = new Blob(mediaBlobs, {type: 'video/webm'});
            audioDom.src = window.URL.createObjectURL(superBuffer);
            mediaBlobs = [];
        } else {
            setTimeout("sound()", during/3);
        }
    }
    function initAudio() {
        doMediaOperate({video: false, audio: true}, function (stream) {
            window.stream = stream;
            audioParse(stream);
            record();
        })
    }

    //============================================== video part =========================
    videoDom.oncanplay = function () {
//        this.play();
    };
    videoDom.onended = function (data) {
        movie();
    };
    function movie() {
        if (mediaBlobs.length >= 2) {
            if (mediaRecorder.state != "inactive") {
                var superBuffer = new Blob(mediaBlobs, {type: 'video/webm'});
                videoDom.src = window.URL.createObjectURL(superBuffer);
                mediaBlobs = [];
            }
        }
        setTimeout("movie()", during / 3);
    }
    function initVideo() {
        doMediaOperate({video: true, audio: true}, function (localMediaStream) {
            window.stream = localMediaStream;
            displayResource();
            audioParse(localMediaStream);
            record();
        })
    }

function init() {
    mediaRecorder&&mediaRecorder.stop();
    socket&&socket.close();
    videoDom&&videoDom.pause();

     socket = new WebSocket('ws://localhost:8080/websocket');
    socket.onopen = function (event) {
        var isVideoModel = document.getElementById("model").value === "video";

        isVideoModel && initVideo();
        !isVideoModel && initAudio();

        socket.onmessage = function (event) {
            mediaBlobs.push(event.data);
            isVideoModel && movie();
            !isVideoModel && sound();
        };
        socket.onclose = function (event) {
            console.log('Client notified socket has closed', event);
        };
    };
}

init();
</script>
</html>

