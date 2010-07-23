package net.riaspace.flerry
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.system.Capabilities;
	
	import mx.utils.StringUtil;
	
	import net.riaspace.flerry.events.FlerryInitEvent;
	
	[Bindable]
	public class BaseStartupInfoProvider extends EventDispatcher implements IStartupInfoProvider
	{
	
		/**
		 * Default classpath where {0} will be replaced with proper classpath separator and {1} with application classpath property 
		 * "../flerry.jar{0}../libs/flex-messaging-core.jar{0}../libs/flex-messaging-common.jar"
		 */
		public var classpathTemplate:String = "./jars/flerry.jar{0}./jars/flex-messaging-core.jar{0}./jars/flex-messaging-common.jar{0}{1}";
		
		public var jarsDirectory:String;
		
		public var binPath:String;
		
		public var source:String;
		
		public var singleton:Boolean;
		
		protected var findJavaProcess:NativeProcess;
		
		private var os:String;
		
		public function BaseStartupInfoProvider(jarsDirectory:String = null, source:String = null, singleton:Boolean = false)
		{
			this.os = Capabilities.os.toLowerCase();
			
			this.jarsDirectory = jarsDirectory;
			this.source = source;
			this.singleton = singleton;
			
			processClasspath();
		}
		
		/**
		 * Process the $jarsDir, adding all jars to classpath
		 */
		protected function processClasspath():void
		{
			var cp:String = os.indexOf('win') > -1 ? ';':':';
			
			var jarsDir:File = File.applicationDirectory.resolvePath(jarsDirectory);
			var jars:Array = jarsDir.getDirectoryListing();
			binPath = "";
			
			for (var i:int = 0; i < jars.length; i++) 
			{
				if(classpathTemplate.indexOf(File(jars[i]).name) != -1)
				{
					continue;
				}
				
				binPath += "./" + jarsDirectory + "/" + File(jars[i]).name + cp;
			}
		}
		
		public function findJava():void
		{
			if (os.indexOf('win') > -1)
				findJavaOnWindows();
			else
				findJavaOnUnix();
		}

		protected function handleError(errorMessage:String):void
		{
			dispatchEvent(new FlerryInitEvent(FlerryInitEvent.INIT_ERROR, null, errorMessage));
		}
		
		protected function findJavaOnWindows():void 
		{
			try
			{
				var findJavaInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
				findJavaInfo.executable = File.applicationDirectory.resolvePath(jarsDirectory).resolvePath("FindJava.exe");
				findJavaInfo.workingDirectory = File.applicationDirectory;
				
				findJavaProcess = new NativeProcess();
				findJavaProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, findJavaProcess_outputDataHandler);
				findJavaProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, findJavaProcess_errorDataHandler);
				
				findJavaProcess.addEventListener(IOErrorEvent.STANDARD_INPUT_IO_ERROR, findJavaProcess_ioErrorHandler);
				findJavaProcess.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, findJavaProcess_ioErrorHandler);
				findJavaProcess.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, findJavaProcess_ioErrorHandler);
	
				findJavaProcess.start(findJavaInfo);
			}
			catch (error:Error)
			{
				handleError("Couldn't execute FindJava.exe: " + error.message);
			}
		}

		private function findJavaProcess_ioErrorHandler(event:IOErrorEvent):void
		{
			handleError("Error finding Java on Windows platform: " + event.text);
		}

		private function findJavaProcess_errorDataHandler(event:ProgressEvent):void
		{
			handleError("Error finding Java on Windows platform: " + event.type);
		}

		private function findJavaProcess_outputDataHandler(event:ProgressEvent):void
		{
			var java:File = new File(findJavaProcess.standardOutput.readUTFBytes(findJavaProcess.standardOutput.bytesAvailable));
			handleResultEvent(java);	
			
			if (findJavaProcess.running)
				findJavaProcess.exit();
			findJavaProcess = null;
		}
		
		protected function findJavaOnUnix():void
		{
			var java:File = new File("/usr/bin/java");
			if (!java.exists)
				java = new File(os.indexOf("mac") > -1 ? "/System/Library/Frameworks/JavaVM.framework/Versions/Current/Commands/java" : "/etc/alternatives/java");
			
			handleResultEvent(java);
		}

		protected function handleResultEvent(java:File):void
		{
			if (java.exists)
				dispatchEvent(new FlerryInitEvent(FlerryInitEvent.INIT_COMPLETE, createStartupInfo(java)));
			else
				handleError("Couldn't find java!");
		}
		
		protected function createStartupInfo(java:File):NativeProcessStartupInfo
		{
			var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			startupInfo.executable = java;
			startupInfo.workingDirectory = File.applicationDirectory;
			
			var args:Vector.<String> = new Vector.<String>();
			args.push("-cp");
			args.push(StringUtil.substitute(classpathTemplate, os.indexOf('win') > -1 ? ';':':', binPath));
			args.push("net.riaspace.flerry.NativeObject");
			args.push("-source", source, "-singleton", singleton);
			startupInfo.arguments = args;
			
			return startupInfo;	
		}
	}
}