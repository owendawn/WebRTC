package com.zone.test.mapper;

import java.util.HashMap;
import java.util.List;

public interface UserMapper {

    List<HashMap<String, Object>> checkUserExists(String name);

    boolean updateUser(String pwd);

}
