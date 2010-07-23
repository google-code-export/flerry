package net.riaspace.flerry
{
	import flash.events.EventDispatcher;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;

	[Event(name="result", type="mx.rpc.events.ResultEvent")]
	[Event(name="fault", type="mx.rpc.events.FaultEvent")]
	public class NativeMethod extends EventDispatcher
	{
		public var name:String;
		
		public function NativeMethod()
		{
		}		
	}
}