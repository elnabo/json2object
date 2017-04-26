package tests;

import json2object.JsonParser;

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


class EnumTest extends haxe.unit.TestCase {

	public function test () {
		{
			var parser = new JsonParser<EnumStruct>();
			var data = parser.fromJson('{"value":"Red"}', "test.json");
			assertEquals(0, parser.errors.length);
			assertEquals(Red, data.value);

			data = parser.fromJson('{"value":"RGBA"}', "test.json");
			assertEquals(2, parser.errors.length);
			assertEquals(null, data.value);
		}

		{
			var parser = new JsonParser<EnumStruct>();
			var data = parser.fromJson('{"value":{"Red":{}}}', "test.json");
			assertEquals(Red, data.value);
			assertEquals(0, parser.errors.length);

			data = parser.fromJson('{"value":{"RGBA":{"r":25, "g":30, "b":255, "a":0.5}}}', "test.json");
			assertEquals(0, parser.errors.length);
			assertTrue(Type.enumEq(RGBA(25,30,255,0.5),data.value));
		}

		{
			var parser = new JsonParser<EnumStruct>();
			var data = parser.fromJson('{"value":{"Red":{"a":0.5}}}', "test.json");
			assertEquals(null, data.value);
			assertEquals(2, parser.errors.length);
		}

		{
			var parser = new JsonParser<EnumStruct>();
			var data = parser.fromJson('{"value":{"None":{"a":0.5}}}', "test.json");
			assertEquals(null, data.value);
			assertEquals(2, parser.errors.length);
		}

		{
			var parser = new JsonParser<EnumStruct>();
			var data = parser.fromJson('{"value":{"None":{"r":{"a":25}}}}', "test.json");
			assertEquals(0, parser.errors.length);
			switch (data.value) {
				case None(r):
					assertEquals(25, r.a);
				default:
					assertEquals(None({a:25}), data.value);
			}
		}

		{
			var parser = new JsonParser<ArrayEnumStruct>();
			var data = parser.fromJson('{"value":["Red", "Green", "Yellow", {"Red":{}}, {"RGBA":{"r":1, "g":1, "b":0}}, {"RGBA":{"r":1, "g":1, "b":0, "a":0.2}}]}', "");
			assertEquals(4, data.value.length);
			assertEquals(-1, data.value.indexOf(null));
		}
	}
}
