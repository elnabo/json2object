package utest.utils;

/**
Shadow version to avoid issue with variable named async which is a keyword on python 3.5+ but not escaped in haxe 3.
**/
class AsyncUtils {
	static public inline function orResolved(_async:Null<Async>):Async {
		return _async == null ? Async.getResolved() : _async;
	}
}
