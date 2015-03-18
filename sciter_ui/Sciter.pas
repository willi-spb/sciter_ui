unit Sciter;

interface
uses  Windows, System.SysUtils, SciterTypes;

const
  engineDLL = 'sciter32.dll';

  RT_HTML = MAKEINTRESOURCE (23);
  LOAD_OK = 0;
  LOAD_DISCARD = 1; // discard request completely
  LOAD_DELAYED = 2; // data will be delivered later by the host

  SIH_REPLACE_CONTENT     = 0;
  SIH_INSERT_AT_START     = 1;
  SIH_APPEND_AFTER_LAST   = 2;
  SOH_REPLACE             = 3;
  SOH_INSERT_BEFORE       = 4;
  SOH_INSERT_AFTER        = 5;

type


  HNODE = Pointer;
  FLOAT_VALUE = Pointer;


 SCDOM_RESULT  = (
    SCDOM_OK = 0,
    SCDOM_INVALID_HWND = 1,
    SCDOM_INVALID_HANDLE = 2,
    SCDOM_PASSIVE_HANDLE = 3,
    SCDOM_INVALID_PARAMETER = 4,
    SCDOM_OPERATION_FAILED = 5,
    SCDOM_OK_NOT_HANDLED = (-1)
);

  PMETHOD_PARAMS = ^METHOD_PARAMS;
  METHOD_PARAMS = packed record
    methodID: UINT;
  end;

  PREQUEST_PARAMS = ^REQUEST_PARAMS;
  REQUEST_PARAMS = packed record        //!!!
    methodID: UINT;
  end;


  PSCITER_CALLBACK_NOTIFICATION = ^SCITER_CALLBACK_NOTIFICATION;
  SCITER_CALLBACK_NOTIFICATION = record
    code: UINT; //< [in] one of the codes above.
    hwnd: HWND; //< [in] HWINDOW of the window this callback was attached to.*/
  end;

LPSciterHostCallback = function( pns: PSCITER_CALLBACK_NOTIFICATION; callbackParam:  LPVOID ):UINT; stdcall;
SciterWindowDelegate =  function(hwnd: HWND; msg: UINT; wParam: WPARAM; lParam: LPARAM; pParam:  LPVOID; var pResult: LRESULT):  BOOL; stdcall;
SciterElementCallback =  function( he: HELEMENT; param: LPVOID  ): BOOL; stdcall;

DEBUG_OUTPUT_PROC = procedure(param: LPVOID; subsystem:  UINT {OUTPUT_SUBSYTEMS}; severity: UINT; text: LPCWSTR; text_length: UINT); stdcall;
SCITER_DEBUG_BP_HIT_CB = function( inFile: LPCWSTR; atLine: UINT; const envData: pointer{VALUE*}; param: LPVOID):UINT; stdcall; // breakpoint hit event receiver
SCITER_DEBUG_DATA_CB = procedure(onCmd: UINT; const data: Pointer{VALUE* }; param: LPVOID); stdcall; // requested data ready receiver
SCITER_DEBUG_BREAKPOINT_CB = function(fileUrl: LPCWSTR; lineNo: UINT; param: LPVOID):  BOOL; stdcall;


LPELEMENT_EVENT_PROC = ^ElementEventProc;
ElementEventProc = function(tag: LPVOID; he: HELEMENT; evtg: UINT; prms: LPVOID): BOOL; stdcall;

LPCSTR_RECEIVER = procedure( str: LPCSTR; str_length: UINT; param: LPVOID); stdcall;
//////////////////////////////////////////////////////////////////////////
///
///  W
///
TELEMENT_STATESREC=record
  const
    STATE_LINK = $00000001;
    STATE_HOVER = $00000002;
    STATE_ACTIVE =$00000004;
    STATE_FOCUS = $00000008;
    STATE_VISITED =$00000010;
    STATE_CURRENT =$00000020; // current (hot) item
    STATE_CHECKED = $00000040; // element is checked (or selected)
    STATE_DISABLED = $00000080; // element is disabled
    STATE_READONLY =$00000100; // readonly input element
    STATE_EXPANDED = $00000200; // expanded state - nodes in tree view
    STATE_COLLAPSED = $00000400; // collapsed state - nodes in tree view - mutually exclusive with
    STATE_INCOMPLETE = $00000800;// one of fore/back images requested but not delivered
    STATE_ANIMATING = $00001000;// is animating currently
    STATE_FOCUSABLE = $00002000;// will accept focus
    STATE_ANCHOR = $00004000;// anchor in selection (used with current in selects)
    STATE_SYNTHETIC = $00008000;// this is a synthetic element - don't emit it's head/tail
    STATE_OWNS_POPUP = $00010000;// this is a synthetic element - don't emit it's head/tail
    STATE_TABFOCUS = $00020000;// focus gained by tab traversal
    STATE_EMPTY = $00040000;// empty - element is empty (text.size() == 0 && subs.size() == 0)
    // if element has behavior attached then the behavior is responsible for the value of this flag.
    STATE_BUSY = $00080000;// busy; loading
    STATE_DRAG_OVER = $00100000;// drag over the block that can accept it (so is current drop target). Flag is set for the drop target block
    STATE_DROP_TARGET = $00200000;// active drop target.
    STATE_MOVING = $00400000;// dragging/moving - the flag is set for the moving block.
    STATE_COPYING = $00800000;// dragging/copying - the flag is set for the copying block.
    STATE_DRAG_SOURCE = $01000000;// element that is a drag source.
    STATE_DROP_MARKER = $02000000;// element is drop marker
    STATE_PRESSED = $04000000;// pressed - close to active but has wider life span - e.g. in MOUSE_UP it
    // is still on; so behavior can check it in MOUSE_UP to discover CLICK condition.
    STATE_POPUP = $08000000;// this element is out of flow - popup
    STATE_IS_LTR = $10000000;// the element or one of its containers has dir=ltr declared
    STATE_IS_RTL = $20000000; // the element or one of its containers has dir=rtl declared
    STATE_NULL =$00000000;
    State_Load=$40000000; // Willi
    State_Clear=$3FFFFFFF;
