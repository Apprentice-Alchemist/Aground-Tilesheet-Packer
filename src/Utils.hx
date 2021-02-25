#if macro
using haxe.macro.Tools;
#end

@:noUsing macro function assert(e) {
	return macro @:pos($v{e.pos}) if (!$e)
		throw "assert " + $v{e.toString()};
}

inline function error(msg:String) {
	Sys.println(msg);
	Sys.exit(1);
}

inline function or<T>(v:Null<T>, o:T):T {
	return v == null ? o : v;
}

inline function parseInt(s:Null<String>):Int
	return s == null ? 0 : Std.parseInt(s);
