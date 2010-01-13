package net.riaspace.flerry
{
	import flash.desktop.NativeProcessStartupInfo;

	public interface IStartupInfoProvider
	{
		function getStartupInfo(binPath:String, source:String, singleton:Boolean, executablePath:String = null):NativeProcessStartupInfo;
	}
}