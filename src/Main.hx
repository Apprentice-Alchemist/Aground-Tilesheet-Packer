function main(){
	var args = Sys.args();
	switch args.shift() {
		case "pack":
			error("todo : packing tilesheets");
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

function unpack(file:String, out:String, ?id:String) {
	var image = Types.Image.fromPng(Path.withExtension(file, "png"));
	function unpackSheet(s:Sheet, outpath:String) {
		if (s == null)
			throw "unpackSheet: sheet is null.";
		var r = new Rectangle(0, 0, s.width, s.height);
		for (f in s.frames) {
			if (f.offsetX + f.width > r.width)
				r.width = f.offsetX + f.width;
			if (f.offsetY + f.height > r.height)
				r.height = f.offsetY + f.height;
		}
		var out = new Image(r.width * s.frames.length, r.height);
		for (f in s.frames)
			out.blit(image, new Rectangle(f.x, f.y, f.width, f.height), new Rectangle(f.id * s.width + f.offsetX, f.offsetY, f.width, f.height));
		out.writePng(outpath);
	}
	if (!sys.FileSystem.exists(file)) {
		error('File "${file}" does not exist.');
	}

	var fcontent = sys.io.File.getContent(file);
	var xml = Xml.parse(fcontent).firstElement();
	var sheets = new Array<Sheet>();
	if (xml.nodeName == "sheets") {
		for (c in xml.elementsNamed("tilesheet")) {
			sheets.push(Sheet.fromXml(c));
		}
	} else {
		assert(xml.nodeName == "tilesheet");
		sheets.push(Sheet.fromXml(xml));
	}
	if (id != null) {
		var sheet = sheets.find(s -> s.id == id);
		if (sheet == null)
			throw "no sheet width id " + id;
	} else {
		for (s in sheets) {
			var path = out == null ? s.id + ".png" : Path.normalize(Path.join([out, s.id + ".png"]));
			unpackSheet(s, path);
		}
	}
}