end;

//  Control types.
//  Control here is any dom element having appropriate behavior applied
type ctl_type=
  (
         CTL_NO, ///< This dom element has no behavior at all.
        CTL_UNKNOWN = 1, ///< This dom element has behavior but its type is unknown.
        CTL_EDIT, ///< Single line edit box.
        CTL_NUMERIC, ///< Numeric input with optional spin buttons.
        CTL_CLICKABLE, ///< toolbar button, behavior:clickable.
        CTL_BUTTON, ///< Command button.
        CTL_CHECKBOX, ///< CheckBox (button).
        CTL_RADIO, ///< OptionBox (button).
        CTL_SELECT_SINGLE, ///< Single select, ListBox or TreeView.
        CTL_SELECT_MULTIPLE, ///< Multiselectable select, ListBox or TreeView.
        CTL_DD_SELECT, ///< Dropdown single select.
        CTL_TEXTAREA, ///< Multiline TextBox.
        CTL_HTMLAREA, ///< WYSIWYG HTML editor.
        CTL_PASSWORD, ///< Password input element.
        CTL_PROGRESS, ///< Progress element.
        CTL_SLIDER, ///< Slider input element.
        CTL_DECIMAL, ///< Decimal number input element.
        CTL_CURRENCY, ///< Currency input element.
        CTL_SCROLLBAR,
        CTL_HYPERLINK,
        CTL_MENUBAR,
        CTL_MENU,
        CTL_MENUBUTTON,
        CTL_CALENDAR,
        CTL_DATE,
        CTL_TIME,
        CTL_FRAME,
        CTL_FRAMESET,
        CTL_GRAPHICS,
        CTL_SPRITE,
        CTL_LIST,
        CTL_RICHTEXT,
        CTL_TOOLTIP,
        CTL_HIDDEN,
        CTL_URL, ///< URL input element.
        CTL_TOOLBAR,
        CTL_FORM);



////////////////////////////////////////////////////////////////////////////////////////
PSciterAPI = ^ISCiterAPI;
ISciterAPI =  record
  version: UINT; // is zero for now

  SciterClassName: function():LPCWSTR; stdcall;
  SciterVersion: function(major: BOOL):UINT; stdcall;
  SciterDataReady: function(hwnd: HWND; uri: LPCWSTR; data: Pointer; dataLength: UINT): BOOL; stdcall;
  SciterDataReadyAsync: function(hwnd: HWND; uri: LPCWSTR; data: pointer; dataLength: UINT; requestId: LPVOID): BOOL; stdcall;
{$IFDEF MSWINDOWS}
  SciterProc: function(hwnd: HWND; msg: UINT; wParam: WPARAM; lParam: LPARAM ): lresult; stdcall;
  SciterProcND: function(hwnd: HWND; msg: UINT; wParam: WPARAM; lParam: LPARAM; var pbHandled: BOOL): LRESULT; stdcall;
{$ENDIF}
  SciterLoadFile: function(hWndSciter: HWND; filename: LPCWSTR ): BOOL; stdcall;
  SciterLoadHtml: function(hWndSciter: HWND; html: Pointer; htmlSize: UINT; baseUrl: LPCWSTR ): BOOL; stdcall;
  SciterSetCallback: procedure(hWndSciter: HWND; cb: LPSciterHostCallback; cbParam: LPVOID ); stdcall;
  SciterSetMasterCSS: function(utf8: pointer; numBytes: UInT): BOOl; stdcall;
  SciterAppendMasterCSS: function(utf8: pointer; numBytes: UInT):BOOl; stdcall;
  SciterSetCSS: function(hWndSciter: HWND; utf8: pointer; numBytes: UInT; baseUrl:LPCWSTR; mediaType: LPCWSTR ):BOOl; stdcall;
  SciterSetMediaType: function(hWndSciter: HWND; mediaType:  LPCWSTR): BOOL;  stdcall;
  SciterSetMediaVars: function(hWndSciter: HWND; const mediaVars: PSCITER_VALUE): BOOL;  stdcall;
  SciterGetMinWidth: function(hWndSciter: HWND):UINT; stdcall;
  SciterGetMinHeight: function(hWndSciter: HWND; width: UINT): UINT; stdcall;
  SciterCall: function(hwnd: HWND; functionName: LPCSTR; argc: UINT; const argv: PSCITER_VALUE; var retval: SCITER_VALUE): BOOL; stdcall;
  SciterEval: function(hwnd: HWND; script: LPCWSTR; scriptLength: UINT;  var retval: SCITER_VALUE): BOOL; stdcall;
  SciterUpdateWindow: procedure(hwnd: HWND); stdcall;
{$IFDEF MSWINDOWS}
  SciterTranslateMessage: function(var lpMsg: MSG): BOOL; stdcall;
{$ENDIF}
  SciterSetOption: function(hwnd: HWND; option: UINT; value: UINT_PTR ): BOOL; stdcall;
  SciterGetPPI: procedure(hWndSciter: HWND; var px: UINT; var py: UINT); stdcall;
  SciterGetViewExpando: function( hwnd: HWND; pval: pointer ): BOOL; stdcall;  //!!!
  SciterEnumUrlData: function(hWndSciter: HWND; receiver: pointer; param: LPVOID ; url: LPCSTR ): BOOL; stdcall; //!!!
{$IFDEF MSWINDOWS}
  SciterRenderD2D: function(hWndSciter: HWND; prt: pointer {PID2D1RenderTarget}): BOOL; stdcall;
  SciterD2DFactory: function(ppf: pointer{PID2D1Factory}): BOOL; stdcall;
  SciterDWFactory: function( ppf: Pointer {PIDWriteFactory}): BOOL; stdcall;
{$ENDIF}
  SciterGraphicsCaps: function( pcaps: PUINT): BOOL; stdcall;
  SciterSetHomeURL: function(hWndSciter: HWND; baseUrl: LPCWSTR ): BOOL; stdcall;
{$IFDEF MACOS}
  HWINDOW SCFN( SciterCreateNSView )( LPRECT frame ); // returns NSView*     //!!!
{$ENDIF}
  SciterCreateWindow: function( creationFlags: LPVOID; frame: PRECT; delegate: SciterWindowDelegate; delegateParam: LPVOID; parent: HWND): HWND; stdcall;

  SciterSetupDebugOutput: procedure(
                hwndOrNull:           HWND;   // HWINDOW or null if this is global output handler
                param:                LPVOID; // param to be passed "as is" to the pfOutput
                pfOutput:   DEBUG_OUTPUT_PROC // output function, output stream alike thing.
                ); stdcall;
  SciterDebugSetupClient: function(
                hwnd:                 HWND;      // HWINDOW of the sciter
                param:                LPVOID;     // param to be passed "as is" to these functions:
                onBreakpointHit: SCITER_DEBUG_BP_HIT_CB;  // breakpoint hit event receiver
                onDataRead:       SCITER_DEBUG_DATA_CB        // receiver of requested data
              ): BOOL; stdcall;
  SciterDebugAddBreakpoint: function(
                hwnd:      HWND;      // HWINDOW of the sciter
                fileUrl: LPCWSTR;
                lineNo: UINT
              ): BOOL; stdcall;
  SciterDebugRemoveBreakpoint: function(
                hwnd:      HWND;      // HWINDOW of the sciter
                fileUrl: LPCWSTR;
                lineNo: UINT
              ): BOOL; stdcall;
  SciterDebugEnumBreakpoints: function(
                hwnd:      HWND;      // HWINDOW of the sciter
                param:     LPVOID;     // param to be passed "as is" to the pfOutput
                receiver:  SCITER_DEBUG_BREAKPOINT_CB
              ): BOOL; stdcall;
