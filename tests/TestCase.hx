/*
Copyright (c) 2017 Guillaume Desquesnes, Valentin Lemière

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
import json2object.Error;

typedef Oracle = {
	map:Map<String, Map<String, Array<Bool>>>,
	mapSimple:Map<String, Bool>,
	version:Null<String>,
	items:Array<Dynamic>,
	items2:Array<TDArray0<TDString>>,
	test:Array<String>,
	item:Dynamic,
	u:Int,
	v:Float,
	oolean:Bool,
	missing:Bool,
	c1:Cl<String>,
	c2:Cl<Bool>,
	m:Map<Int, String>
}

class TestCase extends haxe.unit.TestCase {
	public function testParsing1() {
		var json = '{ "version": "0.0.1",
		"map":{"0":{"k":[true], "0":[false]},"ho":{}},
		"mapSimple":{"0":true,"ho":false},
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
		"hey":"hu?",
		"c1":{"c":"a"},
		"c2":{"c":false},
		"m":{"0":"0", "a":"tutu"},
		"a":[1,2,3,"t", null]}';

		var parser = new JsonParser<Data<String, Bool>>();
		var data = parser.fromJson(json, "data.json");
		var warnings = parser.warnings;

		var c1 = new Cl<String>();
		c1.c = "a";
		var c2 = new Cl<Bool>();
		c2.c = false;

		var oracle:Oracle = {
			map:["0"=>["k"=>[true], "0"=>[false]],"ho"=>new Map<String,Array<Bool>>()],
			mapSimple:["0"=>true,"ho"=>false],
			version:"0.0.1",
			test:["U","b"],
			item:{name:"item1",type:null},
			items: [
				{name:"item2",type:null},
				{name:"b",type:"y"}
				],
			u:5,
			v:5.5,
			items2: [['b'],["1","3"]],
			#if (cpp || cppia || flash || cs || java || hl) // static platforms
			oolean: false,
			missing: false,
			#else
			oolean: null,
			missing:null,
			#end
			c1:c1,
			m:[0=>"test", 5=>"tutu"],
			c2:c2
		}
		assertEquals(warnings.length, 12);
		checkOracle(data, oracle);
	}

	public function testParsing2() {
		var json = '{ "version": "0.0.1",
		"map":{"0":{"k":[true], "0":[false]},"ho":{}},
		"mapSimple":{"0":true,"ho":false},
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
		"missing":false,
		"c1":{"c":"a"},
		"c2":{"c":false},
		"m":{"0":"0", "5":"tutu"},
		"a":[1,2,3]
		};';

		var warnings = [];
		var data = new JsonParser<Data<String, Bool>>(warnings).fromJson(json, "data.json");
		new JsonParser<Map<Int, Bool>>().fromJson('{"0.5":false, "55":true}', "temp.json");

		assertEquals(warnings.length, 0);
		var c1 = new Cl<String>();
		c1.c = "a";
		var c2 = new Cl<Bool>();
		c2.c = false;

		var oracle:Oracle = {
			map:["0"=>["k"=>[true], "0"=>[false]],"ho"=>new Map<String,Array<Bool>>()],
			mapSimple:["0"=>true,"ho"=>false],
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
			c1:c1,
			m:[0=>"test", 5=>"tutu"],
			c2:c2,
		};
		checkOracle(data,oracle);
	}

	private function checkOracle(data:Data<String, Bool>, oracle:Oracle) {
		assertEquals(data.version, oracle.version);
		assertEquals(Lambda.count(data.map), Lambda.count(oracle.map));
		assertEquals(Lambda.count(data.mapSimple), Lambda.count(oracle.mapSimple));
		var d = data.mapSimple.keys();
		var o = oracle.mapSimple.keys();

		for (i in 0...Lambda.count(oracle.mapSimple)) {
			var dk = d.next();
			var ok = o.next();
			assertEquals(dk, ok);
			assertEquals(data.mapSimple.get(dk), oracle.mapSimple.get(ok));
		}
		assertEquals(data.test.length, oracle.test.length);
		for (i in 0...data.test.length) {
			assertEquals(data.test[i],oracle.test[i]);
		}

		assertEquals(data.item.name, oracle.item.name);
		assertEquals(data.item.type, oracle.item.type);

		assertEquals(data.items.length, oracle.items.length);
		for (i in 0...data.items.length) {
			assertEquals(data.items[i].name, oracle.items[i].name);
			assertEquals(data.items[i].type, oracle.items[i].type);
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
		assertEquals(data.c1.c, oracle.c1.c);
		assertEquals(data.c2.c, oracle.c2.c);
	}
}
