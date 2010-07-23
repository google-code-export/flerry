package net.riaspace.flerrydemo.models
{
	[Bindable]
	[RemoteClass(alias="net.riaspace.flerrydemo.models.ComplexVO")]
	public class ComplexVO
	{
		public var someString:String;
		
		public var someInteger:Number;
		
		public var someDate:Date;		
		
		public function ComplexVO()
		{
		}
	}
}