//|
//| DOM Element API
//|
  Sciter_UseElement: function(he: HELEMENT): SCDOM_RESULT; stdcall;
  Sciter_UnuseElement: function(he: HELEMENT): SCDOM_RESULT; stdcall;
  SciterGetRootElement: function(hwnd: HWND; var phe: HELEMENT): SCDOM_RESULT; stdcall;
  SciterGetFocusElement: function(hwnd: HWND; var phe: HELEMENT): SCDOM_RESULT; stdcall;
  SciterFindElement: function(hwnd: HWND; pt: TPoint; var phe: HELEMENT): SCDOM_RESULT; stdcall;
  SciterGetChildrenCount: function(he: HELEMENT; var count: UINT): SCDOM_RESULT; stdcall;
  SciterGetNthChild: function(he: HELEMENT; n: UINT; var phe: HELEMENT): SCDOM_RESULT; stdcall;
  SciterGetParentElement: function(he: HELEMENT; var p_parent_he: HELEMENT): SCDOM_RESULT; stdcall;
  SciterGetElementHtmlCB: function(he: HELEMENT; outer: BOOL; rcv: pointer; rcv_param: LPVOID): SCDOM_RESULT; stdcall;  //!!!
  SciterGetElementTextCB: function(he: HELEMENT; rcv: LPCSTR_RECEIVER; rcv_param: LPVOID ): SCDOM_RESULT; stdcall;  //!!!
  SciterSetElementText: function(he: HELEMENT; utf16: LPCWSTR; length: UINT ): SCDOM_RESULT; stdcall;
  SciterGetAttributeCount: function(he: HELEMENT; var p_count: UINT): SCDOM_RESULT; stdcall;
  SciterGetNthAttributeNameCB: function(he: HELEMENT; n: UINT; rcv: LPCSTR_RECEIVER; rcv_param: LPVOID ): SCDOM_RESULT; stdcall;
  SciterGetNthAttributeValueCB: function(he: HELEMENT; n: UINT; rcv: pointer{LPCWSTR_RECEIVER* };rcv_param: LPVOID ): SCDOM_RESULT; stdcall;
  SciterGetAttributeByNameCB: function(he: HELEMENT; name: LPCSTR;rcv: pointer{LPCWSTR_RECEIVER* }; rcv_param: LPVOID ): SCDOM_RESULT; stdcall;
  SciterSetAttributeByName: function(he: HELEMENT; name: LPCSTR; value: LPCWSTR ): SCDOM_RESULT; stdcall;
  SciterClearAttributes: function(he: HELEMENT): SCDOM_RESULT; stdcall;
  SciterGetElementIndex: function(he: HELEMENT; var p_index: UINT): SCDOM_RESULT; stdcall;
  SciterGetElementType: function(he: HELEMENT; var p_type: LPCSTR): SCDOM_RESULT; stdcall;
  SciterGetElementTypeCB: function(he: HELEMENT;  rcv: pointer{LPCWSTR_RECEIVER* }; rcv_param: LPVOID): SCDOM_RESULT; stdcall;
  SciterGetStyleAttributeCB: function(he: HELEMENT; name: LPCSTR; rcv: pointer{LPCWSTR_RECEIVER* }; rcv_param: LPVOID): SCDOM_RESULT; stdcall;
  SciterSetStyleAttribute: function(he: HELEMENT; name: LPCSTR; value: LPCWSTR): SCDOM_RESULT; stdcall;
  SciterGetElementLocation: function(he: HELEMENT; p_location: PRECT; areas: UINT {ELEMENT_AREAS}): SCDOM_RESULT; stdcall;
  SciterScrollToView: function(he: HELEMENT; SciterScrollFlags: UINT): SCDOM_RESULT; stdcall;
  SciterUpdateElement: function(he: HELEMENT; andForceRender: BOOL): SCDOM_RESULT; stdcall;
  SciterRefreshElementArea: function(he: HELEMENT; rc: TRect): SCDOM_RESULT; stdcall;
  SciterSetCapture: function(he: HELEMENT): SCDOM_RESULT; stdcall;
  SciterReleaseCapture: function(he: HELEMENT): SCDOM_RESULT; stdcall;
  SciterGetElementHwnd: function(he: HELEMENT; var p_hwnd: HWND; rootWindow: BOOL): SCDOM_RESULT; stdcall;
  SciterCombineURL: function(he: HELEMENT; szUrlBuffer: LPWSTR; UrlBufferSize: UINT): SCDOM_RESULT; stdcall;
  SciterSelectElements: function(he: HELEMENT; CSS_selectors: LPCSTR; callback: SciterElementCallback; param: LPVOID): SCDOM_RESULT; stdcall;
  SciterSelectElementsW: function(he: HELEMENT; CSS_selectors: LPCWSTR; callback: SciterElementCallback; param: LPVOID): SCDOM_RESULT; stdcall;
  SciterSelectParent: function(he: HELEMENT; selector: LPCSTR; depth: UINT; var heFound: HELEMENT): SCDOM_RESULT; stdcall;
  SciterSelectParentW: function(he: HELEMENT; selector: LPCWSTR; depth: UINT; var heFound: HELEMENT): SCDOM_RESULT; stdcall;
{ where: UINT
  * - SIH_REPLACE_CONTENT 0- replace content of the element
* - SIH_INSERT_AT_START 1- insert html before first child of the element
* - SIH_APPEND_AFTER_LAST 2- insert html after last child of the element
*
* - SOH_REPLACE 3- replace element by html, a.k.a. element.outerHtml = "something"
* - SOH_INSERT_BEFORE 4- insert html before the element
* - SOH_INSERT_AFTER 5- insert html after the element
* ATTN: SOH_*** operations do not work for inline elements like <SPAN>
}
  SciterSetElementHtml: function(he: HELEMENT; const html: Pointer; htmlLength: UINT; where: UINT): SCDOM_RESULT; stdcall;
  SciterGetElementUID: function(he: HELEMENT; var puid: UINT): SCDOM_RESULT; stdcall;
  SciterGetElementByUID: function(hwnd: HWND; uid: UINT; var phe: HELEMENT): SCDOM_RESULT; stdcall;
  SciterShowPopup: function(popup: HELEMENT; Anchor: HELEMENT; placement: UINT): SCDOM_RESULT; stdcall;
  SciterShowPopupAt: function(Popup: HELEMENT; pos: TPoint; animate: BOOL): SCDOM_RESULT; stdcall;
  SciterHidePopup: function(he: HELEMENT): SCDOM_RESULT; stdcall;
  SciterGetElementState: function( he: HELEMENT; var pstateBits: UINT): SCDOM_RESULT; stdcall;
  SciterSetElementState: function( he: HELEMENT; stateBitsToSet: UINT; stateBitsToClear: UINT; updateView: BOOL): SCDOM_RESULT; stdcall;
  { Create new element, the element is disconnected initially from the DOM.
   Element created with ref_count = 1 thus you \b must call Sciter_UnuseElement on returned handler.
* \param[in] tagname \b LPCSTR, html tag of the element e.g. "div", "option", etc.
* \param[in] textOrNull \b LPCWSTR, initial text of the element or NULL. text here is a plain text - method does no parsing.
* \param[out ] phe \b #HELEMENT*, variable to receive handle of the element
  }
  SciterCreateElement: function( tagname: LPCSTR; textOrNull: LPCWSTR; out phe: HELEMENT ): SCDOM_RESULT; stdcall;
  SciterCloneElement: function( he: HELEMENT; out phe: HELEMENT): SCDOM_RESULT; stdcall;
  SciterInsertElement: function( he: HELEMENT; hparent: HELEMENT; index: UINT ): SCDOM_RESULT; stdcall;
  SciterDetachElement: function( he: HELEMENT ): SCDOM_RESULT; stdcall;
  SciterDeleteElement: function(he: HELEMENT): SCDOM_RESULT; stdcall;
  SciterSetTimer: function( he: HELEMENT; milliseconds: UINT; var timer_id: UINT ): SCDOM_RESULT; stdcall;
  SciterDetachEventHandler: function( he: HELEMENT; pep: LPELEMENT_EVENT_PROC; tag: LPVOID ): SCDOM_RESULT; stdcall;
  SciterAttachEventHandler: function( he: HELEMENT; pep: LPELEMENT_EVENT_PROC; tag: LPVOID ): SCDOM_RESULT; stdcall;
  SciterWindowAttachEventHandler: function( hwndLayout: HWND; pep: LPELEMENT_EVENT_PROC; tag: LPVOID; subscription: UINT ): SCDOM_RESULT; stdcall;
  SciterWindowDetachEventHandler: function( hwndLayout: HWND; pep: LPELEMENT_EVENT_PROC; tag: LPVOID ): SCDOM_RESULT; stdcall;
  SciterSendEvent: function( he: HELEMENT; appEventCode: UINT; Source: HELEMENT; reason: PUINT; var handled: BOOL): SCDOM_RESULT; stdcall;
  SciterPostEvent: function( he: HELEMENT; appEventCode: UINT; Source: HELEMENT; reason: PUINT): SCDOM_RESULT; stdcall;
  SciterCallBehaviorMethod: function(he: HELEMENT; params: PMETHOD_PARAMS): SCDOM_RESULT; stdcall;
  SciterRequestElementData: function( he: HELEMENT; url: LPCWSTR; dataType: UINT; initiator: HELEMENT ): SCDOM_RESULT; stdcall;
  SciterHttpRequest: function( he: HELEMENT;           // element to deliver data
                              url: LPCWSTR;          // url
                              dataType: UINT;     // data type, see SciterResourceType.
                              requestType: UINT;  // one of REQUEST_TYPE values
                              requestParams: PREQUEST_PARAMS;// parameters
                              nParams: UINT       // number of parameters
                              ): SCDOM_RESULT; stdcall;
  SciterGetScrollInfo: function( he: HELEMENT; scrollPos: TPoint; viewRect:TRect; contentSize: TSize  ): SCDOM_RESULT; stdcall;
  SciterSetScrollPos: function( he: HELEMENT; scrollPos: TPoint; smooth: BOOL ): SCDOM_RESULT; stdcall;
  SciterGetElementIntrinsicWidths: function( he: HELEMENT; var pMinWidth: integer; var pMaxWidth: integer ): SCDOM_RESULT; stdcall;
  SciterGetElementIntrinsicHeight: function( he: HELEMENT; forWidth: Integer; var pHeight: integer ): SCDOM_RESULT; stdcall;
  SciterIsElementVisible: function( he: HELEMENT; var pVisible: BOOL): SCDOM_RESULT; stdcall;
  SciterIsElementEnabled: function( he: HELEMENT; var pEnabled: BOOL ): SCDOM_RESULT; stdcall;
  SciterSortElements: function( he: HELEMENT; firstIndex: UINT; lastIndex: UINT; cmpFunc: pointer{ELEMENT_COMPARATOR*}; cmpFuncParam: LPVOID ): SCDOM_RESULT; stdcall;
  SciterSwapElements: function( he1: HELEMENT; he2: HELEMENT ): SCDOM_RESULT; stdcall;
  SciterTraverseUIEvent: function( evt: UINT; eventCtlStruct: LPVOID ; var bOutProcessed: BOOL ): SCDOM_RESULT; stdcall;
  SciterCallScriptingMethod: function( he: HELEMENT; name: LPCSTR; const argv: sc_VALUE; argc: UINT; var retval: sc_VALUE ): SCDOM_RESULT; stdcall;
  SciterCallScriptingFunction: function( he: HELEMENT; name: LPCSTR;const argv: sc_VALUE; argc: UINT; var retval: sc_VALUE ): SCDOM_RESULT; stdcall;
  SciterEvalElementScript: function( he: HELEMENT; script:LPCWSTR; scriptLength:UINT; var retval: sc_VALUE ): SCDOM_RESULT; stdcall;
  SciterAttachHwndToElement: function(he: HELEMENT; hwnd: hwnd): SCDOM_RESULT; stdcall;
  // see ctl_type for pType Ord();
  SciterControlGetType: function( he: HELEMENT; {CTL_TYPE} var pType: UINT ): SCDOM_RESULT; stdcall;
  SciterGetValue: function( he: HELEMENT; var pval: sc_VALUE ): SCDOM_RESULT; stdcall;
  SciterSetValue: function( he: HELEMENT; const  pval: sc_VALUE ): SCDOM_RESULT; stdcall;
  SciterGetExpando: function( he: HELEMENT; var  pval: sc_VALUE; forceCreation: BOOL ): SCDOM_RESULT; stdcall;
  SciterGetObject: function( he: HELEMENT; var pval: pointer {tiscript_value*}; forceCreation: BOOL ): SCDOM_RESULT; stdcall;
  SciterGetElementNamespace: function(  he: HELEMENT; var pval: pointer {tiscript_value*}): SCDOM_RESULT; stdcall;
  SciterGetHighlightedElement: function(hwnd: hwnd; var phe: HELEMENT): SCDOM_RESULT; stdcall;
  SciterSetHighlightedElement: function(hwnd: hwnd; he: HELEMENT): SCDOM_RESULT; stdcall;
