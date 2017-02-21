package com.zone.test.webrtc;

import org.springframework.web.socket.WebSocketSession;

/**
 * Created by Owen Pan on 2017/1/17.
 */
public class LinkUser {
    private String linkAddress;
    private WebSocketSession webSocketSession;
    private boolean isWebSocketConnecting;
    private String roomAddress;

    public LinkUser( WebSocketSession webSocketSession,String roomAddress) {
        this.linkAddress = webSocketSession.getRemoteAddress().toString();
        this.webSocketSession = webSocketSession;
        this.roomAddress=roomAddress;
        this.isWebSocketConnecting=true;
    }

    public String getLinkAddress() {
        return linkAddress;
    }

    public void setLinkAddress(String linkAddress) {
        this.linkAddress = linkAddress;
    }

    public WebSocketSession getWebSocketSession() {
        return webSocketSession;
    }

    public void setWebSocketSession(WebSocketSession webSocketSession) {
        this.webSocketSession = webSocketSession;
    }

    public String getRoomAddress() {
        return roomAddress;
    }

    public void setRoomAddress(String roomAddress) {
        this.roomAddress = roomAddress;
    }

    public boolean isWebSocketConnecting() {
        return isWebSocketConnecting;
    }

    public void setWebSocketConnecting(boolean webSocketConnecting) {
        isWebSocketConnecting = webSocketConnecting;
    }
}
