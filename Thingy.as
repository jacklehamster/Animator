package  {
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import flash.geom.Matrix;
	import flash.utils.ByteArray;
	import by.blooddy.crypto.MD5;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import by.blooddy.crypto.image.PNG24Encoder;
	import flash.display.Stage;
	import flash.display.Shape;

	
	public class Thingy extends MovieClip {
		private var tag:String = null;
		private var bitmap:Bitmap = new Bitmap(new BitmapData(1,1));
		private var tempBitmap:BitmapData = new BitmapData(1,1);
		private var rect:Rectangle;
		private var savedHash:Object = {};
		private var dir:File;
		private var data:Object;
		private var frame:int = 1;
		private var dim:Object = {};
		private var previousLabel:String = null;
		private var maxWidth:int=0, maxHeight:int=0;
		private var stopped:Boolean = false;
		private var shape:Shape = new Shape();
		
		public function Thingy() {
			dir = File.documentsDirectory.resolvePath("animations");
			addEventListener(Event.ADDED_TO_STAGE, onStage);
			addEventListener(Event.REMOVED_FROM_STAGE, offStage);
			visible = false;
		}
		
		private function onStage(e:Event):void {
			var owner:MovieClip = MovieClip(parent);
			var hotSpot:Point = owner.localToGlobal(new Point());
			data = {
				frames:[],
				sprites:[],
				fps: stage.frameRate,
				frameCount: owner.totalFrames,
				hotSpot:[hotSpot.x,hotSpot.y],
				backgroundColor: "#" + (stage.color & 0xFFFFFF).toString(16)
			}
			
			addEventListener(Event.ENTER_FRAME, onFrame);		
			refresh();
		}
		
		private function offStage(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onStage);
			removeEventListener(Event.REMOVED_FROM_STAGE, offStage);
			removeEventListener(Event.ENTER_FRAME, onFrame);
			if(bitmap.parent) {
				bitmap.stage.removeChild(bitmap);				
			}
		}
		
		private function onFrame(e:Event):void {
			if(stopped) {
				return;
			}
			frame++;
			refresh();
			if(MovieClip(parent).currentFrame===MovieClip(parent).totalFrames) {
				trace("DONE");
				if(bitmap.parent)
					bitmap.parent.removeChild(bitmap);
				if(shape.parent)
					shape.parent.removeChild(shape);
				stopped = true;
			}
		}
		
		private function reduceBitmap(scale:Number):void {
			var found:Boolean = false;
			var topLine:int = 0;
			var x:int, y:int;
			for(y=0;y<bitmap.bitmapData.height && !found;y++) {
				for(x=0;x<bitmap.bitmapData.width;x++) {
					if(bitmap.bitmapData.getPixel32(x,y)) {
						topLine = y;
						found = true;
						break;
					}
				}
			}
			
			found = false;
			var bottomLine:int = bitmap.bitmapData.height-1;
			for(y=bitmap.bitmapData.height-1;y>=0 && !found;y--) {
				for(x=0;x<bitmap.bitmapData.width;x++) {
					if(bitmap.bitmapData.getPixel32(x,y)) {
						bottomLine = y;
						found = true;
						break;
					}
				}
			}
			
			found = false;
			var leftLine:int = 0;
			for(x=0;x<bitmap.bitmapData.width && !found;x++) {
				for(y=0;y<bitmap.bitmapData.height;y++) {
					if(bitmap.bitmapData.getPixel32(x,y)) {
						leftLine = x;
						found = true;
						break;
					}
				}
			}
			
			found = false;
			var rightLine:int = 0;
			for(x=bitmap.bitmapData.width-1; x>=0 && !found;x--) {
				for(y=0;y<bitmap.bitmapData.height;y++) {
					if(bitmap.bitmapData.getPixel32(x,y)) {
						rightLine = x;
						found = true;
						break;
					}
				}
			}
			
			if(topLine >0 || bottomLine < bitmap.bitmapData.height-1 
					|| leftLine >0 || rightLine < bitmap.bitmapData.width-1) {
				var bitmapData2:BitmapData = new BitmapData(
					rightLine-leftLine+1,
					bottomLine-topLine+1,
					true
				);
				bitmapData2.copyPixels(bitmap.bitmapData,
					new Rectangle(leftLine,topLine,rightLine-leftLine+1,bottomLine-topLine+1),
					new Point()
				);
				bitmap.bitmapData = bitmapData2;
				
				var owner:MovieClip = MovieClip(parent);
				rect = owner.getRect(owner);
				var shift:Point = rect.topLeft;
				rect.left = leftLine/scale + shift.x;
				rect.top = topLine/scale + shift.y;
				rect.right = rightLine/scale + shift.x;
				rect.bottom = bottomLine/scale + shift.y;
			}
		}
		
		private function findTag(tag:String, data:Object) {
			for(var i=0;i<data.sprites.length;i++) {
				if(tag===data.sprites[i][0]) {
					return i;
				}
			}
			return -1;
		}
		
		private function checkTag() {
			var bytes:ByteArray = bitmap.bitmapData.getPixels(bitmap.bitmapData.rect);
			var md5:String = MD5.hashBytes(bytes); //MD5.hashBytes(bytes);
			
			if(tag !== md5) {
				tag = md5;
				if(!savedHash[tag]) {
					saveBytes(tag, bitmap.bitmapData);
					savedHash[tag] = true;
					data.sprites.push([
						tag, 0, 0, bitmap.bitmapData.width, bitmap.bitmapData.height
					]);
				}
			}
			
			var dimdim:Object = {
				frame: frame,
				tag: findTag(md5, data),
				rect: getStageDimension(rect)
			};
			if(dimdim.tag !== dim.tag 
				|| JSON.stringify(dimdim.rect) !== JSON.stringify(dim.rect)
				|| MovieClip(parent).currentLabel !== previousLabel
			) {
				if(MovieClip(parent).currentLabel !== previousLabel) {
					dimdim.label = MovieClip(parent).currentLabel;
					previousLabel = dimdim.label;
				}
				
				if(dim.rect) {
					shape.graphics.lineStyle(1,0xFF0000);
					shape.graphics.moveTo(dim.rect[0][0],dim.rect[0][1]);
					shape.graphics.lineTo(dim.rect[1][0],dim.rect[1][1]);
					shape.graphics.lineTo(dim.rect[2][0],dim.rect[2][1]);
					shape.graphics.lineTo(dim.rect[3][0],dim.rect[3][1]);
					shape.graphics.lineTo(dim.rect[0][0],dim.rect[0][1]);
				}
				stage.addChild(shape);
					
				dim = dimdim;
				addDimension(dimdim);
				
				dim.rect.forEach(function(pos,index,array) {
					maxWidth = Math.max(maxWidth, Math.ceil(pos[0]+1));
					maxHeight = Math.max(maxHeight, Math.ceil(pos[1]+1));					
				});
				data.size = [maxWidth, maxHeight];
			}
			if(frame > data.frameCount) {
				data.frameCount = frame;
				save();
			}
			
		}
		
		private function addDimension(newDim:Object):void {
			data.frames.push(newDim);
			save();
		}
		
		private function save():void {
			var file:File = dir.resolvePath("json").resolvePath(name + ".json");
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeUTFBytes(JSON.stringify(data,null,'\t'));
			fileStream.close();			
		}
		
		private function saveBytes(md5:String, bitmapData:BitmapData):void {
			var file:File = dir.resolvePath("assets").resolvePath(md5+".png");
			if(file.exists) {
				return;
			}
			var bytes:ByteArray = PNG24Encoder.encode(bitmapData);
			
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeBytes(bytes);
			fileStream.close();
		}
		
		private function getStageDimension(rect:Rectangle):Object {
			var r:Rectangle = rect;
			var owner:MovieClip = MovieClip(parent);
			var topLeft:Point = owner.localToGlobal(r.topLeft);
			var topRight:Point = owner.localToGlobal(new Point(r.right,r.top));
			var bottomLeft:Point = owner.localToGlobal(new Point(r.left,r.bottom));
			var bottomRight:Point = owner.localToGlobal(r.bottomRight);
			return [
				[bottomLeft.x,bottomLeft.y],
				[bottomRight.x,bottomRight.y],
				[topRight.x,topRight.y],
				[topLeft.x,topLeft.y]
			];
		}
		
		private function refresh():void {
			var owner:MovieClip = MovieClip(parent);
			rect = owner.getRect(owner);
			var stageRect:Rectangle = owner.getRect(stage);
			var scale:Number = Math.max(
				stageRect.width/rect.width,
				stageRect.height/rect.height
			);
			if(rect.width * scale != tempBitmap.width || rect.height * scale != tempBitmap.height) {
				tempBitmap = new BitmapData(rect.width * scale,rect.height * scale,true);
			}
			tempBitmap.fillRect(tempBitmap.rect,0);
			bitmap.bitmapData = tempBitmap;
			bitmap.bitmapData.draw(
				owner,
				new Matrix(scale,0,0,scale,-rect.left*scale,-rect.top*scale),
				null,
				null,
				null,
				true);
			reduceBitmap(scale);
			checkTag();
			bitmap.alpha = .5;
			bitmap.scaleX = bitmap.scaleY = .5;
			stage.addChild(bitmap);
		}
	}
	
}
