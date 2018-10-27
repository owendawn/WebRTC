package com.zone.test.controller;

import com.zone.test.common.BaseController;
import com.zone.test.webrtc.WebRTCService;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.HashMap;

@Controller
@RequestMapping("/user")
public class UserController extends BaseController {
    @Autowired
    private WebRTCService webRTCService;
    org.slf4j.Logger logger = LoggerFactory.getLogger(UserController.class);


    @RequestMapping("/getRooms")
    @ResponseBody
    public HashMap getRooms(){
        HashMap hm=new HashMap();
         hm.put("data",webRTCService.getRooms());
         hm.put("success",true);
         return hm;
    }
}
