package  {
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.display.Stage;
	
	public class Element extends MovieClip {

		protected var myStage:Stage;
		public var index:int = -1;
		static private var registry:Array = [];
		
		public function Element() {
			this.addEventListener(Event.ADDED_TO_STAGE, onStage);
			this.addEventListener(Event.REMOVED_FROM_STAGE, offStage);
		}
		
		protected function onStage(e:Event):void {
			myStage = stage;
			index = registry.length;
			registry.push(this);
		}
		
		protected function offStage(e:Event):void {
			if(registry.length>0) {
				registry[index] = registry[registry.length-1];
				registry[index].index = index;				
				registry.pop();
			}
			index = -1;
			myStage = null;
		}
		
		static public function elements():Array {
			return registry;
		}
	}
}
