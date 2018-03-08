package  {
	
	public class GameData {
		static public var instance:GameData = new GameData();
		
		public var gameStarted:Boolean = false;
		public var position:Object = { x:0, y:0 };
		public var velocity:Object = { x:0, y:0 };
		public var location:Object = { x:0, y:0 };
		public var state:String = null;
		public var checkPoint:Array = null;
		public var hasPlayed:Boolean = false;
		
		public var forcePowers:Object = {
			jump: false,
			push: true
		};
		
		public function clear():void {
			gameStarted = false;
			checkPoint = null;
			state = null;
		}
		
		public function ensureLocation(sceneName:String):void {
		}
	}
	
}
