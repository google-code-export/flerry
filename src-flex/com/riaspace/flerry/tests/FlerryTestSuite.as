package com.riaspace.flerry.tests
{
	import com.riaspace.flerry.tests.MessagingTests;
	import com.riaspace.flerry.tests.RemotingTests;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class FlerryTestSuite
	{
		public var test1:com.riaspace.flerry.tests.MessagingTests;
		public var test2:com.riaspace.flerry.tests.RemotingTests;
		
	}
}