package bubblebobble.editor;

import bubblebobble.dialogs.ActorsDialog;
import bubblebobble.dialogs.TilesDialog;
import bubblebobble.dialogs.ItemContainer;
import com.tyrannotorus.utils.Colors;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;

/**
 * LevelEditor.as
 * - A Level editor.
 */
class LevelEditor extends Sprite {
	
	// States
	private static inline var DRAG_ACTOR:String = "DRAG_ACTOR";
	private static inline var PLACE_TILE:String = "PLACE_TILE";
	
	private var state:String;
	private var levelLayer:Sprite;
	private var largeTilesLayer:Sprite;
	private var smallTilesLayer:Sprite;
	private var actorsLayer:Sprite;
	private var dialogLayer:Sprite;

	private var tilesDialog:TilesDialog;
	private var actorsDialog:ActorsDialog;
	private var selectedTile:Bitmap;
	private var selectedActor:Actor;
	private var selectedActorDragged:Bool;
	private var largeTilesArray:Array<Array<Sprite>> = new Array<Array<Sprite>>();
	private var smallTilesArray:Array<Array<Sprite>> = new Array<Array<Sprite>>();
	
	/**
	 * Constructor.
	 */
	public function new() {
		
		super();
		
		// Create the level layer with black background.
		levelLayer = new Sprite();
		levelLayer.graphics.beginFill(Colors.BLACK);
		levelLayer.graphics.drawRect(0, 0, Main.GAME_WIDTH, Main.GAME_HEIGHT);
		levelLayer.graphics.endFill();
		addChild(levelLayer);
		
		// Create the tiles layers.
		largeTilesLayer = new Sprite();
		addChild(largeTilesLayer);
		smallTilesLayer = new Sprite();
		addChild(smallTilesLayer);
		
		actorsLayer = new Sprite();
		addChild(actorsLayer);
				
		// Create the dialog layer.
		dialogLayer = new Sprite();
		addChild(dialogLayer);
		
		// Create and add the tiles dialog.
		tilesDialog = new TilesDialog();
		tilesDialog.loadTiles();
		dialogLayer.addChild(tilesDialog);
		
		// Create and add the actors dialog.
		actorsDialog = new ActorsDialog();
		actorsDialog.loadActors();
		dialogLayer.addChild(actorsDialog);
		
		actorsDialog.addEventListener(MouseEvent.ROLL_OUT, onMouseRollOut);
		actorsDialog.addEventListener(MouseEvent.ROLL_OVER, onMouseRollOver);
		this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		this.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		this.addEventListener(MouseEvent.ROLL_OUT, onMouseUp);
		this.addEventListener(Event.MOUSE_LEAVE, onMouseUp);
	}
	
	/**
	 * If we're dragging an actor, bring the character in from the field.
	 * @param {MouseEvent.ROLL_OVER} e
	 */
	private function onMouseRollOver(e:MouseEvent):Void {
		trace("onMouseRollOver");
		
		if (state == DRAG_ACTOR) {
			
			// The character has been dragged.
			if (selectedActor != null) {
				selectedActor.startDrag(true);
				addChild(selectedActor);
			}
		
		}		
		
	}
	
	/**
	 * If we're dragging an actor, put the character in the field.
	 * @param {MouseEvent.ROLL_OUT} e
	 */
	private function onMouseRollOut(e:MouseEvent):Void {
		
		trace("onMouseRollOut");
		
		if (state == DRAG_ACTOR) {
			
			// The character has been dragged.
			if (selectedActor != null) {
				selectedActor.stopDrag();
				actorsLayer.addChild(selectedActor);
				trace("onMouseRollOut adding to actors layer");
			}
		
		}		
		
	}
	
