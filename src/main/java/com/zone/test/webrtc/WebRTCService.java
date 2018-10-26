package com.zone.test.webrtc;

import com.alibaba.fastjson.JSON;
import com.zone.test.model.User;
import org.springframework.stereotype.Service;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.io.IOException;
import java.util.*;

/**
 * Created by Owen Pan on 2017/1/17.
 */
@Service
public class WebRTCService {
    private static HashMap<String, LiveVideoRoom> rooms = new HashMap<>();
    private static HashMap<String, LinkUser> users = new HashMap<>();

    public Set<HashMap> getRooms() {
        Set<HashMap> r = new HashSet<>();
        for (String s : rooms.keySet()) {
            LiveVideoRoom it = rooms.get(s);
            HashMap hm = new HashMap();
            hm.put("address", s);
            hm.put("status", it.isStatus());
            r.add(hm);
        }
        return r;
    }

    private void broadcastTextMsg(List<LinkUser> users, Map msg) throws IOException {
        broadcastTextMsg(users, msg, null);
    }

    private void broadcastTextMsg(List<LinkUser> users, Map msg, String exceptAddress) throws IOException {
        for (int i = 0; i < users.size(); i++) {
            LinkUser user = users.get(i);
            if (!user.getLinkAddress().equals(exceptAddress) && user.getWebSocketSession() != null) {
                user.getWebSocketSession().sendMessage(new TextMessage(JSON.toJSONString(msg)));
            }
        }
    }

    private void sendTextMsg(WebSocketSession socketSession,Map msg) throws IOException {
        socketSession.sendMessage(new TextMessage(JSON.toJSONString(msg)));
    }

