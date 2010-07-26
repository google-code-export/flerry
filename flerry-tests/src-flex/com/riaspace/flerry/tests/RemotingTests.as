package com.riaspace.flerry.tests
{
	import com.riaspace.flerry.tests.models.ComplexVO;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import net.riaspace.flerry.NativeObject;
	
	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.assertNotNull;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;

	public class RemotingTests
	{		
		
		private var nativeObject:NativeObject;
		
		private static const TIMEOUT:uint = 5000;
		
		[Before]
		public function setUp():void
		{
			nativeObject = new NativeObject("com.riaspace.flerry.tests.JavaService", true);
			nativeObject.debug = false;
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
		
		[Test(async, timeout="5000")]
		public function exchangeLargeObjectsTest():void
		{
			var largeObject:Array = new Array();
			for (var i:int = 0; i < 1000; i++)
			{
				var vo:ComplexVO = new ComplexVO();
				vo.someDate = new Date();
				vo.someInteger = 1;
				vo.someString = "some value";
				
				largeObject.push(vo);
			}
			
			var token:AsyncToken = nativeObject.exchangeLargeObjects(largeObject);
			token.addResponder(Async.asyncResponder(this, new TestResponder(exchangeLargeObjects_resultHandler, remote_faultHandler), TIMEOUT));
		}		

		[Test(async, timeout="5000")]
		private function exchangeLargeObjects_resultHandler(event:ResultEvent, param:*):void
		{
			var list:Array = event.result as Array;
			assertNotNull(list);
			assertEquals(list.length, 1000);
			
			var cvo:ComplexVO = list[0] as ComplexVO;
			assertNotNull(cvo);
		}

		[Test(async, timeout="5000")]
		public function getDynamicObject():void
		{
			var token:AsyncToken = nativeObject.getDynamicObject("some value");
			token.addResponder(Async.asyncResponder(this, new TestResponder(getDynamicObject_resultHandler, remote_faultHandler), TIMEOUT));
		}

		private function getDynamicObject_resultHandler(event:ResultEvent, param:*):void
		{
			assertEquals("some value", event.result.someString);
		}

		private function remote_faultHandler(event:FaultEvent, param:*):void
		{
			trace(event.fault.faultDetail);
		}
		
	}
}