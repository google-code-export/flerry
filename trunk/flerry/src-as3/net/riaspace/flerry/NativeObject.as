package net.riaspace.flerry
{
	import flash.desktop.NativeProcess;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import mx.core.mx_internal;
	import mx.messaging.events.MessageEvent;
	import mx.messaging.events.MessageFaultEvent;
	import mx.messaging.messages.AcknowledgeMessage;
	import mx.messaging.messages.ErrorMessage;
	import mx.messaging.messages.RemotingMessage;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import net.riaspace.flerry.events.FlerryInitEvent;
	
	use namespace flash_proxy;
	use namespace mx_internal;
	
	[DefaultProperty("methods")]
	
	[Event(name="result", type="mx.rpc.events.ResultEvent")]
	[Event(name="fault", type="mx.rpc.events.FaultEvent")]
	public dynamic class NativeObject extends Proxy implements IEventDispatcher
	{
		
		public static const STOP_PROCESS_HEADER:String = "STOP_PROCESS_HEADER";
		
		[Bindable]
		public var source:String;
		
		[Bindable]
		public var singleton:Boolean = false;

		[Bindable]
		public var libsDirectory:String = "libs";
		
		[Bindable]
		public var debugPort:uint = 8000;

		[Bindable]
		public var debug:Boolean = Capabilities.isDebugger;

		[Bindable]
		public var startupInfoProvider:IStartupInfoProvider;
		
		protected var _methods:Array = new Array();
		
		protected var messagesBuffer:Vector.<RemotingMessage> = new Vector.<RemotingMessage>();
		
		protected var eventDispatcher:IEventDispatcher;
		
		protected var nativeProcess:NativeProcess;
		
		protected var tokens:Dictionary = new Dictionary();
		
		protected var messageBytes:ByteArray = new ByteArray();
		
		public function NativeObject(source:String = null, singleton:Boolean = false)
		{
			eventDispatcher = new EventDispatcher(this);
			this.source = source;
			this.singleton = singleton;
		}
		
		protected function initialize():void
		{
			if (!startupInfoProvider)
				startupInfoProvider = new BaseStartupInfoProvider(libsDirectory, source, singleton, debug, debugPort);
			startupInfoProvider.addEventListener(FlerryInitEvent.INIT_COMPLETE, startupInfoProvider_initCompleteHandler);
			startupInfoProvider.addEventListener(FlerryInitEvent.INIT_ERROR, startupInfoProvider_initErrorHandler);
			startupInfoProvider.findJava();
		}

		protected function startupInfoProvider_initErrorHandler(event:FlerryInitEvent):void
		{
			event.stopImmediatePropagation();
			
			if (hasEventListener(FaultEvent.FAULT))
				dispatchEvent(FaultEvent.createEvent(new Fault("001", event.errorMessage, event.errorMessage)));
			else
				trace("Error initilizing NativeProcessStartupInfo:", event.errorMessage);
		}

		protected function startupInfoProvider_initCompleteHandler(event:FlerryInitEvent):void
		{
			event.stopImmediatePropagation();
			
			nativeProcess = new NativeProcess();
			nativeProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			nativeProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			
			nativeProcess.addEventListener(IOErrorEvent.STANDARD_INPUT_IO_ERROR, ioErrorInputError);
			nativeProcess.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, ioErrorInputError);
			nativeProcess.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, ioErrorInputError);
			
			nativeProcess.start(event.startupInfo);
			
			// Invoking buffered native calls
			messagesBuffer.reverse();
			while (messagesBuffer.length > 0)
			{
				writeMessageObject(messagesBuffer.pop());
			}
		}
		
		protected function ioErrorInputError(event:IOErrorEvent):void
		{
			messageBytes.clear();
		}
		
		protected function onOutputData(event:ProgressEvent):void
		{
			nativeProcess.standardOutput.readBytes(
				messageBytes, messageBytes.length, nativeProcess.standardOutput.bytesAvailable);
			
			if ((messageBytes[messageBytes.length -1] == 99) &&  
				(messageBytes[messageBytes.length -2] == 99) && 
				(messageBytes[messageBytes.length -3] == 99) && 
				(messageBytes[messageBytes.length -4] == 99))
			{
				/* NOTE: messageBytes.readObject will IGNORE the marker bytes automatically, so no need to delete them */
				//create object from the collected bytes
				var message:AcknowledgeMessage = messageBytes.readObject() as AcknowledgeMessage;
				if (message && tokens[message.correlationId])
				{
					var token:AsyncToken = tokens[message.correlationId];
					delete tokens[message.correlationId];
					
					var resultEvent:ResultEvent = ResultEvent.createEvent(message.body, token, message);
					token.applyResult(resultEvent);
					
					var remotingMessage:RemotingMessage = token.message as RemotingMessage;
					if (remotingMessage)
					{
						var method:NativeMethod = _methods[remotingMessage.operation];
						if (method.hasEventListener(ResultEvent.RESULT))
							method.dispatchEvent(resultEvent);					
					}
					
					if (hasEventListener(ResultEvent.RESULT))
						dispatchEvent(resultEvent);
				}
				// if message isn't a response to a request then dispatch MessageEvent
				else if (message)
				{
					var messageEvent:mx.messaging.events.MessageEvent = MessageEvent.createEvent(message.correlationId, message)
					dispatchEvent(messageEvent);
				}
				messageBytes.clear();
			} 
		}
		
		protected function onErrorData(event:ProgressEvent):void
		{
			var buffer:ByteArray = new ByteArray();
			while (nativeProcess.standardError.bytesAvailable > 0)
				nativeProcess.standardError.readBytes(buffer, buffer.length, nativeProcess.standardError.bytesAvailable);

			try
			{
				var message:ErrorMessage = buffer.readObject() as ErrorMessage;
				if (message && message.correlationId)
				{
					var token:AsyncToken = tokens[message.correlationId];
					delete tokens[message.correlationId];
					
					var resultEvent:FaultEvent = FaultEvent.createEventFromMessageFault(MessageFaultEvent.createEvent(message), token);
					
					token.applyFault(resultEvent);
					var remotingMessage:RemotingMessage = token.message as RemotingMessage;
					if (remotingMessage)
					{
						var method:NativeMethod = _methods[remotingMessage.operation];
						if (method.hasEventListener(FaultEvent.FAULT))
							method.dispatchEvent(resultEvent);					
					}
					
					if (hasEventListener(FaultEvent.FAULT))
						dispatchEvent(resultEvent);
				} 
				else if (message)
				{
					throw new Error("NativeProcess error without correlationId: " + message);
				}
			} 
			catch (error:Error)
			{
				throw new Error("Error deserializing received AMF object: " + buffer.toString());
			}
		}
		
		/**
		 * tries to close remote process
		 */
		public function exit():void
		{
			if(nativeProcess)
			{
				var stopMessage:RemotingMessage = new RemotingMessage();
				stopMessage.headers = {STOP_PROCESS_HEADER:true};
				writeMessageObject(stopMessage);
				
				nativeProcess.exit(true);
				nativeProcess = null;
			}
		}
		
		/**
		 * Subscribe to receive remote messages.
		 * @param String messageId
		 * @param Function(event:MessageEvent)
		 */
		public function subscribe(messageId:String, handler:Function):void
		{
			if (nativeProcess)
				initialize();
			
			addEventListener(messageId, handler);
		}
		
		override flash_proxy function setProperty(name:*, value:*):void
		{
			trace("setProperty called! " + name);
		}
		
		override flash_proxy function callProperty(methodName:*, ... args):* 
		{
			
			var method:* = _methods[methodName];
			
			if(method is Function){
				var fnc:Function = method;
				return fnc.apply(args);
			}
			
			if (method == null){
				method = new NativeMethod();
				method.name = methodName;
				_methods[methodName] = method;
			}
			
			if(args && args.length > 0 && args[0] is IResponder){
				var responder:IResponder = args.shift()
				// listener function as variable so we can remove it after the call
				var resultResponder:Function = function(e:ResultEvent):void {
					responder.result(e);
					NativeMethod(method).removeEventListener(ResultEvent.RESULT,resultResponder)
				}
				NativeMethod(method).addEventListener(ResultEvent.RESULT,resultResponder)
				// same as above :)
				var faultResponder:Function = function(e:FaultEvent):void {
					responder.fault(e);
					NativeMethod(method).removeEventListener(FaultEvent.FAULT,faultResponder)
				}
				NativeMethod(method).addEventListener(FaultEvent.FAULT,faultResponder)
			}
			
			return call(method, args);
		}
			
		protected function call(method:NativeMethod, ... args):AsyncToken
		{
			var message:RemotingMessage = new RemotingMessage();
			message.operation = method.name;
			message.source = source;
			message.headers = {SINGLETON_HEADER:singleton};
			if (args.length == 1)
				message.body = args[0];
			
			if (!nativeProcess)
			{
				messagesBuffer.push(message);
				initialize();
			}
			else
			{
				writeMessageObject(message);
			}
			
			var token:AsyncToken = new AsyncToken(message);
			tokens[message.messageId] = token;
			
			return token;
		}
		
		protected function writeMessageObject(message:RemotingMessage):void
		{
			var bytes:ByteArray = new ByteArray;
			bytes.writeObject(message);
			// add flags to identify the end of message			
			bytes.writeByte(99);
			bytes.writeByte(99);
			bytes.writeByte(99);
			bytes.writeByte(99);
			
			var packetSize:int = 256;
			// send the message in chunks of size {packetSize}
			for(var i:int = 0; i < Math.ceil(bytes.length / packetSize) ; i++){
				nativeProcess.standardInput.writeBytes(bytes,i * packetSize, Math.min(bytes.length - (i * packetSize),packetSize) ); 
			}
		}
		
		[Bindable]
		public function set methods(methods:Array):void
		{
			_methods = new Array();
			for each(var method:NativeMethod in methods)
			{
				_methods[method.name] = method;
			}
		}
		
		[ArrayElementType("net.riaspace.flerry.NativeMethod")]
		public function get methods():Array
		{
			return _methods;
		}
		
		/// ----------------------------------
		/// EventDispatcher functions
		/// ----------------------------------
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
		{
			eventDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function dispatchEvent(event:Event):Boolean
		{
			return eventDispatcher.dispatchEvent(event);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void
		{
			eventDispatcher.removeEventListener(type, listener, useCapture);
		}
		
		public function hasEventListener(type:String):Boolean
		{
			return eventDispatcher.hasEventListener(type);
		}
		
		public function willTrigger(type:String):Boolean
		{
			return eventDispatcher.willTrigger(type);
		}
	}
}