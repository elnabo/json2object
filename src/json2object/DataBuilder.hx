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

package json2object;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

using haxe.macro.ComplexTypeTools;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;

typedef JsonType = {jtype:String, name:String, params:Array<Type>}
typedef ParserInfo = {packs:Array<String>, clsName:String}

class DataBuilder {

	public static function typeToHxjsonAst(type:Type) {
		return switch (type) {
			case TInst(t, p):
				switch (t.get().name) {
					case "String":
						{ jtype: "JString", name: "String", params: [] };
					case "Array":
						{ jtype: "JArray", name: "Array", params: p };
					default:  { jtype: "JObject", name: t.get().name, params: p };
				}
			case TAbstract(t,p):
				switch(t.get().name) {
					case "Bool":
						{ jtype: "JBool", name: "Bool", params: [] };
					case "Int":
						{ jtype: "JNumber", name: "Int", params: [] };
					case "Float":
						{ jtype: "JNumber", name: "Float", params: [] };
					case "Map", "IMap":
						{ jtype: "JObject", name: "Map", params: p };
					default: throw "Only Bool/Int/Float/Map abstracts are supported";//typeToHxjsonAst(type.followWithAbstracts());
				}
			case TType(t,_):
				typeToHxjsonAst(type.follow());
			default: null;
		}
	}

	public static function parseType(type:Type, info:JsonType, level=0, parser:ParserInfo): Expr {
		var caseVar = "s" + level;
		var cls = { name:parser.clsName, pack:parser.packs, params:[TPType(type.toComplexType())]};

		return switch (info.jtype) {
			case "JString", "JBool": macro $i{caseVar};
			case "JNumber": switch (info.name) {
				case "Int": macro Std.parseInt($i{caseVar});
				case "Float": macro Std.parseFloat($i{caseVar});
				default : Context.fatalError("Unsupported number format: " + info.name, Context.currentPos());
			}
			case "JArray": handleArray(info.params[0].followWithAbstracts(), level+1, parser);
			case "JObject":
				if (info.name == "IMap" || info.name == "Map") {
					handleMap(
						info.params[0],
						info.params[1],
						level+1,
						parser
					);
				}
				else {
					macro new $cls().loadJson($i{caseVar});
				}
			default: Context.fatalError("Unsupported element: " + info.name, Context.currentPos());

		}
	}

	public static function handleArray(type:Type, level=1, parser:ParserInfo) : Expr {
		var forVar = "s" + (level-1);
		var caseVar = "s" + level;
		var content = "content"+level;
		var n = "n"+level;

		var info = typeToHxjsonAst(type);

		var e = parseType(type, info, level, parser);
		var errorMsg = "Expected " + info.name +" got: ";

		return macro [for ($i{content} in $i{forVar})  {
				switch ($i{content}.value) {
					case $i{info.jtype}($i{caseVar}): $e;
					default: throw $v{errorMsg} + $i{content}.value;
				}
			}];
	}

	public static function handleMap(key:Type, value:Type, level=1, parser:ParserInfo) : Expr {
		var forVar = "s" + (level-1);
		var caseVar = "s" + level;
		var content = "content"+level;
		var n = "n"+level;

		var fieldVar = "field" + level;
		var keyVar = "key" + level;
		var valueVar = "value" + level;

		var info = typeToHxjsonAst(value);
		var errorMsg = "Expected " + info.name +" got: ";

		var keyExpr = macro $i{fieldVar}.name;
		var valueExpr = macro {
			switch($i{fieldVar}.value.value){
				case $i{info.jtype}($i{caseVar}):
					${parseType(value, info, level, parser)};
				default:
					throw $v{errorMsg} + $i{fieldVar}.value.value;
			}
		};

		var packs = ["json2object"];
		var params = [TPType(key.toComplexType()), TPType(value.toComplexType())];
		trace(params);
		var pair = { name:"Pair", pack:packs, params:params };
		var map = { name:"Map", pack:[], params:params};
		var filler = { name:"MapTools", pack:packs, params:params};
		return macro new $filler().fromArray(new $map(), [ for ($i{fieldVar} in $i{forVar}) new $pair(${keyExpr}, ${valueExpr})]);

	}

