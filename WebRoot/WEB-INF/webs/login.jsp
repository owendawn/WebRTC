<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%
String path = request.getContextPath();
String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path+"/";
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
  <head>
    <base href="<%=basePath%>">
    
    <title>登录</title>
	<meta http-equiv="pragma" content="no-cache">
	<meta http-equiv="cache-control" content="no-cache">
	<meta http-equiv="expires" content="0">    
	<meta http-equiv="keywords" content="keyword1,keyword2,keyword3">
	<meta http-equiv="description" content="This is my page">
	<!--
	<link rel="stylesheet" type="text/css" href="styles.css">
	-->
  </head>
  
  <body>
    hello World login <br>
    base forward
    <form method="post" action="/SpringMVC/user/login.action?logined=true">
    	用户名:<input type="text" name="name">
    	<br>
    	<input type="submit" value="提交">
    	<br>
    	<span style="color:red;display:<%=(request.getAttribute("returnMsg")==null?"none":"block")%>;">${returnMsg}</span>
    	
    	
    </form>
  </body>
</html>
