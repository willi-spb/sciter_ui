unit sc_agent;

interface

uses  Windows, Types, System.SysUtils, Sciter, SciterTypes, Variants,// System.Generics.Collections,
     System.Classes, System.Zip;

// тип загрузки ресурсов
// 0 - ресурсы, 1, 2 - файлы, 3 - зип архив в ресурсах
var scResourceConnectRegime: integer = 0;

type
 TSciterWindowState = (
    swstate_Shown, swstate_Minimized, swstate_Maximized, swstate_Hidden);

 type
   SCITER_CREATE_WINDOW_FLAG = (
   SW_CHILD ,     // child window only, if this flag is set all other flags ignored
   SW_TITLEBAR ,  // toplevel window, has titlebar
   SW_RESIZEABLE, // has resizeable frame
   SW_TOOL ,      // is tool window
   SW_CONTROLS,   // has minimize / maximize buttons
   SW_GLASSY,     // glassy window ( DwmExtendFrameIntoClientArea on windows )
   SW_ALPHA,      // transparent window ( e.g. WS_EX_LAYERED on Windows )
   SW_MAIN,       // main window of the app, will terminate app on close
   SW_POPUP       // the window is created as topmost.
  );

  SCITER_CREATE_WINDOW_FLAGS = set of SCITER_CREATE_WINDOW_FLAG;

  ELEMENT_HANDLERS = UINT;

  TOnMessages  =  function(hwnd: HWND; msg: UINT; wParam: WPARAM; lParam: LPARAM; var pResult: LRESULT):  BOOL{ of object};
  TStdEvent    =  procedure of object;
  TSciterEvent =  procedure(Sender: HELEMENT) of object;
  TErrorPlace =record
   eSender:TObject;
   eDesc,eTrace:string;
   eCode,eNum:integer;
   //
   eLine:integer;
   eName:string;
   ePlace:string;
   procedure SetNull;
   function toString:string;
  end;

  TReadyDataRecord=record
  public
   cbhead_code: integer; //< [in] one of the codes above.
   cbhead_hwnd: HWND; //< [in] HWINDOW of the window this callback was attached to.*/
   uri:string;  //*< [in] fully qualified uri, for example \"http://server/folder/file.ext\".*/
   outData: PBYTE;          //*< [in,out] pointer to loaded data to return. if data exists in the cache then this field contain pointer to it*/
   outDataSize: integer;      //*< [in,out] loaded data size to return.*/
   dataType: integer;         //*< [in] SciterResourceType */
   requestId: Pointer;        //*< [in] request id that needs to be passed as is to the SciterDataReadyAsync call */
   principal: HELEMENT;
   initiator: HELEMENT;
  end;


  pReadyDataRecord=^TReadyDataRecord;


  TErrorEvent= procedure(const aErrPlace:TErrorPlace) of object;

////
 TAgentFailureEvent=procedure(const aPlace:string; aUID:Cardinal; aErrIndex:integer; const aData:String) of object;

///
///  Тип внешнего обработчик Callback:
///
///  hPval - указатель на Helement   hUid-UID элемента - остальное см el_Proc параметры
///  также тип сообщения + указатель на метод обработки (указатель хранится в TscAgent.fEvents
 TscElementHandlerEvent=procedure(aTag,hPval: Pointer;  hUId,evTG: LongWord; prms: Pointer;
                                     ascEvent:TSCITER_EVENTS;
                                     aEventPtr:pointer;
                                     var HRes:boolean) of object;
///
///  для скрипта
 TscScryptHandlerEvent=procedure(const aName:string; aData:Variant; var HRes:boolean) of Object;
///
 TscAgent=class(TObject)  // Singleton
   protected
    fHwnd:Hwnd;
    FFileName:String;
    FVisible:boolean;
    fEvents: TElementsEvents; /// массив events
    fLastResult:SCDOM_RESULT; // результат функции скайтера
    fParent: HWND;
    fCreationFlags: SCITER_CREATE_WINDOW_FLAGS;
    fOnMessages: TOnMessages;
    fOnClose: TStdEvent;
    hAccelTable: HACCEL;
    ///
    FonFailureEvent:TAgentFailureEvent;
    FonError:TErrorEvent;
    /// in Loading - add fields:
    fResourceStream: TResourceStream;
    fInitialWindowState: TSciterWindowState;
    fOnZipFileLoad:TNotifyEvent;
    fZipStream: TMemoryStream;
    fZipFile: TZipFile;
    ///
    procedure SetVisible(value:boolean);
    ///  propertyes
    function getInitialWindowState: TSciterWindowState;
    ///
    /// обработка ошибки при обращениях - когда <>SCDOM_OK
    procedure el_failure(const APlace,atext:string; aUid:cardinal);
    // сформировать ошибку и обработать её - используется для показа Исключений
    procedure ConcatErrorData(aEE:Exception;  const adata:string=''; aLine:integer=0);
    ///
    ///  обработка команд - исп. в el_Proc
    function handle_scripting_call_E(he: HELEMENT; prms: PSCRIPTING_METHOD_PARAMS):boolean;
    ///
    ///  callback
    function el_Proc(tag: LPVOID; he: HELEMENT; evtg: UINT; prms: LPVOID): BOOL; stdcall;
    function scWindowProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
   public
    GroupNum:integer;
    Name:string;
    Caption:string;
    // CB:
        el_HandlerEvent:TscElementHandlerEvent; //  event
        ScryptHandlerEvent:TscScryptHandlerEvent;
   ///
   ///
   ///  AllSection
   function GetClassName:string;
   function GetVersion(major:boolean):integer;
   function DataReady(const Ur:string; data: Pointer; dataLength: integer):integer;
   function DataReadyAsync(adataType:integer; const Ur:string; data: pointer; dataLength: integer; reqId: pReadyDataRecord=nil): integer;
   // загрузить из потока   type: ->  SciterResourceType
   function LoadDataFromStream(aDataType:integer; const AStream:TStream; const aURl:string; aUrlFormatSign:integer=0):boolean;
   // analog absolute
   function LoadDataFromMemStream(aDataType:integer; const AMStream:TMemoryStream; const aURl:string; aUrlFormatSign:integer=0):boolean;
   ///
   ///  загрузить из ресурсов - идентификатор ресурса - это имя файла (без расширения) - тип ресурса - это расширение файла
   function LoadDataFromRes(aDataType:integer; const aURl:string; aUrlFormatSign:integer=0):boolean;
   ///  аналог - список ресурсов
   function LoadDataFromResources(aDataType:integer; const Astr:array of string; aUrlFormatSign:integer=0):boolean;
   ///
   ///
   function LoadFile(const aFilename:string):boolean;
   function LoadHtml(aBytes:PByte; bSize:integer; const baseUrl:string):boolean;
   function LoadHtmlFromRes(const aURl:string):boolean;
   ///
   ///  установка общего callback  0 - nil   1 - по умолчанию на процедуру модуля Sciter > BasicHostCallback
   function SetCallbackRegime(aCBRegime:integer):boolean;
   ///
   function SetMediaType(const mediaType:String):boolean;
   function SetMediaVars(const mediaVars: PSCITER_VALUE):boolean;

   function GetMinWidth:integer;
   function GetMinHeight(aWd:integer):integer;
   ///
   procedure UpdateWindow;
   ///
   function SetOption(option:SCITER_RT_OPTIONS; value:integer):boolean;
   function GetPPI:Tpoint;
   function GetViewExpando(var Pval:PSCITER_VALUE):boolean;
   ///
   function getGraphicsCaps(var aType:integer):boolean; // Get!
   function SetHomeURL(const aURL:string):boolean;
   /// DOM Api
   function el_Use(he: HELEMENT):boolean;
   function el_Unuse(he: HELEMENT):boolean;
   function el_GetRoot:HELEMENT;
   function el_GetFocus:HELEMENT;
   function el_Find(pt: TPoint):HELEMENT;
   function el_GetChildrenCount(he: HELEMENT):integer;
   function el_GetNthChild(he: HELEMENT; num:integer):HELEMENT;
  function el_GetParent(he: HELEMENT):HELEMENT;
  function el_GetHtml(he: HELEMENT; outer: boolean):string;
  function el_GetText(he: HELEMENT):string;
  function el_GetAttributeCount(he: HELEMENT):integer; // - error=-1;
  function el_GetNthAttributeName(he: HELEMENT; num:integer):string;
  function el_GetNthAttributeValue(he: HELEMENT; num:integer):string;
  function el_GetAttributeByName(he: HELEMENT; const aname:string):string;
  function el_SetAttributeByName(he: HELEMENT; const aname,aValue:string):boolean;
  function el_ClearAttributes(he: HELEMENT):boolean;
  function el_GetIndex(he: HELEMENT):integer;
  function el_GetType(he: HELEMENT):string;
  function el_GetTypeCB(he: HELEMENT):string;
  function el_GetStyleAttribute(he: HELEMENT; const aname: string):string;
  function el_SetStyleAttribute(he: HELEMENT; const aname,aValue: string):boolean;
  function el_GetLocation(he: HELEMENT; areas: integer; var ARect:Trect):boolean;
  function el_ScrollToView(he: HELEMENT; aScroll_ToTop,aScrollSmooth:boolean):boolean;
  function el_Update(he: HELEMENT; andForceRender: boolean):boolean;
  function el_RefreshArea(he: HELEMENT; rRect: TRect):boolean;
  function el_SetCapture(he: HELEMENT):boolean;
  function el_ReleaseCapture(he: HELEMENT):boolean;
  function el_GetHwnd(he: HELEMENT; rootWindow: BOOLean):HWND; // 0 - in error
  function el_CombineURL(he: HELEMENT; const UrlBuffer: string):boolean;
