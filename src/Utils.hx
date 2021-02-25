import haxe.macro.Context;
import haxe.macro.Expr;

#if macro
using haxe.macro.Tools;
#end

@:noUsing macro function assert(e) {
	return macro @:pos($v{e.pos}) if (!$e)
		throw "assert " + $v{e.toString()};
}

function error(msg:String) {
	Sys.println(msg);
	Sys.exit(1);
}

function or<T>(v:Null<T>, o:T):T {
	return v == null ? o : v;
}
