/**
 * Created by SuperAdministrator on 2017/2/8.
 */
window.NotificationHelper=1;
(function(windowObj) {
    var _NotificationHelper = function () {};
    _NotificationHelper.prototype.showNotification = function (text) {
        if (window.Notification) {
            var popNotice = function () {
                if (Notification.permission == "granted") {
                    var notification = new Notification("Hi，帅哥：", {
                        body: text,
                        icon: 'http://image.zhangxinxu.com/image/study/s/s128/mm1.jpg'
                    });

                    // notification.onclick = function () {
                    //     notification.close();
                    // };
                } else if (Notification.permission != "denied") {
                    Notification.requestPermission(function (permission) {
                        popNotice();
                    });
                }
            };
            popNotice();
        } else {
            alert('浏览器不支持Notification');
        }
    };
    windowObj.NotificationHelper=new _NotificationHelper();
})(window);

