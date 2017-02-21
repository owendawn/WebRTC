package com.zone.test.model;

public class User {
	private Integer id;
	private String name;
	private String pwd;
	private Integer deptId;

	public User() {
		super();
	}

	public User(Integer id, String name, String pwd, Integer deptId) {
		super();
		this.id = id;
		this.name = name;
		this.pwd = pwd;
		this.deptId = deptId;
	}

	public Integer getId() {
		return id;
	}

	public void setId(Integer id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getPwd() {
		return pwd;
	}

	public void setPwd(String pwd) {
		this.pwd = pwd;
	}

	public Integer getDeptId() {
		return deptId;
	}

	public void setDeptId(Integer deptId) {
		this.deptId = deptId;
	}

	@Override
	public String toString() {
		return "UserModel [id=" + id + ", name=" + name + ", pwd=" + pwd
				+ ", deptId=" + deptId + "]";
	}

}
