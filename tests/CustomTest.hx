/*
	Copyright (c) 2017-2018 Guillaume Desquesnes, Valentin Lemière

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

import hxjsonast.Printer;
import haxe.Json;
import json2object.JsonParser;
import json2object.JsonWriter;
import utest.Assert;

class CustomNum {
	@:jcustomwrite(tests.CustomTest.CustomNum.CustomWriteInt)
	@:jcustomparse(tests.CustomTest.CustomNum.CustomParseInt)
	public var value:Int;

	@:jcustomwrite(tests.CustomTest.CustomNum.CustomWriteString)
	@:jcustomparse(tests.CustomTest.CustomNum.CustomParseString)
	@:optional
	@:default("0")
	public var opt_value:String;

	public var control:Int;

	public static var _prefix = "The Number ";

	public static function CustomWriteInt(o:Int):String {
		return '"$_prefix$o"';
	}

	public static function CustomWriteString(o:String):String {
		return '$o';
	}

	public static function CustomParseInt(val:hxjsonast.Json, name:String):Int {
		switch (val.value) {
			case JString(s):
				var str = StringTools.replace(s, _prefix, "");
				return Std.parseInt(str);
			default:
				throw 'Unexpected value for $name';
		}
	}

	public static function CustomParseString(val:hxjsonast.Json, name:String):String {
		switch (val.value) {
			case JNumber(s):
				return s;
			default:
				throw 'Unexpected value for $name';
		}
	}
}

@:jcustomparse(tests.CustomTest.WrappedDynamic.CustomParse)
@:jcustomwrite(tests.CustomTest.WrappedDynamic.CustomWrite)
class WrappedDynamic {
	@:jignored
	public var value:Dynamic;

	public function new() {}

	public static function CustomWrite(o:WrappedDynamic):String {
		return '${Json.stringify(o.value)}';
	}

	public static function CustomParse(val:hxjsonast.Json, name:String):WrappedDynamic {
		var str = Printer.print(val);
		var w = new WrappedDynamic();
		w.value = Json.parse(str);
		return w;
	}
}

class NestedTest {
	public var num:CustomNum;
	public var dyn:WrappedDynamic;

	public function new() {}
}

class CustomTest implements utest.ITest {
	public function new() {}

	public function test1() {
		var parser = new JsonParser<CustomNum>();
		var writer = new JsonWriter<CustomNum>();
		var data = parser.fromJson('{"value": "The Number 42", "control":123}');
		Assert.equals(0, parser.errors.length);
		Assert.equals(42, data.value);
		Assert.equals("0", data.opt_value);
		Assert.equals(123, data.control);
		Assert.same(data, parser.fromJson(writer.write(data)));
	}

	public function test2() {
		var parser = new JsonParser<WrappedDynamic>();
		var writer = new JsonWriter<WrappedDynamic>();
		var data = parser.fromJson('{"foo": 1, "bar":"two"}');
		Assert.equals(0, parser.errors.length);
		Assert.equals(1, data.value.foo);
		Assert.equals("two", data.value.bar);
		Assert.same(data, parser.fromJson(writer.write(data)));
	}

	public function test3() {
		var parser = new JsonParser<NestedTest>();
		var writer = new JsonWriter<NestedTest>();
		var data = parser.fromJson('{"dyn":{"foo": 1, "bar":"two"}, "num":{"value": "The Number 42", "control":123}}');
		Assert.equals(0, parser.errors.length);
		Assert.equals(1, data.dyn.value.foo);
		Assert.equals(42, data.num.value);
		Assert.same(data, parser.fromJson(writer.write(data)));
	}

	public function test4() {
		var parser = new JsonParser<CustomNum>();
		var data = parser.fromJson('{"value": 1, "control":123}');
		Assert.equals(2, parser.errors.length);
		Assert.equals(0, data.value);
		Assert.equals("0", data.opt_value);
		Assert.equals(123, data.control);
	}

	public function test5() {
		var parser = new JsonParser<CustomNum>();
		var writer = new JsonWriter<CustomNum>();
		var data = parser.fromJson('{"value": "The Number 62", "opt_value": 71, "control": 12}');
		Assert.equals(0, parser.errors.length);
		Assert.equals(62, data.value);
		Assert.equals("71", data.opt_value);
		Assert.equals(12, data.control);
		Assert.same(data, parser.fromJson(writer.write(data)));
	}

	public function test6() {
		var parser = new JsonParser<CustomNum>();
		var data = parser.fromJson('{"value": "The Number 62", "opt_value": "4564", "control": 12}');
		Assert.equals(1, parser.errors.length);

		switch (parser.errors[0]) {
			case CustomFunctionException(e, _):
				Assert.equals(e, "Unexpected value for opt_value");
			default:
				Assert.isTrue(false);
		}

		Assert.equals(62, data.value);
		Assert.equals("0", data.opt_value);
		Assert.equals(12, data.control);
	}
}
