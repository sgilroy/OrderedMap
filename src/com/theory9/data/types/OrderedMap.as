/**
 * OrderedMap by TheoryNine
 * Visit us at http://theorynine.com/labs for news, code and more fun toys.
 * Support TheoryNine open-source projects at http://theorynine.com/labs/donations and help keep this and other projects going strong.
 *
 * Copyright (c) 2010 TheoryNine
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 **/

package com.theory9.data.types
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;

	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;

//	[ResourceBundle("collections")]

	/**
	 *  Dispatched when the <code>OrderedMap</code> has been updated in some way.
	 *
	 *  @eventType mx.events.CollectionEvent.COLLECTION_CHANGE
	 */
	[Event(name="collectionChange", type="mx.events.CollectionEvent")]
	public class OrderedMap extends EventDispatcher implements IList
	{
		//--------------------------------------------------------------------------
		//
		//  Class constants
		//
		//--------------------------------------------------------------------------

		/**
		 * The library version (following the format: 'major.minor.incremental').
		 */
		static public const VERSION:String = "1.1.0";

		/**
		 * Return property types.
		 */
		static public const RETURN_PROPERTY_KEY:String = "key";
		static public const RETURN_PROPERTY_VALUE:String = "value";
		static public const RETURN_PROPERTY_LIST:String = "list";
		static public const RETURN_PROPERTY_OBJECT:String = "object";

		//--------------------------------------------------------------------------
		//
		//  Class properties
		//
		//--------------------------------------------------------------------------

		/**
		 * Toggles between throwing errors or tracing them out across all OrderedMap instances.
		 * Set to false, do not throw error, by default.
		 */
		static public var doThrowErrors:Boolean;

		//--------------------------------------------------------------------------
		//
		//  Constants
		//
		//--------------------------------------------------------------------------

		/**
		 * The library version as defined in the class constant by the same name.
		 * This constant is setup for accessibility.
		 */
		public const VERSION:String = OrderedMap.VERSION;

		/**
		 * Error messages.
		 */
		protected const ERROR_ADD_KEY_VALUE_DUPLICATE:String = "Error - OrderedMap 1001: Could not add the key/value pair because the key '[[key]]' already exists.";
		protected const ERROR_REMOVE_KEY_NONE:String = "Error - OrderedMap 1002: Could not remove the key/value pair because the key '[[key]]' does not exist.";
		protected const ERROR_REMOVE_INDEX_NONE:String = "Error - OrderedMap 1003: Could not remove the key/value pair because the index '[[index]]' is out of range and does not exist.";
		protected const ERROR_REMOVE_VALUE_NONE:String = "Error - OrderedMap 1004: Could not remove the key/value pair because the value '[[value]]' does not exist.";

		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------

		/**
		 * Constructor
		 */
		public function OrderedMap(source:Dictionary = null, keyPropertyName:String = "key")
		{
			super();

			_keyPropertyName = keyPropertyName;

			arrayOfKeys = new ArrayCollection();

			if (source)
			{
				_dict = source;
				for each (var item:Object in _dict)
				{
					startTrackUpdates(item);
					arrayOfKeys.addItem(getKey(item));
				}
			}
			else
			{
				//Create dictionary and list of keys objects.
				_dict = new Dictionary();
			}
		}

		//--------------------------------------------------------------------------
		//
		//  Properties
		//
		//--------------------------------------------------------------------------

		/**
		 * The primary means of data storage.
		 */
		private var _dict:Dictionary;

		/**
		 * A list of all the keys that exists in the dictionary in the order they added.
		 */
		public var arrayOfKeys:ArrayCollection;

		private var _keyPropertyName:String;

		/**
		 *  @private
		 *  Used for accessing localized Error messages.
		 */
		private var resourceManager:IResourceManager =
				ResourceManager.getInstance();

		/**
		 *  @private
		 *  Indicates if events should be dispatched.
		 *  calls to enableEvents() and disableEvents() effect the value when == 0
		 *  events should be dispatched.
		 */
		private var _dispatchEvents:int = 0;

		/**
		 * @return The number of items in the map/list.
		 */
		public function get length():int
		{
			return arrayOfKeys.length;
		}

		//--------------------------------------------------------------------------
		//
		//  Public methods
		//
		//--------------------------------------------------------------------------

		/**
		 * Add a key/value pair to the data structure.
		 * @param key The unique identifier for the data.
		 * @param item The data to be stored.
		 * @param override Whether to override the data in the event that the specified key is already in use.
		 * @returnProperty The property to be returned (key, value, list or object).
		 * @return The value, key or both properties of the key/value pair being added -- returns null if index does not exist.
		 */
		public function addKeyValue(key:Object, item:Object, override:Boolean = false,
									returnProperty:String = "value"):*
		{
			// If key does NOT exist yet.
			if (_dict[key] == null)
			{
				//Create entry.
				_dict[key] = item;

				var index:int = arrayOfKeys.length;

				//Add to end of list.
				arrayOfKeys.addItem(key);

				startTrackUpdates(item);
				internalDispatchEvent(CollectionEventKind.ADD, item, index);
			}
			// Else if key exists but value is set to override existing value.
			else if (override)
			{
				var removed:Object = _dict[key];
				stopTrackUpdates(removed);
				var removedIndex:int = getIndexByKey(key);
				internalDispatchEvent(CollectionEventKind.REMOVE, removed, removedIndex);

				//Set value.
				_dict[key] = item;

				startTrackUpdates(item);
				internalDispatchEvent(CollectionEventKind.ADD, item, removedIndex);
			}
			// Else if set to throw errors.
			else if (doThrowErrors)
			{
				throw new Error(ERROR_ADD_KEY_VALUE_DUPLICATE.replace("[[key]]", key));
				return null;
			}
			// Else just trace the error.
			else
			{
				trace(ERROR_ADD_KEY_VALUE_DUPLICATE.replace("[[key]]", key));
				return null;
			}

			return getReturnProperty(returnProperty, key, item);
		}

		/**
		 * Removes the key/value pair from the data structure by key.
		 * @param key The unique identifier for the data.
		 * @returnProperty The property to be returned (key, value, list or object).
		 * @return The value, key or both properties of the key/value pair being removed -- returns null if index does not exist.
		 */
		public function removeByKey(key:Object, returnProperty:String = "value"):*
		{
			var value:Object;

			//If the key exists.
			if (_dict[key] != null)
			{
				var index:int = getIndexByKey(key);

				//Get data.
				value = _dict[key];
				//Clear out data.
				_dict[key] = null;
				delete _dict[key];

				//Iterate over the list of keys.
				for (var i:int = 0; i < arrayOfKeys.length; i++)
				{
					//If key is found.
					if (arrayOfKeys[i] == key)
					{
						//Remove from the list.
						arrayOfKeys.removeItemAt(i);
						break;
					}
				}

				stopTrackUpdates(value);
				internalDispatchEvent(CollectionEventKind.REMOVE, value, index);
			}
			//Else if set to throw errors.
			else if (doThrowErrors)
			{
				throw new Error(ERROR_REMOVE_KEY_NONE.replace("[[key]]", key));
			}
			//Else just trace the error.
			else
			{
				trace(ERROR_REMOVE_KEY_NONE.replace("[[key]]", key));
			}

			//Return the removed value (null if key does not exist).
			return getReturnProperty(returnProperty, key, value);
		}

		/**
		 * Removes the key/value pair from the data structure by index.
		 * @param index The index of the key/value pair.
		 * @returnProperty The property to be returned (key, value, list or object).
		 * @return The value, key or both properties of the key/value pair being removed -- returns null if index does not exist.
		 */
		public function removeByIndex(index:int, returnProperty:String = "value"):*
		{
			var value:Object;
			var key:Object;

			//If within range.
			if (index > -1 && index < arrayOfKeys.length)
			{
				//Set key found at the specified index.
				key = arrayOfKeys[index];

				//Get data.
				value = _dict[key];
				//Clear out data.
				_dict[key] = null;
				delete _dict[key];

				//Remove from the list.
				arrayOfKeys.removeItemAt(index);

				stopTrackUpdates(value);
				internalDispatchEvent(CollectionEventKind.REMOVE, value, index);
			}
			//Else if set to throw errors.
			else if (doThrowErrors)
			{
				throw new Error(ERROR_REMOVE_INDEX_NONE.replace("[[index]]", index));
			}
			//Else just trace the error.
			else
			{
				trace(ERROR_REMOVE_INDEX_NONE.replace("[[index]]", index));
			}

			return getReturnProperty(returnProperty, key, value);
		}

		/**
		 * Removes the key/value pair from the data structure by the first occurance of the value found (there may be more than one occurance of the value).
		 * @param value The data value stored.
		 * @returnProperty The property to be returned (key, value, list or object).
		 * @return The value, key or both properties of the key/value pair being removed -- returns null if index does not exist.
		 */
		public function removeByValue(value:Object, returnProperty:String = "key"):*
		{
			var key:Object;
			var index:int;

			//Iterate over the list of keys.
			for (var i:int = 0; i < arrayOfKeys.length; i++)
			{
				//If value is found.
				if (value == _dict[arrayOfKeys[i]])
				{
					index = i;

					//Set key found at the specified index.
					key = arrayOfKeys[i];
					//Remove from the list.
					arrayOfKeys.removeItemAt(i);
					break;
				}
			}

			//If the key exists.
			if (_dict[key] != null)
			{
				//Clear out data.
				_dict[key] = null;
				delete _dict[key];

				stopTrackUpdates(value);
				internalDispatchEvent(CollectionEventKind.REMOVE, value, index);
			}
			//Else if set to throw errors.
			else if (doThrowErrors)
			{
				throw new Error(ERROR_REMOVE_VALUE_NONE.replace("[[value]]", value));
			}
			//Else just trace the error.
			else
			{
				trace(ERROR_REMOVE_VALUE_NONE.replace("[[value]]", value));
			}

			return getReturnProperty(returnProperty, key, value);
		}

		/**
		 * Gets the index of of the key/value pair by its key.
		 * @param key The unique identifier for the data.
		 * @return The index of the key/value pair.
		 */
		public function getIndexByKey(key:Object):int
		{
			//Iterate over the list of keys.
			for (var i:int = 0; i < arrayOfKeys.length; i++)
			{
				//If the key is found.
				if (key == arrayOfKeys[i])
				{
					return i;
				}
			}

			return -1;
		}

		/**
		 * Determines whether the OrderedMap contains the specified value.
		 * @param value The data value stored.
		 * @return true if the value is in the OrderedMap.
		 */
		public function contains(value:Object):Boolean
		{
			var key:Object = getKey(value);

			return (_dict[key] != null);
		}

		/**
		 * Gets the index of of the key/value pair by the first occurance of the value found (there may be more than one occurance of the value).
		 * @param value The data value stored.
		 * @return The index of the key/value pair.
		 */
		public function getIndexByValue(value:Object):int
		{
			var key:Object = getKey(value);

			// If key does NOT exist
			if (_dict[key] == null)
			{
				return -1;
			}

			//Iterate over the list of keys.
			for (var i:int = 0; i < arrayOfKeys.length; i++)
			{
				//If the value is found.
				if (key == arrayOfKeys[i])
				{
					return i;
				}
			}

			return -1;
		}

		/**
		 * Gets the key of of the key/value pair by its index.
		 * @param index The index of the key/value pair.
		 * @return The key of the key/value pair.
		 */
		public function getKeyByIndex(index:int):*
		{
			return arrayOfKeys[index];
		}

		/**
		 * Gets the key of of the key/value pair by the first occurance of the value found (there may be more than one occurance of the value).
		 * @param value The data value stored.
		 * @return The key of the key/value pair.
		 */
		public function getKeyByValue(value:Object):*
		{
			//Iterate over the dictionary of keys.
			for (var key:Object in _dict)
			{
				//If the value is found.
				if (value == _dict[key])
				{
					return key;
				}
			}

			return null;
		}

		/**
		 * Gets the value of of the key/value pair by its index.
		 * @param index The index of the key/value pair.
		 * @return The value of the key/value pair.
		 */
		public function getValueByIndex(index:int):*
		{
			return _dict[arrayOfKeys[index]];
		}

		/**
		 * Gets the value of of the key/value pair by its key.
		 * @param key The unique identifier for the data.
		 * @return The value of the key/value pair.
		 */
		public function getValueByKey(key:Object):*
		{
			return _dict[key];
		}

		/**
		 * Removes the first element and returns it.
		 * @return The first element.
		 */
		public function shift():*
		{
			return removeItemAt(0);
		}

		/**
		 * Converts the ordered map into an array of arrays consisting of a key and value.
		 * @return Array of data structure.
		 */
		public function toArrayOfArrays():Array
		{
			var list:Array = [];

			//Iterate over keys.
			for (var i:int = 0; i < arrayOfKeys.length; i++)
			{
				//Add key and value array.
				list.push([arrayOfKeys[i], _dict[arrayOfKeys[i]]]);
			}

			return list;
		}

		/**
		 * Converts the ordered map into an array of objects consisting of a key and value.
		 * @return Array of data structure.
		 */
		public function toArrayOfObjects():Array
		{
			var list:Array = [];

			//Iterate over keys.
			for (var i:int = 0; i < arrayOfKeys.length; i++)
			{
				//Add key and value object.
				list.push({key:arrayOfKeys[i], value:_dict[arrayOfKeys[i]]});
			}

			return list;
		}

		/**
		 * Converts the ordered map into an array of the values.
		 * @return Array of values.
		 */
		public function values():Array
		{
			var list:Array = [];

			//Iterate over keys.
			for (var i:int = 0; i < arrayOfKeys.length; i++)
			{
				//Add key and value object.
				list.push(_dict[arrayOfKeys[i]]);
			}

			return list;
		}

		//--------------------------------------------------------------------------
		//
		//  Private methods
		//
		//--------------------------------------------------------------------------

		private function getReturnProperty(type:String, key:Object, value:Object):Object
		{
			//Switch on case insensitive property type.
			switch (type.toLowerCase())
			{
				case "list":
				{
					return [key, value];
				}
				case "object":
				{
					return {key:key, value:value};
				}
				case "key":
				{
					return key;
				}
				default:
				{
					return value;
				}
			}
		}

		public function addItem(item:Object):void
		{
			addItemAt(item, length);
		}

		private function getKey(item:Object):*
		{
			return item && item.hasOwnProperty(keyPropertyName) ? item[keyPropertyName] : null;
		}

		private function get keyPropertyName():String
		{
			return _keyPropertyName;
		}

		public function addItemAt(item:Object, index:int):void
		{
			if (index < 0 || index > length)
			{
				var message:String = resourceManager.getString(
						"collections", "outOfBounds", [ index ]);
				throw new RangeError(message);
			}

			var key:Object = getKey(item);

			// If key does NOT exist yet.
			if (_dict[key] == null)
			{
				// Create entry.
				_dict[key] = item;

				// Add to appropriate position in list
				arrayOfKeys.addItemAt(key, index);

				startTrackUpdates(item);
				internalDispatchEvent(CollectionEventKind.ADD, item, index);
			}
			//Else if set to throw errors.
			else if (doThrowErrors)
			{
				throw new Error(ERROR_ADD_KEY_VALUE_DUPLICATE.replace("[[key]]", key));
			}
			//Else just trace the error.
			else
			{
				trace(ERROR_ADD_KEY_VALUE_DUPLICATE.replace("[[key]]", key));
			}
		}

		public function getItemAt(index:int, prefetch:int = 0):Object
		{
			if (index < 0 || index >= length)
			{
				var message:String = resourceManager.getString(
						"collections", "outOfBounds", [ index ]);
				throw new RangeError(message);
			}

			var key:Object = arrayOfKeys[index];
			return _dict[key];
		}

		public function getItemIndex(item:Object):int
		{
			return getIndexByValue(item);
		}

		public function itemUpdated(item:Object, property:Object = null, oldValue:Object = null,
									newValue:Object = null):void
		{
			var event:PropertyChangeEvent =
					new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE);

			event.kind = PropertyChangeEventKind.UPDATE;
			event.source = item;
			event.property = property;
			event.oldValue = oldValue;
			event.newValue = newValue;

			itemUpdateHandler(event);
		}

		/**
		 *  Enables event dispatch for this list.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		private function enableEvents():void
		{
			_dispatchEvents++;
			if (_dispatchEvents > 0)
				_dispatchEvents = 0;
		}

		/**
		 *  Disables event dispatch for this list.
		 *  To re-enable events call enableEvents(), enableEvents() must be called
		 *  a matching number of times as disableEvents().
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		private function disableEvents():void
		{
			_dispatchEvents--;
		}

		/**
		 *  Called when any of the contained items in the list dispatch an
		 *  ObjectChange event.
		 *  Wraps it in a <code>CollectionEventKind.UPDATE</code> object.
		 *
		 *  @param event The event object for the ObjectChange event.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		protected function itemUpdateHandler(event:PropertyChangeEvent):void
		{
			if (event.property == keyPropertyName)
			{
				updateKey(event.target, event);
			}

			internalDispatchEvent(CollectionEventKind.UPDATE, event);
			// need to dispatch object event now
			if (_dispatchEvents == 0 && hasEventListener(PropertyChangeEvent.PROPERTY_CHANGE))
			{
				var objEvent:PropertyChangeEvent = PropertyChangeEvent(event.clone());
				var index:uint = getItemIndex(event.target);
				objEvent.property = index.toString() + "." + event.property;
				dispatchEvent(objEvent);
			}
		}

		private function updateKey(item:Object, event:PropertyChangeEvent):void
		{
			var oldKey:Object = event.oldValue;
			_dict[oldKey] = null;
			delete _dict[oldKey];

			var key:Object = getKey(item);
			if (_dict[key] != null)
			{
				// another item exists with the same key; remove it so it can be replaced by the updated item
				removeByKey(key);
			}

			_dict[key] = item;

			// we wait to get the index until after the conflicting item is (potentially) removed because the index may change
			var index:uint = getIndexByKey(oldKey);
			arrayOfKeys[index] = key;
		}

		/**
		 *  If the item is an IEventDispatcher, watch it for updates.
		 *  This method is called by the <code>addItemAt()</code> method,
		 *  and when the source is initially assigned.
		 *
		 *  @param item The item passed to the <code>addItemAt()</code> method.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		protected function startTrackUpdates(item:Object):void
		{
			if (item && (item is IEventDispatcher))
			{
				IEventDispatcher(item).addEventListener(
						PropertyChangeEvent.PROPERTY_CHANGE,
						itemUpdateHandler, false, 0, true);
			}
		}

		/**
		 *  If the item is an IEventDispatcher, stop watching it for updates.
		 *  This method is called by the <code>removeItemAt()</code> and
		 *  <code>removeAll()</code> methods, and before a new
		 *  source is assigned.
		 *
		 *  @param item The item passed to the <code>removeItemAt()</code> method.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		protected function stopTrackUpdates(item:Object):void
		{
			if (item && item is IEventDispatcher)
			{
				IEventDispatcher(item).removeEventListener(
						PropertyChangeEvent.PROPERTY_CHANGE,
						itemUpdateHandler);
			}
		}

		/**
		 *  Dispatches a collection event with the specified information.
		 *
		 *  @param kind String indicates what the kind property of the event should be
		 *  @param item Object reference to the item that was added or removed
		 *  @param location int indicating where in the source the item was added.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		private function internalDispatchEvent(kind:String, item:Object = null, location:int = -1):void
		{
			if (_dispatchEvents == 0)
			{
				if (hasEventListener(CollectionEvent.COLLECTION_CHANGE))
				{
					var event:CollectionEvent =
							new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
					event.kind = kind;
					event.items.push(item);
					event.location = location;
					dispatchEvent(event);
				}

				// now dispatch a complementary PropertyChangeEvent
				if (hasEventListener(PropertyChangeEvent.PROPERTY_CHANGE) &&
						(kind == CollectionEventKind.ADD || kind == CollectionEventKind.REMOVE))
				{
					var objEvent:PropertyChangeEvent =
							new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE);
					objEvent.property = location;
					if (kind == CollectionEventKind.ADD)
						objEvent.newValue = item;
					else
						objEvent.oldValue = item;
					dispatchEvent(objEvent);
				}
			}
		}

		public function removeAll():void
		{
			if (length > 0)
			{
				var len:int = length;
				for (var i:int = 0; i < len; i++)
				{
					stopTrackUpdates(getItemAt(i));
				}

				arrayOfKeys.removeAll();
				_dict = new Dictionary();
				internalDispatchEvent(CollectionEventKind.RESET);
			}
		}

		public function removeItemAt(index:int):Object
		{
			if (index < 0 || index > length)
			{
				var message:String = resourceManager.getString(
						"collections", "outOfBounds", [ index ]);
				throw new RangeError(message);
			}

			var key:Object = getKeyByIndex(index);
			var value:Object = getValueByKey(key);

			stopTrackUpdates(value);
			internalDispatchEvent(CollectionEventKind.REMOVE, value, index);

			return value;
		}

		public function setItemAt(item:Object, index:int):Object
		{
			var key:Object = getKey(item);

			if (_dict[key] != null)
			{
				removeByKey(key);
			}
			else if (index != length)
			{
				removeByIndex(index);
			}

			_dict[key] = item;

			arrayOfKeys.addItemAt(key, index);

			startTrackUpdates(item);
			internalDispatchEvent(CollectionEventKind.ADD, item, index);

			return item;
		}

		public function toArray():Array
		{
			return values();
		}

		private function set keyPropertyName(value:String):void
		{
			_keyPropertyName = value;
		}

		public function get dict():Dictionary
		{
			return _dict;
		}

		public function set dict(value:Dictionary):void
		{
			_dict = value;
		}

		public function get source():Dictionary
		{
			return _dict;
		}

		public function set source(value:Dictionary):void
		{
			_dict = value;
		}
	}
}
