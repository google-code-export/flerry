package net.riaspace.flerry
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.system.Capabilities;
	
	import mx.utils.StringUtil;
	
	import net.riaspace.flerry.events.FlerryInitEvent;

	public class JavaStartupInfoProvider extends EventDispatcher implements IStartupInfoProvider
	{
		/**
		 * Default classpath where {0} will be replaced with proper classpath separator and {1} with application classpath property 
		 * "../flerry.jar{0}../libs/flex-messaging-core.jar{0}../libs/flex-messaging-common.jar"
		 */
		public var classpathTemplate:String = "./jars/flerry.jar{0}./jars/flex-messaging-core.jar{0}./jars/flex-messaging-common.jar{0}{1}";
		
		protected var findJavaProcess:NativeProcess;
		
		protected var binPath:String;
		
		protected var source:String;
		
		protected var singleton:Boolean;
		
		public function JavaStartupInfoProvider(jarsDirectory:String, source:String, singleton:Boolean)
		{
			processClasspath(jarsDirectory);
			this.source = source;
			this.singleton = singleton;
		}
		
		/**
		 * Process the $jarsDir, adding all jars to classpath
		 */
		public function processClasspath(jarsDirectory:String):void{
			var cp:String = Capabilities.os.toLowerCase().indexOf('win') > -1 ? ';':':';
			
			var jarsDir:File = File.applicationDirectory.resolvePath(jarsDirectory);
			var jars:Array = jarsDir.getDirectoryListing();
			binPath = "";
			
			for (var i:int = 0; i < jars.length; i++) {
				if(classpathTemplate.indexOf(File(jars[i]).name)!= -1){
					continue
				}
				
				binPath += "./" + jarsDirectory + "/" + File(jars[i]).name + cp;
			}
		}
		
		public function findJava():void
		{
			var osName:String = Capabilities.os.toLowerCase();
			if (osName.indexOf("win") > -1) 
			{
				var findJavaInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
				findJavaInfo.executable = File.applicationDirectory.resolvePath("./jars/FindJava.exe");
				findJavaInfo.workingDirectory = File.applicationDirectory;
				
				findJavaProcess = new NativeProcess();
				findJavaProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, findJavaProcess_outputDataHandler);
				findJavaProcess.start(findJavaInfo);
			} 
			else
			{
				dispatchEvent(new FlerryInitEvent(FlerryInitEvent.INIT_COMPLETE, getStartupInfo()));
			}
		}

		protected function findJavaProcess_outputDataHandler(event:ProgressEvent):void
		{
			var javaPath:String = findJavaProcess.standardOutput.readUTFBytes(findJavaProcess.standardOutput.bytesAvailable);
			// TODO: dispatch event if not found
			
			dispatchEvent(new FlerryInitEvent(FlerryInitEvent.INIT_COMPLETE, getStartupInfo()));
			
			findJavaProcess.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, findJavaProcess_outputDataHandler);
			findJavaProcess.exit();
			findJavaProcess = null;
		}
		
		protected function getStartupInfo():NativeProcessStartupInfo
		{
			var executable:File = executableFile;
			if (executable != null)
			{
				var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
				startupInfo.executable = executable;
				startupInfo.workingDirectory = File.applicationDirectory;
				
				var args:Vector.<String> = new Vector.<String>();
				args.push("-cp");
				args.push(StringUtil.substitute(classpathTemplate, classpathSeparator, binPath));
				args.push("net.riaspace.flerry.NativeObject");
				args.push("-source", source, "-singleton", singleton);
				startupInfo.arguments = args;
				
				return startupInfo;				
			}
			else
				throw new Error("NativeProcess executable was not found for this operating system!");
		}
		
		protected function get classpathSeparator():String
		{
			var osName:String = Capabilities.os.toLowerCase();
			if (osName.indexOf("win") > -1) 
			{
				return ";";
			} 
			else
			{
				return ":";
			}
		}
		
		protected function get executableFile():File
		{
			var result:File;
			var osName:String = Capabilities.os.toLowerCase();
			
			if (osName.indexOf("mac") > -1)
			{
				result = getJavaOnUnix("/System/Library/Frameworks/JavaVM.framework/Versions/Current/Commands/java");
			} 
			else if (osName.indexOf("linux") > -1) 
			{
				result = getJavaOnUnix("/etc/alternatives/java");
			}
			
			return result;
		}		
		
		protected function getJavaOnUnix(alternativePath:String):File
		{
			var java:File = new File("/usr/bin/java");
			if (!java.exists)
				java = new File(alternativePath);
			return java;
		}
	}
}