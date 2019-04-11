/*
Copyright (c) 2017-2019 Guillaume Desquesnes, Valentin Lemière

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

package tests;

import json2object.Error;
import json2object.JsonParser;
import json2object.JsonWriter;
import json2object.utils.JsonSchemaWriter;
import utest.Assert;

enum Color {
	Green;
	Red;
	RGBA(r:Int, g:Int, b:Int, a:Float);
	None(r:{a:Int});
}

enum WithParam<T1, T2> {
	First(a:T1);
	Second(a:T2);
	Both(a:T1, b:T2);
}

typedef EnumStruct = {
	var value : Color;
}

typedef ArrayEnumStruct = {
	var value : Array<Color>;
}

typedef WithParamStruct = {
	var value : WithParam<String, Int>;
}

enum Enum1 {
	EnumValue1(value:String);
	EnumValue2(errors:String);
	EnumValue3(putils:String);
}

typedef WithDefault = {
	@:default(Green) @:optional var value : Color;
}

typedef WithDefaultOther = {
	@:default(VAL1) @:optional var value : tests.OtherEnum.TestEnum;
}

class EnumTest implements utest.ITest
{
	public function new () {}

	public function test1 ()
	{
		var parser = new JsonParser<EnumStruct>();
		var writer = new JsonWriter<EnumStruct>();
		var data = parser.fromJson('{"value":"Red"}', "test.json");
		Assert.equals(0, parser.errors.length);
		Assert.equals(Red, data.value);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"value":"RGBA"}', "test.json");
		Assert.equals(2, parser.errors.length);
		Assert.isNull(data.value);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	public function test2 ()
	{
		var parser = new JsonParser<EnumStruct>();
		var writer = new JsonWriter<EnumStruct>();
		var data = parser.fromJson('{"value":{"Red":{}}}', "test.json");
		Assert.equals(Red, data.value);
		Assert.equals(0, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"value":{"RGBA":{"r":25, "g":30, "b":255, "a":0.5}}}', "test.json");
		Assert.equals(0, parser.errors.length);
		Assert.isTrue(Type.enumEq(RGBA(25,30,255,0.5),data.value));
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	public function test3 ()
	{
		var parser = new JsonParser<EnumStruct>();
		var writer = new JsonWriter<EnumStruct>();
		var data = parser.fromJson('{"value":{"Red":{"a":0.5}}}', "test.json");
		Assert.isNull(data.value);
		Assert.equals(2, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	public function test4 ()
	{
		var parser = new JsonParser<EnumStruct>();
		var writer = new JsonWriter<EnumStruct>();
		var data = parser.fromJson('{"value":{"None":{"a":0.5}}}', "test.json");
		Assert.isNull(data.value);
		Assert.equals(2, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	public function test5 ()
	{
		var parser = new JsonParser<EnumStruct>();
		var writer = new JsonWriter<EnumStruct>();
		var data = parser.fromJson('{"value":{"None":{"r":{"a":25}}}}', "test.json");
		Assert.equals(0, parser.errors.length);
		switch (data.value) {
			case None(r):
				Assert.equals(25, r.a);
			default:
				Assert.equals(None({a:25}), data.value);
		}
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	public function test6 ()
	{
		var parser = new JsonParser<ArrayEnumStruct>();
		var writer = new JsonWriter<ArrayEnumStruct>();
		var data = parser.fromJson('{"value":["Red", "Green", "Yellow", {"Red":{}}, {"RGBA":{"r":1, "g":1, "b":0}}, {"RGBA":{"r":1, "g":1, "b":0, "a":0.2}}]}', "");
		Assert.equals(4, data.value.length);
		Assert.equals(-1, data.value.indexOf(null));
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	public function test7 ()
	{
		var parser = new JsonParser<WithParamStruct>();
		var writer = new JsonWriter<WithParamStruct>();
		var data = parser.fromJson('{"value":{"First":{"a":"a"}}}', "test.json");
		Assert.equals(0, parser.errors.length);
		Assert.isTrue(Type.enumEq(First("a"),data.value));
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"value":{"Second":{"a":1}}}', "test.json");
		Assert.equals(0, parser.errors.length);
		Assert.isTrue(Type.enumEq(Second(1),data.value));
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"value":{"Both":{"a":"a","b":1}}}', "test.json");
		Assert.equals(0, parser.errors.length);
		Assert.isTrue(Type.enumEq(Both("a",1),data.value));
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"value":{"Both":{"b":1,"a":"a"}}}', "test.json");
		Assert.equals(0, parser.errors.length);
		Assert.isTrue(Type.enumEq(Both("a",1),data.value));
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"value":{"Second":{"b":1}}}', "test.json");
		Assert.same(InvalidEnumConstructor("Second", "WithParam", {file:"test.json", lines:[{number:1, start:10, end:28}], min:10, max:28}), parser.errors[0]);
		Assert.same(UninitializedVariable("value", {file:"test.json", lines:[{number:1, start:29, end:29}], min:29, max:29}), parser.errors[1]);
		Assert.equals(2, parser.errors.length);
	}

	public function test8 ()
	{
		var parser = new JsonParser<WithParamStruct>();
		var writer = new JsonWriter<WithParamStruct>();
		var data = parser.fromJson('{"value":{"First":{"a":1}}}', "test.json");
		Assert.equals(2, parser.errors.length);
		Assert.isNull(data.value);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('{"value":{"Second":{"b":"1"}}}', "test.json");
		Assert.equals(2, parser.errors.length);
		Assert.isNull(data.value);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	/** Issue 32 */
	public function test9 ()
	{
		var writer = new JsonWriter<Enum1>();
		var json:String = writer.write(EnumValue1("test"));
		Assert.equals(json,'{"EnumValue1": {"value": "test"}}');

		var parser = new JsonParser<Enum1>();
		parser.fromJson(json, '');
		Assert.same(parser.errors, []);
		Assert.same(parser.value, EnumValue1("test"));

		var parser = new JsonParser<Enum1>();
		parser.fromJson('{"EnumValue2": {"errors": "test"}}', '');
		Assert.same(parser.errors, []);
		Assert.same(parser.value, EnumValue2("test"));

		var parser = new JsonParser<Enum1>();
		parser.fromJson('{"EnumValue3": {"putils": "test"}}', '');
		Assert.same(parser.errors, []);
		Assert.same(parser.value, EnumValue3("test"));
	}

	/** Issue 34 **/
	public function test10 ()
	{
		var parser = new JsonParser<WithDefault>();
		var writer = new JsonWriter<WithDefault>();
		var data = parser.fromJson('{}', "test.json");
		Assert.equals(0, parser.errors.length);
		Assert.same(data.value, Color.Green);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));

		var parser = new JsonParser<WithDefaultOther>();
		var writer = new JsonWriter<WithDefaultOther>();
		var data = parser.fromJson('{}', "test.json");
		Assert.equals(0, parser.errors.length);
		Assert.same(data.value, tests.OtherEnum.TestEnum.VAL1);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}
}
