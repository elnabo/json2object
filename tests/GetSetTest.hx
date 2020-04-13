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

import json2object.Error;
import json2object.JsonParser;
import json2object.JsonWriter;
import utest.Assert;

class GetSetTest implements utest.ITest {

	var h : Int = 1;
	public var i(get,set) : Int;
	function get_i () : Int {
		return h * 2;
	}
	function set_i (v:Int) : Int {
		return h = v;
	}

	@:isVar var j (get, set) : Float;
	function get_j () : Float {
		return j * 50;
	}
	function set_j (j:Float) : Float {
		return this.j = j;
	}

	var k (get, set) : Int;
	function get_k () : Int {
		return Std.int(j);
	}
	function set_k (v:Int) : Int {
		j = v;
		return v;
	}

	var l (default, default) : Int = 1;
	var m (default, never) : Int = 2;
	var n (default, null) : Int = 3;
	var o (default, set) : Int;
	function set_o (v:Int) {
		return this.o = v * 2;
	}

	var q (null, default) : Int = 5;
	var s (null, null) : Int = 7;
	var t (get, null) : Int = 8;
	function get_t () :Int { return 1; }

	var u (null, never) : Int;
	var v (null, set) : Int;
	function set_v (v:Int) : Int {
		return this.v = v;
	}

	public function new () {}

	public function test1 () {
		var gst = new GetSetTest();
		gst.j = Math.PI;
		gst.o = 2;
		Reflect.setField(gst, "u", 2);
		gst.v = 9;

		var json = '{"h":1,"j":3.14159265358979,"l":1,"m":2,"n":3,"o":4,"q":5,"s":7,"t":8,"u":2,"v":9}';

		var parser = new JsonParser<GetSetTest>();
		var writer = new JsonWriter<GetSetTest>();
		var data = parser.fromJson(json, "test");
		Assert.same(gst, data);
		Assert.equals(0, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}

	public function test2 () {
		var gst = new GetSetTest();
		gst.k = 4;
		gst.l = 3;
		Reflect.setField(gst, "m", 4);
		gst.n = 5;
		gst.o = 2;
		Reflect.setField(gst, "u", 23);
		gst.v = 9;

		var json = '{"j":4.0, "h":1, "k":3, "l":3, "m":4, "n":5, "o":4, "q":5, "s":7, "t":8, "u":23, "v":9}';

		var parser = new JsonParser<GetSetTest>();
		var writer = new JsonWriter<GetSetTest>();
		var data = parser.fromJson(json, "test");
		Assert.same(gst, data);
		Assert.same(UnknownVariable("k", {file:"test", lines:[{number:1, start:18, end:21}], min:18, max:21}), parser.errors[0]);
		Assert.equals(1, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data), "test"));
	}
}
