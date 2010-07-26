package com.riaspace.flerry.tests
{
	import mx.messaging.events.MessageEvent;
	
	import net.riaspace.flerry.NativeObject;
	
	import org.flexunit.asserts.assertTrue;
	import org.flexunit.async.Async;

	public class MessagingTests
	{		
		private var nativeObject:NativeObject;
		
		private static const TIMEOUT:uint = 5000;

		[Before]
		public function setUp():void
		{
			nativeObject = new NativeObject("com.riaspace.flerry.tests.JavaService", true);
			nativeObject.debug = false;
			nativeObject.startThread();
		}
		
		[After]
		public function tearDown():void
		{
			nativeObject.exit();
		}
		
		[BeforeClass]
		public static function setUpBeforeClass():void
		{
		}
		
		[AfterClass]
		public static function tearDownAfterClass():void
		{
		}
		
		[Test(async, timeout="10000")]
		public function sendMessageTest():void
		{
			Async.handleEvent(this, nativeObject, "countResult", sendMessage_resultHandler, TIMEOUT);
		}
		
		private function sendMessage_resultHandler(event:MessageEvent, param:*):void 
		{
			var count:int = event.message.body["count"];
			trace("count:", count);
			
			assertTrue(count is int);
			
			// Looping test to receive few messages
			if (count < 3)
				Async.handleEvent(this, nativeObject, "countResult", sendMessage_resultHandler, TIMEOUT);
		}
	}
}