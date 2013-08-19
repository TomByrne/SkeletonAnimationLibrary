package dragonBones.display
{
	/**
	* Copyright 2012-2013. DragonBones. All Rights Reserved.
	* @playerversion Flash 10.0
	* @langversion 3.0
	* @version 2.0
	*/

	
	import dragonBones.objects.DBTransform;
	
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.textures.Texture;
	import dragonBones.display.StarlingMask;
	
	/**
	 * The StarlingDisplayBridge class is an implementation of the IDisplayBridge interface for starling.display.DisplayObject.
	 *
	 */
	public class StarlingDisplayBridge implements IDisplayBridge
	{
		private var _imageBackup:Image;
		private var _textureBackup:Texture;
		private var _pivotXBackup:Number;
		private var _pivotYBackup:Number;
		
		private var _display:Object;
		private var _addedDisplay:Object;
		private var _mask:Object;
		private var _maskWrapper:StarlingMask;
		
		private var _addIndex:int;
		private var _container:Object;
		/**
		 * @inheritDoc
		 */
		public function get display():Object
		{
			return _display;
		}
		public function set display(value:Object):void
		{
			if (_display is Image && value is Image)
			{
				var from:Image = _display as Image;
				var to:Image = value as Image;
				if (from.texture == to.texture)
				{
					if(from == _imageBackup)
					{
						from.texture = _textureBackup;
						from.pivotX = _pivotXBackup;
						from.pivotY = _pivotYBackup;
						from.readjustSize();
					}
					return;
				}
			
				from.texture = to.texture;
				//update pivot
				from.pivotX = to.pivotX;
				from.pivotY = to.pivotY;
				from.readjustSize();
				return;
			}
			
			if (_display == value)
			{
				return;
			}
			
			/*if (_display)
			{
				var parent:* = _display.parent;
				if (parent)
				{
					var index:int = _display.parent.getChildIndex(_display);
				}
				removeDisplay();
			}
			else */if(!_display && value is Image && !_imageBackup)
			{
				_imageBackup = value as Image;
				_textureBackup = _imageBackup.texture;
				_pivotXBackup = _imageBackup.pivotX;
				_pivotYBackup = _imageBackup.pivotY;
			}
			_display = value;
			//addDisplay(parent, index);
			if(_display){
				if (_mask) {
					_maskWrapper.addChild(_display as DisplayObject);
				}else {
					assessDisplay();
				}
			}
		}
		
		public function get visible():Boolean
		{
			return _display?_display.visible:false;
		}
		public function set visible(value:Boolean):void
		{
			if(_display)
			{
				_display.visible = value;
			}
		}
		
		public function get mask():Object
		{
			return _mask;
		}
		public function set mask(value:Object):void
		{
			if (_mask == value)
			{
				return;
			}

			_mask = value as DisplayObject;

			if (_mask)
			{
				if (!_maskWrapper)_maskWrapper = new StarlingMask();

				if (_mask.parent) {
					_mask.parent.removeChild(_mask);
				}
			}
			if (_maskWrapper) _maskWrapper.mask = _mask as DisplayObject;

			assessDisplay();
			if (_mask && _display)
			{
				_maskWrapper.addChild(_display as DisplayObject);
			}
		}
		
		/**
		 * Creates a new StarlingDisplayBridge instance.
		 */
		public function StarlingDisplayBridge()
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
			_display = null;
			_imageBackup = null;
			_textureBackup = null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function updateTransform(matrix:Matrix, transform:DBTransform):void
		{
			var pivotX:Number = _display.pivotX;
			var pivotY:Number = _display.pivotY;
			matrix.tx -= matrix.a * pivotX + matrix.c * pivotY;
			matrix.ty -= matrix.b * pivotX + matrix.d * pivotY;
			//if(updateStarlingDisplay)
			//{
			//	_display.transformationMatrix = matrix;
			//}
			//else
			//{
				_display.transformationMatrix.copyFrom(matrix);
			//}
			if (_maskWrapper)_maskWrapper.invalidate();
		}
		
		/**
		 * @inheritDoc
		 */
		public function updateColor(
			aOffset:Number, 
			rOffset:Number, 
			gOffset:Number, 
			bOffset:Number, 
			aMultiplier:Number, 
			rMultiplier:Number, 
			gMultiplier:Number, 
			bMultiplier:Number
		):void
		{
			if (_display is Quad)
			{
				(_display as Quad).alpha = aMultiplier;
				(_display as Quad).color = (uint(rMultiplier * 0xff) << 16) + (uint(gMultiplier * 0xff) << 8) + uint(bMultiplier * 0xff);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function addDisplay(container:Object, index:int = -1):void
		{
			_container = container;
			_addIndex = index;
			assessDisplay();
		}

		private function assessDisplay():void {
			if (_container) {
				var display:Object;
				if (_mask) {
					display = _maskWrapper;
				}else {
					display = _display;
				}
				if (_addedDisplay == display) return;

				var index:int = _addIndex;
				if (_addedDisplay) {
					index = _addedDisplay.parent.getChildIndex(_addedDisplay);
					_addedDisplay.parent.removeChild(_addedDisplay);
				}
				if (display) {
					if (index == -1) {
						_container.addChild(display);
					}else{
						_container.addChildAt(display, index);
					}
					_addedDisplay = display;
				}

			}else if (_addedDisplay) {
				_addedDisplay.parent.removeChild(_addedDisplay);
				_addedDisplay = null;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeDisplay():void
		{
			if (_display && _display.parent)
			{
				_display.parent.removeChild(_display);
			}
		}
	}
}