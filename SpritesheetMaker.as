package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.net.FileReference;
	import flash.net.FileFilter;
	import flash.events.Event;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.filesystem.FileStream;
	import flash.filesystem.File;
	
	
	public class SpritesheetMaker extends MovieClip {
		private var fr:FileReference = new FileReference();
		private var dir:File;
		
		public function SpritesheetMaker() {
			stage.addEventListener(MouseEvent.CLICK, onClick);
			fr.addEventListener(Event.SELECT, onSelect);
			fr.addEventListener(Event.COMPLETE, onOpen);
			dir = File.documentsDirectory.resolvePath("animations");
		}
		
		function onSelect(e:Event):void {
			fr.load();
		}
		
		private var count:int = 0;
		private var imageFile:Object = {};
		function onOpen(e:Event):void {
			count = 0;
			imageFile = {};
			imgCount = 0;
			var json:Object = JSON.parse(fr.data.toString());
			for(var i=0; i<json.sprites.length; i++) {
				var sprite = json.sprites[i];
				var tag = sprite[0];
				if(!imageFile[tag]) {
					var md5:String = tag;
					var file:File = dir.resolvePath("assets").resolvePath(md5+".png");
					imageFile[tag] = file;
					if(file.exists) {
						count++;
						file.load();
						file.addEventListener(Event.COMPLETE, onLoad);
					}
				}
			}
		}
				
		function onClick(e:MouseEvent):void {
			fr.browse([
				new FileFilter("Data json", "json")
			]);
		}
	}
	
}
