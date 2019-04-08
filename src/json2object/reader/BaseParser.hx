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

package json2object.reader;

import json2object.Error;
import json2object.Error.ErrorType;
import json2object.Position;
import json2object.PositionUtils;

class BaseParser<T> {

	public var value : T;

	@:deprecated("json2object: Field 'object' is replaced by 'value'")
	public var object(get,never) : T;

	public var errors:Array<Error>;
	@:deprecated("json2object: Field 'warnings' is replaced by 'errors'")
	public var warnings(get,never):Array<Error>;
	@:deprecated("json2object: Field 'warnings' is replaced by 'errors'")
	private inline function get_warnings():Array<Error> { return errors; }

	@:deprecated("json2object: Field 'object' is replaced by 'value'")
	private inline function get_object() { return value; }

	private var errorType:Error.ErrorType;

	private var putils:PositionUtils;

	private function new(errors:Array<Error>, putils:PositionUtils, errorType:ErrorType) {
		this.errors = errors;
		this.putils = putils;
		this.errorType = errorType;
	}


	public function fromJson(jsonString:String, ?filename:String='') : T {
		putils = new PositionUtils(jsonString);
		errors = [];
		try {
			var json = hxjsonast.Parser.parse(jsonString, filename);
			loadJson(json);
		}
		catch (e:hxjsonast.Error) {
			errors.push(ParserError(e.message, putils.convertPosition(e.pos)));
		}
		return value;
	}

	public function loadJson(json:hxjsonast.Json, ?variable:String="") : T {
		var pos = putils.convertPosition(json.pos);
		switch (json.value) {
			case JNull : loadJsonNull(pos, variable);
			case JString(s) : loadJsonString(s, pos, variable);
			case JNumber(n) : loadJsonNumber(n, pos, variable);
			case JBool(b) : loadJsonBool(b, pos, variable);
			case JArray(a) : loadJsonArray(a, pos, variable);
			case JObject(o) : loadJsonObject(o, pos, variable);
		}
		return value;
	}

	private function loadJsonNull(pos:Position, variable:String) {
		onIncorrectType(pos, variable);
	}
	private function loadJsonString(s:String, pos:Position, variable:String) {
		onIncorrectType(pos, variable);
	}
	private function loadJsonNumber(f:String, pos:Position, variable:String) {
		onIncorrectType(pos, variable);
	}
	private function loadJsonBool(b:Bool, pos:Position, variable:String) {
		onIncorrectType(pos, variable);
	}
	private function loadJsonArray(a:Array<hxjsonast.Json>, pos:Position, variable:String) {
		onIncorrectType(pos, variable);
	}
	private function loadJsonObject(o:Array<hxjsonast.Json.JObjectField>, pos:Position, variable:String) {
		onIncorrectType(pos, variable);
	}

	private function onIncorrectType(pos:Position, variable:String) {}
}