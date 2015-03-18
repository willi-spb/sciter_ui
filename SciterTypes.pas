unit SciterTypes;

interface
uses windows, System.SysUtils;

const

  HANDLE_INITIALIZATION = $0000; //** attached/detached */
  HANDLE_MOUSE = $0001;          //** mouse events */
  HANDLE_KEY = $0002;            //** key events */
  HANDLE_FOCUS = $0004;          //** focus events, if this flag is set it also means that element it attached to is focusable */
  HANDLE_SCROLL = $0008;         //** scroll events */
  HANDLE_DRAW = $0040;           /// ** draw event   -> willi adding
  HANDLE_TIMER = $0010;          //** timer event */
  HANDLE_SIZE = $0020;           //** size changed event */
  HANDLE_DATA_ARRIVED = $080;    //** requested data () has been delivered */
  HANDLE_BEHAVIOR_EVENT        = $0100; //** logical, synthetic events:
                                         //    BUTTON_CLICK, HYPERLINK_CLICK, etc.,
                                         //    a.k.a. notifications from intrinsic behaviors */
  HANDLE_METHOD_CALL           = $0200; //** behavior specific methods */
  HANDLE_SCRIPTING_METHOD_CALL = $0400; //** behavior specific methods */
  HANDLE_TISCRIPT_METHOD_CALL  = $0800; //** behavior specific methods using direct tiscript::value's */

  HANDLE_EXCHANGE              = $1000; //** system drag-n-drop */
  HANDLE_GESTURE               = $2000; //** touch input events */

  HANDLE_ALL                   = $FFFF; //* all of them */

  SUBSCRIPTIONS_REQUEST        = $FFFFFFFF; //** special value for getting subscription flags */


  BEHAVIOR_DETACH = 0;
  BEHAVIOR_ATTACH = 1;

  //  This notification gives application a chance to override built-in loader and
// implement loading of resources in its own way (for example images can be loaded from database or other resource)
  SC_LOAD_DATA       = 1;
//This notification indicates that external data (for example image) download process completed.
// This notifiaction is sent for each external resource used by document when
// this resource has been completely downloaded. Sciter will send this notification asynchronously.
  SC_DATA_LOADED     = 2;
//This notification is sent on parsing the document and while processing  * elements having non empty style.behavior attribute value.
//Application has to provide implementation of #sciter::behavior interface. Set #SCN_ATTACH_BEHAVIOR::impl to address of this implementation.
SC_ATTACH_BEHAVIOR   = 4;
//This notification is sent when instance of the engine is destroyed. It is always final notification.
SC_ENGINE_DESTROYED  = 5;

/// Options for Sciter set
type
    SCITER_RT_OPTIONS=(
    SCITER_NO =0,
    SCITER_SMOOTH_SCROLL = 1, // value:TRUE - enable, value:FALSE - disable, enabled by default
    SCITER_CONNECTION_TIMEOUT = 2, // value: milliseconds, connection timeout of http client
    SCITER_HTTPS_ERROR = 3, // value: 0 - drop connection, 1 - use builtin dialog, 2 - accept connection silently
    SCITER_FONT_SMOOTHING = 4, // value: 0 - system default, 1 - no smoothing, 2 - std smoothing, 3 - clear type
    SCITER_TRANSPARENT_WINDOW = 6, // Windows Aero support, value:
    // 0 - normal drawing,
    // 1 - window has transparent background after calls DwmExtendFrameIntoClientArea() or DwmEnableBlurBehindWindow().
    SCITER_SET_GPU_BLACKLIST = 7, // hWnd = NULL,
    // value = LPCBYTE, json - GPU black list, see: gpu-blacklist.json resource.
    SCITER_SET_SCRIPT_RUNTIME_FEATURES = 8, // value - combination of SCRIPT_RUNTIME_FEATURES flags.
    SCITER_SET_GFX_LAYER = 9); // hWnd = NULL, value - GFX_LAYER

