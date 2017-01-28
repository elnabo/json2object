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

class Data<T:String, K> {
	public var map:Map<String, Map<String, Array<Bool>>>;
	public var mapSimple:Map<String, K>;
	@:jignored
	public var toBeIgnored:Class<Ignored>;
	public var version:T;
	public var items:Inventory<Item>;
	public var items2:Array<TDArray0<TDString>>;
	public var test:Inventory<String>;
	public var item:Item;
	public var u:Int;
	public var v:Float;
	public var oolean:Bool;
	public var missing:Bool;
	public var c1:Cl<T>;
	public var c2:Cl<K>;
	public var m:Map<Int, String>;
	public var a:Array<Int>;
	@:optional
	public var optional:Int;
	public var never(default, never):Int;
	public var nullSet(default, null):Int;
	@:require(flag, "'-D flag' is required for variable require")
	public var require:Int;

	public function new() {
	}
}
