package net.riaspace.flerry;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.lang.reflect.Method;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;


import flex.messaging.io.SerializationContext;
import flex.messaging.io.amf.Amf3Input;
import flex.messaging.io.amf.Amf3Output;
import flex.messaging.messages.AcknowledgeMessage;
import flex.messaging.messages.ErrorMessage;
import flex.messaging.messages.RemotingMessage;


public class NativeObject 
{
	
	public static final String STOP_PROCESS_HEADER = "STOP_PROCESS_HEADER";
	protected Class<?> sourceClass;
	protected Boolean singleton;
	protected Object singletonObject;
	
	protected static PrintStream out = System.out;
	protected static PrintStream err = System.err;
	protected static InputStream in = System.in;
	
	protected static Lock readWriteLock = new ReentrantLock();

	public NativeObject(Class<?> sourceClass, Boolean singleton) 
	{
		try 
		{
			System.setOut(new PrintStream(new FileOutputStream("out.log", true)));
			System.setErr(new PrintStream(new FileOutputStream("err.log", true)));
		} 
		catch (FileNotFoundException e) {
			// TODO what to do here?
		}
		
		this.sourceClass = sourceClass;
		this.singleton = singleton;
	}

	public void init() 
	{
		final int BUFFER_SIZE = 512;
		char[] buffer = new char[BUFFER_SIZE]; 
		BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(in));
		StringBuffer stringBuffer = new StringBuffer();
		
		try 
		{
			int read;
			while ((read = bufferedReader.read(buffer, 0, buffer.length)) > 0) 
			{
				stringBuffer.append(buffer, 0, read);
				String tempString  = stringBuffer.toString();
				
				//if the string contains 2 markers
				if ((tempString.startsWith("_")) && (tempString.indexOf("_", 1) != -1)) 
				{
					//take string between the markers only
					int beginIndex = 1;
					int endIndex = tempString.indexOf("_", 1);
					String amfString = tempString.substring(beginIndex,endIndex);
					
					//decode Base64 string to AMF bytes
					byte[] amfBytes = Base64.decode(amfString);

					//create input stream for Amf3Input
					InputStream bais = new ByteArrayInputStream(amfBytes);
					Amf3Input amf3Input = new Amf3Input(SerializationContext.getSerializationContext());
					amf3Input.setInputStream(bais);
					
					//cleanup
					stringBuffer = new StringBuffer(); 
					tempString = "";
					
					try 
					{
						Object object = amf3Input.readObject();
						if (object instanceof RemotingMessage)
						{
							RemotingMessage message = (RemotingMessage) object;
							try 
							{
								if (message.getSource() != null) 
								{
									Object sourceObject = null;
									if (singleton)sourceObject = singletonObject;

									if (sourceObject == null) 
									{
										sourceObject = sourceClass.newInstance();
										if (singleton)singletonObject = sourceObject;
									}

									Object[] params = (Object[]) message.getBody();
								
									Method[] methods =  sourceObject.getClass().getMethods();
									for (Method method : methods)
									{
										if (method.getName().equals(message.getOperation()) && method.getParameterTypes().length == params.length) 
										{
											
											Object result = method.invoke(sourceObject, params);
											
											sendMessage(result, message.getMessageId());
											break;
										}
									}
								} 
								else 
								{
									Boolean stopProcess = (Boolean) message.getHeader(NativeObject.STOP_PROCESS_HEADER);
									if (stopProcess != null && stopProcess) 
									{
										break;
									}
								}
							} 
							catch (Exception e)
							{
								handleException(e, message.getMessageId());
							}
						} 
						else 
						{
							handleException(new Exception("Received object is not RemotingMessage type!"),null);
						}
					} 
					catch (ClassNotFoundException e) 
					{
						e.printStackTrace();
					}
				}
			}
		} 
		catch (IOException e) 
		{
			handleException(e, null);
		}
	}

	protected static void handleException(Exception e, String correlationId) 
	{
		try 
		{
			Amf3Output amf3Output = new Amf3Output(SerializationContext.getSerializationContext());
			ByteArrayOutputStream baos = new ByteArrayOutputStream();
			amf3Output.setOutputStream(baos);

			ErrorMessage message = new ErrorMessage();
			message.faultString = e.getMessage();
			message.faultDetail = e.toString();
			message.setCorrelationId(correlationId);

			amf3Output.writeObject(message);
			
			//Convert AMF binary data to Base64 string 
			String amfString = Base64.encodeBytes(baos.toByteArray());
			
			//add markers at the beginning and the end of the string
			amfString = "_" + amfString + "_" ; 
			
			err.write(amfString.getBytes("utf-8"));

			amf3Output.close();
		} 
		catch (Exception e1) 
		{
			e1.printStackTrace();
		}
	}

	public static void sendMessage(Object object, String correlationId) 
	{
		try 
		{
			
			Amf3Output amf3Output = new Amf3Output(SerializationContext.getSerializationContext());
			ByteArrayOutputStream baos = new ByteArrayOutputStream();
			amf3Output.setOutputStream(baos);

			AcknowledgeMessage message = new AcknowledgeMessage();
			message.setBody(object);
			message.setCorrelationId(correlationId);
			amf3Output.writeObject(message);
			

			//Convert AMF binary data to Base64 string 
			String amfString = Base64.encodeBytes(baos.toByteArray());
			
			//add markers at the beginning and the end of the string
			amfString = "_" + amfString + "_" ; 
			out.write(amfString.getBytes("utf-8"));
			
			amf3Output.flush();
			amf3Output.reset();
			amf3Output.close();
			//Thread.sleep(10);
		} 
		catch (Exception e) 
		{
			handleException(e, correlationId);
		}
	}
	
	public static void main(String[] args) 
	{
		NativeObject.readWriteLock.lock();
		
		String source = null;
		Boolean singleton = false;
		for (int i = 0; i < args.length; i++) {
			if (args[i].equals("-source"))
				source = args[i + 1];
			else if (args[i].equals("-singleton"))
				singleton = Boolean.parseBoolean(args[i + 1]);
		}

		NativeObject nativeObject = null;
		try 
		{
			nativeObject = new NativeObject(Class.forName(source), singleton);
			nativeObject.init();
		} catch (Exception e) {
			nativeObject.handleException(e, null);
		}
		
		NativeObject.readWriteLock.unlock();
	}
}