/// adding for options   1
 GFX_LAYER=(
GFX_LAYER_GDI = 1,
GFX_LAYER_WARP = 2,
GFX_LAYER_D2D = 3,
GFX_LAYER_AUTO = $FFFF);
/// adding for options   2
 SCRIPT_RUNTIME_FEATURES=
(ALLOW_FILE_IO = $00000001,
ALLOW_SOCKET_IO = $00000002,
ALLOW_EVAL = $00000004,
ALLOW_SYSINFO = $00000008
);

///

type
TSCITER_EVENTS = (
  eOnClick,
  eOnDblClick,
  eOnMouseEnter,
  eOnMouseLeave,
  eOnMouseMove,
  eOnMouseDown,
  eOnMouseUP,
  eOnMouseWheel,
  eOnMouseIdle,// ( mouse stay idle for some time)
  eOnDrop,
  eOnDragEnter,
  eOnDragLeave,
  //Keys
  eOnKeyDown,
  eOnKeyUp,
  eOnKeyChar,
  ///
  eOnSetFocus,
  eOnLostFocus,
  //Scroll
  eOnScroll,
  eOnDrawBackGround,
  eOnDrawContent,
  eOnDrawForeground,
  //Gesture
  eOnGesture,
  //Timer
  eOnTimer,
  //Size
  eOnSizeChanged,
  //other
  eOnBehavior,// (component-specific events)
  eOnScrypt,
  eOnOther    //  willi -> b.s. none param
);

 TElementEvents = record
    UID: UINT;
    events: array[0..Integer(eOnOther)] of Pointer;
 end;


  PSCITER_VALUE = ^SCITER_VALUE;
  SCITER_VALUE = record
   t: UINT;
   u: UINT;
   d: UINT64;
  end;

VALUE_TYPE = (
    T_UNDEFINED = 0,
    T_NULL = 1,
    T_BOOL,
    T_INT,
    T_FLOAT,
    T_STRING,
    T_DATE,     // INT64 - contains a 64-bit value representing the number of 100-nanosecond intervals since January 1, 1601 (UTC), a.k.a. FILETIME on Windows
    T_CURRENCY, // INT64 - 14.4 fixed number. E.g. dollars = int64 / 10000;
    T_LENGTH,   // length units, value is int or float, units are VALUE_UNIT_TYPE
    T_ARRAY,
    T_MAP,
    T_FUNCTION,
    T_BYTES,      // sequence of bytes - e.g. image data
    T_OBJECT,     // scripting object proxy (TISCRIPT/SCITER)
    T_DOM_OBJECT  // DOM object (CSSS!), use get_object_data to get HELEMENT
);

  psc_VALUE = ^sc_VALUE;
  sc_VALUE = packed record
   pval: PSCITER_VALUE;
  public
   class function Create(): sc_VALUE; overload; static;
   constructor Create(str: string); overload;

   class operator Implicit(AVar: sc_VALUE): String;
   class operator Implicit(AVar: sc_VALUE): Integer;
   class operator Implicit(AVar: sc_VALUE): Int64;

   function GetType: VALUE_TYPE;
  end;


ElementID = UINT;
HELEMENT = packed record
    pval: pointer;
   public
     class operator Implicit(AVar: HELEMENT): ElementID;
     function toUID: ElementID;
end;

TElementsEvents = record
    hItems: array of TElementEvents;
  public
    procedure SetEvent(elm: HELEMENT; etype: TSCITER_EVENTS; evt: Pointer );
    procedure ReleaseEvent(elm: HELEMENT; etype: TSCITER_EVENTS);
    function Assigned(elm: HELEMENT; etype: TSCITER_EVENTS): BOOL;
    function FindEvent(elm: HELEMENT; etype: TSCITER_EVENTS): Pointer;
end;

THELEMENT_Func = reference to procedure(itm: HELEMENT);

HELEMENTS = packed record
   hItems: array of HELEMENT;
  private
    function Get(Index: Integer): HELEMENT;
    procedure Put(Index: Integer; const Value: HELEMENT);
  public
   procedure add(elm: HELEMENT);
   procedure Foreach(proc: THELEMENT_Func);
   property Items[Index: Integer]: HELEMENT read Get write Put; default;
