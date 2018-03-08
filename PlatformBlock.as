package  {
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	
	public class PlatformBlock extends StaticBlock {
		static private var pMap:Object = {};
		
		private function get intX():int {
			return Math.floor(posX / width);
		}
		
		private function get intY():int {
			return Math.floor(posY / height);
		}

		var timeout:int = 0;
		public function set indexImage(value:int):void {
			if(!timeout) {
				gotoAndStop(value+1);
			}
			clearTimeout(timeout);
			timeout = setTimeout(fun,0,value+1);
		}
		
		private function fun(frame:int):void {
			gotoAndStop(frame);
			timeout = 0;
		}
		
		public function hasP(iX:int, iY:int):Boolean {
			var p:PlatformBlock = getP(iX,iY);
			return p && (Math.abs(this.posX - p.posX) < width+3 && Math.abs(this.posY - p.posY) < height+3);
		}
		
		static private function updateIndex(iX:int, iY:int):void {
			var p:PlatformBlock = getP(iX,iY);
			if(p) {
				var index:int = 0;
				if(p.hasP(iX,iY-1)) index += 1;
				if(p.hasP(iX+1,iY)) index += 2;
				if(p.hasP(iX,iY+1)) index += 4;
				if(p.hasP(iX-1,iY)) index += 8;
				p.indexImage = index;
			}
		}
		
		static private function getP(x:int, y:int):PlatformBlock {
			return pMap[x+"_"+y];
		}
		
		override protected function onStage(e:Event):void {
			super.onStage(e);
			holes.gotoAndStop(Math.floor(Math.random()*holes.totalFrames)+1);
			stop();
			pMap[intX+"_"+intY] = this;
			updateIndex(intX,intY);
			updateIndex(intX-1,intY);
			updateIndex(intX+1,intY);
			updateIndex(intX,intY-1);
			updateIndex(intX,intY+1);
		}
		
		override protected function offStage(e:Event):void {			
			if(getP(intX,intY) === this) {
				delete pMap[intX+"_"+intY];
			}			
			super.offStage(e);
		}	
	}
	
}
