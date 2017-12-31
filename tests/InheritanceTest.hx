package tests;

import json2object.JsonParser;
import utest.Assert;

class Parent
{
	public var a : Int;
}

class Child extends Parent
{
	public var b : String;
}

class OtherChild extends Parent
{
	public var b : Bool;
}

class InheritanceTest
{
	public function new () {}

	public function test1 ()
	{
		var parser = new JsonParser<Parent>();
		var data = parser.fromJson('{"a": 7}', "test.json");
		Assert.equals(0, parser.errors.length);
		Assert.equals(7, data.a);
	}

	public function test2 ()
	{
		var parser = new JsonParser<Child>();
		var data = parser.fromJson('{"a": 7, "b": "hello"}', "test.json");
		Assert.equals(0, parser.errors.length);
		Assert.equals(7, data.a);
		Assert.equals("hello", data.b);
	}

	public function test3 ()
	{
		var parser = new JsonParser<OtherChild>();
		var data = parser.fromJson('{"a": 7, "b": true}', "test.json");
		Assert.equals(0, parser.errors.length);
		Assert.isTrue(data.b);
	}

	public function test4 ()
	{
		var parser = new JsonParser<Child>();
		var data = parser.fromJson('{"a": 7, "b": true}', "test.json");
		Assert.equals(2, parser.errors.length);
	}

	public function test5 ()
	{
		var parser = new JsonParser<OtherChild>();
		var data = parser.fromJson('{"a": 7, "b": "hello"}', "test.json");
		Assert.equals(2, parser.errors.length);
	}
}
