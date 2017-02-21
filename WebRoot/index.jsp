<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%
String path = request.getContextPath();
String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path+"/";
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
  <head>
    <base href="<%=basePath%>">
    
    <title>外部入口</title>
	<meta http-equiv="pragma" content="no-cache">
	<meta http-equiv="cache-control" content="no-cache">
	<meta http-equiv="expires" content="0">    
	<meta http-equiv="keywords" content="keyword1,keyword2,keyword3">
	<meta http-equiv="description" content="This is my page">
  </head>
  
  <body>
    hello world 
    <br>
    	外部
    <br>
    <a href="<%=path%>/view/index">已登录</a>
    <a href="<%=path%>/view/login">未登录</a>
    <br>
    <br>
    <a href="<%=path%>/view/index">直播【使用MediaRecorder录播（频闪，易崩溃）】</a>
    <br>
    <br>
    <a href="<%=path%>/view/index4">一对一直播</a>
    <a href="<%=path%>/view/watch4">查看直播【webrtc原生api】</a>

    <br>
    <br>
    <a href="<%=path%>/view/index5">一对多直播</a>
    <a href="<%=path%>/view/watch5">查看直播【webrtc原生api复杂使用】</a>

  </body>
</html>