//|
//| DOM Node API
//|
  SciterNodeAddRef: function(hn: HNODE): SCDOM_RESULT; stdcall;
  SciterNodeRelease: function(hn: HNODE): SCDOM_RESULT; stdcall;
  SciterNodeCastFromElement: function(he: HELEMENT; var phn: HNODE): SCDOM_RESULT; stdcall;
  SciterNodeCastToElement: function(hn: HNODE; var he: HELEMENT): SCDOM_RESULT; stdcall;
  SciterNodeFirstChild: function(hn: HNODE; var phn: HNODE): SCDOM_RESULT; stdcall;
  SciterNodeLastChild: function(hn: HNODE; var phn: HNODE): SCDOM_RESULT; stdcall;
  SciterNodeNextSibling: function(hn: HNODE; var phn: HNODE): SCDOM_RESULT; stdcall;
  SciterNodePrevSibling: function(hn: HNODE; var phn: HNODE): SCDOM_RESULT; stdcall;
  SciterNodeParent: function(hnode: HNODE; var pheParent: HELEMENT): SCDOM_RESULT; stdcall;
  SciterNodeNthChild: function(hnode: HNODE; n:UINT; var phn: HNODE): SCDOM_RESULT; stdcall;
  SciterNodeChildrenCount: function(hnode: HNODE; var pn: UINT): SCDOM_RESULT; stdcall;
  SciterNodeType: function(hnode: HNODE; var pNodeType: UINT{NODE_TYPE}): SCDOM_RESULT; stdcall;
  SciterNodeGetText: function(hnode: HNODE;  rcv: pointer{LPCWSTR_RECEIVER*}; rcv_param: LPVOID): SCDOM_RESULT; stdcall;
  SciterNodeSetText: function(hnode: HNODE; text: LPCWSTR; textLength:UINT): SCDOM_RESULT; stdcall;
  SciterNodeInsert: function(hnode: HNODE; where: UINT{NODE_INS_TARGET}; what: HNODE): SCDOM_RESULT; stdcall;
  SciterNodeRemove: function(hnode: HNODE;  finalize: BOOL): SCDOM_RESULT; stdcall;
  SciterCreateTextNode: function(text: LPCWSTR; textLength: UINT; var phn: HNODE): SCDOM_RESULT; stdcall;
  SciterCreateCommentNode: function(text: LPCWSTR; textLength: UINT; var phn: HNODE): SCDOM_RESULT; stdcall;
