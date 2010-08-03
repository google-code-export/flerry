To build native installer use following command from bin-debug - after building project in Flash Builder:

/path/to/adt -package -storetype pkcs12 -keystore /path/to/cert.p12 -target native flerry.dmg FlerryDemo-app.xml FlerryDemo.swf jars
