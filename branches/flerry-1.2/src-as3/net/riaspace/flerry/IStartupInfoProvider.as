package net.riaspace.flerry
{
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.IEventDispatcher;

	[Event(name="result", type="net.riaspace.flerry.events.FlerryInitEvent")]
	[Event(name="fault", type="net.riaspace.flerry.events.FlerryInitEvent")]
	public interface IStartupInfoProvider extends IEventDispatcher
	{
		function findJava():void;
	}
	
}