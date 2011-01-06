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
	
		protected var classpath:String = "./libs/flerry.jar";
		
		public var libsDirectory:String;
		
		public var source:String;
		
		public var singleton:Boolean;
		
		public var debug:Boolean;
		
		public var debugPort:uint;
		
		protected var findJavaProcess:NativeProcess;
		
		private var os:String;
		
		public function BaseStartupInfoProvider(libsDirectory:String = null, source:String = null, singleton:Boolean = false, debug:Boolean = false, debugPort:uint = 8000)
		{
			this.os = Capabilities.os.toLowerCase();
			
			this.libsDirectory = libsDirectory;
			this.source = source;
			this.singleton = singleton;
			this.debug = debug;
			this.debugPort = debugPort;
			
			processClasspath();
		}
		
		/**
		 * Process the $jarsDir, adding all jars to classpath
		 */
		protected function processClasspath():void
		{
			var separator:String = os.indexOf('win') > -1 ? ';':':';
			
			var jarsDir:File = File.applicationDirectory.resolvePath(libsDirectory);
			var jars:Array = jarsDir.getDirectoryListing();
			
			classpath = classpath + separator;
			
			for (var i:int = 0; i < jars.length; i++) 
			{
				if(classpath.indexOf(File(jars[i]).name) != -1)
				{
					continue;
				}
				
				classpath += "./" + libsDirectory + "/" + File(jars[i]).name + separator;
			}
			
			classpath += "./classes";
		}
		
		public function findJava():void
		{
			var java:File;
			// Chacking first in default locations
			if (os.indexOf('win') > -1)
				java = new File("c:/windows/system32/javaw.exe");
			else
			{
				java = new File("/usr/bin/java");
				if (!java.exists)
					java = new File(os.indexOf("mac") > -1 ? "/System/Library/Frameworks/JavaVM.framework/Versions/Current/Commands/java" : "/etc/alternatives/java");
			}
			
			// If default locations succeeded
			if (java.exists)
				handleResultEvent(java);
			// Running fallback mechanizm with native services
			else
			{
				if (os.indexOf('win') > -1)
					runFallbackMechanizm(File.applicationDirectory.resolvePath(libsDirectory).resolvePath("FindJava.exe"));
				else
				{
					var args:Vector.<String> = new Vector.<String>();
					args.push("java");
					runFallbackMechanizm(new File("/usr/bin/whereis"), args);
				}				
			}
		}

		protected function runFallbackMechanizm(executable:File, args:Vector.<String> = null):void
		{
			try
			{
				var findJavaInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
				findJavaInfo.executable = executable;
				findJavaInfo.workingDirectory = File.applicationDirectory;
				findJavaInfo.arguments = args
				
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
				handleError("Couldn't execute whereis java: " + error.message);
			}
		}
		
		private function findJavaProcess_ioErrorHandler(event:IOErrorEvent):void
		{
			handleError("Error finding Java: " + event.text);
		}

		private function findJavaProcess_errorDataHandler(event:ProgressEvent):void
		{
			handleError("Error finding Java: " + event.type);
		}

		private function findJavaProcess_outputDataHandler(event:ProgressEvent):void
		{
			var java:File = new File(StringUtil.trim(findJavaProcess.standardOutput.readUTFBytes(findJavaProcess.standardOutput.bytesAvailable)));
			if (os.indexOf('win') > -1) // In case of win FindJava.exe returns only path to directory with java
				java = java.resolvePath("bin").resolvePath("javaw.exe");
			
			handleResultEvent(java);	
			
			if (findJavaProcess.running)
				findJavaProcess.exit();
			findJavaProcess = null;
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
			if (debug)
				args.push("-Xdebug", "-Xrunjdwp:transport=dt_socket,server=n,suspend=n,quiet=y,address=" + debugPort.toString());
			args.push("-cp");
			args.push(classpath);
			args.push("net.riaspace.flerry.NativeObject");
			args.push("-source", source, "-singleton", singleton);
			startupInfo.arguments = args;
			
			return startupInfo;	
		}
		
		protected function handleError(errorMessage:String):void
		{
			dispatchEvent(new FlerryInitEvent(FlerryInitEvent.INIT_ERROR, null, errorMessage));
		}

	}
}