package json2object.utils.schema;

typedef JsonSchemaType = {
	@:optional
	var const: Null<String>;
	@:optional @:alias('const')
	var const_bool : Bool;
	@:optional @:alias('const')
	var const_int : Int;
	@:optional @:alias('const')
	var const_float : Float;
	@:optional
	var description: String;
	@:optional
	var type: String;
	@:optional @:alias("$schema")
	var __j2o_s_a_0: String;
	@:optional @:alias("$ref")
	var __j2o_s_a_1: String;
	@:optional
	var required: Array<String>;
	@:optional
	var properties: Map<String, JsonSchemaType>;
	@:optional
	var additionalProperties: Bool;
	@:optional @:alias("additionalProperties")
	var additionalProperties_obj: JsonSchemaType;
	@:optional
	var items: JsonSchemaType;
	@:optional
	var patternProperties: Map<String, JsonSchemaType>;
	@:optional
	var anyOf: Array<JsonSchemaType>;
	@:optional
	var definitions: Map<String, JsonSchemaType>;
}