	public static function handleVariable(type:Type, variable:Expr, parser:ParserInfo) {
		var info = typeToHxjsonAst(type);
		var cls = { name:parser.clsName, pack:parser.packs, params:[TPType(type.toComplexType())]};

		var clsname = info.name;
		var expr = parseType(type, info, parser);
		return macro {
			switch(field.value.value){
				case $i{info.jtype}(s0):
					${variable} = ${expr};
				default:
					trace("Expected " +$v{clsname} + " got: " +field.value.value);
			}
		};
	}

	public static function makeParser(c:ClassType, parsedType:Type) {
		var parsedName:String = null;
		var classParams:Array<TypeParam>;
		var cases = new Array<Case>();
		var parserName = c.name + "__";
		var packs:Array<String> = [];

		switch (parsedType) {
			case TInst(t, params):
				parsedName = t.get().name;
				parserName += parsedName;
				packs = t.get().pack;

				try { return haxe.macro.Context.getType(parserName); } catch (_:Dynamic) {}

				classParams = [for (p in params) TPType(p.toComplexType())];
				for (field in t.get().fields.get()) {
					if (!field.isPublic) { continue; }
					switch(field.kind) {
						case FVar(_,_):
							var f_a = { expr: EField(macro obj, field.name), pos: Context.currentPos() };
							var lil_switch = handleVariable(field.type, f_a, {clsName:c.name, packs:c.pack});
							cases.push({ expr: lil_switch, guard: null, values: [{ expr: EConst(CString(${field.name})), pos: Context.currentPos()}] });
						default:  // Ignore
					}
				}
			case TType(t, params):
				return makeParser(c, parsedType.followWithAbstracts());
			case TAbstract(t, params):
				return makeParser(c, parsedType.followWithAbstracts());
			default: trace("Not instance");
		}


		var default_e = macro trace("Error", field.name);
		var switch_e = { expr: ESwitch(macro field.name, cases, default_e), pos: Context.currentPos() };

		var cls = { name:parsedName, pack:packs, params:classParams};
		var new_e = macro var obj = new $cls();


		var loadJsonClass = macro class $parserName {

			public function new() {}

			/**
			 * Create an instance initialized from a hxjsonast.
			 *
			 * @param fields JSON fields.
			 * @param objectPos Position of the current json object in the main file.
			 * @param posUtils Tools for converting hxjsonast.Position into Position.
			 * @param parentWarnings List of warnings for the parent class.
			 */
			public function loadJson(fields:Array<hxjsonast.Json.JObjectField>) {
				${new_e};
				// Assign every JSON fields.
				for (field in fields) {
					${switch_e}
				}
				return obj;
			}

			/** Create an instance initialized from a JSON.
			 *
			 * Return `null` if the JSON is invalid.
			 */
			public function fromJson(jsonString:String, filename:String) {
				//~ var putils = new json2object.PosUtils(jsonString);
				try {
					var json = hxjsonast.Parser.parse(jsonString, filename);
					switch (json.value) {
						case hxjsonast.Json.JsonValue.JObject(fields):
							return loadJson(fields);
						default:
							return null;
					}
				}
				catch (e:hxjsonast.Error) {
					throw e;
				}
			}
		};

		//~ if (parsedName == "Data")
		//~ for(f in loadJsonClass.fields) { trace(new haxe.macro.Printer().printField(f));}
		haxe.macro.Context.defineType(loadJsonClass);
		return haxe.macro.Context.getType(parserName);
	}

	public static function build() {
		var classType:Type;
		var className:String = null;
		var classParams:Array<TypeParam>;
		var cases = new Array<Case>();

		var clsName:String;
		switch (Context.getLocalType()) {
			case TInst(c, [type]):
				return makeParser(c.get(), type);
			case t:
				Context.error("Class expected", Context.currentPos());
				return null;
		}
	}
}
