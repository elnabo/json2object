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

import json2object.JsonParser;
import json2object.JsonWriter;
import json2object.utils.JsonSchemaWriter;
import utest.Assert;

class ArrayTest implements utest.ITest {
	public function new () {}

	public function test1 () {
		var parser = new JsonParser<Array<Int>>();
		var writer = new JsonWriter<Array<Int>>();
		var data = parser.fromJson('[0,1,4,3]', "");
		var oracle = [0,1,4,3];
		for (i in 0...data.length) {
			Assert.equals(oracle[i], data[i]);
		}
		Assert.equals(0, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data),"test"));

		data = parser.fromJson('[0,1,4.4,3]', "");
		Assert.equals(1, parser.errors.length);
		oracle = [0,1,3];
		for (i in 0...data.length) {
			Assert.equals(oracle[i], data[i]);
		}
		Assert.same(data, parser.fromJson(writer.write(data),"test"));
	}

	#if !lua
	public function test2 () {
		var schema = new JsonSchemaWriter<Array<Int>>().schema;
		var oracle = '{"$$schema": "http://json-schema.org/draft-07/schema#","items": {"type": "integer"},"type": "array"}';
		Assert.isTrue(JsonComparator.areSame(oracle, schema));
	}
	#end
}
