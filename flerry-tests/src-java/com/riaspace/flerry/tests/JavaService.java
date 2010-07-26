package com.riaspace.flerry.tests;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.riaspace.flerry.NativeObject;

import com.riaspace.flerry.tests.models.ComplexVO;
import com.riaspace.flerry.tests.models.NotExistingVO;

public class JavaService {
	public JavaService() {
	}

	public Integer add(Integer value1, Integer value2) {
		return value1 + value2;
	}

	public ComplexVO processComplexVO(ComplexVO cvo) {
		cvo.setSomeDate(new Date());
		cvo.setSomeString("Hello Flex!");
		cvo.setSomeInteger(1);

		return cvo;
	}

	public List<ComplexVO> getLargeObject()
	{
		List<ComplexVO> result = new ArrayList<ComplexVO>();
		
		for(int i = 0; i < 100000; i++)
		{
			ComplexVO cvo = new ComplexVO();
			cvo.setSomeDate(new Date());
			cvo.setSomeString("Hello Flex!");
			cvo.setSomeInteger(1);

			result.add(cvo);
		}
		
		return result;
	}
	
	public NotExistingVO getNotExistingVO(String someString) {
		NotExistingVO result = new NotExistingVO();
		result.setSomeString(someString);
		return result;
	}
	
	public String startThread(){
		new MyThread().start();
		return "thread started";
	}

	public class MyThread extends Thread {

		int count = 0;

		public void run() {

			while (true) {

				Map<String, Integer> map = new HashMap<String, Integer>();
				map.put("count", count);
				NativeObject.sendMessage(map, "countResult");
				count++;
				try {
					Thread.sleep(2000);
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		}
	}

}