end;


  PINITIALIZATION_PARAMS = ^INITIALIZATION_PARAMS;
  INITIALIZATION_PARAMS = packed record
      cmd: UINT;          // INITIALIZATION_EVENTS
  end;

  MOUSE_EVENTS = (
      MOUSE_ENTER = 0,
      MOUSE_LEAVE = 1,
      MOUSE_MOVE = 2,
      MOUSE_UP = 3,
      MOUSE_DOWN = 4,
      MOUSE_DCLICK = 5,
      MOUSE_WHEEL = 6,
      MOUSE_TICK = 7, // mouse pressed ticks
      MOUSE_IDLE = 8, // mouse stay idle for some time
      DROP        = 9,   // item dropped, target is that dropped item
      DRAG_ENTER  = 10, // drag arrived to the target element that is one of current drop targets.
      DRAG_LEAVE  = 11, // drag left one of current drop targets. target is the drop target element.
      DRAG_REQUEST = 12,  // drag src notification before drag start. To cancel - return true from handler.
      MOUSE_CLICK = $FF, // mouse click event
      DRAGGING = $100 // This flag is 'ORed' with MOUSE_ENTER..MOUSE_DOWN codes if dragging operation is in effect.
                        // E.g. event DRAGGING | MOUSE_MOVE is sent to underlying DOM elements while dragging.
  );


  PMOUSE_PARAMS = ^MOUSE_PARAMS;
  MOUSE_PARAMS = record
      cmd: UINT;             // MOUSE_EVENTS
      target: HELEMENT;      // target element
      pos: TPOINT;           // position of cursor, element relative
      pos_view: TPOINT;      // position of cursor, view relative
      button_state: UINT;    // MOUSE_BUTTONS or MOUSE_WHEEL_DELTA
      alt_state: UINT;       // KEYBOARD_STATES
      cursor_type: UINT;     // CURSOR_TYPE to set, see CURSOR_TYPE
      is_on_icon: Integer;   // mouse is over icon (foreground-image, foreground-repeat:no-repeat)

      dragging: HELEMENT;     // element that is being dragged over, this field is not NULL if (cmd & DRAGGING) != 0
      dragging_mode: UINT;   // see DRAGGING_TYPE.
  end;

  KEY_EVENTS=(
     KEY_DOWN = 0,
     KEY_UP,
     KEY_CHAR);

  PKEY_PARAMS = ^KEY_PARAMS;
  KEY_PARAMS = packed record
      cmd: UINT;          // KEY_EVENTS
      target: HELEMENT;       // target element
      key_code: UINT;     // key scan code, or character unicode for KEY_CHAR
      alt_state: UINT;    // KEYBOARD_STATES
  end;

PDRAW_PARAMS=^DRAW_PARAMS;
DRAW_PARAMS=packed record
 cmd: UINT; // DRAW_EVENTS
 hdc: HDC; // hdc to paint on
 area: TRECT; // element area, to get invalid area to paint use GetClipBox,
 reserved:UINT; // for DRAW_BACKGROUND/DRAW_FOREGROUND - it is a border box
                // for DRAW_CONTENT - it is a content box
end;

 FOCUS_EVENTS=(
   FOCUS_LOST = 0,
   FOCUS_GOT = 1);


  PFOCUS_PARAMS = ^FOCUS_PARAMS;
  FOCUS_PARAMS = packed record
      cmd: UINT;            // FOCUS_EVENTS
      target: HELEMENT;         // target element, for FOCUS_LOST it is a handle of new focus element
                      // and for FOCUS_GOT it is a handle of old focus element, can be NULL
      by_mouse_click: Integer; // TRUE if focus is being set by mouse click
      cancel: Integer;         // in FOCUS_LOST phase setting this field to TRUE will cancel transfer focus from old element to the new one.
 end;

  PTIMER_PARAMS = ^TIMER_PARAMS;
  TIMER_PARAMS = packed record
      timerId: UINT_PTR;
  end;

  PBEHAVIOR_EVENT_PARAMS = ^BEHAVIOR_EVENT_PARAMS;
  BEHAVIOR_EVENT_PARAMS = packed record
      cmd: UINT;        // BEHAVIOR_EVENTS
      heTarget: HELEMENT;   // target element handler
      he: HELEMENT;         // source element e.g. in SELECTION_CHANGED it is new selected <option>, in MENU_ITEM_CLICK it is menu item (LI) element
      reason: UINT;     // EVENT_REASON or EDIT_CHANGED_REASON - UI action causing change.
                  // In case of custom event notifications this may be any
                  // application specific value.

