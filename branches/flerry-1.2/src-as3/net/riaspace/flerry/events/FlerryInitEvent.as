package net.riaspace.flerry.events
{
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	
	public class FlerryInitEvent extends Event
	{
		
		public static const INIT_COMPLETE:String = "INIT_COMPLETE";
		
		public static const INIT_ERROR:String = "INIT_ERROR";
		
		public var startupInfo:NativeProcessStartupInfo;
		
		public function FlerryInitEvent(type:String, startupInfo:NativeProcessStartupInfo = null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.startupInfo = startupInfo;
			super(type, bubbles, cancelable);
		}
	}
}