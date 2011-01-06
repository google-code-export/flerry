package net.riaspace.flerry.events
{
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	
	public class FlerryInitEvent extends Event
	{
		
		public static const INIT_COMPLETE:String = "INIT_COMPLETE";
		
		public static const INIT_ERROR:String = "INIT_ERROR";
		
		public var startupInfo:NativeProcessStartupInfo;
		
		public var errorMessage:String;
		
		public function FlerryInitEvent(type:String, startupInfo:NativeProcessStartupInfo = null, errorMessage:String = null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.startupInfo = startupInfo;
			this.errorMessage = errorMessage;
			super(type, bubbles, cancelable);
		}
	}
}