package net.riaspace.flerrydemo;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import net.riaspace.flerry.NativeObject;
import net.riaspace.flerrydemo.models.ComplexVO;
import net.riaspace.flerrydemo.models.NotExistingVO;

public class MyJavaObject {
	public MyJavaObject() {
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

	public NotExistingVO getNotExistingVO(String someString) {
		NotExistingVO result = new NotExistingVO();
		result.setSomeString("Hello Flex!");
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
				NativeObject.sendMessage(map, "sendMsg");
				count++;
				try {
					Thread.sleep(5000);
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		}
	}

}
