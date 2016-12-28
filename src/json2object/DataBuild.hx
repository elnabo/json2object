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

package json2object;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.ExprTools;

/**
 * Contains all required functions to add the loadJson and fromJson function to a class.
 */
class DataBuild {
	/**
	 * Verify if the Type (typedef, abstract, class) is supported and replace typdefs by their value.
	 *
	 * Return `null` if the type is unsupported.
	 */
	static function cleanType(type:Type) {
		switch (type) {
			case TInst(t, p):
				var params = [];
				for (param in p) {
					switch(param) {
						case TType(t1, p1):
							params.push(cleanType(t1.get().type));
						case TAbstract(t1, p1):
							params.push(cleanType(t1.get().type));
						case TMono(_):
						default:
							params.push(param);
					}
				}
				return TInst(t, params);
			case TType(t, p):
				var params = p;
				var cleaned = cleanType(t.get().type);
				switch (cleaned) {
					case TInst(t1, p1):
						params = params.concat(p1);
						return TInst(t1, [for (n in [for (param in params) cleanType(param)]) if (n != null) n]);
					default: // Never reached
						return null;
				}
			case TAbstract(t, p):
				switch (t.get().name) {
					case "Bool","Float","Int":
						return type;
					default:
						return cleanType(t.get().type);
				}
			case TAnonymous(_):
				Context.warning("Anonymous structure are not supported", Context.currentPos());
				return null;
			case TDynamic(_):
				Context.warning("Dynamic type are not supported", Context.currentPos());
				return null;
			case TEnum(_):
				Context.warning("Enum type are not supported", Context.currentPos());
				return null;
			case TMono(_):
				return null;
			default:
				return type;
		}
	}

	/**
	 * Transform a TypePath to a valid Type.
	 */
	static function typePathToType(typePath:TypePath):Type {
		var type = Context.getType(typePath.name);
		var params = [for (param in typePath.params)
			switch (param) {
				case TPType(tpt):
					switch (tpt) {
						case TPath(tp):
							typePathToType(tp);
						default:
							null;
					}
				default:
					null;
			}];

		var clean = cleanType(type);
		switch (clean) {
			case TInst(t, p):
				for (param in p) {
					params.push(param);
				}
				return TInst(t, params);
			default:
				return clean;
		}
	}

	/**
	 * From a Type, obtain the type of JSON required, the name of the object and its parameters.
	 *
	 * Display warning in case of unsupported object.
	 *
	 * Return null if the type is unsupported or if the object is not tagged with the json2object @:build meta.
	 */
	static function parseType(type:Type) {
		return switch (type) {
			case TInst(t, p):
				switch(t.get().name) {
					case "String":
						{ jtype: "JString", name: "String", params: [] };
					case "Array":
						{ jtype: "JArray", name: "Array", params: p };
					default:
						if (p.length > 0) {
							Context.warning("Variable with a genereic type are not supported", Context.currentPos());
						}
						var loader = false;
						for (meta in t.get().meta.get()) {
							loader = meta.name == ":build" && meta.params[0].toString() == "json2object.DataBuild.loadJson()";
							if (loader) {
								break;
							}
						}

						if (!loader) {
							Context.warning(t.get().name + " lack the @:build(json2object.DataBuild.loadJson) meta", Context.currentPos());
							null;
						}
						else {
							{ jtype: "JObject", name: t.get().name, params: p };
						}
				}
			case TAbstract(t,p):
				switch(t.get().name) {
					case "Bool":
						{ jtype: "JBool", name: "Bool", params: [] };
					case "Int":
						{ jtype: "JNumber", name: "Int", params: [] };
					case "Float":
						{ jtype: "JNumber", name: "Float", params: [] };
					default:
						var abstractType = parseType(t.get().type);
						return abstractType;
				}
			default:
				Context.warning("Only Int/Bool/Float/String/Array and object with the @:build(json2object.DataBuild.loadJson) meta are supported", Context.currentPos());
				null;
		};
	}

	/**
	 * Recursively build the assignation of a JSON array of a given type.
	 *
	 * Return a recursive macro for array assignation.
	 */
	static function arrayParser(type:Type, level=1) {
		var parsed = parseType(type);

		var jtype = parsed.jtype;
		var name = parsed.name;
		var params = parsed.params;

		var forVar = "s" + (level-1);
		var caseVar = "s" + level;

		var e:Expr = switch (jtype) {
			case "JObject":
				macro $i{name}.loadJson($i{caseVar}, posUtils.convertPosition(field.value.pos), posUtils, obj.warnings);
			case "JArray":
				arrayParser(params[0], level+1);
			case "JNumber":
				switch(name) {
					case "Int":
						macro Std.parseInt($i{caseVar});
					case "Float":
						macro Std.parseFloat($i{caseVar});
					case _:
						macro $i{caseVar};
				};
			default:
				macro $i{caseVar};
		};
		return macro [ for (n in [ for (content in $i{forVar}) { switch (content.value) {
					case $i{jtype}($i{caseVar}):
						$e;
					default:
						obj.warnings.push(IncorrectType(field.name, $v{name}, posUtils.convertPosition(field.value.pos)));
						null;
					}}
			]) if (n != null) n];
	}

