/*
Copyright (c) 2016 Guillaume Desquesnes, Valentin Lemière

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

class TestCase extends haxe.unit.TestCase {
	public function testParsing1() {
		var json = '{ "version": "0.0.1",
		"test":["U","b"],
		"item":{"name":"item1", "type":1},
		"items":[
			{"name":"item2", "type":2},
			{"name":"b", "type":"y"}
		],
		"u":5,
		"v":5.5,
		"items2":[[1,"b"],["1","3"]],
		"oolean":"true",
		"hey":"hu?"}';

		var data = Data.fromJson(json, "data.json");

		var oracle = {
			version:"0.0.1",
			test:["U","b"],
			item:{name:"item1",type:null, warnings:[IncorrectType("type","String",null)]},
			items: [
				{name:"item2",type:null,warnings:[IncorrectType("type","String",null)]},
				{name:"b",type:"y",warnings:[]}
				],
			u:5,
			v:5.5,
			items2: [['b'],["1","3"]],
			oolean: null,
			missing:null,
			warnings:[IncorrectType("type","String",null), IncorrectType("type", "String", null), IncorrectType("items2", "String", null), IncorrectType("oolean", "Bool", null), UnknownVariable("hey", null),UninitializedVariable("missing", null)]
		}
		checkOracle(data, oracle);
	}

	public function testParsing2() {
		var json = '{ "version": "0.0.1",
		"test":["U","b"],
		"item":{"name":"item1", "type":"1"},
		"items":[
			{"name":"item2", "type":"2"},
			{"name":"b", "type":"y"}
		],
		"u":5,
		"v":5.5,
		"items2":[["1","b"],["1","3"]],
		"oolean":true,
		"missing":false}';

		var data = Data.fromJson(json, "data.json");

		var oracle = {
			version:"0.0.1",
			test:["U","b"],
			item:{name:"item1",type:"1",warnings:[]},
			items:[
				{name:"item2",type:"2",warnings:[]},
				{name:"b",type:"y",warnings:[]}
				],
			u:5,
			v:5.5,
			items2:[["1",'b'],["1","3"]],
			oolean:true,
			missing:false,
			warnings:[]
		};
		checkOracle(data,oracle);
	}

	private function checkOracle(data:Data, oracle:Dynamic) {
		assertEquals(data.version, oracle.version);
		assertEquals(data.test.length, oracle.test.length);
		for (i in 0...data.test.length) {
			assertEquals(data.test[i],oracle.test[i]);
		}

		assertEquals(data.item.name, oracle.item.name);
		assertEquals(data.item.type, oracle.item.type);
		assertEquals(data.item.warnings.length, oracle.item.warnings.length);

		assertEquals(data.items.length, oracle.items.length);
		for (i in 0...data.items.length) {
			assertEquals(data.items[i].name, oracle.items[i].name);
			assertEquals(data.items[i].type, oracle.items[i].type);
			assertEquals(data.items[i].warnings.length, oracle.items[i].warnings.length);
		}
		assertEquals(data.u, oracle.u);
		assertEquals(data.v, oracle.v);

		assertEquals(data.items2.length, oracle.items2.length);
		for (i in 0...data.items2.length) {
			assertEquals(data.items2[i].length, oracle.items2[i].length);
			for (j in 0...data.items2[i].length) {
				assertEquals(data.items2[i][j], oracle.items2[i][j]);
			}
		}
		assertEquals(data.oolean, oracle.oolean);
		assertEquals(data.missing, oracle.missing);

		assertEquals(data.warnings.length, oracle.warnings.length);
	}
}


@:build(json2object.DataBuild.loadJson())
class Data {
	//~ public var version:String;
	public var version:AbsString;
	public var items:Inventory;
	public var items2:Array<TDArray0<TDString>>;
	public var test:Array<String>;
	public var item:TDItem;
	public var u:AbsInt;
	//~ public var u:Int;
	public var v:Float;
	public var oolean:Bool;
	public var missing:Bool;

	public function new() {
	}
}

typedef TDItem = Item;
typedef TDString = AbsString;
typedef TDArray0<T> = Array<T>;
typedef TDArray1 = Array<String>;
typedef TDArray2 = Array<TDArray1>;

@:build(json2object.DataBuild.loadJson())
class Item {
	public var name:String;
	public var type:String;

	public function new() {
	}
}

@:forward
abstract Inventory(Array<Item>) from Array<Item> {

	@:arrayAccess function get(i:Int):Item {
		return this[i];
	}
	@:arrayAccess function arrayWrite(i:Int, item:Item):Item {
		this[i] = item;
		return item;
	}
}

abstract AbsString(String) from String{
}

abstract AbsInt(Int) from Int{
}
