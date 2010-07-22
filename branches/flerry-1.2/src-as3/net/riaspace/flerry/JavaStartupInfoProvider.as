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
		
		public function init(binPath:String, source:String, singleton:Boolean, executablePath:String = null):void
		{
			var osName:String = Capabilities.os.toLowerCase();
			if (osName.indexOf("win") > -1) 
			{
				var findJavaInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
				findJavaInfo.executable = new File("./jars/FindJava.exe");
				findJavaInfo.workingDirectory = File.applicationDirectory;
				
				findJavaProcess = new NativeProcess();
				findJavaProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, findJavaProcess_outputDataHandler);
				findJavaProcess.start(findJavaInfo);
			} 
			else
			{
				var startupInfo:NativeProcessStartupInfo = getStartupInfo(binPath, source, singleton, executablePath);
				dispatchEvent(new FlerryInitEvent(FlerryInitEvent.INIT_COMPLETE, startupInfo));
			}
		}

		private function findJavaProcess_outputDataHandler(event:ProgressEvent):void
		{
			trace(findJavaProcess.standardOutput.readUTFBytes(findJavaProcess.standardOutput.bytesAvailable));
			
			findJavaProcess.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, findJavaProcess_outputDataHandler);
			findJavaProcess.exit();
			findJavaProcess = null;
		}
		
		protected function getStartupInfo(binPath:String, source:String, singleton:Boolean, executablePath:String = null):NativeProcessStartupInfo
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
			
			if (osName.indexOf("win") > -1) 
			{
				var programFiles:File = new File("C:\\Program Files\\");
				if (programFiles.exists)
				{
					for each(var appDir:File in programFiles.getDirectoryListing())
					{
						if (appDir.name.toLowerCase().indexOf("java") > -1 && appDir.isDirectory)
						{
							for each(var subDir:File in appDir.getDirectoryListing())
							{
								var subDirName:String = subDir.name.toLowerCase();
								if (subDirName.indexOf("jdk") > -1 || subDirName.indexOf("jre") > -1)
								{
									var javaw:File = subDir.resolvePath("bin").resolvePath("javaw.exe");
									if (javaw.exists)
									{
										result = javaw;
										break;
									}
								}
							}
							if (result != null)
								break;
						}
					}
				}
			} 
			else if (osName.indexOf("mac") > -1)
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