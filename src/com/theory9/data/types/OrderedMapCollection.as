package com.theory9.data.types
{
////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2005-2007 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

	import flash.utils.Dictionary;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;

	import mx.collections.ListCollectionView;
	import mx.core.mx_internal;

	use namespace mx_internal;

	[DefaultProperty("source")]

	[RemoteClass(alias="com.theory9.data.types.OrderedMapCollection")]

	/**
	 *  The OrderedMapCollection class is a wrapper class that exposes an OrderedMap as
	 *  a collection that can be accessed and manipulated using the methods
	 *  and properties of the <code>ICollectionView</code> or <code>IList</code>
	 *  interfaces. Operations on a OrderedMapCollection instance modify the data source;
	 *  for example, if you use the <code>removeItemAt()</code> method on an
	 *  OrderedMapCollection, you remove the item from the underlying OrderedMap.
	 *
	 *  @mxml
	 *
	 *  <p>The <code>&lt;mx:OrderedMapCollection&gt;</code> tag inherits all the attributes of its
	 *  superclass, and adds the following attributes:</p>
	 *
	 *  <pre>
	 *  &lt;mx:OrderedMapCollection
	 *  <b>Properties</b>
	 *  source="null"
	 *  /&gt;
	 *  </pre>
	 *
	 *  @example The following code creates a simple OrderedMapCollection object that
	 *  accesses and manipulates an array with a single Object element.
	 *  It retrieves the element using the IList interface <code>getItemAt</code>
	 *  method and an IViewCursor object that it obtains using the ICollectionView
	 *  <code>createCursor</code> method.
	 *  <pre>
	 *  var myCollection:OrderedMapCollection = new OrderedMapCollection([ { first: 'Matt', last: 'Matthews' } ]);
	 *  var myCursor:IViewCursor = myCollection.createCursor();
	 *  var firstItem:Object = myCollection.getItemAt(0);
	 *  var firstItemFromCursor:Object = myCursor.current;
	 *  if (firstItem == firstItemFromCursor)
	 *        doCelebration();
	 *  </pre>
	 *
	 *  @langversion 3.0
	 *  @playerversion Flash 9
	 *  @playerversion AIR 1.1
	 *  @productversion Flex 3
	 */
	public class OrderedMapCollection extends ListCollectionView implements IExternalizable
	{
		private var _keyPropertyName:String;

		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------

		/**
		 *  Constructor.
		 *
		 *  <p>Creates a new OrderedMapCollection using the specified source array.
		 *  If no array is specified an empty array will be used.</p>
		 *
		 *  @param source The source Array.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function OrderedMapCollection(source:Dictionary = null, keyPropertyName:String = "key")
		{
			super();

			_keyPropertyName = keyPropertyName;
			this.source = source;
		}

		//--------------------------------------------------------------------------
		//
		//  Properties
		//
		//--------------------------------------------------------------------------

		//----------------------------------
		//  source
		//----------------------------------

		[Inspectable(category="General", arrayType="Object")]
		[Bindable("listChanged")]
		//superclass will fire this

		/**
		 *  The source of data in the OrderedMapCollection.
		 *  The OrderedMapCollection object does not represent any changes that you make
		 *  directly to the source array. Always use
		 *  the ICollectionView or IList methods to modify the collection.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get source():Dictionary
		{
			if (list && (list is OrderedMap))
			{
				return OrderedMap(list).source;
			}
			return null;
		}

		/**
		 *  @private
		 */
		public function set source(s:Dictionary):void
		{
			list = new OrderedMap(s, _keyPropertyName);
		}

		//--------------------------------------------------------------------------
		//
		//  Methods
		//
		//--------------------------------------------------------------------------

		/**
		 *  @private
		 *  Ensures that only the source property is serialized.
		 */
		public function readExternal(input:IDataInput):void
		{
			if (list is IExternalizable)
				IExternalizable(list).readExternal(input);
			else
				source = input.readObject() as Dictionary;
		}

		/**
		 *  @private
		 *  Ensures that only the source property is serialized.
		 */
		public function writeExternal(output:IDataOutput):void
		{
			if (list is IExternalizable)
				IExternalizable(list).writeExternal(output);
			else
				output.writeObject(source);
		}

		override public function contains(item:Object):Boolean
		{
			return OrderedMap(list).getIndexByValue(item) != -1;
		}
	}

}
