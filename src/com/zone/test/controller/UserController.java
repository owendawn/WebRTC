package com.zone.test.controller;

import java.util.HashMap;
import java.util.List;

import javax.annotation.Resource;


import com.zone.test.common.BaseController;
import com.zone.test.webrtc.WebRTCService;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import ch.qos.logback.classic.Logger;

import com.zone.test.service.UserService;

@Controller
@RequestMapping("/user")
public class UserController extends BaseController {
    @Resource
    private UserService userService;
    @Autowired
    private WebRTCService webRTCService;
    private HashMap<String, Object> returnMsg = new HashMap<String, Object>();
    org.slf4j.Logger logger = LoggerFactory.getLogger(UserController.class);

    @RequestMapping("/login")
    public ModelAndView login(@RequestParam(value = "name", defaultValue = "") String name, @RequestParam(value = "logined", defaultValue = "false") boolean logined) {
        if (name.equals("")) {
            returnMsg.put("returnMsg", "用户名为空");
        } else {
            logger.info("the param logined value is :" + logined);
            List<HashMap<String, Object>> list = userService.checkUserExists(name);
            try {
                //测试事务
                userService.testTransactional(name);
            }catch (Exception e){
                e.printStackTrace();
            }
            System.out.println(name);
            if (list!=null&&list.size() > 0) {
                returnMsg.put("returnMsg", "用户存在，跳转主页");
                return new ModelAndView("/index", returnMsg);
            } else {
                returnMsg.put("returnMsg", "用户名不存在");
            }
        }
        return new ModelAndView("/login", returnMsg);
    }

    @RequestMapping("/getRooms")
    @ResponseBody
    public HashMap getRooms(){
        HashMap hm=new HashMap();
         hm.put("data",webRTCService.getRooms());
         hm.put("success",true);
         return hm;
    }
}
