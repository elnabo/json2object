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

using StringTools;
using haxe.macro.ComplexTypeTools;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;

typedef JsonType = {jtype:String, name:String, params:Array<Type>}
typedef ParserInfo = {packs:Array<String>, clsName:String}

class DataBuilder {

	private static function getParserName(parsed:Type, ?level=1) {
		var res = "";
		switch (parsed) {
			case TInst(t, params):
				res += "_".lpad("_", level) + t.get().name;
				for (p in params) {
					res += getParserName(p.follow(), level+1);
				}
			case TAbstract(t, params):
				res += "_".lpad("_", level) + t.get().name;
				for (p in params) {
					res += getParserName(p.follow(), level+1);
				}
			default: return res;
		}
		return res;
	}

	private static function useParams(type:Type, paramsDef:Array<TypeParameter>, paramsValue:Array<Type>) {
		for (i in 0...paramsDef.length) {
			if (type.unify(paramsDef[i].t)) {
				return paramsValue[i];
			}
		}
		return type;
	}

	private static function applyParams(type:Type, paramsDef:Array<TypeParameter>, paramsValue:Array<Type>) {
		var appliedType = useParams(type, paramsDef, paramsValue);
		var paramsType = switch (type) {
			case TInst(_, p), TAbstract(_,p), TEnum(_,p), TType(_,p):
				p.map(function(p:Type) { return useParams(p, paramsDef, paramsValue);});
			default:
				return type;
		}
		return switch(appliedType) {
			case TInst(t,_): return TInst(t, paramsType);
			case TAbstract(t,_): return TAbstract(t, paramsType);
			case TEnum(t,_): return TEnum(t, paramsType);
			case TType(t,_): return TType(t, paramsType);
			default: return type;
		}
	}

