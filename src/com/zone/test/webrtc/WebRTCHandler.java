package com.zone.test.webrtc;

import com.alibaba.fastjson.JSON;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
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
public class WebRTCHandler extends BinaryWebSocketHandler {
    @Autowired
    private WebRTCService webRTCService;

    private SimpMessagingTemplate template;

    public WebRTCHandler() {
    }

    public WebRTCHandler(SimpMessagingTemplate template) {
        this.template = template;
        System.out.println("初始化 webrtc handler");
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        String c=message.getPayload();
        System.out.print("----------------------------webrtc text msg:");
        System.out.println(c);
        HashMap msgObj= JSON.parseObject(c,HashMap.class);
        try {
            if ("offer_cfg".equals(msgObj.get("event").toString())) {
                webRTCService.initRoomDescription(session, msgObj.get("cfg").toString(),msgObj.get("id")==null?null:msgObj.get("id").toString());
            }else if ("offer_candidate".equals(msgObj.get("event").toString())) {
                webRTCService.initRoomCandidate(session, msgObj.get("cfg").toString(),msgObj.get("id")==null?null:msgObj.get("id").toString());
            }else if("answer_cfg".equals(msgObj.get("event").toString())) {
                webRTCService.initRoomReply(session, msgObj.get("cfg").toString(),"answer_cfg_reply");
            }else if("candidate_back_cfg".equals(msgObj.get("event").toString())) {
                webRTCService.initRoomReply(session, msgObj.get("cfg").toString(),"candidate_back_cfg_reply");
            }else if("client_join".equals(msgObj.get("event").toString())) {
                webRTCService.initRoomOfferAndAnswer(session);
            }else if("join_room".equals(msgObj.get("event").toString())){
                webRTCService.joinRoom(session, null);
            }
        }catch (Exception e){
            e.printStackTrace();
        }
    }

    @Override
    protected void handleBinaryMessage(WebSocketSession session, BinaryMessage message) {
        ByteBuffer c=message.getPayload();
        System.out.print("------------------------ webrtc binary msg:");
        System.out.println(c);
        try {
            session.sendMessage(message);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        System.out.println("connect to the webrtc websocket success......"+session.getRemoteAddress());
        webRTCService.createRoom(session);
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
        if(session.isOpen()){
            if(exception instanceof IOException){
                webRTCService.leaveRoomByCloseConnection(session);
            }else {
                webRTCService.leaveRoom(session);
            }
            session.close();
        }
        System.out.println("webrtc err:"+ exception.getMessage());
//        exception.printStackTrace();
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus closeStatus) throws Exception {
        webRTCService.leaveRoomByCloseConnection(session);
        System.out.println("webrtc websocket connection closed......"+session.getRemoteAddress());
    }

}
