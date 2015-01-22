unit SciterClass;

interface

uses windows,messages, SciterTypes;// sc_Agent,

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

PSciterForm = ^TSciterForm;
TSciterForm = class
  fEvents: TElementsEvents;
  fHandle: HWND;
  fParent: HWND;
  fCreationFlags: SCITER_CREATE_WINDOW_FLAGS;
  fOnMessages: TOnMessages;
  fOnClose: TStdEvent;
  fHtml: string;

  hAccelTable: HACCEL;
 private
  c_wideFlag:boolean;
  curr_Str:string;
  elem_rec: procedure (str: LPCSTR; str_length: UINT; param: LPVOID) stdcall of object;
  ///
  function MyWindowProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
  function ElementProc(tag: LPVOID; he: HELEMENT; evtg: UINT; prms: LPVOID): BOOL; stdcall;
  ///
  procedure Element_RECEIVER(str: LPCSTR; str_length: UINT; param: LPVOID); stdcall;
 public
 // scAgent:TscAgent;
  constructor Create(html: string; creationFlags: SCITER_CREATE_WINDOW_FLAGS; frame: TRect; OnMessages: TOnMessages = nil; parent: HWND = 0);
  destructor Destroy; virtual;
  procedure Close;
  procedure Run;
  procedure ProcessMessages(iTime: Cardinal = 0);

  function Show: TSciterForm;

  function exec(cmd: string): BOOL;

//DOM handling
  function SelectFirst( selector: string): HELEMENT;
  function Select( selector: string): HELEMENTS;
  function SetElementHandler( element: HELEMENT; etype: TSCITER_EVENTS; handler: Pointer): boolean;

  property Handle: HWND read fHandle;
  property OnClose:  TStdEvent read fOnClose write fOnClose;
end;

function  OleInitialize(pwReserved: Pointer): HResult; stdcall;  external 'ole32.dll';
procedure OleUninitialize; stdcall; external 'ole32.dll';

implementation
uses Sciter, Vcl.Dialogs, Sysutils;


{ TSciterForm }
procedure TSciterForm.Close;
begin
  PostMessage(fHandle,WM_CLOSE,0,0);
end;

procedure OnClick( he: HELEMENT);
begin
 // Beep(1000,100);
end;



constructor TSciterForm.Create(html: String; creationFlags: SCITER_CREATE_WINDOW_FLAGS; frame: TRect; OnMessages: TOnMessages; parent: HWND);
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
 fCreationFlags:=creationFlags;
 fOnMessages:=OnMessages;
 fParent:=parent;
 fHtml:=html;
{
 if @fOnMessages=nil  then begin

   fHandle := ISciter.SciterCreateWindow( @fCreationFlags ,@frame,nil,nil,fParent);

 end else begin
}
  if not GetClassInfoEx(hInstance, PChar('TSciterWindow'), WindowClass) then begin
    FillChar(WindowClass, SizeOf(WindowClass), 0);
    WindowClass.cbSize:=SizeOf(windowclass);
    WindowClass.Style := CS_HREDRAW or CS_VREDRAW;
    WindowClass.lpfnWndProc := MethodToProcedure(Self,@TSciterForm.MyWindowProc);
    WindowClass.cbClsExtra := 0;
    WindowClass.cbWndExtra := 0;
    WindowClass.hInstance := hInstance;
    WindowClass.hIcon			:= LoadIcon(hInstance, 'MAINICON');
    WindowClass.hCursor := LoadCursorW(0, PChar(IDC_ARROW));
    WindowClass.hbrBackground := HBRUSH(COLOR_WINDOW+1);
    WindowClass.lpszMenuName := nil;
    WindowClass.lpszClassName := PChar('TSciterWindow');
  	WindowClass.hIconSm		:= LoadIcon(hInstance, 'MAINICON');
    if RegisterClassEx(WindowClass) = 0 then  Halt;
  end;

  style:=0;
  exstyle:=0;
  if SW_ALPHA in fCreationFlags then exstyle:=exstyle + WS_EX_LAYERED;
  if SW_MAIN in fCreationFlags then  exstyle:=exstyle + WS_EX_APPWINDOW;
  if SW_POPUP in fCreationFlags then  style:=style + WS_POPUP;


  fHandle := CreateWindowEx(exstyle, WindowClass.lpszClassName, 'Windows Player', style,
            frame.Left,frame.Top,frame.Width,frame.Height,fParent,0,HInstance,nil);
  SetWindowLongPtr(fHandle, GWLP_USERDATA, LONG_PTR(self));
 // ISciter.SciterSetCallback(fHandle,@BasicHostCallback,nil);
  ISciter.SciterWindowAttachEventHandler(fHandle,MethodToProcedure(Self,@TSciterForm.ElementProc),nil,HANDLE_SCRIPTING_METHOD_CALL);
  ISciter.SciterLoadFile(fHandle,PChar(fHtml));
 // scAgent:=TScAgent.Create(fHandle);
