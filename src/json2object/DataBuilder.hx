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

#if !macro
class DataBuilder {}
#else
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

using StringTools;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;

typedef JsonType = {jtype:String, name:String, params:Array<Type>}
typedef ParserInfo = {packs:Array<String>, clsName:String}

class DataBuilder {

	private static var counter = 0;
	private static var parsers = new Map<String, Type>();

	private static function notNull(type:Type):Type {
		return switch (type) {
			case TType(_.get()=>t, p):
				(t.name == "Null") ? notNull(type.follow()) : type;
			default:
				type;
		}
	}

	private static function isNullable(type:Type) {
		if (notNull(type) != type) { return true; }
		return switch (type.followWithAbstracts()) {
			case TAbstract(_.get()=>t,_):
				!t.meta.has(":notNull");
			default:
				true;
		}
	}

	private static function getParserName(parsed:Type, ?level=1) {
		var res = "";

		switch (parsed) {
			case TInst(t, params):
				res += "_".lpad("_", level) + "Inst_" + t.get().name;
				for (p in params) {
					res += getParserName(p.follow(), level+1);
				}

			case TAbstract(t, params):
				res += "_".lpad("_", level) + "Abstract_" + t.get().name;
				for (p in params) {
					res += getParserName(p.follow(), level+1);
				}

			case TAnonymous(_.get() => a):
				res += "_".lpad("_", level) + "Ano_";
				for (f in a.fields) {
					var name = f.name;

					for (m in f.meta.get())
					{
						if (m.name == ":alias" && m.params.length == 1)
						{
							switch (m.params[0].expr)
							{
								case EConst(CString(s)):
									name = s;

								default:
							}
						}
					}

					res += name + "_" + getParserName(f.type, level+1);
				}

			default:
		}

		return res;
	}

	private static function changeExprOf(field:Field, e:Expr) {
		switch (field.kind) {
			case FFun(f):
				f.expr = e;
			default: return;
		}
	}

	private static function changeFunction(name:String, of:TypeDefinition, to:Expr) {
		for (field in of.fields) {
			if (field.name == name) {
				changeExprOf(field, to);
			}
		}
	}

	public static function makeStringParser(parser:TypeDefinition) {
		changeFunction("loadJsonString", parser, macro {value = s;});
		changeFunction("loadJsonNull", parser, macro {value = null;});
	}

	public static function makeIntParser(parser:TypeDefinition) {
		var e = macro {
			if (Std.parseInt(f) != null && Std.parseInt(f) == Std.parseFloat(f)) {
				value = Std.parseInt(f);
			}
			else {
				onIncorrectType(pos, variable);
			}
		};
		changeFunction("loadJsonNumber", parser, e);
	}

	public static function makeFloatParser(parser:TypeDefinition) {
		var e = macro {
			if (Std.parseInt(f) != null) {
				value = cast Std.parseFloat(f);
			}
			else {
				onIncorrectType(pos, variable);
			}
		};
		changeFunction("loadJsonNumber", parser, e);
	}

	public static function makeBoolParser(parser:TypeDefinition) {
		changeFunction("loadJsonBool", parser, macro { value = b; });
	}

	public static function makeArrayParser(parser:TypeDefinition, subType:Type, baseParser:BaseType) {
		var cls = { name:baseParser.name, pack:baseParser.pack, params:[TPType(subType.toComplexType())]};
		var e = macro {
			value = [
				for (j in a)
					try { new $cls(errors, putils, THROW).loadJson(j); }
					catch (_:String) { continue; }
			];
		}
		changeFunction("loadJsonArray", parser, e);
		changeFunction("loadJsonNull", parser, macro {value = null;});
	}