	/**
	 * Add static functions, loadJson and fromJson, to a class allowing instantiation from JSON file.
	 */
	static function loadJson() {
		var fields = Context.getBuildFields();
		var cases = [];
		var names:Array<Expr> = [];

		var localType = Context.getLocalType();
		switch (localType) {
			case TInst(t, p):
				if (p.length > 0) {
					Context.warning("Generic type with generic variable are not supported (except Array)", Context.currentPos());
				}
			default:
		}

		for (field in fields) {
			switch (field.kind) {
				// Only variable are assigned
				case FVar(a, _):
					if (field.name == "warnings") {
						Context.fatalError('Field "warnings" is reserved', Context.currentPos());
					}

					// Ignore flagged variable
					var flag = false;
					for (meta in field.meta) {
						if (meta.name == ":jignore") {
							flag = true;
							cases.push({ expr: null, guard: null, values: [{ expr: EConst(CString(${field.name})), pos: Context.currentPos()}] });
							break;
						}
					}
					if(flag) {
						continue;
					}

					switch (a) {
						case TPath(p):
							var parsedType = parseType(typePathToType(p));
							if (parsedType == null) {
								break;
							}

							var jtype = parsedType.jtype;
							var objectName = parsedType.name;
							var params = parsedType.params;
							// Keep track if the variable are assigned.
							names.push(macro { assignement.set($v{field.name}, $v{objectName});});

							var f_a = { expr: EField(macro obj, field.name), pos: Context.currentPos() };
							var expr:Expr = switch (jtype) {
								case "JString","JBool":
									macro ${f_a} = s0;
								case "JNumber":
									macro ${f_a} = ${switch(parsedType.name) {
										case "Int":
											macro Std.parseInt(s0);
										case "Float":
											macro Std.parseFloat(s0);
										case _:
											macro s0;
										}
									};
								case "JArray":
									macro ${f_a} = ${arrayParser(params[0])};
								default: // JObject
									macro ${f_a} = $i{objectName}.loadJson(s0, posUtils.convertPosition(field.value.pos), posUtils, obj.warnings);
							}

							// Assign only if the types match.
							var lil_switch = macro {
								assignement.set(field.name, null);
								switch(field.value.value){
									case $i{jtype}(s0):
										${expr};
									default:
										obj.warnings.push(IncorrectType(field.name, $v{objectName}, posUtils.convertPosition(field.value.pos)));
								}
							};

							cases.push({ expr: lil_switch, guard: null, values: [{ expr: EConst(CString(${field.name})), pos: Context.currentPos()}] });
						default:
					}
				default:
			}
		}

		// Raise a warning, if a field is not in the JSON.
		var default_e = macro obj.warnings.push(UnknownVariable(field.name, posUtils.convertPosition(field.value.pos)));
		var switch_e = { expr: ESwitch(macro field.name, cases, default_e), pos: Context.currentPos() };

		var new_e = { expr: ENew({ name: Context.getLocalClass().get().name, pack: [], params: [] }, []), pos: Context.currentPos() };

		var loadJsonFunction = macro : {
			/**
			 * Create an instance initialized from a hxjsonast.
			 *
			 * @param fields JSON fields.
			 * @param objectPos Position of the current json object in the main file.
			 * @param posUtils Tools for converting hxjsonast.Position into Position.
			 * @param parentWarnings List of warnings for the parent class.
			 */
			public static function loadJson(fields:Array<hxjsonast.Json.JObjectField>, objectPos:json2object.Position, posUtils:json2object.PosUtils, ?parentWarnings:Array<json2object.Error>=null) {
				var assignement = new Map<String,String>();
				$b{names}
				var obj = ${new_e};
				// Assign every JSON fields.
				for (field in fields) {
					${switch_e}
				}
				// Verify that all variables are assigned.
				for (s in assignement.keys()) {
					if (assignement.get(s) != null) {
						obj.warnings.push(UninitializedVariable(s, objectPos));
					}
				}
				// Send warnings to the parent class.
				if (parentWarnings != null) {
					for (w in obj.warnings) {
						parentWarnings.push(w);
					}
				}
				return obj;
			}
		};

		var fromJsonFunction = macro : {
			/**
			 * Create an instance initialized from a JSON.
			 *
			 * Return `null` if the JSON is invalid.
			 */
			public static function fromJson(jsonString:String, filename:String) {
				var putils = new json2object.PosUtils(jsonString);
				try {
					var json = hxjsonast.Parser.parse(jsonString, filename);
					switch (json.value) {
						case hxjsonast.Json.JsonValue.JObject(fields):
							return loadJson(fields, putils.convertPosition(json.pos), putils);
						default:
							return null;
					}
				}
				catch (e:hxjsonast.Error) {
					throw json2object.Error.ParserError(e.message, putils.convertPosition(e.pos));
				}
			}
		};

		var warnings = macro : {
			/** Store warnings raised during the assignation of the JSON to this object. */
			public var warnings = new Array<json2object.Error>();
		};

		switch (loadJsonFunction) {
			case TAnonymous(f):
				fields = fields.concat(f);
			case _:
		}
		switch (fromJsonFunction) {
			case TAnonymous(f):
				fields = fields.concat(f);
			case _:
		}
		switch (warnings) {
			case TAnonymous(f):
				fields = fields.concat(f);
			case _:
		}

		return fields;
	}
}
