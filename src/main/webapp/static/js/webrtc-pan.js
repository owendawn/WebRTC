/**
 * Created by SuperAdministrator on 2017/2/13.
 */
;
(function (window,document,undefined) {
    "use strict";
    var debugEnable=false,
        RTCPeerConnectionServerPool={},
        RTCPeerConnectionClientPool={},
        Helper={};
    Helper.extend = function(target, /*optional*/source, /*optional*/deep) {
        target = target || {};
        var sType = typeof source, i = 1, options;
        if( sType === 'undefined' || sType === 'boolean' ) {
            deep = sType === 'boolean' ? source : false;
            source = target;
            target = this;
        }
        if( typeof source !== 'object' && Object.prototype.toString.call(source) !== '[object Function]' )
            source = {};
        while(i <= 2) {
            options = i === 1 ? target : source;
            if( options != null ) {
                for( var name in options ) {
                    var src = target[name], copy = options[name];
                    if(target === copy)
                        continue;
                    if(deep && copy && typeof copy === 'object' && !copy.nodeType)
                        target[name] = this.extend(src ||
                            (copy.length != null ? [] : {}), copy, deep);
                    else if(copy !== undefined)
                        target[name] = copy;
                }
            }
            i++;
        }
        return target;
    };

    function WebRTCLiveChannel(theDebugEnable) {
        debugEnable=theDebugEnable ||false;
        this.config;
    }
    function _WebRTCLiveChannelItem(id) {
        this.id=id;
        this.RTCPeerConnection;
    }
    /**
     * =============================================================================================
     *   SERVER PART
     * =============================================================================================
     */
    /**
     *
     * @param op
     * @returns {_WebRTCLiveChannelItem}
     */
    WebRTCLiveChannel.prototype.newServerItem=function (op) {
        var _option={
            id:null,
            stream:null,
            RTCPeerConnectionConfig:null,
            onicecandidate:null,
            onaddstream:null
        };
        var _theCfg=this.config=Helper.extend(_option,op,true);
        var _item=new _WebRTCLiveChannelItem(this.config.id);
        _item.stream=this.config.stream;
        _item.RTCPeerConnection = new RTCPeerConnection(this.config.RTCPeerConnectionConfig);
        _item.RTCPeerConnection.onicecandidate = function(event) {
            if (!event || !event.candidate) return;
            if (event.candidate) {
                debugEnable&&console.log("Server["+_theCfg.id+"] onicecandidate : candidate.");
                _theCfg.onicecandidate&&_theCfg.onicecandidate(event);
            } else {
                debugEnable&&console.log("Server["+_theCfg.id+"] onicecandidate : End of candidates.");
            }
        };

        _item.RTCPeerConnection.onaddstream = function (event) {
            debugEnable&&console.log("Server["+_theCfg.id+"] onaddstream : stream added.");
            _theCfg.onaddstream&&_theCfg.onaddstream(event);
        };
        _item.RTCPeerConnection.onconnecting = function (message) {
            debugEnable&&console.log("Server["+_theCfg.id+"] onconnecting : Session connecting.");
        };
        _item.RTCPeerConnection.onopen = function (message) {
            debugEnable&&console.log("Server["+_theCfg.id+"] onopen : Session opened.");
        };
        _item.RTCPeerConnection.onremovestream = function (event) {
            debugEnable&&console.log("Server["+_theCfg.id+"] onremovestream : stream removed.");
        };
        _item.RTCPeerConnection.addStream(op.stream);
        RTCPeerConnectionServerPool[_theCfg.id]=_item;
        return _item;
    };
    /**
     *
     * @param id
     * @returns {_WebRTCLiveChannelItem}
     */
    WebRTCLiveChannel.prototype.getServerItem=function (id) {
        return RTCPeerConnectionServerPool[id];
    };
    WebRTCLiveChannel.prototype.removeServerItem=function (id) {
        if(RTCPeerConnectionServerPool[id]) {
            RTCPeerConnectionServerPool[id].RTCPeerConnection.close();
            delete RTCPeerConnectionServerPool[id];
        }
    };
    /**
     *  mediaConstraints={
     *      offerToReceiveAudio: 1,
     *      offerToReceiveVideo: 1
     *  };
     * @param mediaConstraints
     */
    _WebRTCLiveChannelItem.prototype.createServerOffer=function(mediaConstraints,success,fail){
        mediaConstraints=Helper.extend({
            offerToReceiveAudio: 1,
            offerToReceiveVideo: 1
        },mediaConstraints);
        var _id=this.id;
        var _RTCPeerConnection=this.RTCPeerConnection;
        _RTCPeerConnection.createOffer(function (sessionDescription) {
            debugEnable&&console.log("Server["+_id+"] createOffer success.");
            _RTCPeerConnection.setLocalDescription(sessionDescription).then(function () {
                debugEnable&&console.log("Server["+_id+"] setLocalDescription success.");
            },function (e) {
                debugEnable&&console.warn("Server["+_id+"] setLocalDescription fail : ",e);
            });
            success&&success(sessionDescription);
        }, function (e) {
            debugEnable&&console.warn("Server["+_id+"] createOffer fail : ",e);
            fail&&fail(e);
        }, mediaConstraints);
    };
    _WebRTCLiveChannelItem.prototype.answerBackReplyFromClient=function(cfg){
        var theId=this.id;
        this.RTCPeerConnection.setRemoteDescription(cfg).then(function () {
            debugEnable&&console.log("Server["+theId+"] setRemoteDescription success.");
        },function (e) {
            debugEnable&&console.warn("Server["+theId+"] setRemoteDescription fail : ",e);
        });
    };
    _WebRTCLiveChannelItem.prototype.candidateBackReplyFromClient=function(cfg){
        var _id=this.id;
        this.RTCPeerConnection.addIceCandidate(cfg).then(function () {
            debugEnable&&console.log("Server["+_id+"] addIceCandidate success.");
        },function (e) {
            debugEnable&&console.warn("Server["+_id+"] addIceCandidate fail : ",e);
        });
    };

    /**
     * ===================================================================================================
     *   CLIENT PART
     * ===================================================================================================
     */
    /**
     *
     * @param op
     * @returns {_WebRTCLiveChannelItem}
     */
    WebRTCLiveChannel.prototype.newClientItem=function (op) {
        var _option={
            id:null,
            RTCPeerConnectionConfig:null,
            onicecandidate:null,
            onaddstream:null
        };
        var _theCfg=this.config=Helper.extend(_option,op,true);
        var _item=new _WebRTCLiveChannelItem(this.config.id);
        _item.RTCPeerConnection = new RTCPeerConnection(this.config.RTCPeerConnectionConfig);
        _item.RTCPeerConnection.onicecandidate = function(event) {
            if (!event || !event.candidate) return;
            if (event.candidate) {
                debugEnable&&console.log("Client["+_theCfg.id+"] onicecandidate : candidate.");
                _theCfg.onicecandidate&&_theCfg.onicecandidate(event);
            } else {
                debugEnable&&console.log("Client["+_theCfg.id+"] onicecandidate : End of candidates.");
            }
        };

        _item.RTCPeerConnection.onaddstream = function (event) {
            debugEnable&&console.log("Client["+_theCfg.id+"] onaddstream : stream added.");
            _theCfg.onaddstream&&_theCfg.onaddstream(event);
        };
        _item.RTCPeerConnection.onconnecting = function (message) {
            debugEnable&&console.log("Client["+_theCfg.id+"] onconnecting : Session connecting.");
        };
        _item.RTCPeerConnection.onopen = function (message) {
            debugEnable&&console.log("Client["+_theCfg.id+"] onopen : Session opened.");
        };
        _item.RTCPeerConnection.onremovestream = function (event) {
            debugEnable&&console.log("Client["+_theCfg.id+"] onremovestream : stream removed.");
        };
        RTCPeerConnectionClientPool[_theCfg.id]=_item;
        return _item;
    };
    /**
     *
     * @param id
     * @returns {_WebRTCLiveChannelItem}
     */
    WebRTCLiveChannel.prototype.getClientItem=function (id) {
        return RTCPeerConnectionClientPool[id];
    };
    WebRTCLiveChannel.prototype.removeClientItem=function (id) {
        if(RTCPeerConnectionClientPool[id]) {
            RTCPeerConnectionClientPool[id].RTCPeerConnection.close();
            delete RTCPeerConnectionClientPool[id];
        }
    };
    _WebRTCLiveChannelItem.prototype.createAnswerToServer=function (cfg,success,fail) {
        var _id=this.id;
        var _RTCPeerConnection=this.RTCPeerConnection;
        _RTCPeerConnection.setRemoteDescription(cfg).then(function () {
            debugEnable&&console.log("Client["+_id+"] setRemoteDescription : setRemoteDescription success.");
        },function (e) {
            debugEnable&&console.log("Client["+_id+"] setRemoteDescription : setRemoteDescription fail : ",e);
        });
        _RTCPeerConnection.createAnswer().then(function (desc) {
                debugEnable&&console.log("Client["+_id+"] createAnswer : createAnswer success.");
                // Final answer, setting a=recvonly & sdp type to answer.
                desc.sdp = desc.sdp.replace(/a=inactive/g, 'a=recvonly');
                desc.type = 'answer';
                _RTCPeerConnection.setLocalDescription(desc).then(function () {
                    debugEnable&&console.log("Client["+_id+"] setLocalDescription : setLocalDescription success.");
                },function (e) {
                    debugEnable&&console.log("Client["+_id+"] setLocalDescription : setLocalDescription fail : ",e);
                });
                success&&success(desc);
            },
            function (e) {
                debugEnable&&console.log("Client["+_id+"] createAnswer : createAnswer fail : ",e);
                fail&&fail(e);
            }
        );
    };
    _WebRTCLiveChannelItem.prototype.candidateReplyFromServer=function(cfg){
        var _id=this.id;
        this.RTCPeerConnection.addIceCandidate(new RTCIceCandidate(cfg)).then(function () {
            debugEnable&&console.log("Client["+_id+"] addIceCandidate success.");
        },function (e) {
            debugEnable&&console.warn("Client["+_id+"] addIceCandidate fail : ",e);
        });
    };

    WebRTCLiveChannel.prototype.doMediaOperate=function(conf, fun) {
        if (navigator.getUserMedia) {
            navigator.mediaDevices.getUserMedia(conf).then(fun).catch(function (e) {
                console.log(e);
            });
        } else {
            console.warn("Your browser is not support the WebRTC!");
        }
    };
    if (typeof window !== 'undefined') {
        window.WebRTCLiveChannel =WebRTCLiveChannel;
    } else {
        console.log('the parameter "window"  is undefined!');
    }
})(window,document,undefined);