	/**
	 * A Tile was selected within the tiles dialog.
	 * @param {MouseEvent.CLICK} e
	 */
	private function onMouseDown(e:MouseEvent):Void {
		
		trace("onMouseDown() " + e.target + " " + e.currentTarget);
		
		destroyActor();
		
				
		selectedTile = null;
		state = null;
		
		// User has mouseDowned on an actor.
		if (Std.is(e.target, Actor)) {
			
			trace(e.target.parent);
			
			// Actor has been added to the level previously. Begin relocation.
			if (e.target.parent == actorsLayer) {
				selectedActor = cast(e.target, Actor);
							
			// Actor is being dragged from actors menu.
			} else {
				selectedActor = actorsDialog.getActor(e.target);
			}
						
			state = DRAG_ACTOR;
			selectedActorDragged = false;
			actorsDialog.mouseChildren = false;
								
		} else {
			state = null;
		}
	}
	
	/**
	 * User has mouse upped.
	 * @param {MouseEvent.MOUSE_UP} e
	 */
	private function onMouseUp(e:Event):Void {
		trace("onMouseUp() " + state + " " + e.target + " " + e.currentTarget);
		
		actorsDialog.mouseChildren = true;
		
		if (state == DRAG_ACTOR) {
			
			// The character has been dragged.
			if (selectedActorDragged) {
				
				selectedActor.mouseEnabled = true;
				selectedActor.mouseChildren = true;
								
				// Drop the character back into the inventory.
				if (Std.is(e.target, ActorsDialog)) {
					destroyActor();
				}
			
			// Actor was clicked, not dragged. Flip him horizontally.
			} else if(!Std.is(selectedActor.parent, ItemContainer)){
				selectedActor.scaleX *= -1;
			}
			
			selectedActor = null;
			selectedActorDragged = false;
			state = null;
		}
	}
	
	private function destroyActor():Void {
		
		if (selectedActor != null) {
			
			if (selectedActor.parent != null) {
				selectedActor.parent.removeChild(selectedActor);
			}
				
			selectedActor.stopDrag();
			actorsDialog.removeActor(selectedActor);
		}
		
		selectedActor = null;
		selectedActorDragged = false;
	}
	
	/**
	 * A Tile was selected within the tiles dialog.
	 * @param {MouseEvent.CLICK} e
	 */
	private function onMouseMove(e:MouseEvent):Void {
		
		if (state == DRAG_ACTOR) {
			
			// The user has begun dragging the character.
			if (!selectedActorDragged) {
				
				selectedActor.mouseEnabled = false;
				selectedActor.mouseChildren = false;
				selectedActorDragged = true;
				
				if (selectedActor.parent != actorsLayer) {
					selectedActor.startDrag(true);
					addChild(selectedActor);
				}
			}
			
			if(selectedActor.parent == actorsLayer) {
				
				var x:Float = Math.floor(actorsLayer.mouseX / 8) * 8;
				selectedActor.x = (x <= 0) ? 8 : (x < Main.GAME_WIDTH) ? x : Main.GAME_WIDTH - 8;
				
				var y:Float = Math.floor(actorsLayer.mouseY / 8) * 8;
				selectedActor.y = (y < this.y) ? this.y : (y >= Main.GAME_HEIGHT - this.y) ? Main.GAME_HEIGHT - this.y : y;
			}
		}
	}
	
	/**
	 * A Tile was selected within the tiles dialog.
	 * @param {MouseEvent.CLICK} e
	 */
	private function setTileState(e:MouseEvent):Void {
		e.stopImmediatePropagation();
		selectedTile = tilesDialog.getSelectedTile();
		state = PLACE_TILE;
	}
	
	/**
	 * 
	 */
	private function onActorMouseDown(e:MouseEvent):Void {
		e.stopImmediatePropagation();
		if (Std.is(e.target, Actor)) {
			
			
		}
	}
	
	
	/**
	 * Mouse Downed over an actor.
	 * @param {MouseEvent.MOUSE_DOWN} e
	 */
	private function setActorState(e:MouseEvent):Void {
		
		trace("onActorsDialogClick()");
		
		e.stopImmediatePropagation();
		
		selectedActor = actorsDialog.getActor(e.target);
		
		if (selectedActor != null) {
			selectedTile = null;
			addChild(selectedActor);
			selectedActor.mouseChildren = false;
			selectedActor.mouseEnabled = false;
			selectedActor.startDrag(true);
			
		}
	}
	
	
	
