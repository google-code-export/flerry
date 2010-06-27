package net.riaspace.flerry
{
	import flash.events.Event;
	
	public class MessageEvent extends Event
	{
		public var data:Object;
		
		public function MessageEvent(type:String, data:Object)
		{
			super(type, true, false);
			this.data = data;
		}
	}
}