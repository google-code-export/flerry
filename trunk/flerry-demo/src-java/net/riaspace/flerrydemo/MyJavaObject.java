package net.riaspace.flerrydemo;

import java.util.Date;

import net.riaspace.flerrydemo.models.ComplexVO;
import net.riaspace.flerrydemo.models.NotExistingVO;

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
	
	public NotExistingVO getNotExistingVO(String someString)
	{
		NotExistingVO result = new NotExistingVO();
		result.setSomeString("Hello Flex!");
		return result;
	}
}
