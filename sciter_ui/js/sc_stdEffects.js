
var acceptMovedElements=new Array();

function movable() // install movable window handler
  {    
    var xoff,yoff;
    var dragging = false;
    var body = $(body);
	var div = $(div);
      
    function doDrag()
    { //w_pLogStr("view.root.  doDrag");
      while( dragging )
        view.doEvent();
    }
      
    function onMouseDown(evt)
    {  
      if( evt.target!==null)
	   { //w_pLogStr("view.root.  onMouseDown  target="+evt.target.id);
	     //  w_pLog(evt.target);
	    var il=acceptMovedElements.indexOf(evt.target);
		if (il<0) { return false;}
		}
      xoff = evt.x;
      yoff = evt.y;
      dragging = true;
      view.root.capture(true);
      doDrag();
      return true;
    }
      
    function onMouseMove(evt)
    {
      if( dragging )
      {
        view.move( evt.xScreen - xoff, evt.yScreen - yoff, true); // true - x,y are coordinates of the client area on the screen
        return true;
      }
	  else {
	         
	        }
      return false;
    }
      
    function stopDrag()
    {
      if(dragging)
      {
        dragging = false;
        view.root.capture(false);
        return true;
      }
      return false;
    }
    
    //    function onMouseDown1(evt){ w_pLogStr("view. onMouseDown1"); }
	
    function onMouseUp(evt) { return stopDrag(); // w_pLogStr("view.root.  onMouseUp"); 
	                         }
    function onKeyDown(evt) { if(evt.keyCode == Event.VK_ESCAPE ) return stopDrag(); }
      
    // hookup event handlers:
    view.root.subscribe(onMouseDown, Event.MOUSE, Event.MOUSE_DOWN );
    view.root.subscribe(onMouseUp, Event.MOUSE, Event.MOUSE_UP );
    view.root.subscribe(onMouseMove, Event.MOUSE, Event.MOUSE_MOVE );
    view.root.subscribe(onKeyDown, Event.KEY, Event.KEY_DOWN );
	
	// view.subscrube(onMouseDown1,Event.MOUSE, Event.MOUSE_DOWN);
	
    return false;
  }
  
//  CALL ! 
 
 movable();