package net.riaspace.flerry;

import java.io.ByteArrayOutputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintStream;

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
	protected PrintStream fileOut;
	
	public NativeObject(Class<?> sourceClass, Boolean singleton) 
	{
		this.sourceClass = sourceClass;
		this.singleton = singleton;
		
		try {
			System.setOut(new PrintStream(new FileOutputStream("out.log", true)));
			System.setErr(new PrintStream(new FileOutputStream("err.log", true)));
		} catch (FileNotFoundException e) {
			// TODO what to do here?
		}
	}
	
	public void init()
	{
		Amf3Input amf3Input = new Amf3Input(SerializationContext.getSerializationContext());
		amf3Input.setInputStream(System.in);
		try
		{
			Object object;
			while ((object = amf3Input.readObject()) != null)
			{
				if (object instanceof RemotingMessage)
				{
					RemotingMessage message = (RemotingMessage) object;
					try
					{
						if (message.getSource() != null)
						{
							Object sourceObject = null;
							if (singleton)
								sourceObject = singletonObject;
	
							if (sourceObject == null)
							{
								sourceObject = sourceClass.newInstance();
								if (singleton)
									singletonObject = sourceObject;
							}
							
							Object[] params = (Object[]) message.getBody();
							Class<?>[] paramsTypes = new Class[params.length];
							for (int i = 0; i < paramsTypes.length; i++)
							{
								paramsTypes[i] = params[i].getClass();
							}
	
							Object result = sourceObject.getClass().getMethod(message.getOperation(), paramsTypes).invoke(sourceObject, params);
							sendMessage(result, message.getMessageId());
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
					catch(Exception e)
					{
						handleException(e, message.getMessageId());
					}
				}
				else
				{
					handleException(new Exception(
							"Received object is not RemotingMessage type!"), null);
				}
			}
		}
		catch (Exception e)
		{
			handleException(e, null);
		}
		finally
		{
			try
			{
				amf3Input.close();
			}
			catch (IOException e)
			{
				handleException(e, null);
			}
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
			err.write(baos.toByteArray());

			amf3Output.close();
		}
		catch (Exception e1)
		{
			e1.printStackTrace();
		}
	}
	
	public static void sendMessage(Object object, String correlationId){
		try
		{
			Amf3Output amf3Output = new Amf3Output(SerializationContext.getSerializationContext());			
			ByteArrayOutputStream baos = new ByteArrayOutputStream();
			amf3Output.setOutputStream(baos);
			
			AcknowledgeMessage message = new AcknowledgeMessage();
			message.setBody(object);
			message.setCorrelationId(correlationId);
			amf3Output.writeObject(message);
			
			byte[] tempArry = baos.toByteArray();
			byte[] byteArray = new byte[tempArry.length + 4];
			
			int index = 0;
			for (;index < tempArry.length; ++index) {
				byteArray[index] = tempArry[index];
			}
			
			//add marker bytes at the end of the array 
			byteArray[index] = new Byte("99");
			byteArray[index + 1] = new Byte("99");
			byteArray[index + 2] = new Byte("99");
			byteArray[index + 3] = new Byte("99");
			out.write(byteArray);
			
			amf3Output.close();			
		}
		catch (Exception e)
		{
			handleException(e, correlationId);
		}
	}
	
	public static void main(String[] args) 
	{
		String source = null;
		Boolean singleton = false;
		for (int i = 0; i< args.length; i++)
		{
			if (args[i].equals("-source"))
				source = args[i + 1];
			else if (args[i].equals("-singleton"))
				singleton = Boolean.parseBoolean(args[i + 1]);
		}
		
		try
		{
			(new NativeObject(Class.forName(source), singleton)).init();
		}
		catch (ClassNotFoundException e)
		{
			handleException(e, null);
		}
	}
	
}