	public static function makeObjectOrAnonParser(parser:TypeDefinition, type:Type, baseParser:BaseType) {
		var cls = {name:baseParser.name, pack:baseParser.pack, params:[TPType(type.toComplexType())]};


		var initializator:Expr;
		var isAnon = false;
		var fields:Array<ClassField>;

		var tParams:Array<TypeParameter>;
		var params:Array<Type>;

		switch (type) {
			case TAnonymous(_.get()=>t):
				isAnon = true;
				fields = t.fields;
				tParams = [];
				params = [];

			case TInst(_.get()=>t, p):
				fields = t.fields.get();
				tParams = t.params;
				params = p;

				var pack = t.pack;
				var module = null;
				if (t.module != t.pack.join(".") + "." + t.name)
				{
					pack = t.module.split(".");
					module = pack.pop();
				}
				var t_cls = { name: module != null ? module : t.name, pack: pack, params: [for (i in p) TPType(i.toComplexType())], sub: module != null ? t.name : null };
				initializator = macro new $t_cls();

			case _: return;
		}

		// TODO @:default + constructor

		var anonBaseValues:Array<{field:String, expr:Expr}> = [];
		var assigned:Array<Expr> = [];
		var cases:Array<Case> = [];

		for (field in fields) {
			if (!field.isPublic || field.meta.has(":jignored")) { continue; }

			switch(field.kind) {
				case FVar(_,w):
					if (w == AccNever) { continue; }

					assigned.push(macro { assigned.set($v{field.name}, $v{field.meta.has(":optional")});});

					var f_a = { expr: EField(macro value, field.name), pos: Context.currentPos() };
					var f_type = field.type.applyTypeParameters(tParams, params);
					var f_cls = {name:baseParser.name, pack:baseParser.pack, params:[TPType(f_type.toComplexType())]};

					var assignation = macro {
						try {
							$f_a = new $f_cls(errors, putils, THROW).loadJson(field.value, field.name);
							assigned.set($v{field.name}, true);
						} catch (_:Dynamic) {}
					}

					var caseValue = null;
					for (m in field.meta.get()) {
						if (m.name == ":alias" && m.params.length == 1) {
							switch (m.params[0].expr) {
								case EConst(CString(_)):
									caseValue = m.params[0];
								default:
							}
						}
					}

					if (caseValue == null) {
						caseValue = { expr: EConst(CString(${field.name})), pos: Context.currentPos()};
					}

					cases.push({ expr: assignation, guard: null, values: [caseValue] });

					if (isAnon) {

						if (field.meta.has(":default")) {
							var metas = field.meta.extract(":default");
							if (metas.length > 0) {
								var meta = metas[0];
								if (meta.params != null && meta.params.length == 1) {
									if (f_type.followWithAbstracts().unify(Context.typeof(meta.params[0]).followWithAbstracts())) {
										anonBaseValues.push({field:field.name, expr:meta.params[0]});
									}
									else {
										Context.fatalError("json2object: default value for "+field.name+" is of incorrect type", Context.currentPos());
									}
								}
							}
						}
						else {
							anonBaseValues.push({field:field.name, expr:macro new $f_cls([], putils, NONE).loadJson({value:JNull, pos:{file:"",min:0, max:1}})});
						}
					}

				default:
			}
		}

		var default_e = macro errors.push(UnknownVariable(field.name, putils.convertPosition(field.namePos)));
		var loop = { expr: ESwitch(macro field.name, cases, default_e), pos: Context.currentPos() };

		if (isAnon) {
			initializator = { expr: EObjectDecl(anonBaseValues), pos: Context.currentPos() };
		}


		var e = macro {
			var assigned = new Map<String,Bool>();
			$b{assigned}
			@:privateAccess {
				value = $initializator;
				for (field in o) {
					$loop;
				}
			}

			var lastPos = putils.convertPosition(new hxjsonast.Position(pos.file, pos.max-1, pos.max-1));
			for (s in assigned.keys()) {
				if (!assigned[s]) {
					errors.push(UninitializedVariable(s, lastPos));
				}
			}
		};

		changeFunction("loadJsonObjectOrAnon", parser, e);
		changeFunction("loadJsonNull", parser, macro {value = null;});
	}

	public static function makeMapParser(parser:TypeDefinition, key:Type, value:Type, baseParser:BaseType) {

		var keyMacro = switch (key.followWithAbstracts()) {
			case TInst(_.get()=>t, _):
				if (t.module == "String") {
					macro field.name;
				}
				else {
					Context.fatalError("json2object: Only map with Int or String key are parsable, got"+key.toString(), Context.currentPos());
				}
			case TAbstract(_.get()=>t, _):
				if (t.module == "StdTypes" && t.name == "Int") {
					macro {
						if (Std.parseInt(field.name) != null && Std.parseFloat(field.name) == Std.parseInt(field.name)) {
							Std.parseInt(field.name);
						}
						else{
							try {
								onIncorrectType(putils.convertPosition(field.namePos), field.name);
							}
							catch (_:Dynamic) {}
							continue;
						}
					}
				}
				else {
					Context.fatalError("json2object: Only map with Int or String key are parsable, got"+key.toString(), Context.currentPos());
				}
			default: Context.fatalError("json2object: Only map with Int or String key are parsable, got"+key.toString(), Context.currentPos());
		}

		var v_cls = {name:baseParser.name, pack:baseParser.pack, params:[TPType(value.toComplexType())]};
		var valueMacro = macro {
			try {
				new $v_cls(errors, putils, THROW).loadJson(field.value, field.name);
			}
			catch (_:Dynamic) {
				continue;
			}
		};

		var cls = {name:"Map", pack:[], params:[TPType(key.toComplexType()), TPType(value.toComplexType())]};

		var e = macro {
			value = cast new $cls();
			for (field in o) {
				//~ trace(field.name+ " uio" + new $v_cls([], putils, NONE).loadJson(field.value, field.name));
				value.set($keyMacro, $valueMacro);
			}
		}

		changeFunction("loadJsonObjectOrAnon", parser, e);
		changeFunction("loadJsonNull", parser, macro {value = null;});
	}

