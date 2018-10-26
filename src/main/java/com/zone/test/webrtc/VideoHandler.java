package com.zone.test.webrtc;

import com.alibaba.fastjson.JSON;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.socket.BinaryMessage;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.BinaryWebSocketHandler;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.HashMap;

/**
 * Created by Owen Pan on 2017/1/17.
 */
public class VideoHandler extends BinaryWebSocketHandler {
    @Autowired
    private WebRTCService webRTCService;

    @Override
    protected void handleBinaryMessage(WebSocketSession session, BinaryMessage message) {
        System.out.println("-----------------video msg begin-----------------------");
        ByteBuffer c=message.getPayload();
        System.out.print("video msg:");
        System.out.println(c);
        System.out.println("------------------ video msg end ----------------------");
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        System.out.print("-------------- video msg:");
        System.out.println(message.getPayload());
        HashMap msgObj=JSON.parseObject(message.getPayload(),HashMap.class);
        String event=msgObj.get("event").toString();
        try {
            switch (event) {
                case "join_room": webRTCService.joinRoom(session, msgObj.get("address").toString());break;
                case "leave_room":webRTCService.leaveRoom(session);break;
                case "answer_cfg":webRTCService.initRoomReply(session, msgObj.get("cfg").toString(),"answer_cfg_reply");break;
                case "candidate_back_cfg":webRTCService.initRoomReply(session, msgObj.get("cfg").toString(),"candidate_back_cfg_reply");break;
                case "client_join":webRTCService.initRoomOfferAndAnswer(session);break;
                case "client_leave":webRTCService.closeRoomOfferAndAnswer(session);break;
            }
        }catch (Exception e){
            e.printStackTrace();
        }
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        System.out.println("connect to the video websocket success......"+session.getRemoteAddress());
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
        if(session.isOpen()){
            if(exception instanceof IOException){
                webRTCService.leaveRoomByCloseConnection(session);
            }else {
                webRTCService.leaveRoom(session);
            }
        }
        System.out.println("video err:"+ exception.getMessage());
//        exception.printStackTrace();
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus closeStatus) throws Exception {
        webRTCService.leaveRoomByCloseConnection(session);
        System.out.println("video websocket connection closed......"+session.getRemoteAddress());
    }

}
