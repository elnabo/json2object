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

	// return true if type.followWithAbstract == String, Int, Float or Bool or Array of the previous
	private static function isBaseType(type:Type) {
		return switch (type.followWithAbstracts()) {
			case TInst(_.get()=>t, p):
				(t.module == "String" || (t.module == "Array" && isBaseType(p[0])));
			case TAbstract(_.get()=>t, p):
				(t.module == "StdTypes" && (t.name == "Int" || t.name == "Float" || t.name == "Bool"));
			default: false;
		}
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
		changeFunction("loadJsonString", parser, macro {value = cast s;});
		changeFunction("loadJsonNull", parser, macro {value = null;});
	}

	public static function makeIntParser(parser:TypeDefinition, ?base:Type=null) {
		var e = macro {
			if (Std.parseInt(f) != null && Std.parseInt(f) == Std.parseFloat(f)) {
				value = cast Std.parseInt(f);
			}
			else {
				onIncorrectType(pos, variable);
			}
		};
		changeFunction("loadJsonNumber", parser, e);
		if (base != null && isNullable(base)) {
			changeFunction("loadJsonNull", parser, macro {value = null;});
		}
	}

	public static function makeFloatParser(parser:TypeDefinition, ?base:Type=null) {
		var e = macro {
			if (Std.parseInt(f) != null) {
				value = cast Std.parseFloat(f);
			}
			else {
				onIncorrectType(pos, variable);
			}
		};
		changeFunction("loadJsonNumber", parser, e);
		if (base != null && isNullable(base)) {
			changeFunction("loadJsonNull", parser, macro {value = null;});
		}
	}

	public static function makeBoolParser(parser:TypeDefinition, ?base:Type=null) {
		changeFunction("loadJsonBool", parser, macro { value = cast b; });
		if (base != null && isNullable(base)) {
			changeFunction("loadJsonNull", parser, macro {value = null;});
		}
	}

	public static function makeArrayParser(parser:TypeDefinition, subType:Type, baseParser:BaseType) {
		var cls = { name:baseParser.name, pack:baseParser.pack, params:[TPType(subType.toComplexType())]};
		var e = macro value = cast [
				for (j in a)
					try { new $cls(errors, putils, THROW).loadJson(j, variable); }
					catch (_:String) { continue; }
			];
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

					var assignation = (isNullable(f_type))
						?
						macro {
							try {
								var tmp = new $f_cls(errors, putils, OBJECTTHROW).loadJson(field.value, field.name);
								if (tmp != null) { $f_a = tmp; }
								assigned.set($v{field.name}, true);
							} catch (_:Dynamic) {}
						}
						:
						macro {
							try {
								$f_a = new $f_cls(errors, putils, OBJECTTHROW).loadJson(field.value, field.name);
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

		changeFunction("loadJsonObject", parser, e);
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
				value.set(cast $keyMacro, cast $valueMacro);
			}
		}

		changeFunction("loadJsonObject", parser, e);
		changeFunction("loadJsonNull", parser, macro {value = null;});
	}

	public static function makeEnumParser(parser:TypeDefinition, type:Type, baseParser:BaseType) {

		var objMacro:Expr;
		var strMacro:Expr;

		var typeName:String;
		switch (type) {
			case TEnum(_.get()=>t, p):
				typeName = t.name;
				var internStringCases = new Array<Case>();
				var internObjectCases = new Array<Case>();
				for (n in t.names) {

					var l = t.module.split(".");
					l.push(t.name);
					l.push(n);
					var subExpr = {expr:EConst(CIdent(l.shift())), pos:Context.currentPos()};
					while (l.length > 0) {
						subExpr = {expr:EField(subExpr, l.shift()), pos:Context.currentPos()};
					}

					switch (t.constructs.get(n).type) {
						case TEnum(_,_):
							subExpr = macro value = cast ${subExpr};
							internStringCases.push({expr: subExpr, guard: null, values: [macro $v{n}]});

							var objSubExpr = macro if (s0.length == 0) {
								$subExpr;
							} else {
								errors.push(InvalidEnumConstructor(field.name, $v{t.name}, pos));
									switch (errorType) {
										case OBJECTTHROW, THROW : throw "json2object: parsing throw";
										case _:
									}
							};
							internObjectCases.push({expr: objSubExpr, guard: null, values: [macro $v{n}]});

						case TFun(args, _):
							var enumParams:Array<Expr> = [];
							var blockExpr = [
								macro if (s0.length != $v{args.length}) {
									errors.push(InvalidEnumConstructor(field.name, $v{t.name}, pos));
									switch (errorType) {
										case OBJECTTHROW, THROW : throw "json2object: parsing throw";
										case _:
									}
								}
							];
							var argCount = 0;
							for (a in args) {
								enumParams.push(macro $i{a.name});
								blockExpr.push({expr: EVars([{name:a.name, type:a.t.toComplexType(), expr:null}]), pos:Context.currentPos()});

								var a_cls = {name:baseParser.name, pack:baseParser.pack, params:[TPType(a.t.toComplexType())]};
								var v = macro $i{a.name} = new $a_cls(errors, putils, THROW).loadJson(s0[$v{argCount}].value, field.name+"."+$v{a.name});
								blockExpr.push(v);
								argCount++;
							}

							subExpr = (enumParams.length > 0)
								? {expr:ECall(subExpr, enumParams), pos:Context.currentPos()}
								: subExpr;
							blockExpr.push(macro value = cast ${subExpr});

							var lil_expr:Expr = {expr: EBlock(blockExpr), pos:Context.currentPos()};
							internObjectCases.push({ expr: lil_expr, guard: null, values: [{ expr: EConst(CString($v{n})), pos: Context.currentPos()}] });


						default:
					}
				}
				var default_e = macro {
						errors.push(IncorrectEnumValue(variable, $v{t.name}, pos));
						switch (errorType) {
							case OBJECTTHROW, THROW : throw "json2object: parsing throw";
							case _:
						}
					};
				objMacro = {expr: ESwitch(macro field.name, internObjectCases, default_e), pos: Context.currentPos() };
				objMacro = macro if (o.length != 1) {
					errors.push(IncorrectType(variable, $v{typeName}, pos));
					switch (errorType) {
						case OBJECTTHROW, THROW : throw "json2object: parsing throw";
						case _:
					}
				} else {
					var field = o[0];
					switch (o[0].value.value) {
						case JObject(s0):
							${objMacro};
						default:
							errors.push(IncorrectType(field.name, $v{typeName}, putils.convertPosition(field.value.pos)));
							switch (errorType) {
								case OBJECTTHROW, THROW : throw "json2object: parsing throw";
								case _:
							}
					}
				}
				strMacro = {expr: ESwitch(macro $i{"s"}, internStringCases, default_e), pos: Context.currentPos() };
			default:
		}

		changeFunction("loadJsonObject", parser, objMacro);
		changeFunction("loadJsonString", parser, strMacro);
		changeFunction("loadJsonNull", parser, macro { value = null; });
	}

	public static function makeAbstractEnumParser(parser:TypeDefinition, type:Type, baseParser:BaseType) {
		var name:String;

		switch (type.followWithAbstracts()) {
			case TInst(_.get()=>t, _):
				if (t.module != "String") {
					Context.fatalError("json2object: Unsupported abstract enum type:"+type.toString(), Context.currentPos());
				}
				name = "String";
			case TAbstract(_.get()=>t, _):
				if (t.module != "StdTypes" && (t.name != "Int" && t.name != "Bool" && t.name != "Float")) {
					Context.fatalError("json2object: Unsupported abstract enum type:"+type.toString(), Context.currentPos());
				}
				name = t.name;
			default: Context.fatalError("json2object: Unsupported abstract enum type:"+type.toString(), Context.currentPos());
		}

		var caseValues = new Array<Expr>();

		var e = macro null;

		switch (type) {
			case TAbstract(_.get()=>t, p) :
				for (field in t.impl.get().statics.get()) {
					if (!field.meta.has(":enum") || !field.meta.has(":impl")) {
						continue;
					}
					if (field.expr() == null) { continue; }
					caseValues.push(
						switch (field.expr().expr) {
							case TConst(_): Context.getTypedExpr(field.expr());
							case TCast(caste, _):
								switch (caste.expr) {
									case TConst(tc):
										switch (tc) {
											case TNull: continue;
											default: Context.getTypedExpr(caste);
										}
									default: Context.getTypedExpr(caste);
								}
							default: continue;
						}
					);
				}

				if (caseValues.length == 0 && !isNullable(type)) {
					Context.fatalError("json2object: Abstract enum of type "+ type.toString() +"can't be parsed if empty", Context.currentPos());
				}



				var v = switch (name) {
					case "String": macro s;
					case "Int", "Float":
						var cls = {name:baseParser.name, pack:baseParser.pack, params:[TPType(Context.getType(name).toComplexType())]} ;
						macro new $cls([], putils, NONE).loadJson({value:JNumber(f), pos:{file:pos.file, min:pos.min, max:pos.max}}, variable);
					case "Bool": macro b;
					default: macro null;
				}
				var case_e = [{expr:macro value = cast $v, guard:null, values:caseValues}];
				var default_e = macro {value = cast ${caseValues[0]}; onIncorrectType(pos, variable);};

				e = {expr: ESwitch(macro cast $v, case_e, default_e), pos: Context.currentPos() };

				changeFunction("onIncorrectType", parser, macro {
					value = cast ${caseValues[0]};
					errors.push(IncorrectType(variable, $v{type.toString()}, pos));
					switch (errorType) {
						case THROW: throw "json2object: parsing throw";
						case OBJECTTHROW: errors.push(UninitializedVariable(variable, pos));
						case NONE:
					}
				});

				if (isNullable(t.type)) {
					changeFunction("loadJsonNull", parser, macro {value = cast null;});
				}
			default:
		}

		switch (name) {
			case "String":
				changeFunction("loadJsonString", parser, e);
			case "Int", "Float":
				changeFunction("loadJsonNumber", parser, e);
			case "Bool":
				changeFunction("loadJsonBool", parser, e);
			default:
		}
	}

	public static function makeAbstractParser(parser:TypeDefinition, type:Type, baseParser:BaseType) {
		var hasFromFloat = false;
		var hasOneFrom = false;

		switch (type) {
			case TAbstract(_.get()=>t, p):

				var from = (t.from.length == 0) ? [{t:t.type, field:null}] : t.from;
				var i = 0;
				for(fromType in from) {

					switch (fromType.t.followWithAbstracts()) {
						case TInst(_.get()=>st, sp):
							if (st.module == "String") {
								if (i == 0) { makeStringParser(parser); }
								else {
									var cls = {name:baseParser.name, pack:baseParser.pack, params:[TPType(fromType.t.toComplexType())]};
									changeFunction("loadJsonString",
										parser,
										macro {
											value = new $cls(errors, putils, NONE).loadJson(
											{value:JString(s), pos:{file:pos.file, min:pos.min, max:pos.max}},
												variable);
											});
								}
								hasOneFrom = true;
							}
							if (st.module == "Array") {
								var subType = sp[0];
								for (i in 0...t.params.length) {
									if (subType.unify(t.params[i].t)) {
										subType = p[i];
										break;
									}
								}
								if (isBaseType(subType.followWithAbstracts())) {
									if (i == 0) {
										makeArrayParser(parser,subType.followWithAbstracts(), baseParser);
									}
									else {
										var aParams = switch (fromType.t.followWithAbstracts()) {
											case TInst(r,_): [TPType(TInst(r,[subType]).toComplexType())];
											default:[];
										}
										var cls = {name:baseParser.name, pack:baseParser.pack, params:aParams};
										changeFunction("loadJsonArray",
											parser,
											macro {
												value = new $cls(errors, putils, NONE).loadJson(
												{value:JArray(a), pos:{file:pos.file, min:pos.min, max:pos.max}},
													variable);
												});
									}
									hasOneFrom = true;
								}
							}
						case TAbstract(_.get()=>st, sp):
							if (st.module == "StdTypes") {
								var cls = {name:baseParser.name, pack:baseParser.pack, params:[TPType(fromType.t.toComplexType())]};
								switch (st.name) {
									case "Int":
										if (!hasFromFloat) {
											if (i == 0) {
												makeIntParser(parser, fromType.t);
											}
											else {
												changeFunction("loadJsonNumber",
													parser,
													macro {
														value = new $cls(errors, putils, NONE).loadJson(
														{value:JNumber(f), pos:{file:pos.file, min:pos.min, max:pos.max}},
															variable);
														});
											}
											hasOneFrom = true;
										}
									case "Float":
										if (i == 0) {
												makeFloatParser(parser, fromType.t);
										}
										else {
											changeFunction("loadJsonNumber",
												parser,
												macro {
													value = new $cls(errors, putils, NONE).loadJson(
													{value:JNumber(f), pos:{file:pos.file, min:pos.min, max:pos.max}},
														variable);
													});
										}
										hasFromFloat = true;
										hasOneFrom = true;
									case "Bool":
										if (i == 0) {
											makeBoolParser(parser, fromType.t);
										}
										else {
											changeFunction("loadJsonNumber",
												parser,
												macro {
													value = new $cls(errors, putils, NONE).loadJson(
													{value:JBool(b), pos:{file:pos.file, min:pos.min, max:pos.max}},
														variable);
													});
										}
										hasOneFrom = true;
								}
							}
						default:
					}
					i++;
				}

				if (isNullable(t.type)) {
					changeFunction("loadJsonNull", parser, macro {value = cast null;});
				}
			default:
		}
		if (!hasOneFrom) {
			Context.fatalError("json2object: No parser can be generated for "+type.toString()+ " as it has no supported @:from", Context.currentPos());
		}
	}

	public static function makeParser(c:BaseType, type:Type, ?base:Type=null) {

		if (base == null) { base = type; }

		var parserMapName = base.toString();
		if (parsers.exists(parserMapName)) {
			return parsers.get(parserMapName);
		}

		var parserName = c.name + "_" + (counter++);
		var parser = macro class $parserName {
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
				errors = [];
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
					case JObject(o) : loadJsonObject(o, pos, variable);
				}
				return value;
			}

			private function onIncorrectType(pos:json2object.Position, variable:String) {
				errors.push(IncorrectType(variable, $v{type.toString()}, pos));
				switch (errorType) {
					case OBJECTTHROW, THROW: throw "json2object: parsing throw";
					case NONE:
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
			private function loadJsonObject(o:Array<hxjsonast.Json.JObjectField>, pos:json2object.Position, variable:String) {
				onIncorrectType(pos, variable);
			}
		};

		var value:Field = {
			doc: null,
			kind: FVar(TypeUtils.toComplexType(base), null),
			access: [APublic],
			name: "value",
			pos: Context.currentPos(),
			meta: null,
		};
		parser.fields.push(value);

		var object:Field = {
			doc: null,
			kind: FProp("get", "never",TypeUtils.toComplexType(base), null),
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
						case "Int" : makeIntParser(parser, base);
						case "Float", "Single": makeFloatParser(parser, base);
						case "Bool": makeBoolParser(parser, base);
						default: Context.fatalError("json2object: Parser of "+t.name+" are not generated", Context.currentPos());
					}
				}
				else if (t.module == "Map" && t.name == "Map") {
					makeMapParser(parser, p[0], p[1], c);
				}
				else {
					if (t.meta.has(":enum")) {
						makeAbstractEnumParser(parser, type.applyTypeParameters(t.params, p), c);
					}
					else {
						makeAbstractParser(parser, type.applyTypeParameters(t.params, p), c);
					}
				}
			case TEnum(_.get()=>t, p):
				makeEnumParser(parser, type.applyTypeParameters(t.params, p), c);
			case TType(_.get()=>t, p) :
				return makeParser(c, t.type.applyTypeParameters(t.params, p), type);
			case TLazy(f):
				return makeParser(c, f());
			default: Context.fatalError("json2object: Parser of "+type.toString()+" are not generated", Context.currentPos());
		}

		haxe.macro.Context.defineType(parser);

		//~ var p = new haxe.macro.Printer();
		//~ trace(p.printTypeDefinition(parser));

		var constructedType = haxe.macro.Context.getType(parserName);
		parsers.set(parserMapName, constructedType);
		return constructedType;

	}

	public static function build() {
		switch (Context.getLocalType()) {
			case TInst(c, [type]):
				return makeParser(c.get(), type);
			case _:
				Context.fatalError("json2object: Parsing tools must be a class", Context.currentPos());
				return null;
		}
	}
}
#end