// end;
 { Select('.alles').Foreach(procedure(elm: HELEMENT)
   begin
     p:=Addr(OnClick);
     SetElementHandler(elm,eOnClick,p);
   end
  );
  }
  (*
  h:=SelectFirst('#prew');
  if h.pval<>nil then
    begin
     iTT:=ISciter.Sciter_UseElement(h);
     Lp:=nil;
     p:=nil;

    // iTT:=ISciter.SciterGetElementType(h,Lp);
     elem_rec:=Element_RECEIVER;
     c_wideFlag:=true;
     Lproc:= MethodToProcedure(self,@elem_rec,3);
     iTT:=ISciter.SciterGetElementTextCB(h,Lproc,p);
     ShowMessage(curr_Str);
     Lp:=@Lproc;
     c_wideFlag:=false;
     iTT:=ISciter.SciterGetElementHtmlCB(h,true,Lp,p);
     if Ord(iTT)=0 then
      begin
       ShowMessage(curr_Str);
      end;
     //
     ISciter.SciterSetAttributeByName(h,'title','12222');
     ///
     ISciter.SciterSetElementText(h,'При',3);
     ISciter.SciterUpdateElement(h,false);
     ///

      c_wideFlag:=true;
     ISciter.SciterGetAttributeByNameCB(h,PAnsichar('title'),Lp,p);
     if Ord(iTT)=0 then
      begin
       ShowMessage(curr_Str);
      end;
      ///
      ISciter.SciterSetElementState(h,TELEMENT_STATESREC.State_Load,TELEMENT_STATESREC.State_Clear,true);
       c_wideFlag:=true;
       ISciter.SciterGetElementState(h,LL);
        s:=IntToStr(LL);
       InputQuery('jj','gggg:',s);

   end;
   *)
  { if scAgent.el_FindFromID('prew',h)=true then
    begin
      Showmessage(scAgent.el_GetHtml(h,true));
    end;
    }
end;

destructor  TSciterForm.Destroy;
 begin
  // scAgent.Free;
 end;

procedure TSciterForm.Element_RECEIVER(str: LPCSTR; str_length: UINT; param: LPVOID); stdcall;
 begin
  if c_wideFlag=true then
     curr_Str:=WideCharLenToString(PwideChar(str),str_length)
  else SetString(curr_Str,str,str_length);
 end;

function TSciterForm.ElementProc(tag: LPVOID; he: HELEMENT; evtg: UINT; prms: LPVOID): BOOL; stdcall;
var
 w: word;
 i: ElementID;
begin

        Result := False;
        case evtg of
          SUBSCRIPTIONS_REQUEST: Result:=(he.pval <> nil );

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
            result:=True;//handle_scripting_call(he,PSCRIPTING_METHOD_PARAMS(prms));
           end;

          HANDLE_TISCRIPT_METHOD_CALL: ;

          else      Assert(false);
        end;
end;

function TSciterForm.exec(cmd: string): BOOL;
var    res: SCITER_VALUE;
begin
 result:=ISciter.SciterEval(fHandle,pchar(cmd),length(cmd),res);
end;

procedure TSciterForm.Run;
var
  rMsg: TMsg;
begin
  OleInitialize(0);
   if not IsWindow(fHandle) then Exit;
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

function TSciterForm.Select(selector: string): HELEMENTS;
var root: HELEMENT;
begin
 if SCDOM_OK =  ISciter.SciterGetRootElement(fHandle,root) then begin
    ISciter.SciterSelectElementsW(root ,PChar(selector),fAllElementCallback,@result);
 end;
end;

function TSciterForm.SelectFirst(selector: string): HELEMENT;
var root: HELEMENT;
begin
 if SCDOM_OK =  ISciter.SciterGetRootElement(fHandle,root) then begin
   if SCDOM_OK <>  ISciter.SciterSelectElementsW(root ,PChar(selector),fOneElementCallback,@result.pval) then result.pval:=nil;
 end else result.pval:=nil;
end;

function TSciterForm.SetElementHandler(element: HELEMENT; etype: TSCITER_EVENTS; handler: Pointer): boolean;
begin
  if SCDOM_OK =  ISciter.SciterAttachEventHandler(element,MethodToProcedure(Self,@TSciterForm.ElementProc),@self) then begin
    fEvents.SetEvent(element,etype,handler);
    result:=true;
  end else result:=false;
end;


function TSciterForm.Show: TSciterForm;
begin
 result:=Self;
 ShowWindow(fHandle, 1);
 ISciter.SciterUpdateWindow(fHandle);
end;

function TSciterForm.MyWindowProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var hndld: BOOL;
begin
 if Msg = WM_CLOSE then begin
   if Assigned(fOnClose) then fOnClose();
   PostQuitMessage(0);
 end;
 if Msg = WM_DESTROY then  PostQuitMessage(0);
try
 hndld:=Assigned(fOnMessages) and fOnMessages(hwnd,Msg,wParam,lParam,Result);
 if not hndld then  result:= ISciter.SciterProcND( hWnd,Msg,wParam, lParam, hndld);
 if not hndld then  result:= DefWindowProc(hWnd, msg, wParam, lParam);
except
  //errors handling
end;
end;


procedure TSciterForm.ProcessMessages(iTime: Cardinal = 0);
var
  rMsg: TMsg;
  strt: Cardinal;
begin
   if not IsWindow(fHandle) then Exit;
   strt:= GetTickCount;
   if GetMessage(rMsg, 0, 0, 0) then begin
      try
        if TranslateAccelerator(rMsg.hwnd, hAccelTable, rMsg)=0 then begin
          if not ISciter.SciterTranslateMessage(rMsg) then  TranslateMessage(rmsg);
          DispatchMessage(rMsg);
        end;
      except
        //global exception handling
      end;
    end;
end;

end.
