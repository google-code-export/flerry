package net.riaspace.flerrydemo.responder
{
	import mx.rpc.IResponder;
	
	import spark.components.TextInput;
	
	public class AddResponder implements IResponder
	{
		private var txt:TextInput
		
		public function AddResponder(txt:TextInput)
		{
			this.txt = txt
		}
		
		public function result(data:Object):void
		{
			trace(data.result)
		}
		
		public function fault(info:Object):void
		{
		}
	}
}