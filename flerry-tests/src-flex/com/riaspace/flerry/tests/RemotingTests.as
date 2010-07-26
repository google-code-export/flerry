package com.riaspace.flerry.tests
{
	import com.riaspace.flerry.tests.models.ComplexVO;
	
	import mx.collections.ArrayCollection;
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
		public function addTest():void
		{
			var token:AsyncToken = nativeObject.add(1, 2);
			token.addResponder(Async.asyncResponder(this, new TestResponder(add_resultHandler, remote_faultHandler), TIMEOUT));
		}		

		private function add_resultHandler(event:ResultEvent, param:*):void
		{
			assertEquals(3, event.result);
		}
		
		[Test(async, timeout="5000")]
		public function getLargeObjectTest():void
		{
			var token:AsyncToken = nativeObject.getLargeObject();
			token.addResponder(Async.asyncResponder(this, new TestResponder(getLargeObject_resultHandler, remote_faultHandler), TIMEOUT));
		}		

		[Test(async, timeout="5000")]
		private function getLargeObject_resultHandler(event:ResultEvent, param:*):void
		{
			var list:ArrayCollection = event.result as ArrayCollection;
			assertNotNull(list);
			assertEquals(list.length, 100000);
			
			var cvo:ComplexVO = list.getItemAt(0) as ComplexVO;
			assertNotNull(cvo);
		}
		
		[Test(async, timeout="5000")]
		public function processComplexVOTest():void
		{
			var cvo:ComplexVO = new ComplexVO();
			cvo.someString = "Hello Java!";
			cvo.someInteger = 0;
			cvo.someDate = new Date();
			
			var token:AsyncToken = nativeObject.processComplexVO(cvo);
			token.addResponder(Async.asyncResponder(this, new TestResponder(processComplexVO_resultHandler, remote_faultHandler), TIMEOUT));
		}		

		private function processComplexVO_resultHandler(event:ResultEvent, param:*):void
		{
			var cvo:ComplexVO = event.result as ComplexVO;
			assertNotNull(cvo);
			assertEquals(cvo.someInteger, 1);
		}

		[Test(async, timeout="5000")]
		public function getNotExistingVOTest():void
		{
			var token:AsyncToken = nativeObject.getNotExistingVO("some value");
			token.addResponder(Async.asyncResponder(this, new TestResponder(getNotExistingVO_resultHandler, remote_faultHandler), TIMEOUT));
		}

		private function getNotExistingVO_resultHandler(event:ResultEvent, param:*):void
		{
			assertEquals("some value", event.result.someString);
		}

		private function remote_faultHandler(event:FaultEvent, param:*):void
		{
			trace(event.fault.faultDetail);
		}
		
	}
}