    public void createRoom(WebSocketSession session) {
        String macAddr = session.getRemoteAddress().toString();
        LiveVideoRoom theroom = rooms.get(macAddr);
        if (theroom != null) {
            theroom.setStatus(true);
        } else {
            try {
                users.put(macAddr,new LinkUser(session,macAddr));
                rooms.put(macAddr, new LiveVideoRoom(session));
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public void initRoomDescription(WebSocketSession session, String cfg,String id) throws IOException {
        LiveVideoRoom room = rooms.get(users.get(session.getRemoteAddress().toString()).getRoomAddress());
        HashMap hm = new HashMap();
        hm.put("event", "offer_cfg_reply");
        hm.put("id",id);
        hm.put("cfg", cfg);
        if(id==null){
            sendTextMsg(session,hm);
            broadcastTextMsg(room.getJoinUsers(), hm);
        }else{
            sendTextMsg(users.get(id).getWebSocketSession(),hm);
        }
    }

    public void initRoomCandidate(WebSocketSession session, String cfg,String id) throws IOException {
        LiveVideoRoom room = rooms.get(users.get(session.getRemoteAddress().toString()).getRoomAddress());
        HashMap hm = new HashMap();
        hm.put("event", "candidate_cfg_reply");
        hm.put("id",id);
        hm.put("cfg", cfg);
        if(id!=null){
            sendTextMsg(users.get(id).getWebSocketSession(),hm);
        }
    }

    public void initRoomReply(WebSocketSession session, String cfg,String eventName) throws IOException {
        LinkUser user = users.get(users.get(session.getRemoteAddress().toString()).getRoomAddress());
        HashMap hm = new HashMap();
        hm.put("event", eventName);
        hm.put("cfg", cfg);
        hm.put("id",session.getRemoteAddress().toString());
        user.getWebSocketSession().sendMessage(new TextMessage(JSON.toJSONString(hm)));
    }

    public void joinRoom(WebSocketSession session, String address) throws IOException {
        if(address!=null)
        leaveRoom(session.getRemoteAddress().toString(), null);

        LinkUser theUser = new LinkUser(session, address);
        LiveVideoRoom liveVideoRoom = rooms.get(address);
        List<LinkUser> joins = liveVideoRoom.getJoinUsers();
        joins.add(theUser);
        users.put(session.getRemoteAddress().toString(), theUser);

        HashMap hashMap = new HashMap();
        hashMap.put("event", "desc");
        hashMap.put("desc", session.getRemoteAddress().toString() + " join room");
        broadcastTextMsg(joins, hashMap);
        sendTextMsg(liveVideoRoom.getRoomOwner().getWebSocketSession(),hashMap);


    }

    private void leaveRoom(String userMacAddr, String exceptMacAddr) throws IOException {
        LinkUser user = users.get(userMacAddr);
        if (user == null) return;
        LiveVideoRoom theroom = rooms.get(user.getRoomAddress());

        HashMap hm=new HashMap();
        hm.put("id",userMacAddr);
        if(user.isWebSocketConnecting()) {
            hm.put("event", "client_close_reply");
            user.getWebSocketSession().sendMessage(new TextMessage(JSON.toJSONString(hm)));
        }
        if(theroom.getRoomOwner().isWebSocketConnecting()) {
            hm.put("event", "server_close_reply");
            theroom.getRoomOwner().getWebSocketSession().sendMessage(new TextMessage(JSON.toJSONString(hm)));
        }

        if (theroom != null) {
            if (theroom.getRoomOwner() != null && userMacAddr.equals(theroom.getRoomOwner().getLinkAddress())) {
                theroom.setStatus(false);
                theroom.setRoomOwner(null);
            }
            List<LinkUser> joins = theroom.getJoinUsers();
            if (joins != null) {
                if(joins.size()==0){
                    rooms.remove(user.getRoomAddress());
                    return;
                }
                HashMap hashMap = new HashMap();
                hashMap.put("event", "desc");
                hashMap.put("desc", userMacAddr + " leave room");
                broadcastTextMsg(joins, hashMap, exceptMacAddr);
                if(theroom.getRoomOwner()!=null){
                    sendTextMsg(theroom.getRoomOwner().getWebSocketSession(),hashMap);
                }

                for (int i = 0; i < joins.size(); i++) {
                    if (joins.get(i).getLinkAddress().equals(userMacAddr)) {
                        joins.remove(i);
                    }
                }
            }
        }
    }

    public void leaveRoom(WebSocketSession session) throws IOException {
        String macAddr = session.getRemoteAddress().toString();
        leaveRoom(macAddr, null);
        users.remove(macAddr);
    }

    public void leaveRoomByCloseConnection(WebSocketSession session) throws IOException {
        String macAddr = session.getRemoteAddress().toString();
        if(users.get(macAddr)!=null) {
            users.get(macAddr).setWebSocketConnecting(false);
        }
        if(rooms.get(macAddr)!=null) {
            LinkUser roomOwner = rooms.get(macAddr).getRoomOwner();
            if (roomOwner != null && roomOwner.getLinkAddress().equals(macAddr)) {
                rooms.get(macAddr).getRoomOwner().setWebSocketConnecting(false);
            }
        }
        leaveRoom(macAddr, macAddr);
        users.remove(macAddr);
    }

    public void initRoomOfferAndAnswer(WebSocketSession session) throws IOException {
        LinkUser user = users.get(session.getRemoteAddress().toString());
        if (user == null) return;
        LiveVideoRoom theroom = rooms.get(user.getRoomAddress());
        HashMap h=new HashMap();
        h.put("id",session.getRemoteAddress().toString());
        h.put("event","client_create_reply");
        session.sendMessage(new TextMessage(JSON.toJSONString(h)));
        h.put("event","server_create_reply");
        theroom.getRoomOwner().getWebSocketSession().sendMessage(new TextMessage(JSON.toJSONString(h)));
    }

    public void closeRoomOfferAndAnswer(WebSocketSession session) throws IOException {
        LinkUser user = users.get(session.getRemoteAddress().toString());
        if (user == null) return;
        LiveVideoRoom theroom = rooms.get(user.getRoomAddress());
        HashMap h=new HashMap();
        h.put("event","server_close_reply");
        h.put("id",session.getRemoteAddress().toString());
        theroom.getRoomOwner().getWebSocketSession().sendMessage(new TextMessage(JSON.toJSONString(h)));
        h.put("event","client_close_reply");
        session.sendMessage(new TextMessage(JSON.toJSONString(h)));
    }
}
