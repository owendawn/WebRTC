package com.zone.test.service;

import java.util.HashMap;
import java.util.List;

public interface UserService {
    List<HashMap<String, Object>> checkUserExists(String name);

    boolean testTransactional(String pwd);
}