//  function el_SelectElements: function(he: HELEMENT; CSS_selectors: LPCSTR; callback: SciterElementCallback; param: LPVOID): SCDOM_RESULT; stdcall;
//  function el_SelectElementsW: function(he: HELEMENT; CSS_selectors: LPCWSTR; callback: SciterElementCallback; param: LPVOID): SCDOM_RESULT; stdcall;
  function el_SelectParent(he: HELEMENT; const aSelector:string; aDepth:integer; ansiFlag:boolean):HELEMENT;
  ///
  ///  получить массив или первый найденный  по строке выбора
  function el_Select(const selector: string): HELEMENTS;
  function el_SelectFirst(const selector: string): HELEMENT;
   ///
   ///
   ///  SET_ELEMENT_HTML
{     whereSign:
 * - SIH_REPLACE_CONTENT 0 - replace content of the element
* - SIH_INSERT_AT_START 1 - insert html before first child of the element
* - SIH_APPEND_AFTER_LAST 2 - insert html after last child of the element
* - SOH_REPLACE 3 - replace element by html, a.k.a. element.outerHtml = "something"
* - SOH_INSERT_BEFORE 4- insert html before the element
* - SOH_INSERT_AFTER 5 - insert html after the element
* ATTN: SOH_*** operations do not work for inline elements like <SPAN>
}
  function el_SetHtml(he: HELEMENT; const htmlTxt: string; whereSign: integer):boolean;
  function el_GetUID(he: HELEMENT):integer; // -1 in error
  function el_GetByUID(uid: integer):HELEMENT;
  ///
  ///  Placement
 {   2 - popup element below of anchor
   * 8 - popup element above of anchor
   * 4 - popup element on left side of anchor
   * 6 - popup element on right side of anchor }
  function el_ShowPopup(popup: HELEMENT; Anchor: HELEMENT; placement: integer):boolean;
  function el_ShowPopupAt(Popup: HELEMENT; posP: TPoint; animate: Boolean):boolean;
  function el_SciterHidePopup(he: HELEMENT):boolean;
  function el_GetState(he: HELEMENT):integer; // -1 - not correct
  function el_SetStateEx(he: HELEMENT; aStateBits,aStateClearBits:integer; updateViewFlag:boolean):boolean;
  { Create new element, the element is disconnected initially from the DOM.
   Element created with ref_count = 1 thus you \b must call Sciter_UnuseElement on returned handler.
* \param[in] tagname \b LPCSTR, html tag of the element e.g. "div", "option", etc.
* \param[in] textOrNull \b LPCWSTR, initial text of the element or NULL. text here is a plain text - method does no parsing.
* \param[out ] phe \b #HELEMENT*, variable to receive handle of the element
  }
  function el_Create(const tagName, text:string):HELEMENT;
  function el_Clone(he: HELEMENT):Helement;
  function el_Insert( he: HELEMENT; hparent: HELEMENT; index:integer):boolean;
  function el_Detach(he: HELEMENT):boolean;
  function el_Delete(he: HELEMENT):boolean;
  function el_SetTimer( he: HELEMENT; milliseconds: integer; var timer_id:integer):boolean;
  function el_ClearTimer( he: HELEMENT):boolean;
  function el_DetachEventHandler(he: HELEMENT; pep: LPELEMENT_EVENT_PROC):boolean;
  function el_AttachEventHandler(he: HELEMENT; pep: LPELEMENT_EVENT_PROC):boolean;
  function el_WindowAttachEventHandler( hwndLayout: HWND; pep: LPELEMENT_EVENT_PROC; subscription: integer):boolean;
  function el_WindowDetachEventHandler( hwndLayout: HWND; pep: LPELEMENT_EVENT_PROC):boolean;
  function el_SendEvent(he: HELEMENT; appEventCode: UINT; aSource: HELEMENT; reason: PUINT; var handled: BOOL):boolean;
  function el_PostEvent(he: HELEMENT; appEventCode: UINT; aSource: HELEMENT; reason: PUINT):boolean;
  function el_CallBehaviorMethod(he:HELEMENT; params: PMETHOD_PARAMS):boolean;
  function el_RequestElementData(he: HELEMENT;const URL:String; dataType: UINT; initiator: HELEMENT):boolean;
  function el_HttpRequest(he: HELEMENT;           // element to deliver data
                              const url:string;          // url
                              dataType: UINT;     // data type, see SciterResourceType.
                              requestType: UINT;  // one of REQUEST_TYPE values
                              requestParams: PREQUEST_PARAMS;// parameters
                              nParams: UINT       // number of parameters
                              ):boolean;
  function el_GetScrollInfo(he: HELEMENT; scrollPos: TPoint; viewRect:TRect; contentSize: TSize):boolean;
  function el_SetScrollPos(he: HELEMENT; scrollPos: TPoint; smoothFlag:boolean):boolean;
  function el_GetIntrinsicWidths(he: HELEMENT; var pMinWidth: integer; var pMaxWidth: integer ):boolean;
  function el_GetIntrinsicHeight(he: HELEMENT; forWidth: Integer; var pHeight: integer):boolean;
  function el_ISVisible(he: HELEMENT):boolean;
  function el_ISEnabled(he: HELEMENT):boolean;
//  SciterSortElements: function( he: HELEMENT; firstIndex: UINT; lastIndex: UINT; cmpFunc: pointer{ELEMENT_COMPARATOR*}; cmpFuncParam: LPVOID ): SCDOM_RESULT; stdcall;
  function el_Swap(he1,he2: HELEMENT):boolean;
{  SciterTraverseUIEvent: function( evt: UINT; eventCtlStruct: LPVOID ; var bOutProcessed: BOOL ): SCDOM_RESULT; stdcall;
  SciterCallScriptingMethod: function( he: HELEMENT; name: LPCSTR; const argv: VALUE; argc: UINT; var retval: VALUE ): SCDOM_RESULT; stdcall;
  SciterCallScriptingFunction: function( he: HELEMENT; name: LPCSTR;const argv: VALUE; argc: UINT; var retval: VALUE ): SCDOM_RESULT; stdcall;
  SciterEvalElementScript: function( he: HELEMENT; script:LPCWSTR; scriptLength:UINT; var retval: VALUE ): SCDOM_RESULT; stdcall;
  }
  function el_AttachHwndToElement(he: HELEMENT; hwnd: hwnd):boolean;
  // see ctl_type for pType Ord();
  function el_ControlGetType(he: HELEMENT; {CTL_TYPE} var pType: UINT ):boolean;
  function el_GetValue(he: HELEMENT; var pval: sc_VALUE):boolean;
  function el_SetValue(he: HELEMENT; const  pval: sc_VALUE):boolean;
  function el_GetExpando(he: HELEMENT; var  pval: sc_VALUE; forceCreation: BOOLean ):boolean;
  function el_GetObject(he:HELEMENT; var pval: pointer {tiscript_value*}; forceCreation: BOOLean ):boolean;
  function el_GetNamespace(he: HELEMENT; var pval: pointer {tiscript_value*}):boolean;
  function el_GetHighlighted(hwnd: hwnd):HELEMENT;
  function el_SetHighlighted(hwnd: hwnd; he: HELEMENT):boolean;
   //
   ///  сервис для Элементов
   function el_FindFromID(const idStr:string; var he:helement):boolean;
   function el_SetHandler(he: HELEMENT; etype: TSCITER_EVENTS; handler: Pointer): boolean;
   /// для случая nil - стираем запись в списке
   function el_GetIDName(he: HELEMENT):string; // найти обратно тэг элемента или ''
   ///
   ///
   constructor Create(const aname, aCaption: string); virtual;
   destructor Destroy; override;
   ///
   function LoadMainFile(const aFilename:string):boolean; virtual;
   ///
   function CreateWindow(creationFlags: SCITER_CREATE_WINDOW_FLAGS; frame: TRect; OnMessages: TOnMessages; parent: HWND):boolean;
   procedure Close;
   ///  only not TApplication type ->
   procedure Run;
   procedure ProcessMessages(iTime: Cardinal = 0);
   ///
   ///
   function Show(asyncFlag:boolean=false):boolean;
   function exec(const cmd: string):boolean;
   ///
    property Handle: HWND read fHwnd;
    property OnClose:  TStdEvent read fOnClose write fOnClose;
    property onElementFailureEvent:TAgentFailureEvent read FonFailureEvent write FonFailureEvent;
    property OnError:TErrorEvent read FOnError write FOnerror;
    ///
    property Filename:string read FFilename;
    property InitialWindowState: TSciterWindowState read getInitialWindowState;
    property Visible:boolean read FVisible write SetVisible;
    // зип файл инициализирован. можно использовать для модификации скина
    // перед его загрузкой скайтером
    property OnZipFileLoad: TNotifyEvent read fOnZipFileLoad write fOnZipFileLoad;
 end;

 function  OleInitialize(pwReserved: Pointer): HResult; stdcall;  external 'ole32.dll';
 procedure OleUninitialize; stdcall; external 'ole32.dll';

 ///////////////////////////////
 ///
 ///   Преобразование к типу для Handlers
 function sc_ConvertHandleToEvent(evtg: UINT; prms:LPVOID):TSCITER_EVENTS;


 var scAgent:TscAgent=nil;

 /////////////////////////////////
 ///
 ///  обработка строки перед её отправкой в скайтер -- замены " на   \"  и пр.
 function prepareStringToValue(const AStr: string): string;

implementation

 uses  Winapi.Messages,
       Vcl.Dialogs;


function prepareStringToValue(const AStr: string): string;
var
  LS: string;
