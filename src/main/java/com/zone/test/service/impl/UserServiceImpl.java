package com.zone.test.service.impl;

import com.zone.test.common.RollBackException;
import com.zone.test.mapper.UserMapper;
import com.zone.test.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
@Service
public class UserServiceImpl implements UserService {
    @Autowired(required = false)
    private UserMapper userMapper;

    @Override
//    @Transactional
    public List<HashMap<String, Object>> checkUserExists(String name) {
        try {
            return userMapper.checkUserExists(name);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    @Override
//    @Transactional
    public boolean testTransactional(String pwd) {
        boolean b = userMapper.updateUser(pwd);
        System.out.println(b);
        List l = null;
        if (l == null) {
            throw new RollBackException("测试事务回滚");
        }
        return false;
    }

}
