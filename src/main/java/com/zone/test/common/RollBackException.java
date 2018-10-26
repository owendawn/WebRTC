package com.zone.test.common;

/**
 * Created by Owen Pan on 2016/10/8.
 */

/**
 * 事务管理数据回滚 Exception
 */
public class RollBackException extends RuntimeException {
    public RollBackException() {
    }

    public RollBackException(String message) {
        super(message);
    }

    public RollBackException(String message, Throwable cause) {
        super(message, cause);
    }

    public RollBackException(Throwable cause) {
        super(cause);
    }

    public RollBackException(String message, Throwable cause, boolean enableSuppression, boolean writableStackTrace) {
        super(message, cause, enableSuppression, writableStackTrace);
    }
}
