package com.riaspace.flerry.tests;

import java.util.HashMap;
import java.util.Map;

import net.riaspace.flerry.NativeObject;

import com.riaspace.flerry.tests.models.DynamicVO;

public class JavaService {

	public JavaService() {
	}

	public Object[] exchangeLargeObjects(Object[] largeObject)
	{
		return largeObject;
	}
	
	public DynamicVO getDynamicObject(String someString) {
		DynamicVO result = new DynamicVO();
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
					Thread.sleep(1000);
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		}
	}

}