//|
//| Value API
//|
  ValueInit : function( pval: sc_VALUE ):UINT; stdcall;
  ValueClear : function( pval: sc_VALUE ):UINT; stdcall;
  ValueCompare : function( const pval1: sc_VALUE; const pval2: sc_VALUE ):UINT; stdcall;
  ValueCopy : function( pdst: sc_VALUE; const psrc: sc_VALUE ):UINT; stdcall;
  ValueIsolate : function( pdst: sc_VALUE ):UINT; stdcall;
  ValueType : function( const pval: sc_VALUE; var pType: UINT; var pUnits: UINT ):UINT; stdcall;
  ValueStringData : function( const pval: sc_VALUE; var pChars: LPCWSTR; var pNumChars: UINT ):UINT; stdcall;
  ValueStringDataSet : function( pval: sc_VALUE; chars: LPCWSTR ;  numChars: UINT;  units: UINT ):UINT; stdcall;
  ValueIntData : function( const pval: sc_VALUE; var pData: Integer ):UINT; stdcall;
  ValueIntDataSet : function( pval: sc_VALUE; data: integer;  vtype: UINT;  units: UINT ):UINT; stdcall;
  ValueInt64Data : function( const pval: sc_VALUE; var pData: int64 ):UINT; stdcall;
  ValueInt64DataSet : function( pval: sc_VALUE;  data: INT64;  vtype: UINT;  units:UINT ):UINT; stdcall;
  ValueFloatData : function( const pval: sc_VALUE; var pData: FLOAT_VALUE ):UINT; stdcall;
  ValueFloatDataSet : function( pval: sc_VALUE;  vdata: FLOAT_VALUE;  vtype: UINT; units: UINT ):UINT; stdcall;
  ValueBinaryData : function( const pval: sc_VALUE; var pBytes: PByte; var pnBytes: UINT ):UINT; stdcall;
  ValueBinaryDataSet : function( pval: sc_VALUE; pBytes: PByte; nBytes: UINT; vtype: UINT; units:UINT ):UINT; stdcall;
  ValueElementsCount : function( const pval: sc_VALUE; var pn: integer):UINT; stdcall;
  ValueNthElementValue : function( const pval: sc_VALUE; n: integer; pretval: sc_VALUE):UINT; stdcall;
  ValueNthElementValueSet : function( pval: sc_VALUE; n: Integer; const pval_to_set: sc_VALUE):UINT; stdcall;
  ValueNthElementKey : function( const pval: sc_VALUE; n: Integer; pretval: sc_VALUE):UINT; stdcall;
  ValueEnumElements : function( pval: sc_VALUE; penum: pointer{KeyValueCallback* }; param: LPVOID ):UINT; stdcall;
  ValueSetValueToKey : function( pval: sc_VALUE; const pkey: sc_VALUE; const pval_to_set: sc_VALUE):UINT; stdcall;
  ValueGetValueOfKey : function( const pval: sc_VALUE; const pkey: sc_VALUE; pretval: sc_VALUE):UINT; stdcall;
  ValueToString : function( var pval: sc_VALUE; {VALUE_STRING_CVT_TYPE} how: UINT ):UINT; stdcall;
  ValueFromString : function( pval: sc_VALUE;  str: LPCWSTR; strLength: UINT; {VALUE_STRING_CVT_TYPE} how: UINT  ):UINT; stdcall;
  ValueInvoke : function( pval: sc_VALUE; pthis: sc_VALUE;  argc: UINT; const argv: sc_VALUE; pretval: sc_VALUE; url: LPCWSTR):UINT; stdcall;
  ValueNativeFunctorSet : function( pval: sc_VALUE; pnfv: pointer{struct NATIVE_FUNCTOR_VALUE* }):UINT; stdcall;
  ValueIsNativeFunctor: function( const pval: sc_VALUE): BOOL; stdcall;

  // tiscript VM API
  TIScriptAPI: function():pointer{tiscript_native_interface*} ; stdcall;

  SciterGetVM: function( hwnd: hwnd ): pointer {HVM}; stdcall;

  Sciter_sv2V: function(vm: pointer{HVM };  script_value: pointer{tiscript_value}; var value: sc_VALUE; isolate: BOOL ): BOOL; stdcall;
  Sciter_V2sv: function(vm: pointer{HVM }; const value: sc_VALUE; var script_value: pointer{tiscript_value}): BOOL; stdcall;