	public static function makeParser(c:BaseType, type:Type) {

		if (parsers.exists(type.toString())) {
			return parsers.get(type.toString());
		}

		var name = getParserName(type);
		var parser = macro class $name {
			public var errors:Array<json2object.Error>;
			@:deprecated
			public var warnings(get,never):Array<json2object.Error>;
			private inline function get_warnings():Array<json2object.Error> { return errors; }

			private inline function get_object() { return value; }

			private var errorType:json2object.ErrorType;

			private var putils:json2object.PosUtils;

			public function new(?errors:Array<json2object.Error>=null, ?putils:json2object.PosUtils=null, ?errorType:json2object.ErrorType=null) {
				this.errors = (errors == null) ? [] : errors;
				this.putils = putils;
				this.errorType = (errorType == null) ? NONE : errorType;
			}

			public function fromJson(jsonString:String, filename:String) {
				putils = new json2object.PosUtils(jsonString);
				try {
					var json = hxjsonast.Parser.parse(jsonString, filename);
					loadJson(json);
					return value;
				}
				catch (e:hxjsonast.Error) {
					throw json2object.Error.ParserError(e.message, putils.convertPosition(e.pos));
				}
			}

			public function loadJson(json:hxjsonast.Json, ?variable:String="") {
				var pos = putils.convertPosition(json.pos);
				switch (json.value) {
					case JNull : loadJsonNull(pos, variable);
					case JString(s) : loadJsonString(s, pos, variable);
					case JNumber(n) : loadJsonNumber(n, pos, variable);
					case JBool(b) : loadJsonBool(b, pos, variable);
					case JArray(a) : loadJsonArray(a, pos, variable);
					case JObject(o) : loadJsonObjectOrAnon(o, pos, variable);
				}
				return value;
			}

			private function onIncorrectType(pos:json2object.Position, variable:String) {
				errors.push(IncorrectType(variable, $v{type.toString()}, pos));
				switch (errorType) {
					case THROW : throw "parsing failed";
					case _:
				}
			}

			private function loadJsonNull(pos:json2object.Position, variable:String) {
				onIncorrectType(pos, variable);
			}
			private function loadJsonString(s:String, pos:json2object.Position, variable:String) {
				onIncorrectType(pos, variable);
			}
			private function loadJsonNumber(f:String, pos:json2object.Position, variable:String) {
				onIncorrectType(pos, variable);
			}
			private function loadJsonBool(b:Bool, pos:json2object.Position, variable:String) {
				onIncorrectType(pos, variable);
			}
			private function loadJsonArray(a:Array<hxjsonast.Json>, pos:json2object.Position, variable:String) {
				onIncorrectType(pos, variable);
			}
			private function loadJsonObjectOrAnon(o:Array<hxjsonast.Json.JObjectField>, pos:json2object.Position, variable:String) {
				onIncorrectType(pos, variable);
			}
		};

		var value:Field = {
			doc: null,
			kind: FVar(TypeUtils.toComplexType(type), null),
			access: [APublic],
			name: "value",
			pos: Context.currentPos(),
			meta: null,
		};
		parser.fields.push(value);

		var object:Field = {
			doc: null,
			kind: FProp("get", "never",TypeUtils.toComplexType(type), null),
			access: [APublic],
			name: "object",
			pos: Context.currentPos(),
			meta: [{name:":deprecated", params:null, pos:Context.currentPos()}],
		};
		parser.fields.push(object);

		switch (type) {
			case TInst(_.get()=>t, p) :
				switch(t.module) {
					case "String":
						makeStringParser(parser);
					case "Array":
						if (p.length == 1 && p[0] != null) {
							makeArrayParser(parser, p[0], c);
						}
					case _:
						switch (t.kind) {
							case KTypeParameter(_):
								Context.fatalError("json2object: Type parameters are not parsable: " + t.name, Context.currentPos());

							default:
						}
						makeObjectOrAnonParser(parser, type, c);
				}
			case TAnonymous(_.get()=>t):
				makeObjectOrAnonParser(parser, type, c);
			case TAbstract(_.get()=>t, p):
				if (t.module == "StdTypes") {
					switch (t.name) {
						case "Int" : makeIntParser(parser);
						case "Float", "Single": makeFloatParser(parser);
						case "Bool": makeBoolParser(parser);
						default: Context.fatalError("json2object: Parser of "+t.name+" are not generated", Context.currentPos());
					}
				}
				else if (t.module == "Map" && t.name == "Map") {
					makeMapParser(parser, p[0], p[1], c);
				}
				else {
				}
			case TType(_) : return makeParser(c, type.follow());
			default: Context.fatalError("json2object: Parser of "+type.toString()+" are not generated", Context.currentPos());
		}

		haxe.macro.Context.defineType(parser);

		//~ var p = new haxe.macro.Printer();
		//~ trace(p.printTypeDefinition(parser));

		var constructedType = haxe.macro.Context.getType(name);
		parsers.set(type.toString(), constructedType);
		return constructedType;

	}

	public static function build() {
		switch (Context.getLocalType()) {
			case TInst(c, [type]):
				return makeParser(c.get(), type);
			case _:
				Context.fatalError("Parsing tools must be a class expected", Context.currentPos());
				return null;
		}
	}
}
#end
