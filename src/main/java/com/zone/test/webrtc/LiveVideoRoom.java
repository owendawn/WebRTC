package com.zone.test.webrtc;

import org.springframework.web.socket.WebSocketSession;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

/**
 * Created by Owen Pan on 2017/1/17.
 */
public class LiveVideoRoom {
    private LinkUser roomOwner;
    private List<LinkUser> joinUsers;
    private boolean status;
    private boolean isConnected;

    public LiveVideoRoom(WebSocketSession webSocketSession){
        this.roomOwner=new LinkUser(webSocketSession,webSocketSession.getRemoteAddress().toString());
        if(this.joinUsers==null){
            this.joinUsers=new ArrayList();
        }
        this.setStatus(true);
        this.isConnected=false;
    }

    public LinkUser getRoomOwner() {
        return roomOwner;
    }

    public void setRoomOwner(LinkUser roomOwner) {
        this.roomOwner = roomOwner;
    }

    public List<LinkUser> getJoinUsers() {
        return joinUsers;
    }

    public void setJoinUsers(List<LinkUser> joinUsers) {
        this.joinUsers = joinUsers;
    }

    public boolean isStatus() {
        return status;
    }

    public void setStatus(boolean status) {
        this.status = status;
    }

    public boolean isConnected() {
        return isConnected;
    }

    public void setConnected(boolean connected) {
        isConnected = connected;
    }
}