end;


 LPSCN_CALLBACK_HOST = ^SCN_CALLBACK_HOST;
 SCN_CALLBACK_HOST =  record
  channel: UINT; // 0 - stdin, 1 - stdout, 2 - stderr
  p1:  SCITER_VALUE; // in, parameter #1
  p2:  SCITER_VALUE; // in, parameter #2
  r:   SCITER_VALUE;  // out, retval
end;

type
  PSCN_LOAD_DATA = ^SCN_LOAD_DATA ;
  SCN_LOAD_DATA = record
    cbhead: SCITER_CALLBACK_NOTIFICATION;
    uri: LPCWSTR;              //*< [in] Zero terminated string, fully qualified uri, for example \"http://server/folder/file.ext\".*/

    outData: PBYTE;          //*< [in,out] pointer to loaded data to return. if data exists in the cache then this field contain pointer to it*/
    outDataSize: UINT;      //*< [in,out] loaded data size to return.*/
    dataType: UINT;         //*< [in] SciterResourceType */

    requestId: Pointer;        //*< [in] request id that needs to be passed as is to the SciterDataReadyAsync call */

    principal: HELEMENT;
    initiator: HELEMENT;
end;


  HVM = ^tiscript_VM;
  tiscript_VM = record
  end;

  SciterNativeMethod_t = procedure (hvm: HVM; selfp: PSCITER_VALUE; argv: PSCITER_VALUE;  argc: Integer; retval: PSCITER_VALUE); stdcall;
  SciterNativeProperty_t = procedure (hvm: HVM; selfp: PSCITER_VALUE; sets: Integer;   val: PSCITER_VALUE); stdcall;
  SciterNativeDtor_t = procedure (hvm: HVM; p_data_slot_value: Pointer); stdcall;

  PSciterNativeMethodDef = ^SciterNativeMethodDef;
  SciterNativeMethodDef = record
      name: LPCSTR;
      method: SciterNativeMethod_t;
  end;

  PSciterNativePropertyDef = ^SciterNativePropertyDef;
  SciterNativePropertyDef = record
      name: LPCSTR;
      propertys: SciterNativeProperty_t;
  end;

  PSciterNativeConstantDef = ^SciterNativeConstantDef;
  SciterNativeConstantDef = record
      name: LPCSTR;
      value: SCITER_VALUE;
