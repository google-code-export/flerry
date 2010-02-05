package net.riaspace.flerrydemo;

import java.util.Date;

import net.riaspace.flerrydemo.models.ComplexVO;

public class MyJavaObject
{
	public MyJavaObject(){}
	
	public Integer add(Integer value1, Integer value2)
	{
		return value1 + value2;
	}
	
	public ComplexVO processComplexVO(ComplexVO cvo)
	{
		cvo.setSomeDate(new Date());
		cvo.setSomeString("Hello Flex!");
		cvo.setSomeInteger(1);
		
		return cvo;
	}
}
