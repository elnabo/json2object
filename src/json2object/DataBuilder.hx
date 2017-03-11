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
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;

typedef JsonType = {jtype:String, name:String, params:Array<Type>}
typedef ParserInfo = {packs:Array<String>, clsName:String}

enum WarningType {
	BREAK;
	CONTINUE;
	THROW;
	NONE;
}

class DataBuilder {

	private static function notNull(type:Type):Type {
		return switch (type) {
			case TType(_.get()=>t, p):
				(t.name == "Null") ? notNull(type.follow()) : type;
			default:
				type;
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
					res += f.name + "_" + getParserName(f.type, level+1);
				}

			default:
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
				p.map(function(p:Type) { return applyParams(useParams(p, paramsDef, paramsValue), paramsDef, paramsValue);});
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
			case TAbstract(_.get() => t, p):
				switch(t.name) {
					case "Bool":
						{ jtype: "JBool", name: "Bool", params: [] };
					case "Int":
						{ jtype: "JNumber", name: "Int", params: [] };
					case "Float":
						{ jtype: "JNumber", name: "Float", params: [] };
					case "Map", "IMap":
						{ jtype: "JObject", name: "Map", params: p };
					case "Null":
						typeToHxjsonAst(p[0].follow());
					default:
						typeToHxjsonAst(applyParams(t.type, t.params, p));
				}
			case TType(t,_):
				typeToHxjsonAst(type.follow());
			case TAnonymous(t):
				{jtype:"JObject", name:"Anonymous", params:[]};
			case TEnum(_.get() => t, p):
				{ jtype: "JObject", name: "enum", params: p }
			default: Context.fatalError("json2object: Unsupported type : "+type.toString(), Context.currentPos()); null;
		}
	}

	private static function parseType(type:Type, info:JsonType, level=0, parser:ParserInfo, json:Expr, ?variable:Expr=null, ?warnings:WarningType): Expr {
		var caseVar = "s" + level;
		var cls = { name:parser.clsName, pack:parser.packs, params:[TPType(type.toComplexType())]};

		var cases:Array<Case> = [];

		var expr = switch (info.jtype) {
			case "JString", "JBool": macro $i{caseVar};
			case "JNumber": switch (info.name) {
				case "Int": macro Std.parseInt($i{caseVar});
				case "Float": macro Std.parseFloat($i{caseVar});
				default : Context.fatalError("json2object: Unsupported number format: " + info.name, Context.currentPos());
			}
			case "JArray": handleArray(info.params[0], level+1, parser);
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
					macro new $cls(warnings, putils).loadJson($i{caseVar}, ${json}.pos);
				}
			default: Context.fatalError("json2object: Unsupported element: " + info.name, Context.currentPos());
		}

		var nullValue = macro null;
		if (variable != null) {
			expr = macro {
				${variable} = cast ${expr};
				assigned.set(field.name, true);
			};

			nullValue = macro {
				${variable} = ${nullValue};
				assigned.set(field.name, true);
			};
		}

		var onWarnings = switch (warnings) {
			case BREAK: macro break;
			case CONTINUE: macro continue;
			case THROW: macro throw "json2object: Invalid type";
			default: macro {};
		};

		if (info.jtype == "JNumber"  && info.name == "Int") {
			expr = macro if (Std.parseInt($i{caseVar}) != null && Std.parseInt($i{caseVar}) == Std.parseFloat($i{caseVar})) {
					${expr};
				}
				else {
					warnings.push(IncorrectType(field.name, "Int", putils.convertPosition(${json}.pos)));
					${onWarnings};
				}
			cases.push({ expr: expr, guard: null, values: [macro JNumber($i{caseVar})] });
		}

		else if (info.name == "enum") {
			var objExpr = macro new $cls(warnings, putils).loadJson($i{caseVar}, ${json}.pos);
			var strExpr:Expr = null;

			switch (type) {
				case TEnum(_.get()=>t, p):

					var cases = new Array<Case>();
					for (n in t.names) {
						switch (t.constructs.get(n).type) {
							case TEnum(_,_):

								var l = t.module.split(".");
								l.push(t.name);
								l.push(n);
								var subExpr = {expr:EConst(CIdent(l.shift())), pos:Context.currentPos()};
								while (l.length > 0) {
									subExpr = {expr:EField(subExpr, l.shift()), pos:Context.currentPos()};
								}

								if (variable != null) {
									subExpr = macro {
										${variable} = ${subExpr};
										assigned.set(field.name, true);
									};
								}
								cases.push({expr: subExpr, guard: null, values: [macro $v{n}]});
							default:
						}
					};

					var default_e =macro {
						warnings.push(IncorrectType(field.name, $v{type.toString()}, putils.convertPosition(${json}.pos)));
						${onWarnings}
					};
					strExpr = {expr: ESwitch(macro $i{caseVar}, cases, default_e), pos: Context.currentPos() };
				default:
			}


			if (variable != null) {
				objExpr = macro {
					${variable} = cast ${objExpr};
					assigned.set(field.name, true);
				};
			}

			objExpr = macro try { ${objExpr} } catch (_:String) {${onWarnings}};

			cases.push({ expr: strExpr, guard: null, values: [macro JString($i{caseVar})] });
			cases.push({ expr: objExpr, guard: null, values: [macro JObject($i{caseVar})] });
		}

		else {
			cases.push({ expr: expr, guard: null, values: [macro $i{info.jtype}($i{caseVar})] });
		}


		var nullExpr = (info.name == "Float" || info.name == "Int" || info.name == "Bool")
			? macro {
				warnings.push(IncorrectType(field.name, $v{info.name}, putils.convertPosition(${json}.pos)));
				${onWarnings};
			}
			: nullValue;

		cases.push({expr: nullExpr, guard: null, values: [macro JNull]});
		var defaultExpr = macro {
			warnings.push(IncorrectType(
				field.name,
				$v{info.name},
				putils.convertPosition(${json}.pos)));
			${onWarnings}
		};

		return { expr: ESwitch(macro ${json}.value, cases, defaultExpr), pos: Context.currentPos() };
	}

	private static function handleArray(type:Type, level=1, parser:ParserInfo) : Expr {
		var forVar = "s" + (level-1);
		var caseVar = "s" + level;
		var content = "content"+level;

		var info = typeToHxjsonAst(type);
		var json = macro $i{content};
		return macro [for ($i{content} in $i{forVar})  {
				${parseType(type, info, level, parser, json, CONTINUE)};
			}];
	}

	private static function handleMap(key:Type, value:Type, level=1, parser:ParserInfo) : Expr {
		var forVar = "s" + (level-1);
		var caseVar = "s" + level;
		var fieldVar = "field" + level;

		var info = typeToHxjsonAst(value);

		var keyExpr = switch (typeToHxjsonAst(key.follow()).name) {
			case "String": macro $i{fieldVar}.name;
			case "Int": macro {
				if (Std.parseInt($i{fieldVar}.name) != null && Std.parseInt($i{fieldVar}.name) == Std.parseFloat($i{fieldVar}.name))
					Std.parseInt($i{fieldVar}.name);
				else {
					warnings.push(IncorrectType(field.name, "Int", putils.convertPosition($i{fieldVar}.namePos)));
					continue;
				}
			};
			default: Context.fatalError("json2object: Map key can only be String or Int", Context.currentPos());
		}

		var json = macro $i{fieldVar}.value;
		var valueExpr = parseType(value, info, level, parser, json, CONTINUE);

		var packs = ["json2object"];
		var params = [TPType(key.toComplexType()), TPType(value.toComplexType())];
		var pair = { name:"Pair", pack:packs, params:params };
		var map = { name:"Map", pack:[], params:params};
		var filler = { name:"MapTools", pack:packs, params:params};
		return macro new $filler().fromArray(new $map(), [ for ($i{fieldVar} in $i{forVar}) new $pair(${keyExpr}, ${valueExpr})]);

	}

	private static function handleVariable(type:Type, variable:Expr, parser:ParserInfo) {
		var info = typeToHxjsonAst(type);
		var clsname = info.name;

		var json = macro field.value;
		return parseType(type, info, parser, json, variable, NONE);
	}

	private static function makeParser(c:BaseType, parsedType:Type, ?base:Type, ?noConstruct:Bool) {
		var parsedName:String = null;
		var classParams:Array<TypeParam>;
		var cases = new Array<Case>();
		var parserName = c.name + getParserName(parsedType);
		var packs:Array<String> = [];
		var parserInfo:ParserInfo = {clsName:c.name, packs:c.pack};

		var names:Array<Expr> = [];
		var loop:Expr;

		var useNew = true;
		var defaultEnum = false;

		var ano_constr_fields = [];

		switch (parsedType) {
			case TInst(t, params):
				try { return haxe.macro.Context.getType(parserName); } catch (_:Dynamic) {}
				parsedName = t.get().name;
				packs = t.get().pack;

				switch (t.get().kind) {
					case KTypeParameter(arrayType):
						Context.fatalError("json2object: Type parameters are not parsable: "+t.get().name, Context.currentPos());
					default:
				}

				classParams = [for (p in params) TPType(p.toComplexType())];
				for (field in t.get().fields.get()) {
					if (!field.isPublic || field.meta.has(":jignored")) { continue; }

					switch(field.kind) {
						case FVar(_,w):
							if (w == AccNever)
							{
								continue;
							}

							names.push(macro { assigned.set($v{field.name}, $v{field.meta.has(":optional")});});
							var fieldType = applyParams(field.type, t.get().params, params);

							var f_a = { expr: EField(macro object, field.name), pos: Context.currentPos() };
							var lil_switch = handleVariable(fieldType, f_a, parserInfo);
							cases.push({ expr: lil_switch, guard: null, values: [{ expr: EConst(CString(${field.name})), pos: Context.currentPos()}] });
						default: // Ignore
					}
				}

				var default_e = macro warnings.push(UnknownVariable(field.name, putils.convertPosition(field.namePos)));
				loop = { expr: ESwitch(macro field.name, cases, default_e), pos: Context.currentPos() };

			case TType(_.get() => t, params):
				return makeParser(c, applyParams(parsedType.follow(), t.params, params), parsedType);

			case TAbstract(_.get() => t, params):
				if (t.name != "Map" && t.name != "IMap") {
					return makeParser(c, applyParams(t.type, t.params, params), parsedType, true);
				}

				try { return haxe.macro.Context.getType(parserName); } catch (_:Dynamic) {}
				parsedName = "Map";
				classParams = params.map(function(ty:Type) {return TPType(ty.toComplexType());});
				packs = t.pack;

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

				var json = macro field.value;
				var valueExpr = parseType(value, info, parserInfo, json, CONTINUE);
				loop = macro object.set($keyExpr, $valueExpr);

			case TAnonymous(_.get() => a):
				try { return haxe.macro.Context.getType(parserName); } catch (_:Dynamic) {}
				useNew = false;

				for (field in a.fields) {
					if (!field.isPublic || field.meta.has(":jignored")) { continue; }

					switch(field.kind) {
						case FVar(_,w):
							if (w == AccNever)
							{
								continue;
							}

							names.push(macro { assigned.set($v{field.name}, $v{field.meta.has(":optional")});});

							var f_a = { expr: EField(macro object, field.name), pos: Context.currentPos() };
							var lil_switch = handleVariable(field.type, f_a, parserInfo);
							cases.push({ expr: lil_switch, guard: null, values: [{ expr: EConst(CString(${field.name})), pos: Context.currentPos()}] });

							var defaultValue:Expr = null;
							if (field.meta.has(":default")) {
								var metas = field.meta.extract(":default");
								if (metas.length > 0) {
									var meta = metas[0];
									if (meta.params != null && meta.params.length == 1) {
										if (field.type.followWithAbstracts().unify(Context.typeof(meta.params[0]).followWithAbstracts())) {
											defaultValue = meta.params[0];
										}
										else {
											Context.fatalError("json2object: default value for "+field.name+" is of incorrect type", Context.currentPos());
										}
									}
								}
							}

							var ano_field_default = (defaultValue != null) ? defaultValue : switch (notNull(field.type)) {
								case TAbstract(_.get() => t, p):
									switch(t.name) {
										case "Bool": macro false;
										case "Int": macro 0;
										case "Float": macro 0.0;
										default: macro null;
									}
								default: macro null;
							}
							ano_constr_fields.push({ field: field.name, expr: ano_field_default });

						default: // Ignore
					}
				}

				var default_e = macro warnings.push(UnknownVariable(field.name, putils.convertPosition(field.namePos)));
				loop = { expr: ESwitch(macro field.name, cases, default_e), pos: Context.currentPos() };

			case TEnum(_.get() => t, p):
				parserName += "_Enum_"+t.name;
				try { return haxe.macro.Context.getType(parserName); } catch (_:Dynamic) {}
				parsedName = t.name;
				noConstruct = false;
				useNew = false;
				defaultEnum = true;

				var constructs = t.constructs;

				for (name in t.names) {
					var enumField = constructs.get(name);
					var args = switch (enumField.type) {
						case TFun(a, _): a;
						default: [];
					}
					var enumParams:Array<Expr> = [];
					var blockExpr = [macro if (s0.length != $v{args.length}) {
							warnings.push(IncorrectType(field.name, $v{t.name}, putils.convertPosition(field.value.pos)));
							throw "json2object: Invalid type";
						}];

					var argCount = 0;
					for (a in args) {
						enumParams.push(macro $i{a.name});
						var type = a.t;
						blockExpr.push({expr: EVars([{name:a.name, type:type.toComplexType(), expr:null}]), pos:Context.currentPos()});

						var info = typeToHxjsonAst(type);
						var variable = macro $i{a.name};
						var json = macro s0[$v{argCount}].value;
						blockExpr.push(parseType(type, info, 1, parserInfo, json, variable, THROW));
						argCount++;
					}

					var l = t.module.split(".");
					l.push(t.name);
					l.push(name);
					var subExpr = {expr:EConst(CIdent(l.shift())), pos:Context.currentPos()};
					while (l.length > 0) {
						subExpr = {expr:EField(subExpr, l.shift()), pos:Context.currentPos()};
					}

					var subExpr = (enumParams.length > 0)
						? {expr:ECall(subExpr, enumParams), pos:Context.currentPos()}
						: subExpr;
					blockExpr.push(macro object = ${subExpr});

					var lil_expr:Expr = {expr: EBlock(blockExpr), pos:Context.currentPos()};
					cases.push({ expr: lil_expr, guard: null, values: [{ expr: EConst(CString($v{name})), pos: Context.currentPos()}] });
				}

				var default_e = macro { warnings.push(IncorrectType(field.name, $v{t.name}, putils.convertPosition(field.namePos))); throw "json2object: Invalid type"; } ;
				var expr = {expr: ESwitch(macro field.name, cases, default_e), pos: Context.currentPos() };

				expr = macro switch (field.value.value) {
					case JObject(s0):
						${expr};
					default:
						warnings.push(IncorrectType(field.name, $v{t.name}, putils.convertPosition(field.value.pos))); throw "json2object: Invalid type";
				}

				loop = macro {
					if (fields.length != 1) {
						warnings.push(IncorrectType(field.name, $v{t.name}, putils.convertPosition(objectPos)));
						throw "json2object: Invalid type";
					}
					else {
						${expr};
					}
				}

			default:
				Context.fatalError("json2object: " + parsedType.toString() + " can't be parsed", Context.currentPos());
		}

		var cls = { name:parsedName, pack:packs, params:classParams};
		var new_e;

		if (noConstruct) {
			new_e = macro {};
		} else if (useNew) {
			new_e = macro object = new $cls();
		} else if (defaultEnum) {
			new_e = macro object = null;
		} else {
			new_e = {
				expr: EBinop(OpAssign, {
						expr: EConst(CIdent("object")),
						pos: Context.currentPos()
					},
					{
						expr: EObjectDecl(ano_constr_fields),
						pos: Context.currentPos()
					}
				),
				pos: Context.currentPos()
			};
		}

		var obj:Field = {
			doc: null,
			access: [APublic],
			kind: FVar(TypeUtils.toComplexType(base != null ? base : parsedType), null),
			name: "object",
			pos: Context.currentPos(),
			meta: null,
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
			 */
			public function loadJson(fields:Array<hxjsonast.Json.JObjectField>, objectPos:hxjsonast.Position) {
				var assigned = new Map<String,Bool>();
				$b{names}

				@:privateAccess {
					${new_e};

					// Assign every JSON fields.
					for (field in fields) {
						${loop}
					}
				}

				// Verify that all variables are assigned.
				var lastPos = putils.convertPosition(new hxjsonast.Position(objectPos.file, objectPos.max-1, objectPos.max-1));
				for (s in assigned.keys()) {
					if (!assigned[s]) {
						warnings.push(UninitializedVariable(s, lastPos));
					}
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
							return loadJson(fields, json.pos);
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

		//var p = new haxe.macro.Printer();
		//trace(p.printTypeDefinition(loadJsonClass));

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