//      SciterNativeConstantDef( LPCSTR n,SCITER_VALUE v = SCITER_VALUE() ):name(n),value(v) {}
  end;

  PSciterNativeClassDef = ^SciterNativeClassDef;
  SciterNativeClassDef = record
      name: LPCSTR;
      methods: PSciterNativeMethodDef;
      properties: PSciterNativePropertyDef;
      dtor: SciterNativeDtor_t;
      constants: PSciterNativeConstantDef;
  end;
var
    ISciter: PSciterAPI;
    function BasicHostCallback(pns: Pointer; callbackParam: Pointer): UINT; stdcall;
    function MethodToProcedure(self: TObject; methodAddr: pointer; maxParamCount: integer = 8) : pointer;
    function GetResourceAsPointer(ResName: pchar; ResType: pchar; out Size: longword): pointer;

    function fOneElementCallback( he: HELEMENT; param: LPVOID  ): BOOL; stdcall;
    function fAllElementCallback( he: HELEMENT; param: LPVOID  ): BOOL; stdcall;

    function SciterInit: PSciterAPI;
    ///
implementation

var
    hlib : HMODULE=0;
    SciterAPI: function():Pointer; stdcall;
    protocol: WideString = 'app:';

function OnLoadData (pns: PSCN_LOAD_DATA): UINT;
var
  url, ps: WideString;
  uri: WideString;
  ext: WideString;
  resName: WideString;
  extdeliPos: integer;
begin

    url := pns.uri;
    ps := Copy (url, 1, 4);
    uri := Copy (url, 5, length (url));
    extdeliPos := Pos ('.', uri);
    resName := Copy (uri, 1, extdeliPos - 1);
 //   ext := UpperCase(Copy (uri, extdeliPos + 1, length (uri)));

    if ps = protocol then // we are using basic:name.ext schema to refer to resources contained in this exe.
    begin
      if (ext = 'HTML') or (ext = 'HTM') then
      begin
        pns.outData := GetResourceAsPointer (PWideChar(resName), RT_HTML, pns.outDataSize);
      end
      else
        pns.outData := GetResourceAsPointer (PWideChar(resName), PWideChar(ext), pns.outDataSize);

      if pns.outDataSize <> 0 then
        result := LOAD_OK
      else
        result := LOAD_DISCARD;

      exit;
    end;

    result := LOAD_OK; // proceed with the default loader.
end;

function BasicHostCallback(pns: Pointer; callbackParam: Pointer): UINT; stdcall;
var
  p: PSCN_LOAD_DATA;
begin
  p := pns;
  case p.cbhead.code of
    SC_LOAD_DATA:
      begin
        result := 0;//OnLoadData (p);
        exit;
      end;
      SC_ENGINE_DESTROYED:
        Beep;
     SC_ATTACH_BEHAVIOR:  Exit(0);
  end;
  Result := 0;
end;

function SciterInit: PSciterAPI;
begin
      hlib:=LoadLibrary(engineDLL);
      if hlib=0 then begin
        MessageBoxW(0, 'File not found: sciter32.dll' + #13#10 +
          ' program will be closed', 'File not found', MB_OK + MB_ICONSTOP +
          MB_TOPMOST);
          Halt(3);
      end;

      SciterAPI := GetProcAddress(hlib, 'SciterAPI');
      if SciterAPI = nil then begin
        MessageBoxW(0, 'Sciter32.dll is corrupted' + #13#10 +
          ' program will be closed', 'File not found', MB_OK + MB_ICONSTOP +
          MB_TOPMOST);
          Halt(5);
      end;

      result:=SciterAPI();
      try
        result.SciterVersion(true);
      except
        MessageBoxW(0, 'Sciter32.dll is bad' + #13#10 +
          ' program will be closed', 'File not found', MB_OK + MB_ICONSTOP +
          MB_TOPMOST);
          Halt(4);
      end;
end;

{ ISciterAPI }
function fOneElementCallback( he: HELEMENT; param: LPVOID  ): BOOL; stdcall;
begin
    HELEMENT(param^):=he;
    result:=true; //no more elements
end;


function fAllElementCallback( he: HELEMENT; param: LPVOID  ): BOOL; stdcall;
begin
    HELEMENTS(param^).add(he);
    result:=false; //more, more elements
end;


{TOOLS}

function MethodToProcedure(self: TObject; methodAddr: pointer; maxParamCount: integer = 8) : pointer;
{$ifdef win64}
var stackSpace,pos,i1 : integer;
           s1, s2     : AnsiString;