	private function onActorDrag(e:MouseEvent = null):Void {
		
		selectedActor.x = Math.floor(selectedActor.x / 8) * 8;
		selectedActor.y = Math.floor(selectedActor.y / 8) * 8;
		
		if (selectedActor.y < 0) {
			selectedActor.y = 0;
		}
	}
	
	private function onStopActorDrag(e:MouseEvent):Void {
		trace("onMouseUp");
		onActorDrag();
		selectedActor.stopDrag();
		selectedActor.mouseChildren = true;
		selectedActor.mouseEnabled = true;
		actorsLayer.addChild(selectedActor);
		selectedActor = null;
	}
	
	/**
	 * User has mouse downed over the stage.
	 * @param {MouseEvent.MOUSE_DOWN} e
	 */
	private function onTileMouseDown(e:MouseEvent):Void {
		
		if (selectedTile == null) {
			e.stopImmediatePropagation();
			return;
		}
				
		placeTile(levelLayer.mouseX, levelLayer.mouseY);
		
	}
	
	/**
	 * User is placing tiles on the level.
	 * @param {MouseEvent.MOUSE_MOVE} e
	 */
	private function onTileMouseMove(e:MouseEvent):Void {
		placeTile(levelLayer.mouseX, levelLayer.mouseY);
	}
	
	/**
	 * Place our selected tile on the stage.
	 * @param {Float} x
	 * @param {Float} y
	 */
	private function placeTile(x:Float, y:Float):Void {
		
		var tileWidth:Int = Std.int(selectedTile.width);
		var tileX:Int = Math.floor(x / tileWidth) * tileWidth;
		var tileY:Int = Math.floor(y / tileWidth) * tileWidth;
		var tilesArray:Array<Array<Sprite>>;
		var tilesLayer:Sprite;
		
		if (tileWidth == 8) {
			tilesArray = smallTilesArray;
			tilesLayer = smallTilesLayer;
		
		} else {
			tilesArray = largeTilesArray;
			tilesLayer = largeTilesLayer;
		}
		
		if (tilesArray[tileX] == null) {
			tilesArray[tileX] = new Array<Sprite>();
		}
		
		var tileSprite:Sprite = tilesArray[tileX][tileY];
		var tileBitmap:Bitmap;
				
		if (tileSprite == null) {
			tileBitmap = new Bitmap();
			tileSprite = new Sprite();
			tileSprite.mouseChildren = false;
			tileSprite.mouseEnabled = true;
			tileSprite.addChild(tileBitmap);
			tileSprite.x = tileX;
			tileSprite.y = tileY;
			tilesArray[tileX][tileY] = tileSprite;
			tilesLayer.addChild(tileSprite);
		
		} else {
			tileBitmap = cast(tileSprite.getChildAt(0), Bitmap);
		}
		
		if (tileWidth == 16) {
			removeTile(smallTilesArray, smallTilesLayer, tileX, tileY);
			removeTile(smallTilesArray, smallTilesLayer, tileX + 8, tileY);
			removeTile(smallTilesArray, smallTilesLayer, tileX, tileY + 8);
			removeTile(smallTilesArray, smallTilesLayer, tileX + 8, tileY + 8);
		}
		
		tileBitmap.bitmapData = selectedTile.bitmapData;
	}
	
	/**
	 * Removes a tile at from paramters position.
	 * @param {Int} tileX
	 * @param {Int} tileY
	 */
	private function removeTile(tilesArray:Array<Array<Sprite>>, tilesLayer:Sprite, tileX:Int, tileY:Int):Void {
		if (tilesArray[tileX] != null && tilesArray[tileX][tileY] != null) {
			tilesLayer.removeChild(tilesArray[tileX][tileY]);
			tilesArray[tileX][tileY] = null;
		}
	}
	
		
	private function onMouseClick(e:MouseEvent):Void {
		if (Std.is(e.target, Actor)) {
			var actor:Actor = cast(e.target, Actor);
			actor.scaleX *= -1;
		}
	}
	
	
	
}