//      data: JSON_VALUE;       // auxiliary data accompanied with the event. E.g. FORM_SUBMIT event is using this field to pass collection of values.
  end;


  PDATA_ARRIVED_PARAMS = ^DATA_ARRIVED_PARAMS;
  DATA_ARRIVED_PARAMS = packed record
  end;

  SCROLL_EVENTS=(
        SCROLL_HOME = 0,
        SCROLL_END,
        SCROLL_STEP_PLUS,
        SCROLL_STEP_MINUS,
        SCROLL_PAGE_PLUS,
        SCROLL_PAGE_MINUS,
        SCROLL_POS,
        SCROLL_SLIDER_RELEASED,
        SCROLL_CORNER_PRESSED,
        SCROLL_CORNER_RELEASED);

  PSCROLL_PARAMS = ^SCROLL_PARAMS;
  SCROLL_PARAMS = packed record
      cmd: UINT;          // SCROLL_EVENTS
      target: HELEMENT;       // target element
      pos: integer;          // scroll position if SCROLL_POS
      vertical: integer;     // TRUE if from vertical scrollbar
  end;

  PSCRIPTING_METHOD_PARAMS = ^SCRIPTING_METHOD_PARAMS;
  SCRIPTING_METHOD_PARAMS = packed record
      name: LPCSTR;   //< method name
      argv: array of sc_VALUE;   //< vector of arguments
      argc: UINT;   //< argument count
      result: pointer; //< return value
  end;

  PTISCRIPT_METHOD_PARAMS = ^TISCRIPT_METHOD_PARAMS;
  TISCRIPT_METHOD_PARAMS = packed record
      vm: pointer;
      tag: PAnsiChar;    //< method id (symbol)
      result: pointer; //< return value
      // parameters are accessible through tiscript::args.
  end;

CURSOR_TYPE=(
 CURSOR_ARROW, //0
 CURSOR_IBEAM, //1
 CURSOR_WAIT, //2
 CURSOR_CROSS, //3
 CURSOR_UPARROW, //4
 CURSOR_SIZENWSE, //5
 CURSOR_SIZENESW, //6
 CURSOR_SIZEWE, //7
 CURSOR_SIZENS, //8
 CURSOR_SIZEALL, //9
 CURSOR_NO, //10
 CURSOR_APPSTARTING, //11
 CURSOR_HELP, //12
 CURSOR_HAND, //13
 CURSOR_DRAG_MOVE, //14
 CURSOR_DRAG_COPY, //15
 CURSOR_OTHER);


implementation
uses Sciter;

{ HELEMENT }

class operator HELEMENT.Implicit(AVar: HELEMENT): ElementID;
begin
 if SCDOM_OK <> ISciter.SciterGetElementUID(AVar,result) then begin
   result:=0;
 end;
end;

function HELEMENT.toUID: ElementID;
begin
  result:=Self;
end;

{ VALUE }

class function sc_VALUE.Create: sc_VALUE;
begin
 result.pval:=GetMemory(SizeOf(SCITER_VALUE));
 if ISciter.ValueInit(result)<>0 then begin
  FreeMem(result.pval);
  result.pval:=nil;
 end;
end;

constructor sc_VALUE.Create(str: string);
begin
 self:= Create;
 ISciter.ValueFromString(self,PChar(str),Length(str),0);
end;

function sc_VALUE.GetType: VALUE_TYPE;
var u,uu: UINT;
begin
 if 0= ISciter.ValueType(self,u,uu) then begin
   Result:=VALUE_TYPE(u);
 end else result:=T_UNDEFINED;