begin
    if maxParamCount < 4 then  maxParamCount := 4;
    if odd(maxParamCount) then      stackSpace := (maxParamCount + 2) * 8
                          else      stackSpace := (maxParamCount + 3) * 8;
    s1 := #$48 + #$81 + #$ec +        #0#0#0#0 +  // sub     rsp, $118
          #$48 + #$89 + #$84 + #$24 + #0#0#0#0 +  // mov     [rsp+$110], rax
          #$48 + #$8b + #$84 + #$24 + #0#0#0#0 +  // mov     rax, [rsp+$120]
          #$48 + #$89 + #$44 + #$24 + #$08     +  // mov     [rsp+8], rax
          #$48 + #$8b + #$84 + #$24 + #0#0#0#0 +  // mov     rax, [rsp+$128]
          #$48 + #$89 + #$44 + #$24 + #$10     +  // mov     [rsp+$10], rax
          #$48 + #$8b + #$84 + #$24 + #0#0#0#0 +  // mov     rax, [rsp+$130]
          #$48 + #$89 + #$44 + #$24 + #$18     +  // mov     [rsp+$18], rax
          #$4c + #$89 + #$4c + #$24 + #$20     +  // mov     [rsp+$20], r9
          #$4d + #$89 + #$c1                   +  // mov     r9, r8
          #$49 + #$89 + #$d0                   +  // mov     r8, rdx
          #$48 + #$89 + #$ca                   +  // mov     rdx, rcx
          #$66 + #$0f + #$6f + #$da            +  // movdqa  xmm3, xmm2
          #$66 + #$0f + #$6f + #$d1            +  // movdqa  xmm2, xmm1
          #$66 + #$0f + #$6f + #$c8;              // movdqa  xmm1, xmm0
    integer(pointer(@s1[ 4])^) := stackSpace;
    integer(pointer(@s1[12])^) := stackSpace -  $8;
    integer(pointer(@s1[20])^) := stackSpace +  $8;
    integer(pointer(@s1[33])^) := stackSpace + $10;
    integer(pointer(@s1[46])^) := stackSpace + $18;
    pos := Length(s1) + 1;
    SetLength(s1, Length(s1) + (maxParamCount - 4) * 16);
    s2 := #$48 + #$8b + #$84 + #$24 + #0#0#0#0 +  // mov     rax, [rsp+$140]
          #$48 + #$89 + #$84 + #$24 + #0#0#0#0;   // mov     [rsp+$28], rax
    for i1 := 1 to maxParamCount - 4 do begin
      integer(pointer(@s2[ 5])^) := $20 + i1 * 8 + stackSpace;
      integer(pointer(@s2[13])^) := $20 + i1 * 8;
      Move(s2[1], s1[pos], Length(s2));
      inc(pos, Length(s2));
    end;
    s2 := #$48 + #$8b + #$84 + #$24 + #0#0#0#0 +  // mov     rax, [rsp+$110]
          #$48 + #$b9       + #0#0#0#0#0#0#0#0 +  // mov     rcx, methodAddr
          #$48 + #$89 + #$8c + #$24 + #0#0#0#0 +  // mov     [rsp+$110], rcx
          #$48 + #$b9       + #0#0#0#0#0#0#0#0 +  // mov     rcx, self
          #$48 + #$89 + #$0c + #$24            +  // mov     [rsp], rcx
          #$ff + #$94 + #$24        + #0#0#0#0 +  // call    [rsp+$110]
          #$48 + #$81 + #$c4        + #0#0#0#0 +  // add     rsp, $118
          #$c3;                                   // ret
    integer(pointer(@s2[ 5])^) := stackSpace - $8;
    pointer(pointer(@s2[11])^) := methodAddr;
    integer(pointer(@s2[23])^) := stackSpace - $8;
    pointer(pointer(@s2[29])^) := self;
    integer(pointer(@s2[44])^) := stackSpace - $8;
    integer(pointer(@s2[51])^) := stackSpace;
    s1 := s1 + s2;
    result := VirtualAlloc(nil, Length(s1), MEM_COMMIT, PAGE_EXECUTE_READWRITE);
    Move(s1[1], result^, Length(s1));
{$else}
  type
    TMethodToProc = packed record
      popEax   : byte;                  // $58      pop EAX
      pushSelf : record                 //          push self
                   opcode  : byte;      // $B8
                   self    : pointer;   // self
                 end;
      pushEax  : byte;                  // $50      push EAX
      jump     : record                 //          jmp [target]
                   opcode  : byte;      // $FF
                   modRm   : byte;      // $25
                   pTarget : ^pointer;  // @target
                   target  : pointer;   // @MethodAddr
                 end;
    end;
var   mtp : ^TMethodToProc absolute result;
begin
    mtp := VirtualAlloc(nil, sizeOf(mtp^), MEM_COMMIT, PAGE_EXECUTE_READWRITE);
    with mtp^ do begin
      popEax          := $58;
      pushSelf.opcode := $68;
      pushSelf.self   := self;
      pushEax         := $50;
      jump.opcode     := $FF;
      jump.modRm      := $25;
      jump.pTarget    := @jump.target;
      jump.target     := methodAddr;
    end;
{$endif}
end;

function GetResourceAsPointer(ResName: pchar; ResType: pchar; out Size: longword): pointer;
var
  InfoBlock: HRSRC;
  GlobalMemoryBlock: HGLOBAL;
begin
  InfoBlock := FindResource(hInstance, resname, restype);
  if InfoBlock = 0 then   raise Exception.Create(SysErrorMessage(GetLastError));
  size := SizeofResource(hInstance, InfoBlock);
  if size = 0 then   raise Exception.Create(SysErrorMessage(GetLastError));
  GlobalMemoryBlock := LoadResource(hInstance, InfoBlock);
  if GlobalMemoryBlock = 0 then   raise Exception.Create(SysErrorMessage(GetLastError));
  Result := LockResource(GlobalMemoryBlock);
  if Result = nil then  raise Exception.Create(SysErrorMessage(GetLastError));
end;


initialization
  //  ISciter:= SciterInit();

end.