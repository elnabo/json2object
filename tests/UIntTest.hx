package tests;

import json2object.JsonParser;
import json2object.JsonWriter;
import utest.Assert;

class UIntTest implements utest.ITest {
	public function new () {}

	public function test1 () {
		var parser = new JsonParser<UInt>();
		var writer = new JsonWriter<UInt>();
		var data = parser.fromJson('2147483648');
		Assert.equals(0, parser.errors.length);
		Assert.same(data, parser.fromJson(writer.write(data)));
	}

	public function test2 () {
		var parser = new JsonParser<UInt>();
		var data = parser.fromJson('2147483648.54');
		var orcale:UInt = 0;
		Assert.equals(1, parser.errors.length);
		Assert.same(orcale, data);
	}
}