end;

class operator sc_VALUE.Implicit(AVar: sc_VALUE): Int64;
begin
   case AVar.GetType of
     T_BOOL:  Result:=  avar.pval.d;
     T_INT:   Result:=  avar.pval.d;
     T_DATE:  Result:=  avar.pval.d;
     else result:=0;
   end;
end;

class operator sc_VALUE.Implicit(AVar: sc_VALUE): Integer;
begin
   case AVar.GetType of
     T_BOOL:  Result:=  avar.pval.d;
     T_INT:   Result:=  avar.pval.d;
     T_DATE:  Result:=  avar.pval.d;
     else result:=0;
   end;
end;

class operator sc_VALUE.Implicit(AVar: sc_VALUE): String;
begin
 try
   case AVar.GetType of
      T_UNDEFINED: result:='NaN';
      T_NULL: Result:='nil';
      T_BOOL: Result:=BoolToStr( avar.pval.d = 1);
      T_STRING: Result:=  string(PChar(Pointer(DWORD(avar.pval.d+8))));
      T_INT: Result:=  IntToStr(avar.pval.d);
   end;
  except result:='undefined'; end;
end;



{ HELEMENTS }

procedure HELEMENTS.add(elm: HELEMENT);
var i: Integer;
begin
 for i := 0 to Length(hItems)-1 do if hItems[i].pval = elm.pval then Exit;
 i:=Length(hItems);
 SetLength(hItems,i+1);
 hItems[i].pval:=elm.pval;
end;

procedure HELEMENTS.Foreach(proc: THELEMENT_Func);
var i: Integer;
begin
 for i := 0 to Length(hItems)-1 do proc(hItems[i]);
end;

function HELEMENTS.Get(Index: Integer): HELEMENT;
begin
 if Index<Length(hItems) then Result.pval:=hItems[index].pval else Result.pval:=nil;
end;

procedure HELEMENTS.Put(Index: Integer; const Value: HELEMENT);
begin
  if Index<Length(hItems) then  hItems[index].pval := Value.pval;
end;

{ TElementsEvents }

function TElementsEvents.Assigned(elm: HELEMENT; etype: TSCITER_EVENTS): BOOL;
begin
 result:= nil <> FindEvent(elm, etype);
end;

function TElementsEvents.FindEvent(elm: HELEMENT; etype: TSCITER_EVENTS): Pointer;
var
  i: Integer;
  eid: ElementID;
begin
  eid:=elm;
  result:=nil;
  for i := 0 to Length(hItems)-1 do if (hItems[i].UID = eid) then Exit(hItems[i].events[Integer(etype)]);
end;

procedure TElementsEvents.ReleaseEvent(elm: HELEMENT; etype: TSCITER_EVENTS);
var
  i,x,l: Integer;
  eid: ElementID;
begin
  eid:=elm;
  for i := 0 to Length(hItems)-1 do
     if hItems[i].UID = eid then begin
        hItems[i].events[Integer(etype)]:=nil;
        l:= length(hItems[i].events);
        for x := 0 to l-1 do if hItems[i].events[x]<>nil then Break;
         if x  = l then hItems[i].UID := 0;
     end;
end;

procedure TElementsEvents.SetEvent(elm: HELEMENT; etype: TSCITER_EVENTS; evt: Pointer);
var
  i,fc,hi: Integer;
  eid: ElementID;
begin
  fc:=-1;
  hi:=-1;
  eid:=elm;
  for i := 0 to Length(hItems)-1 do begin
     if hItems[i].UID = 0 then begin
       if fc=-1 then fc:=i;
       Continue;
     end;
     if hItems[i].UID = eid then begin
       hi:=i;
       Break;
     end;
  end;

  if hi=-1 then begin
    if fc<>-1 then i:=fc else begin
      i:=Length(hItems);
      SetLength(hItems,i+1);
    end;
  end;
  hItems[i].UID :=  eid;
  hItems[i].events[Integer(etype)]:=evt;
end;

end.
