package tests;

import json2object.JsonParser;
import utest.Assert;

enum Color {
	Green;
	Red;
	RGBA(r:Int, g:Int, b:Int, a:Float);
	None(r:{a:Int});
}

typedef EnumStruct = {
	var value : Color;
}
typedef ArrayEnumStruct = {
	var value : Array<Color>;
}

class EnumTest
{
	public function new () {}

	public function test1 ()
	{
		var parser = new JsonParser<EnumStruct>();
		var data = parser.fromJson('{"value":"Red"}', "test.json");
		Assert.equals(0, parser.errors.length);
		Assert.equals(Red, data.value);

		data = parser.fromJson('{"value":"RGBA"}', "test.json");
		Assert.equals(2, parser.errors.length);
		Assert.isNull(data.value);
	}

	public function test2 ()
	{
		var parser = new JsonParser<EnumStruct>();
		var data = parser.fromJson('{"value":{"Red":{}}}', "test.json");
		Assert.equals(Red, data.value);
		Assert.equals(0, parser.errors.length);

		data = parser.fromJson('{"value":{"RGBA":{"r":25, "g":30, "b":255, "a":0.5}}}', "test.json");
		Assert.equals(0, parser.errors.length);
		Assert.isTrue(Type.enumEq(RGBA(25,30,255,0.5),data.value));
	}

	public function test3 ()
	{
		var parser = new JsonParser<EnumStruct>();
		var data = parser.fromJson('{"value":{"Red":{"a":0.5}}}', "test.json");
		Assert.isNull(data.value);
		Assert.equals(2, parser.errors.length);
	}

	public function test4 ()
	{
		var parser = new JsonParser<EnumStruct>();
		var data = parser.fromJson('{"value":{"None":{"a":0.5}}}', "test.json");
		Assert.isNull(data.value);
		Assert.equals(2, parser.errors.length);
	}

	public function test5 ()
	{
		var parser = new JsonParser<EnumStruct>();
		var data = parser.fromJson('{"value":{"None":{"r":{"a":25}}}}', "test.json");
		Assert.equals(0, parser.errors.length);
		switch (data.value) {
			case None(r):
				Assert.equals(25, r.a);
			default:
				Assert.equals(None({a:25}), data.value);
		}
	}

	public function test6 ()
	{
		var parser = new JsonParser<ArrayEnumStruct>();
		var data = parser.fromJson('{"value":["Red", "Green", "Yellow", {"Red":{}}, {"RGBA":{"r":1, "g":1, "b":0}}, {"RGBA":{"r":1, "g":1, "b":0, "a":0.2}}]}', "");
		Assert.equals(4, data.value.length);
		Assert.equals(-1, data.value.indexOf(null));
	}
}
