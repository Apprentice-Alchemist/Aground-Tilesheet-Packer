import Unpacker.unpack;

function main(){
	var args = Sys.args();
	switch args.shift() {
		case "pack":
			throw "todo";
		case "unpack":
			var file = args.shift();
			var out = null;
			var id = null;
			if(file == null) throw "missing file argument";
			while(true) {
				switch args.shift() {
					case "-id": id = args.shift();
					case "-o": out = args.shift();
					case _: break;
				}
			}
			unpack(file,out,id);
		case _:
			Sys.println("Usage : \n\t atp pack -i w h ...files -o out.png\n\tatp unpack file -id id -o out");
	}
}