	private static function typeToHxjsonAst(type:Type) {
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
					default: throw "json2object: Bool/Int/Float/Map are the only abstracts supported, got "+t.get().name;//typeToHxjsonAst(type.followWithAbstracts());
				}
			case TType(t,_):
				typeToHxjsonAst(type.follow());
			default: null;
		}
	}

	private static function parseType(type:Type, info:JsonType, level=0, parser:ParserInfo): Expr {
		var caseVar = "s" + level;
		var cls = { name:parser.clsName, pack:parser.packs, params:[TPType(type.toComplexType())]};
		return switch (info.jtype) {
			case "JString", "JBool": macro $i{caseVar};
			case "JNumber": switch (info.name) {
				case "Int": macro Std.parseInt($i{caseVar});
				case "Float": macro Std.parseFloat($i{caseVar});
				default : Context.fatalError("json2object: Unsupported number format: " + info.name, Context.currentPos());
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
					//~ macro storeWarnings(new $cls(putils).loadJson($i{caseVar}));
					macro new $cls(warnings, putils).loadJson($i{caseVar});
				}
			default: Context.fatalError("json2object: Unsupported element: " + info.name, Context.currentPos());

		}
	}

	private static function handleArray(type:Type, level=1, parser:ParserInfo) : Expr {
		var forVar = "s" + (level-1);
		var caseVar = "s" + level;
		var content = "content"+level;

		var info = typeToHxjsonAst(type);

		var nullCase = (info.name == "Float" || info.name == "Int" || info.name == "Bool")
			? macro {
				warnings.push(IncorrectType(field.name, $v{info.name}, putils.convertPosition($i{content}.pos)));
				continue;
			}
			: macro null;

		var e = parseType(type, info, level, parser);
		return macro [for ($i{content} in $i{forVar})  {
				switch ($i{content}.value) {
					case $i{info.jtype}($i{caseVar}):
						${parseType(type, info, level, parser)};
					case JNull:
						${nullCase};
					default:
						warnings.push(IncorrectType(field.name, $v{info.name}, putils.convertPosition($i{content}.pos)));
						continue;
				}
			}];
	}

	private static function handleMap(key:Type, value:Type, level=1, parser:ParserInfo) : Expr {
		var forVar = "s" + (level-1);
		var caseVar = "s" + level;
		var content = "content"+level;
		var n = "n"+level;

		var fieldVar = "field" + level;
		var keyVar = "key" + level;
		var valueVar = "value" + level;

		var info = typeToHxjsonAst(value);
		var nullCase = (info.name == "Float" || info.name == "Int" || info.name == "Bool")
			? macro {
				warnings.push(IncorrectType(field.name, $v{info.name}, putils.convertPosition($i{fieldVar}.value.pos)));
				continue;
			}
			: macro null;

		var keyExpr = switch (typeToHxjsonAst(key.follow()).name) {
			case "String": macro $i{fieldVar}.name;
			case "Int": macro {
				if (Std.parseInt($i{fieldVar}.name) != null)
					Std.parseInt($i{fieldVar}.name);
				else {
					warnings.push(IncorrectType(field.name, "Int", putils.convertPosition($i{fieldVar}.namePos)));
					continue;
				}
			};
			default: Context.fatalError("json2object: Map key can only be String or Int", Context.currentPos());
		}

		var valueExpr = macro {
			switch($i{fieldVar}.value.value){
				case $i{info.jtype}($i{caseVar}):
					${parseType(value, info, level, parser)};
				case JNull:
					${nullCase};
				default:
					warnings.push(IncorrectType(field.name, $v{info.name}, putils.convertPosition($i{fieldVar}.value.pos)));
					continue;
			}
		};

		var packs = ["json2object"];
		var params = [TPType(key.toComplexType()), TPType(value.toComplexType())];
		var pair = { name:"Pair", pack:packs, params:params };
		var map = { name:"Map", pack:[], params:params};
		var filler = { name:"MapTools", pack:packs, params:params};
		return macro new $filler().fromArray(new $map(), [ for ($i{fieldVar} in $i{forVar}) new $pair(${keyExpr}, ${valueExpr})]);

	}

	private static function handleVariable(type:Type, variable:Expr, parser:ParserInfo) {
		var info = typeToHxjsonAst(type);
		var cls = { name:parser.clsName, pack:parser.packs, params:[TPType(type.toComplexType())]};
		var clsname = info.name;

		var nullCase = (info.name == "Float" || info.name == "Int" || info.name == "Bool")
			? macro {
				warnings.push(IncorrectType(field.name, $v{clsname}, putils.convertPosition(field.value.pos)));
			}
			: macro ${variable} = null;

		var expr = parseType(type, info, parser);
		return macro {
			switch(field.value.value){
				case $i{info.jtype}(s0):
					${variable} = ${expr};
				case JNull:
					${nullCase};
				default:
					warnings.push(IncorrectType(field.name, $v{clsname}, putils.convertPosition(field.value.pos)));
			}
		};
	}

	private static function makeParser(c:ClassType, parsedType:Type) {
		var parsedName:String = null;
		var classParams:Array<TypeParam>;
		var cases = new Array<Case>();
		var parserName = c.name + getParserName(parsedType);
		var packs:Array<String> = [];
		var parserInfo:ParserInfo = {clsName:c.name, packs:c.pack};

		var loop:Expr;

		switch (parsedType) {
			case TInst(t, params):
				parsedName = t.get().name;
				packs = t.get().pack;

				try { return haxe.macro.Context.getType(parserName); } catch (_:Dynamic) {}

				classParams = [for (p in params) TPType(p.toComplexType())];
				for (field in t.get().fields.get()) {
					if (!field.isPublic || field.meta.has(":optional")) { continue; }
					if (field.meta.has(":jignore")) {
						Context.warning("json2object: @:jignore has been deprecated, please use @:optional instead", Context.currentPos());
						continue;
					}
					switch(field.kind) {
						case FVar(_,_):
							var fieldType = applyParams(field.type, t.get().params, params);

							var f_a = { expr: EField(macro object, field.name), pos: Context.currentPos() };
							var lil_switch = handleVariable(fieldType, f_a, parserInfo);
							cases.push({ expr: lil_switch, guard: null, values: [{ expr: EConst(CString(${field.name})), pos: Context.currentPos()}] });
						default: // Ignore
					}
				}

				var default_e = macro warnings.push(UnknownVariable(field.name, putils.convertPosition(field.value.pos)));
				loop = { expr: ESwitch(macro field.name, cases, default_e), pos: Context.currentPos() };

			case TType(t, params):
				return makeParser(c, parsedType.follow());
			case TAbstract(t, params):
				if (t.get().name != "Map" && t.get().name != "IMap") {
					Context.fatalError("json2object: Maps are the only direct abstract type supported got "+t.get().name, Context.currentPos());
				}
				parsedName = "Map";
				classParams = params.map(function(ty:Type) {return TPType(ty.toComplexType());});
				packs = t.get().pack;

				var keyExpr = switch (typeToHxjsonAst(params[0].follow()).name) {
					case "String": macro field.name;
					case "Int": macro {
						if (Std.parseInt(field.name) != null)
							Std.parseInt(field.name);
						else {
							warnings.push(IncorrectType(field.name, "Int", putils.convertPosition(field.namePos)));
							continue;
						}
					};
					default: Context.fatalError("json2object: Map key can only be String or Int", Context.currentPos());
				}

				var value = params[1];
				var info = typeToHxjsonAst(value);
				var nullCase = (info.name == "Float" || info.name == "Int" || info.name == "Bool")
					? macro {
						warnings.push(IncorrectType(field.name, $v{info.name}, putils.convertPosition(field.value.pos)));
						continue;
					}
					: macro null;

				var valueExpr = macro {
					switch(field.value.value){
						case $i{info.jtype}(s0):
							${parseType(value, info, parserInfo)};
						case JNull:
							${nullCase};
						default:
							warnings.push(IncorrectType(field.name, $v{info.name}, putils.convertPosition(field.value.pos)));
							continue;
					}
				};
				loop = macro object.set($keyExpr, $valueExpr);
			default: Context.fatalError("json2object: "+parsedType.toString()+ " can't be parsed", Context.currentPos());
		}


		var cls = { name:parsedName, pack:packs, params:classParams};
		var new_e = macro object = new $cls();

		var obj:Field = {doc:null,
				access:[APublic],
				kind:FVar(parsedType.toComplexType(), null),
				name:"object",
				pos:Context.currentPos(),
				meta:null,
				};

		var loadJsonClass = macro class $parserName {

			public var warnings:Array<json2object.Error>;
			private var putils:json2object.PosUtils;

			public function new(?warnings:Array<json2object.Error>=null,?putils:json2object.PosUtils=null) {
				this.warnings = (warnings == null) ? [] : warnings;
				this.putils = putils;
			}

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
					${loop}
				}
				return object;
			}

			/** Create an instance initialized from a JSON.
			 *
			 * Return `null` if the JSON is invalid.
			 */
			public function fromJson(jsonString:String, filename:String) {
				putils = new json2object.PosUtils(jsonString);
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
					throw json2object.Error.ParserError(e.message, putils.convertPosition(e.pos));
				}
			}
		};

		loadJsonClass.fields.push(obj);
		//~ if (parsedName == "Data")
		//~ for(f in loadJsonClass.fields) { trace(new haxe.macro.Printer().printField(f));}
		haxe.macro.Context.defineType(loadJsonClass);
		return haxe.macro.Context.getType(parserName);
	}

	public static function build() {
		switch (Context.getLocalType()) {
			case TInst(c, [type]):
				return makeParser(c.get(), type);
			case t:
				Context.fatalError("Parsing tools must be a class expected", Context.currentPos());
				return null;
		}
	}
}