begin
  // Внимание - важен порядок вызова заменителей
  // \ to \\
  LS:=StringReplace(AStr, '\', '\\', [rfReplaceAll]);
  // " to \"
  LS:=StringReplace(LS, '"', '\"', [rfReplaceAll]);
  // ' to \'
  LS:=StringReplace(LS, '''', '\''',[rfReplaceAll]);
  Result:=LS;
end;


 procedure TErrorPlace.SetNull;
  begin
     eSender:=nil;
     eDesc:='';
     eTrace:='';
     eCode:=0;
     eNum:=0;
     eLine:=0;
     eName:='';
     ePlace:='';
  end;
 function TErrorPlace.toString:string;
 var LS:string;
  begin
    if Assigned(eSender) then LS:=eSender.ClassName;
    Result:=Concat('OBJECT=',LS,',DESC=',eDesc,',CODE=',IntToStr(eCode),'NUM=',IntToStr(eNum),'LINE=',IntToStr(eLine),
                  ',NAME=',eName,',PLACE=',ePlace,',TRACE=',eTrace);
  end;

  ///  AllSection
function TscAgent.GetClassName:string;
var LP:Pchar;
 begin
   LP:=ISciter.SciterClassName;
   Result:=Strpas(LP);
 end;
function TscAgent.GetVersion(major:boolean):integer;
 begin
   Result:=-1;
   try
     Result:=ISciter.SciterVersion(major);
    except Result:=-1;
   end;
 end;


function TscAgent.DataReady(const Ur:string; data: Pointer; dataLength: integer):integer;
var LFlag:bool;
 begin
   Result:=-1;
   try
     LFlag:=ISciter.SciterDataReady(fhwnd,Pchar(Ur),data,Uint(dataLength));
     if LFlag=true then
        Result:=0;
    except Result:=-10;
   end;
 end;

function TscAgent.DataReadyAsync(adataType:integer; const Ur:string; data: pointer; dataLength: integer; reqId:pReadyDataRecord=nil): integer;
 var LFlag:bool;
     LSCN:SCN_LOAD_DATA;
     pLSCN:PSCN_LOAD_DATA;
     L_reqId:pReadyDataRecord;
     L_record:TReadyDataRecord;
     LL:integer;
 begin
   Result:=-1;
   if reqId<>nil then
        L_reqId:=reqId
   else L_reqId:=@L_record;
   L_reqId^.cbhead_code:=0;
   L_reqId^.cbhead_hwnd:=0;
   L_reqId^.uri:='';
   L_reqId^.outData:=nil;
   L_reqId^.outDataSize:=0;
   L_reqId^.dataType:=adataType;
   L_reqId^.principal.pval:=nil;
   L_reqId^.initiator.pval:=nil;
   LSCN.cbhead.code:=0;
   LSCN.cbhead.hwnd:=fHwnd;
   LSCN.uri:=Pchar(Ur);
   LL:=Length(Ur);
   LSCN.outData:=data;
   LSCN.outDataSize:=dataLength;
   if L_reqId^.dataType<0 then LSCN.dataType:=0 //  see ->> SciterResourceType
   else LSCN.dataType:=L_reqId^.dataType;
   LSCN.requestId:=nil;
   LSCN.principal.pval:=nil;
   LSCN.principal.pval:=nil;
   pLSCN:=@LSCN;
   try
     LFlag:=ISciter.SciterDataReadyAsync(fhwnd,Pchar(Ur),data,Uint(dataLength),pLSCN);
     if LFlag=true then
      begin
        Result:=0;
        L_reqId^.cbhead_code:=pLSCN^.cbhead.code;
        L_reqId^.cbhead_hwnd:=pLSCN^.cbhead.hwnd;
        L_reqId^.uri:=WideCharLenToString(PwideChar(pLSCN^.uri),LL);
        L_reqId^.outData:=pLSCN^.outdata;
        L_reqId^.outDataSize:=pLSCN^.outDataSize;
        L_reqId^.dataType:=pLSCN^.dataType;
        L_reqId^.principal:=pLSCN^.principal;
        L_reqId^.initiator:=pLSCN^.initiator;
      end;
    except Result:=-10;
   end;
 end;

 function TscAgent.LoadDataFromStream(aDataType:integer; const AStream:TStream; const aURl:string; aUrlFormatSign:integer=0):boolean;
 var il:integer;
      LB: TBytes;
      LS:string;
  begin
   Result:=false;
   LS:=aUrl;
   case  aUrlFormatSign of
    1: LS:=Concat('file://',LS);
   end;
   AStream.Seek(0,0);
   SetLength(LB, AStream.Size);
   AStream.Read(Pointer(LB)^, AStream.Size);
   il:=DataReadyAsync(aDataType,LS,Pointer(LB),Integer( AStream.Size));
   SetLength(LB,0);
   Result:=(il=0);
  end;

function TscAgent.LoadDataFromMemStream(aDataType:integer; const AMStream:TMemoryStream; const aURl:string;  aUrlFormatSign:integer=0):boolean;
var il:integer;
    LS:string;
 begin
    Result:=false;
    LS:=aUrl;
    case  aUrlFormatSign of
     1: LS:=Concat('file://',LS);
    end;
   AMStream.Seek(0,0);
   il:=DataReadyAsync(aDataType,LS,AMStream.Memory,Integer(AMStream.Size));
   Result:=(il=0);
 end;

 function _ExtractFilename(const aUrl:String):string;
 var LS:String;
     i:integer;
  begin
    LS:=ExtractFileName(aUrl);
    Result:='';
    i:=Length(LS);
    while i>0 do
     begin
       if (LS[i]<>'/') and (LS[i]<>'\') then Result:=Concat(LS[i],Result)
       else break;
       Dec(i);
     end;
  end;

function TscAgent.LoadDataFromRes(aDataType:integer; const aURl:string; aUrlFormatSign:integer=0):boolean;
var  LresExt,Lresname:string;
     HResInfo: THandle;
     MemHandle: THandle;
    // Stream: TMemoryStream;
     ResPtr: PByte;
     ResSize: Longint;
     LS:string;
     il:integer;
 begin
     Result:=false;
     case aUrlFormatSign of
      1: LS:=Concat('file://',aUrl);
      else LS:=aUrl
     end;
     LresExt:=ExtractFileExt(aUrl);
     if LresExt[1]='.' then LResExt:=Copy(LresExt,2,Length(LresExt)-1);
     Lresname:=ChangeFileExt(_ExtractFileName(aUrl),'');
     HResInfo := FindResource(HInstance,Pchar(Lresname),Pchar(LresExt));
     if HResInfo =0 then
      begin
          MessageDlg('Error name:"'+Lresname+'" type:'+LresExt,mtError,[mbOk],0);
         // RaiseLastOSError;
          exit;
      end
     else begin
      // ShowMessage(LS);
     end;
     MemHandle := LoadResource(HInstance, HResInfo);
     ResPtr := LockResource(MemHandle);
     ResSize := SizeofResource(HInstance, HResInfo);
     il:=DataReadyAsync(aDataType,LS,ResPtr,ResSize);
    ///// il:=DataReady(LS,ResPtr,ResSize);
     Result:=(il=0);
 end;

function TscAgent.LoadDataFromResources(aDataType:integer; const Astr:array of string; aUrlFormatSign:integer=0):boolean;
var i:integer;
   // LS:String;
 begin
 //  LS:='';
   Result:=true;
   i:=Low(Astr);
   while i<=High(Astr) do
    begin
      if LoadDataFromRes(aDataType,Astr[i],aUrlFormatSign)=false then
       begin
         Result:=false;
         break; // !~~
       end;
     // else begin
     //   if LS='' then LS:=LS:=Concat(LS,
     // end;
      Inc(i);
    end;
 end;

///
function TscAgent.LoadFile(const aFilename:string):boolean;
 begin
   Result:=ISciter.SciterLoadFile(fHwnd,Pchar(aFilename));
 end;

function TscAgent.LoadHtml(aBytes:PByte; bSize:integer; const baseUrl:string):boolean;
var LP:Pointer;
    i:Uint;
 begin
  LP:=aBytes;
  i:=bSize;
  Result:=ISciter.SciterLoadHtml(fHwnd,LP,i,Pchar(BaseUrl));
 end;

function TscAgent.LoadHtmlFromRes(const aURl:string):boolean;
var  LresExt,Lresname:string;
     HResInfo: THandle;
     MemHandle: THandle;
    // Stream: TMemoryStream;
     ResPtr: PByte;
     ResSize: Longint;
     LS:string;
     il:integer;
 begin
     Result:=false;
     LS:=_ExtractFileName(aUrl);
     LresExt:=ExtractFileExt(LS);
     if LresExt[1]='.' then LResExt:=Copy(LresExt,2,Length(LresExt)-1);
     Lresname:=ChangeFileExt(LS,'');
     HResInfo := FindResource(HInstance,Pchar(Lresname),Pchar(LresExt));
     if HResInfo =0 then
      begin
          RaiseLastOSError;
          exit;
      end;
     MemHandle := LoadResource(HInstance, HResInfo);
     ResPtr := LockResource(MemHandle);
     ResSize := SizeofResource(HInstance, HResInfo);
     Result:=ISciter.SciterLoadHtml(fHwnd,ResPtr,ResSize,Pchar(aUrl));
     Result:=(il=0);
 end;

function TscAgent.SetCallbackRegime(aCBRegime:integer):boolean;
 begin
   Result:=true;
   case aCBRegime of
   0: ISciter.SciterSetCallback(fHwnd,nil,nil);
   1: begin
       SetBHProtocol(1);
       ISciter.SciterSetCallback(fHwnd,@BasicHostCallback,nil);
      end;
   else Result:=false;
   end;
 end;


function TscAgent.SetMediaType(const mediaType:String):boolean;
 begin
  Result:=ISciter.SciterSetMediaType(fHwnd,Pchar(mediaType));
 end;

function TscAgent.SetMediaVars(const mediaVars: PSCITER_VALUE):boolean;
 begin
   Result:=ISciter.SciterSetMediaVars(fHwnd,mediaVars);
 end;

function TscAgent.GetMinWidth:integer;
 begin
   Result:=ISciter.SciterGetMinWidth(fHwnd);
 end;

function TscAgent.GetMinHeight(aWd:integer):integer;
 begin
   Result:=ISciter.SciterGetMinHeight(fHwnd,aWd);
 end;
///
procedure TscAgent.UpdateWindow;
 begin
   ISciter.SciterUpdateWindow(fHwnd);
 end;
///
function TscAgent.SetOption(option:SCITER_RT_OPTIONS; value:integer):boolean;
var il:uint;
 begin
    il:=value;
    Result:=ISciter.SciterSetOption(fHwnd,Uint(option),il);
    ///
 end;

function TscAgent.GetPPI:Tpoint;
var i,j:uint;
 begin
  ISciter.SciterGetPPI(fhwnd,i,j);
  Result:=Point(i,j);
 end;

function TscAgent.GetViewExpando(var Pval:PSCITER_VALUE):boolean;
 begin
   Result:=ISciter.SciterGetViewExpando(fhwnd,Pval);
 end;
///
function TscAgent.getGraphicsCaps(var aType:integer):boolean;
var i:Uint;
 begin
    i:=aType;
    Result:=ISciter.SciterGraphicsCaps(@i);
    aType:=i;
 end;

function TscAgent.SetHomeURL(const aURL:string):boolean;
 begin
  Result:=ISciter.SciterSetHomeURL(fhwnd,Pchar(aURL));
 end;

/////////////////////////////////////////////////////////////////////////////////////////////
///
///   Properties metods
 procedure TscAgent.SetVisible(value:boolean);
  begin
    if Value<>FVisible then
     begin
       if value=false then
        begin

        end
       else begin
         Show();
       end;
     end;
  end;

function  TscAgent.getInitialWindowState:TSciterWindowState;
 begin
    Result:=self.fInitialWindowState;
 end;


//////////////////////////////////////////////////////////////////////////////////////////////
///
///  element API
///

procedure TscAgent.el_failure(const APlace,aText:string; aUid:cardinal);
var LR:integer;
 begin
     case fLastResult of
        SCDOM_INVALID_HWND: LR:=1;
        SCDOM_INVALID_HANDLE: LR:=2;
        SCDOM_PASSIVE_HANDLE: LR:=3;
        SCDOM_INVALID_PARAMETER: Lr:=4;
        SCDOM_OPERATION_FAILED: LR:=5;
        SCDOM_OK_NOT_HANDLED: LR:=-1;
        else LR:=-10;
     end;
   if Assigned(FonFailureEvent) then
      FonFailureEvent(APlace,aUid,LR,atext);
 end;

 procedure TscAgent.ConcatErrorData(aEE:Exception;  const adata:string=''; aLine:integer=0);
  var LER:TErrorPlace;
   begin
      LER.SetNull;
      LER.eSender:=Self;
      LER.eDesc:=Concat('class=',aEE.ClassName,' ',aEE.Message,' (',aData,')');
      LER.eCode:=0;
      LER.eLine:=aLine;
      LER.eTrace:=aEE.StackTrace;
      LER.ePlace:='sc_Agent.pas';
      if Assigned(FonError) then FonError(LER)
      else
          MessageDlg(LER.toString,mtError,[mbOk],0);
   end;

function TscAgent.handle_scripting_call_E(he: HELEMENT; prms: PSCRIPTING_METHOD_PARAMS): boolean;
var
  i:integer;
  a: PSCITER_VALUE;
  Mas:Variant;
  LS:string;
  LR:boolean;
  Ld:double;
begin
  Result:=false;
   if assigned(ScryptHandlerEvent)=false then exit;
  if prms.argc>0 then begin
    LS:=StrPas(prms.name);
    Mas:=VarArrayCreate([0, prms.argc], varVariant);
    Mas[0]:= VarArrayHighBound(Mas, 1);
    LR:=true;
    for i:=0 to prms.argc-1 do begin
      try
        a:= PSCITER_VALUE(Cardinal(prms.argv)+(i * SizeOf(SCITER_VALUE)));
        case a^.t of
          0: ; //undefined
          1: ; //null
          2: begin //bool
               Mas[i+1] := boolean(a^.d = 1);
             end;
          3: begin //integer
               Mas[i+1] := integer(a^.d);
             end;
          4: begin
               //float
               Ld:=PDouble(@a^.d)^;
               Mas[i+1]:=LD;
             end;
          5: begin   //string;
               Mas[i+1] := string(PChar(Pointer(DWORD(a^.d+8))));
             end;
         end;
        ///
        ///
      except LR:=false;
      end;
    end;
       if (LR=true) and (assigned(ScryptHandlerEvent)) then
         begin
           LR:=false;
           ScryptHandlerEvent(LS,Mas,LR);
           // prms.result:=nil;
           Result:=LR;
         end;
     VarClear(Mas);
  end;
end;

function TscAgent.el_Proc(tag: LPVOID; he: HELEMENT; evtg: UINT; prms: LPVOID): BOOL;
var
// w: word;
 LRes:boolean;
 i: ElementID;
 L_EventType:TSCITER_EVENTS;
begin
        Result := False;
        /// willi
        ///
        if Assigned(el_HandlerEvent) then
           begin
            LRes:=false;
          //  fEvents.FindEvent(he,)
            L_EventType:=sc_ConvertHandleToEvent(evtg,prms);
            if L_EventType=eOnScrypt then
             begin
               result:=handle_scripting_call_E(he,PSCRIPTING_METHOD_PARAMS(prms));
             end
            else
              el_HandlerEvent(tag,he.pval,he.toUID,evtg,prms,L_EventType,fEvents.FindEvent(he,L_EventType),Lres); // !!
            if LRes=true then exit;
            ///
          //  Result:=true;
           end;
        ///  end willi
        ///
        case evtg of
          SUBSCRIPTIONS_REQUEST:
              begin
               Result:=(he.pval <> nil );
              end;

          HANDLE_INITIALIZATION:
          begin
            result:=True;
          end;

          HANDLE_SIZE:
          begin
            result:=True;
          end;

          HANDLE_MOUSE: begin
           if (PMOUSE_PARAMS(prms)^.cmd) or $10000 = (PMOUSE_PARAMS(prms)^.cmd) then Exit(False); //ignore handled
           if (PMOUSE_PARAMS(prms)^.cmd) or $8000  = (PMOUSE_PARAMS(prms)^.cmd) then Exit(False); //ignore sysc
           if PMOUSE_PARAMS(prms)^.cmd = UINT(MOUSE_CLICK) then begin

           end;

            result:=false;
          end;

          HANDLE_TIMER,HANDLE_FOCUS,HANDLE_KEY,
          HANDLE_BEHAVIOR_EVENT, HANDLE_METHOD_CALL,HANDLE_DATA_ARRIVED,HANDLE_SCROLL:
          begin
             result:=True;
          end;

          HANDLE_SCRIPTING_METHOD_CALL:
          begin
            result:=True;//
           // result:=handle_scripting_call(he,PSCRIPTING_METHOD_PARAMS(prms));
           end;

          HANDLE_TISCRIPT_METHOD_CALL: ;

          else      Assert(false,'TscAgent.el_Proc: Error sciter proc type');
        end;
end;

function TscAgent.scWindowProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var hndld: BOOL;
begin
       if Msg = WM_CLOSE then begin
         if Assigned(fOnClose) then fOnClose();
         PostQuitMessage(0);
       end;
       if Msg = WM_DESTROY then  PostQuitMessage(0);
      if (fHwnd=0) or (fHwnd=hwnd) then
       try
        if (fHwnd=0) then fHwnd:=hwnd;

        hndld:=Assigned(fOnMessages) and fOnMessages(hwnd,Msg,wParam,lParam,Result);
        if not hndld then
           result:= ISciter.SciterProcND( hWnd,Msg,wParam, lParam, hndld);
        if not hndld then
            result:= DefWindowProc(hWnd, msg, wParam, lParam);
        except
        //errors handling
      end
     else if (hwnd<>0) then
            begin
             //  result:= DefWindowProc(hWnd, msg, wParam, lParam);
            end;
end;

////////////////////////////////////////////////////////////   public 1
function TscAgent.el_Use(he: HELEMENT):boolean;
 begin
  fLastResult:=ISciter.Sciter_UseElement(he);
  Result:=(fLastResult=SCDOM_OK);
  if Result=false then
     el_failure('el_Use','',he.toUID);
 end;

function TscAgent.el_Unuse(he: HELEMENT):boolean;
 begin
  fLastResult:=ISciter.Sciter_UnuseElement(he);
  Result:=(fLastResult=SCDOM_OK);
  if Result=false then
     el_failure('el_Unuse','',he.toUID);
 end;

function TscAgent.el_GetRoot:HELEMENT;
 begin
  Result.pval:=nil;
  fLastResult:=ISciter.SciterGetRootElement(fhwnd,Result);
  if (fLastResult<>SCDOM_OK) then
   begin
      Result.pval:=nil;
      el_failure('el_GetRoot','',0);
   end;
 end;

function TscAgent.el_GetFocus:HELEMENT;
 begin
    Result.pval:=nil;
    fLastResult:=ISciter.SciterGetFocusElement(fhwnd,Result);
    if (fLastResult<>SCDOM_OK) then
     begin
        Result.pval:=nil;
        el_failure('el_GetFocus','',0);
     end;
 end;

function TscAgent.el_Find(pt: TPoint):HELEMENT;
 begin
   Result.pval:=nil;
   fLastResult:=ISciter.SciterFindElement(fhwnd,pt,Result);
   if (fLastResult<>SCDOM_OK) then
    begin
       Result.pval:=nil;
       el_failure('el_Find',Concat('X=',IntToStr(pt.X),' Y=',IntToStr(pt.Y)),0);
    end;
 end;

function TscAgent.el_GetChildrenCount(he: HELEMENT):integer;
var i:uint;
 begin
   Result:=-1;
   fLastResult:=ISciter.SciterGetChildrenCount(he,i);
   if (fLastResult=SCDOM_OK) then
       Result:=i
   else el_failure('el_GetChildrenCount','',he.toUID);
 end;

function TscAgent.el_GetNthChild(he: HELEMENT; num:integer):HELEMENT;
 begin
  Result.pval:=nil;
  fLastResult:=ISciter.SciterGetNthChild(he,Uint(num),Result);
  if (fLastResult<>SCDOM_OK) then
    begin
       Result.pval:=nil;
       el_failure('el_GetNthChild',Concat('NUM=',IntToStr(num)),he.toUID);
    end;
 end;

function TscAgent.el_GetParent(he: HELEMENT):HELEMENT;
 begin
  Result.pval:=nil;
  fLastResult:=ISciter.SciterGetParentElement(he,Result);
  if (fLastResult<>SCDOM_OK) then
   begin
       Result.pval:=nil;
        el_failure('el_GetParent','',he.toUID);
   end;
 end;

      var sc_EL_GetHtml:string;
      procedure _EL_GetHtml( str: LPCSTR; str_length: UINT; param: LPVOID); stdcall;
       begin
         SetString(sc_EL_GetHtml,str,str_length);
       end;

function TscAgent.el_GetHtml(he: HELEMENT; outer: boolean):string;
var Lproc:LPCSTR_RECEIVER;
    LP:pointer;
 begin
   Result:='';
   sc_EL_GetHtml:='';
   Lproc:=@_EL_GetHtml;
   LP:=@Lproc;
   fLastResult:=ISciter.SciterGetElementHtmlCB(he,Bool(outer),Lp,nil);
   if (fLastResult=SCDOM_OK) then
      Result:=sc_EL_GetHtml
   else el_failure('el_GetHtml','',he.toUID);
 end;

      var sc_EL_GetText:string;
      procedure _EL_GetText( str: LPCSTR; str_length: UINT; param: LPVOID); stdcall;
       begin
        sc_EL_GetText:=WideCharLenToString(PwideChar(str),str_length);
       end;

function TscAgent.el_GetText(he: HELEMENT):string;
var Lproc:LPCSTR_RECEIVER;
 begin
   Result:='';
   sc_EL_GetText:='';
   Lproc:=@_EL_GetText;
   fLastResult:=ISciter.SciterGetElementTextCB(he,Lproc,nil);
   if (fLastResult=SCDOM_OK) then
      Result:=sc_EL_GetText
   else el_failure('el_GetText','',he.toUID);
 end;

function TscAgent.el_GetAttributeCount(he: HELEMENT):integer;
var p_count: UINT;
 begin
   Result:=-1;
   fLastResult:=ISciter.SciterGetAttributeCount(he,p_count);
   if (fLastResult=SCDOM_OK) then result:=p_count
   else el_failure('el_GetAttributeCount','',he.toUID);
 end;

    var sc_EL_GetAname:string;
    procedure _EL_GetAname( str: LPCSTR; str_length: UINT; param: LPVOID); stdcall;
     begin
      sc_EL_GetAname:=WideCharLenToString(PwideChar(str),str_length);
     end;

function TscAgent.el_GetNthAttributeName(he: HELEMENT; num:integer):string;
var Lproc:LPCSTR_RECEIVER;
 begin
   Result:='';
   sc_EL_GetAname:='';
   Lproc:=@_EL_GetAname;
   fLastResult:=ISciter.SciterGetNthAttributeNameCB(he,Uint(num),Lproc,nil);
   if (fLastResult=SCDOM_OK) then
      Result:=sc_EL_GetAname
   else el_failure('el_GetNthAttributeName',Concat('NUM=',IntToStr(num)),he.toUID);
 end;

    var sc_EL_GetAvalue:string;
    procedure _EL_GetAvalue( str: LPCSTR; str_length: UINT; param: LPVOID); stdcall;
     begin
      sc_EL_GetAvalue:=WideCharLenToString(PwideChar(str),str_length);
     end;

function TscAgent.el_GetNthAttributeValue(he: HELEMENT; num:integer):string;
var Lproc:LPCSTR_RECEIVER;
     Lp:pointer;
 begin
   Result:='';
   sc_EL_GetAvalue:='';
   Lproc:=@_EL_GetAvalue;
   LP:=@Lproc;
   fLastResult:=ISciter.SciterGetNthAttributeValueCB(he,Uint(num),Lp,nil);
   if (fLastResult=SCDOM_OK) then
      Result:=sc_EL_GetAvalue
   else el_failure('el_GetNthAttributeValue',Concat('NUM=',IntToStr(num)),he.toUID);
 end;

    var sc_EL_GetABB:string;
    procedure _EL_GetABB( str: LPCSTR; str_length: UINT; param: LPVOID); stdcall;
     begin
      sc_EL_GetABB:=WideCharLenToString(PwideChar(str),str_length);
     end;


function TscAgent.el_GetAttributeByName(he: HELEMENT; const aname:string):string;
   var Lproc:LPCSTR_RECEIVER;
       Lp:pointer;
       LAChar:PAnsiChar;
 begin
   Result:='';
   sc_EL_GetABB:='';
   Lproc:=@_EL_GetABB;
   LP:=@Lproc;
   LAChar:=PansiChar(AnsiString(aname));
   fLastResult:=ISciter.SciterGetAttributeByNameCB(he,LAchar,Lp,nil);
   if (fLastResult=SCDOM_OK) then
      Result:=sc_EL_GetABB
   else
       el_failure('el_GetAttributeByName',Concat('NAME=',aname),he.toUID);
 end;

function TscAgent.el_SetAttributeByName(he: HELEMENT;const aname,aValue:string):boolean;
 begin
  fLastResult:=ISciter.SciterSetAttributeByName(he,PAnsiChar(AnsiString(aname)),PWideChar(aValue));
  Result:=(fLastResult=SCDOM_OK);
  if Result=false then
   el_failure('el_SetAttributeByName',Concat('NAME=',aname,' VALUE=',avalue),he.toUID);
 end;

function TscAgent.el_ClearAttributes(he: HELEMENT):boolean;
 begin
  fLastResult:=ISciter.SciterClearAttributes(he);
  Result:=(fLastResult=SCDOM_OK);
  if Result=false then
     el_failure('el_ClearAttributes','',he.toUID);
 end;

function TscAgent.el_GetIndex(he: HELEMENT):integer;
var i:uint;
 begin
  Result:=-1;
  fLastResult:=ISciter.SciterGetElementIndex(he,i);
  if (fLastResult=SCDOM_OK) then Result:=i
  else el_failure('el_GetIndex','',he.toUID);
 end;

function TscAgent.el_GetType(he: HELEMENT):string;
var LStr:LPCSTR;
 begin
  Result:='';
  fLastResult:=ISciter.SciterGetElementType(he,LStr);
  if (fLastResult=SCDOM_OK) then
      Result:=Strpas(LStr)
  else el_failure('el_GetType','',he.toUID);
 end;

   var sc_EL_GetType:string;
    procedure _EL_GetType( str: LPCSTR; str_length: UINT; param: LPVOID); stdcall;
     begin
      sc_EL_GetType:=WideCharLenToString(PwideChar(str),str_length);
     end;

function TscAgent.el_GetTypeCB(he: HELEMENT):string;
   var Lproc:LPCSTR_RECEIVER;
       Lp:pointer;
 begin
   Result:='';
   sc_EL_GetType:='';
   Lproc:=@_EL_GetType;
   LP:=@Lproc;
   fLastResult:=ISciter.SciterGetElementTypeCB(he,Lp,nil);
   if (fLastResult=SCDOM_OK) then
      Result:=sc_EL_GetType
   else el_failure('el_GetTypeCB','',he.toUID);
 end;

   var sc_EL_GetStyleAttr:string;
    procedure _EL_GetStyleAttr( str: LPCSTR; str_length: UINT; param: LPVOID); stdcall;
     begin
       sc_EL_GetStyleAttr:=WideCharLenToString(PwideChar(str),str_length);
     end;

function TscAgent.el_GetStyleAttribute(he: HELEMENT; const aname: string):string;
   var Lproc:LPCSTR_RECEIVER;
       Lp:pointer;
 begin
   Result:='';
   sc_EL_GetStyleAttr:='';
   Lproc:=@_EL_GetStyleAttr;
   LP:=@Lproc;
   fLastResult:=ISciter.SciterGetStyleAttributeCB(he,PAnsichar(AnsiString(aname)),Lp,nil);
   if (fLastResult=SCDOM_OK) then
      Result:=sc_EL_GetStyleAttr
   else el_failure('el_GetStyleAttribute',Concat('NAME=',aname),he.toUID);
 end;

function TscAgent.el_SetStyleAttribute(he: HELEMENT;  const aname,aValue: string):boolean;
 begin
  fLastResult:=ISciter.SciterSetStyleAttribute(he,PansiChar(AnsiString(aname)),PWideChar(aValue));
  Result:=(fLastResult=SCDOM_OK);
  if Result=false then
    el_failure('el_SetStyleAttribute',Concat('NAME=',aname,' VALUE=',avalue),he.toUID);
 end;

function TscAgent.el_GetLocation(he: HELEMENT; areas: integer; var ARect:Trect):boolean;
 begin
   Result:=false;
   fLastResult:=ISciter.SciterGetElementLocation(he,@Arect,Uint(areas));
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
    el_failure('el_GetLocation',Concat('AREAS=',IntToStr(areas)),he.toUID);
 end;

function TscAgent.el_ScrollToView(he: HELEMENT; aScroll_ToTop,aScrollSmooth:boolean):boolean;
var L_Flag:uint;
 begin
   L_Flag:=0;
   if aScroll_ToTop then L_flag:=L_flag or $1;
   if aScrollSmooth then L_flag:=L_flag or $10;
   fLastResult:=ISciter.SciterScrollToView(he,L_flag);
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
    el_failure('el_ScrollToView',Concat('SIGN=',IntToStr(L_flag)),he.toUID);
 end;

function TscAgent.el_Update(he: HELEMENT; andForceRender: boolean):boolean;
 begin
   fLastResult:=ISciter.SciterUpdateElement(he,andForceRender);
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
    el_failure('el_Update',Concat('FORCE=',BoolToStr(andForceRender)),he.toUID);
 end;

function TscAgent.el_RefreshArea(he: HELEMENT; rRect: TRect):boolean;
 begin
   fLastResult:=ISciter.SciterRefreshElementArea(he,rRect);
    Result:=(fLastResult=SCDOM_OK);
    if Result=false then
    el_failure('el_RefreshArea',Concat('Left=',IntToStr(rRect.Left),' Top=',IntToStr(rRect.Left),
                                       ' Right=',IntToStr(rRect.Right),' Bottom=',IntToStr(rRect.Bottom)),he.toUID);
 end;

function TscAgent.el_SetCapture(he: HELEMENT):boolean;
 begin
   fLastResult:=ISciter.SciterSetCapture(he);
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
    el_failure('el_SetCapture','',he.toUID);
 end;

function TscAgent.el_ReleaseCapture(he: HELEMENT):boolean;
 begin
   fLastResult:=ISciter.SciterReleaseCapture(he);
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
    el_failure('el_ReleaseCapture','',he.toUID);
 end;

function TscAgent.el_GetHwnd(he: HELEMENT; rootWindow: BOOLean):HWND; // 0 - in error
var p_hwnd: HWND;
 begin
   Result:=0;
   fLastResult:=ISciter.SciterGetElementHwnd(he,p_hwnd,rootWindow);
   if (fLastResult=SCDOM_OK) then Result:=p_hwnd
   else
       el_failure('el_GetHwnd',Concat('ROOTWND=',BoolToStr(rootWindow)),he.toUID);
 end;

function TscAgent.el_CombineURL(he: HELEMENT; const UrlBuffer: string):boolean;
var Lp:PwideChar;
    LSize:uint;
 begin
  LP:=PwideChar(UrlBuffer);
  LSize:=Length(LP);
  fLastResult:=ISciter.SciterCombineURL(he,Lp,Lsize);
  Result:=(fLastResult=SCDOM_OK);
  if Result=false then
    el_failure('el_CombineURL',Concat('URL=',UrlBuffer),he.toUID);
 end;

function TscAgent.el_SelectParent(he: HELEMENT; const aSelector:string; aDepth:integer; ansiFlag:boolean):HELEMENT;
 begin
  Result.pval:=nil;
  if ansiFlag then
     fLastResult:=ISciter.SciterSelectParent(he,PansiChar(AnsiString(aSelector)),Uint(aDepth),Result)
  else
     fLastResult:=ISciter.SciterSelectParentw(he,PWideChar(aSelector),Uint(aDepth),Result);
  if (flastResult<>SCDOM_OK) then
   begin
     Result.pval:=nil;
     el_failure('el_SelectParent',Concat('SELECTOR=',aSelector,' DEPTH=',IntToStr(aDepth),
                ' ANSI=',BoolToStr(ansiFlag)),he.toUID);
   end;
 end;
///

{   function in Sciter.pas

      function fAllElementCallback( he: HELEMENT; param: LPVOID  ): BOOL; stdcall;
      begin
          HELEMENTS(param^).add(he);
          result:=false; //more, more elements
      end;
      }

function TscAgent.el_Select(const selector: string): HELEMENTS;
var Lroot: HELEMENT;
    LRes:SCDOM_RESULT;
begin
  LRes:=ISciter.SciterGetRootElement(fhwnd,Lroot);
  if (LRes=SCDOM_OK) then
     Lres:=ISciter.SciterSelectElementsW(Lroot,PChar(selector),fAllElementCallback,@result);
  fLastResult:=LRes;
  if (LRes<>SCDOM_OK) then
    begin
     el_failure('el_Select',Concat('SELECTOR="',Selector,'"'),0);
    end;
end;


function TscAgent.el_SelectFirst(const selector: string): HELEMENT;
var Lroot: HELEMENT;
    LRes:SCDOM_RESULT;
begin
  Result.pval:=nil;
  LRes:=ISciter.SciterGetRootElement(fhwnd,Lroot);
  if (LRes=SCDOM_OK) then
   begin
     LRes:=ISciter.SciterSelectElementsW(Lroot,PChar(selector),fOneElementCallback,@result.pval);
   end;
  fLastResult:=LRes;
  if (fLastResult<>SCDOM_OK) then
     el_failure('el_SelectFirst',Concat('SELECTOR="',Selector,'"'),0);
end;

///
function TscAgent.el_SetHtml(he: HELEMENT; const htmlTxt: string; whereSign: integer):boolean;
var lp:PAnsiChar;
    LSize:uint;
 begin
  lp:=PAnsiChar(AnsiString(htmlTxt));
  LSize:=Uint(Length(lp));
  fLastResult:=ISciter.SciterSetElementHtml(he,Lp,Lsize,Uint(whereSign));
  Result:=(fLastResult=SCDOM_OK);
  if Result=false then
    el_failure('el_SetHtml',Concat('HTML=',htmlTxt,' WHERESIGN=',IntToStr(whereSign)),he.toUID);
 end;

function TscAgent.el_GetUID(he: HELEMENT):integer; // -1 in error
var i:Uint;
 begin
   Result:=-1;
   fLastResult:=ISciter.SciterGetElementUID(he,i);
  if (fLastResult=SCDOM_OK) then
     result:=i
  else
     el_failure('el_GetUID','',he.toUID);
 end;

function TscAgent.el_GetByUID(uid: integer):HELEMENT;
 begin
   Result.pval:=nil;
   fLastResult:=ISciter.SciterGetElementByUID(fhwnd,Uint(uid),Result);
  if (fLastResult<>SCDOM_OK) then
   begin
     result.pval:=nil;
     el_failure('el_GetByUID',Concat('UID=',IntToStr(uid)),0);
   end;
 end;

function TscAgent.el_ShowPopup(popup: HELEMENT; Anchor: HELEMENT; placement: integer):boolean;
 begin
    fLastResult:=ISciter.SciterShowPopup(popup,Anchor,Uint(placement));
    Result:=(fLastResult=SCDOM_OK);
    if Result=false then
      el_failure('el_ShowPopup',Concat('popup_UID=',IntToStr(popup.toUID),' Anchor_UID=',IntToStr(Anchor.toUID),
                                       ' PLACE=',IntToStr(placement)),popup.toUID);
 end;

function TscAgent.el_ShowPopupAt(Popup: HELEMENT; posP: TPoint; animate: Boolean):boolean;
 begin
    fLastResult:=ISciter.SciterShowPopupAt(popup,posP,animate);
    Result:=(fLastResult=SCDOM_OK);
    if Result=false then
       el_failure('el_ShowPopupAt',Concat('POS_X=',IntToStr(posP.X),' POS_Y=',IntToStr(posP.Y),
                                          ' ANIMATE=',BoolToStr(animate)),popup.toUID);
 end;

function TscAgent.el_SciterHidePopup(he: HELEMENT):boolean;
 begin
   fLastResult:=ISciter.SciterHidePopup(he);
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
       el_failure('el_SciterHidePopup','',he.toUID);
 end;

function TscAgent.el_GetState(he: HELEMENT):integer; // -1 - not correct
var i:uint;
 begin
   Result:=-1;
   fLastResult:=ISciter.SciterGetElementState(he,i);
   if (fLastResult=SCDOM_OK) then
    Result:=i
   else el_failure('el_GetState','',he.toUID);
 end;

function TscAgent.el_SetStateEx(he: HELEMENT; aStateBits,aStateClearBits:integer; updateViewFlag:boolean):boolean;
 begin
  fLastResult:=ISciter.SciterSetElementState(he,Uint(aStateBits),Uint(aStateClearBits),updateViewFlag);
  Result:=(fLastResult=SCDOM_OK);
  if Result=false then
       el_failure('el_SetStateEx',Concat('STATEBITS=',IntToStr(aStateBits),' CLEARBITS=',IntToStr(aStateClearBits),
                                         ' UPDATE_FLAG=',BoolToStr(updateViewFlag)),he.toUID);
 end;

function TscAgent.el_Create(const tagName, text:string):HELEMENT;
var LP:PwideChar;
 begin
   Result.pval:=nil;
   if text='' then LP:=nil else LP:=PWideChar(text);
   fLastResult:=ISciter.SciterCreateElement(PAnsiChar(AnsiString(tagname)),LP,Result);
   if (fLastResult<>SCDOM_OK) then
    begin
       result.pval:=nil;
        el_failure('el_Create',Concat('TAG=',tagname,' TEXT="',text,'"'),0);
    end;
 end;

function TscAgent.el_Clone(he: HELEMENT):Helement;
 begin
   result.pval:=nil;
   fLastResult:=ISciter.SciterCloneElement(he,Result);
    if (fLastResult<>SCDOM_OK) then
    begin
       result.pval:=nil;
       el_failure('el_Clone','',he.toUID);
    end;
 end;

function TscAgent.el_Insert( he: HELEMENT; hparent: HELEMENT; index:integer):boolean;
 begin
   fLastResult:=ISciter.SciterInsertElement(he,hParent,Uint(index));
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
       el_failure('el_Insert',Concat('PARENT_UID=',IntToStr(hparent.toUID),' INDEX=',IntToStr(index)),he.toUID);
 end;

function TscAgent.el_Detach(he: HELEMENT):boolean;
 begin
  fLastResult:=ISciter.SciterDetachElement(he);
  Result:=(fLastResult=SCDOM_OK);
  if Result=false then
       el_failure('el_Detach','',he.toUID);
 end;

function TscAgent.el_Delete(he: HELEMENT):boolean;
 begin
   fLastResult:=ISciter.SciterDeleteElement(he);
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
       el_failure('el_Delete','',he.toUID);
 end;

function TscAgent.el_SetTimer( he: HELEMENT; milliseconds: integer; var timer_id:integer):boolean;
var i:Uint;
 begin
   fLastResult:=ISciter.SciterSetTimer(he,Uint(milliseconds),i);
   Result:=(fLastResult=SCDOM_OK);
   if Result=true then
       timer_id:=i
   else el_failure('el_SetTimer',Concat('MSEC=',IntTostr(milliseconds)),he.toUID);
 end;

function TscAgent.el_ClearTimer( he: HELEMENT):boolean;
 var i:Uint;
 begin
   fLastResult:=ISciter.SciterSetTimer(he,0,i);
   Result:=(fLastResult=SCDOM_OK);
   if Result=true then
    begin

    end
   else el_failure('el_ClearTimer','',he.toUID);
 end;

function TscAgent.el_DetachEventHandler(he: HELEMENT; pep: LPELEMENT_EVENT_PROC):boolean;
var Ltag:pointer;
 begin
  Ltag:=nil;
  fLastResult:=ISciter.SciterDetachEventHandler(he,pep,Ltag);
  Result:=(fLastResult=SCDOM_OK);
  if Result=false then el_failure('el_DetachEventHandler','',he.toUID);
 end;

function TscAgent.el_AttachEventHandler(he: HELEMENT; pep: LPELEMENT_EVENT_PROC):boolean;
   var Ltag:pointer;
 begin
  Ltag:=nil;
  fLastResult:=ISciter.SciterAttachEventHandler(he,pep,Ltag);
  Result:=(fLastResult=SCDOM_OK);
  if Result=false then el_failure('el_AttachEventHandler','',he.toUID);
 end;

function TscAgent.el_WindowAttachEventHandler( hwndLayout: HWND; pep: LPELEMENT_EVENT_PROC; subscription: integer):boolean;
 var Ltag:pointer;
 begin
  Ltag:=nil;
  fLastResult:=ISciter.SciterWindowAttachEventHandler(hwndLayout,pep,Ltag,subscription);
  Result:=(fLastResult=SCDOM_OK);
  if Result=false then el_failure('el_WindowAttachEventHandler','',0);
 end;

function TscAgent.el_WindowDetachEventHandler( hwndLayout: HWND; pep: LPELEMENT_EVENT_PROC):boolean;
var Ltag:pointer;
 begin
  Ltag:=nil;
  fLastResult:=ISciter.SciterWindowDetachEventHandler(hwndLayout,pep,Ltag);
  Result:=(fLastResult=SCDOM_OK);
  if Result=false then el_failure('el_WindowDetachEventHandler','',0);
 end;

function TscAgent.el_SendEvent(he: HELEMENT; appEventCode: UINT; aSource: HELEMENT; reason: PUINT; var handled: BOOL):boolean;
 begin
  fLastResult:=ISciter.SciterSendEvent(he,appEventCode,aSource,reason,handled);
  Result:=(fLastResult=SCDOM_OK);
  if Result=false then
      el_failure('el_SendEvent',Concat('APPEVENTCODE=',IntToStr(appEventCode),
                                       ' SourceUID=',IntToStr(aSource.toUID),
                                       ' REASON=',IntTostr(reason^),
                                       ' HANDLED=',BoolToStr(handled)),he.toUID);
 end;

function TscAgent.el_PostEvent(he: HELEMENT; appEventCode: UINT; aSource: HELEMENT; reason: PUINT):boolean;
 begin
    fLastResult:=ISciter.SciterPostEvent(he,appEventCode,aSource,reason);
    Result:=(fLastResult=SCDOM_OK);
    if Result=false then
      el_failure('el_PostEvent',Concat('APPEVENTCODE=',IntToStr(appEventCode),
                                       ' SourceUID=',IntToStr(aSource.toUID),
                                       ' REASON=',IntTostr(reason^)),he.toUID);
 end;

function TscAgent.el_CallBehaviorMethod(he:HELEMENT; params: PMETHOD_PARAMS):boolean;
 var LS:String;
 begin
  fLastResult:=ISciter.SciterCallBehaviorMethod(he,params);
  Result:=(fLastResult=SCDOM_OK);
  if Result=false then
   begin
    LS:='NIL';
    if params<>nil then LS:=IntToStr(params^.methodID);
    el_failure('el_CallBehaviorMethod',Concat('ParamsID=',LS),0);
   end;
 end;

function TscAgent.el_RequestElementData(he: HELEMENT;const URL:String; dataType: UINT; initiator: HELEMENT):boolean;
 begin
   fLastResult:=ISciter.SciterRequestElementData(he,PwideChar(url),dataType,initiator);
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
     el_failure('el_RequestElementData',Concat('URL=',URL,' DATATYPE=',IntToStr(dataType),
                                               ' Initiator_UID=',IntToStr(initiator.toUID)),he.toUID);
 end;

function TscAgent.el_HttpRequest(he: HELEMENT;           // element to deliver data
                            const url:string;          // url
                            dataType: UINT;     // data type, see SciterResourceType.
                            requestType: UINT;  // one of REQUEST_TYPE values
                            requestParams: PREQUEST_PARAMS;// parameters
                            nParams: UINT       // number of parameters
                            ):boolean;
 var LS:string;
  begin
   fLastResult:=ISciter.SciterHttpRequest(he,PwideChar(url),dataType,requestType,requestParams,nParams);
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
    begin
       LS:='NIL';
       if (requestParams<>nil) then LS:=IntToStr(requestParams^.methodID);
       el_failure('el_HttpRequest',Concat('URL=',URL,' DATATYPE=',IntToStr(dataType),
                                               ' REQ_TYPE=',IntToStr(requestType),
                                               ' REQ_PARAMS_M_ID=',LS,
                                               ' NPARAMS=',IntToStr(nParams)),he.toUID);
    end;
  end;
function TscAgent.el_GetScrollInfo(he: HELEMENT; scrollPos: TPoint; viewRect:TRect; contentSize: TSize):boolean;
 begin
   fLastResult:=ISciter.SciterGetScrollInfo(he,scrollPos,viewRect,contentSize);
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
       el_failure('el_GetScrollInfo',Concat('SCROLL_X=',IntToStr(scrollPos.X),' SCROLL_Y=',IntToStr(scrollPos.Y),
                                            ' VR_LEFT=',IntToStr(viewRect.Left),
                                            ' VR_TOP=',IntToStr(viewRect.Top),
                                            ' VR_RIGHT=',IntToStr(viewRect.Right),
                                            ' VR_BOTTOM=',IntToStr(viewRect.Bottom),
                                            ' Content_Size_X=',IntToStr(contentSize.cx),
                                            ' Content_Size_Y=',IntToStr(contentSize.cy)),he.toUID);
 end;

function TscAgent.el_SetScrollPos(he: HELEMENT; scrollPos: TPoint; smoothFlag:boolean):boolean;
 begin
   fLastResult:=ISciter.SciterSetScrollPos(he,scrollPos,smoothFlag);
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
       el_failure('el_SetScrollPos',Concat('SCROLL_X=',IntToStr(scrollPos.X),' SCROLL_Y=',IntToStr(scrollPos.Y),
                                            ' SMOOTH=',BoolToStr(smoothFlag)),he.toUID);
 end;

function TscAgent.el_GetIntrinsicWidths(he: HELEMENT; var pMinWidth: integer; var pMaxWidth: integer ):boolean;
 begin
   fLastResult:=ISciter.SciterGetElementIntrinsicWidths(he,pMinWidth,pMaxWidth);
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
       el_failure('el_GetIntrinsicWidths','',he.toUID);
 end;

function TscAgent.el_GetIntrinsicHeight(he: HELEMENT; forWidth: Integer; var pHeight: integer):boolean;
 begin
  fLastResult:=ISciter.SciterGetElementIntrinsicHeight(he,forWidth,pHeight);
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
       el_failure('el_GetIntrinsicHeight',Concat('FORWIDTH=',IntToStr(forWidth)),he.toUID);
 end;

function TscAgent.el_ISVisible(he: HELEMENT):boolean;
var LFlag:Bool;
 begin
   result:=false;
   fLastResult:=ISciter.SciterIsElementVisible(he,LFlag);
   if (fLastResult<>SCDOM_OK) then
       el_failure('el_ISVisible','',he.toUID)
   else Result:=LFlag;
 end;

function TscAgent.el_ISEnabled(he: HELEMENT):boolean;
var LFlag:Bool;
 begin
   result:=false;
   fLastResult:=ISciter.SciterIsElementEnabled(he,LFlag);
   if (fLastResult<>SCDOM_OK) then
       el_failure('el_ISEnabled','',he.toUID)
   else Result:=LFlag;
 end;

function TscAgent.el_Swap(he1,he2: HELEMENT):boolean;
 begin
   fLastResult:=ISciter.SciterSwapElements(he1,he2);
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
       el_failure('el_Swap',Concat('HE2_ID=',IntToStr(he2.toUID)),he1.toUID);
 end;

function TscAgent.el_AttachHwndToElement(he: HELEMENT; hwnd: hwnd):boolean;
  begin
   fLastResult:=ISciter.SciterAttachHwndToElement(he,hwnd);
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
       el_failure('el_AttachHwndToElement',Concat('HWND=',IntToStr(hwnd)),he.toUID);
  end;

// see ctl_type for pType Ord();
function TscAgent.el_ControlGetType(he: HELEMENT; {CTL_TYPE} var pType: UINT ):boolean;
 begin
   fLastResult:=ISciter.SciterControlGetType(he,pType);
   Result:=(fLastResult=SCDOM_OK);
   if Result=false then
       el_failure('el_ControlGetType',Concat('CTL_TYPE=',IntToStr(pType)),he.toUID);
 end;

function TscAgent.el_GetValue(he: HELEMENT; var pval: sc_VALUE):boolean;
var LS:string;
 begin
    fLastResult:=ISciter.SciterGetValue(he,pval);
    Result:=(fLastResult=SCDOM_OK);
    if Result=false then
     begin
       LS:='NIL';
       el_failure('el_GetValue',Concat('VAL=',LS),he.toUID);
     end;
 end;

function TscAgent.el_SetValue(he: HELEMENT; const  pval: sc_VALUE):boolean;
var LS:string;
 begin
    fLastResult:=ISciter.SciterSetValue(he,pval);
    Result:=(fLastResult=SCDOM_OK);
    if Result=false then
     begin
       LS:='NIL';
       el_failure('el_SetValue',Concat('VAL=',LS),he.toUID);
     end;
 end;

function TscAgent.el_GetExpando(he: HELEMENT; var  pval: sc_VALUE; forceCreation: BOOLean ):boolean;
 var LS:string;
 begin
    fLastResult:=ISciter.SciterGetExpando(he,pval,forceCreation);
    Result:=(fLastResult=SCDOM_OK);
    if Result=false then
     begin
       LS:='NIL';
       el_failure('el_GetExpando',Concat('VAL=',LS),he.toUID);
     end;
 end;

function TscAgent.el_GetObject(he:HELEMENT; var pval: pointer {tiscript_value*}; forceCreation: BOOLean ):boolean;
var LS:string;
 begin
    fLastResult:=ISciter.SciterGetObject(he,pval,forceCreation);
    Result:=(fLastResult=SCDOM_OK);
    if Result=false then
     begin
       LS:='NIL';
       el_failure('el_GetObject',Concat('OBJECT=',LS),he.toUID);
     end;
 end;

function TscAgent.el_GetNamespace(he: HELEMENT; var pval: pointer {tiscript_value*}):boolean;
var Lval:psc_VALUE;
    LS:string;
 begin
    fLastResult:=ISciter.SciterGetElementNamespace(he,pval);
    Result:=(fLastResult=SCDOM_OK);
    if Result=false then
     begin
       LS:='NIL';
       if Lval<>nil then LS:=Lval^;
       el_failure('el_GetNamespace',Concat('VALUE=',LS),he.toUID);
     end;
 end;

function TscAgent.el_GetHighlighted(hwnd: hwnd):HELEMENT;
 begin
   Result.pval:=nil;
   fLastResult:=ISciter.SciterGetHighlightedElement(hwnd,Result);
   if (fLastResult<>SCDOM_OK) then
    begin
       result.pval:=nil;
       el_failure('el_GetHighlighted','',0);
    end;
 end;

function TscAgent.el_SetHighlighted(hwnd: hwnd; he: HELEMENT):boolean;
 begin
   fLastResult:=ISciter.SciterSetHighlightedElement(hwnd,he);
    Result:=(fLastResult=SCDOM_OK);
    if Result=false then
     begin
       el_failure('el_SetHighlighted',Concat('HWND=',IntToStr(hwnd)),he.toUID);
     end;
 end;

function TscAgent.el_FindFromID(const idStr:string; var he:helement):boolean;
 begin
   Result:=false;
   Assert(idStr<>'','els_FindFromID - empty id-string!');
   he:=el_SelectFirst(Concat('#',idStr));
   if he.pval=nil then exit
   else Result:=true;
 end;

function TscAgent.el_SetHandler(he: HELEMENT; etype: TSCITER_EVENTS; handler: Pointer): boolean;
 begin
   if (handler<>nil) and (Assigned(handler)) then
    begin
     fLastResult:=ISciter.SciterAttachEventHandler(he,MethodToProcedure(Self,@TscAgent.El_Proc),@self);
     if (fLastResult=SCDOM_OK) then
       begin
          fEvents.SetEvent(he,etype,handler);  // !
          result:=true;
       end else begin
            result:=false;
            el_failure('el_SetHandler',Concat('SET=TRUE,EVENT_TYPE=',IntToStr(Ord(eType))),he.toUID);
           end;
    end
    else begin
     { fLastResult:=ISciter.SciterDetachEventHandler(he,MethodToProcedure(Self,@TscAgent.El_Proc),@self);
     if (fLastResult=SCDOM_OK) then
       begin
          fEvents.ReleaseEvent(he,etype);  // !
          result:=true;
       end else begin
            result:=false;
            el_failure('el_SetHandler',Concat('SET=FALSE,EVENT_TYPE=',IntToStr(Ord(eType))),he.toUID);
           end;
     }
     // не убираем handler на уровне скайтера - только в списке fEvents
     fEvents.ReleaseEvent(he,etype);  // !
     result:=true;
    end;
 end;

function TscAgent.el_GetIDName(he: HELEMENT):string;
 begin
  Result:=el_GetAttributeByName(he,'id');
  //  Result:=el_GetNthAttributeValue(he,0);
 end;

//////////////////////////////////////////////////////////////////////////////////////////////
constructor TscAgent.Create(const aname, aCaption: string);
begin
  el_HandlerEvent:=nil;
  ScryptHandlerEvent:=nil;
  Self.Name:=Trim(aName);
  Self.Caption:=aCaption;
  inherited Create;
  FFilename:='';
  GroupNum:=-1;
  FonFailureEvent:=nil;
  fhwnd:=0;
  ///
  ///scryptDistionary:=TDictionary<string,Variant>.Create;
 end;

destructor TscAgent.Destroy;
 begin
  inherited Destroy;
 end;

function TscAgent.LoadMainFile(const aFilename:string):boolean;
 var il:integer;
    HTMBytes: TBytes;
begin
   Result:=false;
   self.FFilename:=aFilename;
     ///!
    il:=scResourceConnectRegime; // ВНИМАНИЕ - это глобальный параметр
    ///
   // s_SendLogMsg('Regime='+IntToStr(il),'Load-ResourceConnectRegime');
    try
     case il of
      1: Result:=LoadFile(Concat('file:',fFilename));
      2: Result:=LoadFile(Concat(ExtractFilePath(ParamStr(0)),fFilename));
      // sciter UI stored in zip file in .exe resource with
      // ResName = SciterUIarchive and ResType = SciterUI
      3:
        begin
          self.fResourceStream:=TResourceStream.Create(hInstance, 'SciterUIarchive', 'SciterUI');
          self.fZipStream:=TMemoryStream.Create;
          self.fZipStream.LoadFromStream(self.fResourceStream);
          self.fZipFile:=TZipFile.Create;
          self.fZipFile.Open(self.fZipStream, zmReadWrite);
          self.fZipFile.Read(self.fFilename, HTMBytes);
          if Assigned(self.fOnZipFileLoad) then
            self.fOnZipFileLoad(self);
          Result:=LoadHtml(@HTMBytes[0], Length(HTMBytes),
                            'zip:///'+self.fFilename);
        end
    else
      Result:=LoadFile(Concat('app:', ExtractFilename(fFilename)));
    end;
     finally
    end;
 end;

function TscAgent.CreateWindow(creationFlags: SCITER_CREATE_WINDOW_FLAGS; frame: TRect; OnMessages: TOnMessages; parent: HWND):boolean;
 var
  WindowClass: TWndClassEx;
  style,exstyle: Cardinal;
  hh: HELEMENTS;
  h:HELEMENT;
  p,p1: pointer;
  ///
  Lp:PansiChar;
  i:integer;
  iTT:SCDOM_RESULT;
  Lproc:LPCSTR_RECEIVER;
  LL:Uint;
  S:String;
begin
 Result:=false;
 fCreationFlags:=creationFlags;
 fOnMessages:=OnMessages;
 fParent:=parent;
{
 if @fOnMessages=nil  then begin

   fHandle := ISciter.SciterCreateWindow( @fCreationFlags ,@frame,nil,nil,fParent);

 end else begin
}
  if not GetClassInfoEx(hInstance, PChar('TSciterWindow'), WindowClass) then begin
    FillChar(WindowClass, SizeOf(WindowClass), 0);
    WindowClass.cbSize:=SizeOf(windowclass);
    WindowClass.Style := CS_HREDRAW or CS_VREDRAW;
    WindowClass.lpfnWndProc := MethodToProcedure(Self,@TscAgent.scWindowProc);
    WindowClass.cbClsExtra := 0;
    WindowClass.cbWndExtra := 0;
    WindowClass.hInstance := hInstance;
    WindowClass.hIcon			:= LoadIcon(hInstance, 'MAINICON');
    WindowClass.hCursor := LoadCursorW(0, PChar(IDC_ARROW));
    WindowClass.hbrBackground := HBRUSH(COLOR_WINDOW+1);
    WindowClass.lpszMenuName := nil;
    WindowClass.lpszClassName := PChar('TSciterWindow');
  	WindowClass.hIconSm		:= LoadIcon(hInstance, 'MAINICON');
    if RegisterClassEx(WindowClass) = 0 then
       Halt;
  end;
  style:=0;
  exstyle:=0;
  if SW_ALPHA in fCreationFlags then exstyle:=exstyle + WS_EX_LAYERED;
  if SW_MAIN in fCreationFlags then  exstyle:=exstyle + WS_EX_APPWINDOW;
  if SW_POPUP in fCreationFlags then  style:=style + WS_POPUP;
  ///
  fhwnd := CreateWindowEx(exstyle, WindowClass.lpszClassName, 'Windows Player', style,
            frame.Left,frame.Top,frame.Width,frame.Height,fParent,0,HInstance,nil);
  ///
  SetWindowLongPtr(fhwnd, GWLP_USERDATA, LONG_PTR(self));
 // ISciter.SciterSetCallback(fHandle,@BasicHostCallback,nil);
  fLastResult:=ISciter.SciterWindowAttachEventHandler(fhwnd,MethodToProcedure(Self,@TscAgent.el_Proc),nil,HANDLE_SCRIPTING_METHOD_CALL);
  if (flastResult<>SCDOM_OK) then
    begin
      el_failure('wnd_Create','Error WindowAttachEventHandler!',0);
      Result:=false;
    end
  else Result:=true;
 // ISciter.SciterLoadFile(fhwnd,PChar('bla'));
end;

/////////////////
procedure TscAgent.Close;
begin
  if fHwnd>0 then
    PostMessage(fHwnd,WM_CLOSE,0,0);
end;

procedure TscAgent.Run;
var
  rMsg: TMsg;
begin
  OleInitialize(0);  //  for Drag a Drop Activation
   if not IsWindow(fhwnd) then Exit;
   hAccelTable := LoadAccelerators(hInstance, MAKEINTRESOURCE('IDC_LAYERED'));
   while GetMessage(rMsg, 0, 0, 0) do begin
      try
        if TranslateAccelerator(rMsg.hwnd, hAccelTable, rMsg)=0 then begin
          if not ISciter.SciterTranslateMessage(rMsg) then  TranslateMessage(rmsg);
          DispatchMessage(rMsg);
        end;
      except
        //global exception handling
      end;
    end;
   OleUninitialize();
end;

procedure TscAgent.ProcessMessages(iTime: Cardinal = 0);
var
  rMsg: TMsg;
  strt: Cardinal;
begin
   if not IsWindow(fhwnd) then Exit;
   strt:= GetTickCount;
   if GetMessage(rMsg, 0, 0, 0) then begin
      try
        if TranslateAccelerator(rMsg.hwnd, hAccelTable, rMsg)=0 then begin
          if not ISciter.SciterTranslateMessage(rMsg) then
                TranslateMessage(rmsg);
          DispatchMessage(rMsg);
        end;
      except
        //global exception handling
      end;
    end;
end;

function TscAgent.Show(asyncFlag:boolean=false):boolean;
begin
 result:=false;
  try
     if asyncFlag then ShowWindowAsync (fhwnd, SW_SHOW)
     else ShowWindow(fhwnd, 1);
    except
     on E:Exception do begin
        ConcatErrorData(E,'wnd_Show',1350);
        Exit;
     end;
    end;
 ISciter.SciterUpdateWindow(fhwnd);
 FVisible:=true;
 Result:=true;
 //
end;

function TscAgent.exec(const cmd: string): boolean;
var    res: SCITER_VALUE;
begin
  result:=ISciter.SciterEval(fhwnd,pchar(cmd),length(cmd),res);
end;

////////////////////////////////////////////////////////////////////////////////
///
function sc_ConvertHandleToEvent(evtg: UINT; prms:LPVOID):TSCITER_EVENTS;
var L_pcmd:Cardinal;
    L_cmdMouse:MOUSE_EVENTS;
    L_cmdKey:Key_Events;
    L_cmdDraw:DRAW_PARAMS;
    L_cmdScroll:SCROLL_EVENTS;
 begin
   Result:=eOnOther;
   case evtg of
      SUBSCRIPTIONS_REQUEST: Result:=eOnOther;
      HANDLE_INITIALIZATION: Result:=eOnOther;
      HANDLE_SIZE: Result:=eOnSizeChanged;
      HANDLE_MOUSE: begin
           L_pcmd:=PMOUSE_PARAMS(prms)^.cmd;
           if L_pcmd or $10000 = L_pcmd then Exit;
           if L_pcmd or $8000  = L_pcmd then Exit;
           L_cmdMouse:=MOUSE_EVENTS(L_pcmd);
           case L_cmdMouse of
             MOUSE_DCLICK: Result:=eOnDblClick;
             MOUSE_CLICK: Result:=eOnClick;
             MOUSE_ENTER: Result:=eOnMouseEnter;
             MOUSE_LEAVE: Result:=eOnMouseLeave;
             MOUSE_MOVE: Result:=eOnMouseMove;
             MOUSE_DOWN: Result:=eOnMouseDown;
             MOUSE_UP: Result:=eOnMouseUP;
             MOUSE_WHEEL: Result:=eOnMouseWheel;
             MOUSE_TICK: begin end;
             MOUSE_IDLE: Result:=eOnMouseIdle;
           end;
      end;
       HANDLE_TIMER: Result:=eOnTimer;
       HANDLE_FOCUS:
        begin
          L_pcmd:=PFOCUS_PARAMS(prms)^.cmd;
          if L_pcmd=Uint(FOCUS_GOT) then Result:=eOnSetFocus;
          if L_pcmd=Uint(FOCUS_LOST) then Result:=eOnLostFocus;
        end;
       HANDLE_KEY:
        begin
             L_pcmd:=PKEY_PARAMS(prms)^.cmd;
            if L_pcmd or $10000 = L_pcmd then Exit;
            if L_pcmd or $8000  = L_pcmd then Exit;
            L_cmdKey:=KEY_EVENTS(L_pcmd);
            case L_cmdKey of
               KEY_DOWN: Result:=eOnKeyDown;
               KEY_UP:   Result:=eOnKeyUp;
               KEY_CHAR: Result:=eOnKeyChar;
            end;
        end;
        HANDLE_SCROLL:
         begin
         // L_cmdScroll:=SCROLL_EVENTS(L_cmd);
            Result:=eOnScroll;
          end;
        HANDLE_DRAW:
                   begin
                      L_cmdDraw:=PDRAW_PARAMS(prms)^;
                      case L_cmdDraw.cmd of
                       0:  Result:=eOnDrawBackGround;
                       1:  Result:=eOnDrawContent;
                       2:  Result:=eOnDrawForeground;
                      end; // else none
                    end;
        HANDLE_BEHAVIOR_EVENT: Result:=eOnBehavior;
        // HANDLE_METHOD_CALL,HANDLE_DATA_ARRIVED,
        HANDLE_SCRIPTING_METHOD_CALL: Result:=eOnScrypt;
        HANDLE_TISCRIPT_METHOD_CALL:
         begin
           Result:=eOnOther;
        end;
   end;
 end;

end.
