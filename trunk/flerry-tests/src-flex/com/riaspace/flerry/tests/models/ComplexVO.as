package com.riaspace.flerry.tests.models
{
	[Bindable]
	[RemoteClass(alias="com.riaspace.flerry.tests.models.ComplexVO")]
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