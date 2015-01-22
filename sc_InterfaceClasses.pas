unit sc_InterfaceClasses;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, VCL.Dialogs;


type
  TValueArray = array of TValue;

  TmSciterWindowState = (
    swstate_Shown, swstate_Minimized, swstate_Maximized, swstate_Hidden
  );

  // для наборов
  TMethodRecord = record
    MethodName: string;
    MethodArgs: TValueArray;
  end;

  TMethodEvent = procedure(const aMRec: TMethodRecord) of object;

type
  // интерфейс скайтер класса с окном и прочим
  IscClass = interface
    ['{EE58BAE0-311A-4976-985D-77FF34998C1D}']
    function getInitialWindowState: TmSciterWindowState;

    function exec(cmd: string): boolean; stdcall;
    function isShowing:Boolean;
    // procedure ExecMethod(const MethodName:string; const Args: TValueArray); //stdcall;
    // задача данного метода - установить указатель на выполнение процедуры указанного типа
    // это нужно выполнить внутри ExecMethod
    procedure SetExecEvent(aEvent:TmethodEvent); stdcall;
    procedure SetData(const aBytes:TBytes); stdcall;
    procedure SetDataStream(const aStream:TStream); stdcall;
    /// для получения указателя на калбэк функции загрузки данных в скайтер
    procedure SetBinaryDataProcPtr(aPtr:pointer); stdcall;
    property InitialWindowState: TmSciterWindowState read getInitialWindowState;
  end;

  IscInterface = interface
    ['{8B2730B8-EF3A-436E-80B8-88E8A6EEB575}']
    function RefreshInterface: integer; stdcall;
    function EventsCheck: integer; stdcall;
    function GetscClass:IscClass; stdcall;
    // вернуть запись текущей команды или данных для Sc
    function GetLastData(aCommandFlag: boolean): string; stdcall;
  end;

  ///
  ///  28.08.2014  - данный класс устарел
  ///
  // основной обработчик событий в цикле - поток-таймер
  TscThreadClass = class(TThread)
  private
    FExceptRegime: integer; // 0 - окно сообщения об ошибке - иначе - другое...
    // признаки и код выполнения операции  <0  - значит ошибка
    FRefreshResult, FEventResult: integer;
    FDMsec:Integer;
    FISciter:IscClass;
    FIInterObject:IscInterface;
    FVisible:Boolean;
    // procedure SetVisible(V:Boolean);
    // процедура формирования ошибки при ошибках обмена со скайтером
    procedure Inner_Exception;
  protected
    procedure Execute; override;
  public
    // aDtime - интервал в мсек.
    constructor Create(const ASciterObj, AInterObj:TObject; aDtime:Word; aPriority:TThreadPriority);
    destructor Destroy; override;

    procedure Sync_RefreshInterface;
    procedure Sync_EventsCheck;

    Property Visible: Boolean read FVisible;
  end;

//////////////////////////////////////////////////////////////////////
///
///   DT:28.08.2014
///
///  потоковый класс для работы с обменом командами и посылки данных в скайтер
///
 TscThreadTemplater=class(TThread)
  protected
    FType,F_scInnerSign:Integer;
    FScFlag:Boolean;
    FExceptRegime: integer; // 0 - окно сообщения об ошибке - иначе - другое...
    // признаки и код выполнения операции  <0  - значит ошибка
    FOpResult: integer;
    FDMsec:Integer;
    FInterObj:TObject; // для Assigned проверки
    // интерфейсы
    FISciter:IscClass;
    FIInterObject:IscInterface;
    // процедура формирования ошибки при ошибках обмена со скайтером
    procedure Inner_Exception;
  protected
    procedure Execute; override;
   // procedure Sync_SetFlag;
  public
    // aDtime - интервал в мсек.
    constructor Create(aType:Integer; const AInterObj:TObject);
    procedure SetParams(aDtime:Word; aPriority:TThreadPriority);
    destructor Destroy; override;
    ///
    procedure Sync_Proc;
    ///
    procedure WaitScFlag;  /// ждать обработки в потоке - пока данная возм. не используется
    ///
  end;
///
///  центральный класс, который создает два потока
TscQueue2=class(TObject)
 public
  InterThread,CommandThread:TscThreadTemplater;
  constructor Create(const AInterObj:TObject; AHomeRunFlag:Boolean=True);
  procedure SetParams(aDeltaInter,aDeltaCommands:Word; aprInter,aprCommands:TThreadPriority);
  procedure Start(aStartRegime:Integer=1);
  destructor Destroy; override;
  procedure Wait_SendData;
end;

function ValueArrayToString(const VA: TValueArray; aSep: string = ','): string;
function mRecordToString(const aMrec:TMethodRecord; const aSep: string = ','):string;

implementation

const scErr1='Ошибка скрипта скайтера или некорректные данные.';

function ValueArrayToString(const VA: TValueArray; aSep: string = ','): string;
var
  i: integer;
begin
  Result:='';
  i:=0;
  while i<=High(VA) do begin
    Result:=Concat(Result, aSep, VA[i].ToString);
    Inc(i);
  end;

  if Result<>'' then
    Delete(Result, 1, 1);
end;

function mRecordToString(const aMrec:TMethodRecord; const aSep: string = ','):string;
 begin
   Result:=Concat('NAME=',aMrec.MethodName,' ARR_COUNT=',IntToStr(Length(aMrec.MethodArgs)),
   ' ARRAY=',ValueArrayToString(aMrec.MethodArgs,aSep));
 end;

{ TscThreadClass }

procedure TscThreadClass.Inner_Exception;
var
  LMs:string;
  Lerr:string;
begin
  Lerr:=Concat(
    'Ошибка в цикле отправки команды в скайтер', #13#10,
    'Обмен данными со скайтером прекращен',#13#10
  );

  Lms:='';
  case FRefreshResult of
    -1: LMs:=Concat(
          Lerr, #13#10, FIInterObject.GetLastData(false), ' code=',
          IntToStr(FRefreshResult), #13#10, scErr1
        );
  end;

  if LMs<>'' then
    Lms:=Concat(Lms, #13#10);

  Lerr:=' Ошибка в цикле отправки команды из скайтера';
  case FEventResult of
    -1: LMs:=Concat(
          LMs, Lerr, #13#10, FIInterObject.GetLastData(false),
          ' code=', IntToStr(FRefreshResult), #13#10, scErr1
        );
  end;

  if FExceptRegime=0 then
    MessageDlg(LMs, mtError, [mbOK], 0);
end;

constructor TscThreadClass.Create(
  const ASciterObj, AInterObj: TObject; aDtime: Word; aPriority: TThreadPriority
);
begin
  inherited Create(true);
  self.FDMsec:=aDtime;
  self.Priority:=aPriority;

  self.FExceptRegime:=0;
  FRefreshResult:=0;
  FEventResult:=0;

  ASciterObj.GetInterface(IscClass,FISciter);
  AInterObj.GetInterface(IscInterface,FIInterObject);

  //

  self.Suspended:=false;
end;

destructor TscThreadClass.Destroy;
begin
  inherited Destroy;
end;

procedure TscThreadClass.Sync_RefreshInterface;
begin
  self.FRefreshResult:=FIInterObject.RefreshInterface;
end;

procedure TscThreadClass.Sync_EventsCheck;
begin
  FEventResult:=FIInterObject.EventsCheck;
end;

procedure TscThreadClass.Execute;
begin
  repeat
    if FDMsec>0 then
      sleep(FDMsec);

    if true then begin
//    if FISciter.isShowing then begin
      Synchronize(Sync_RefreshInterface);
      if FRefreshResult<0 then begin
        Synchronize(Inner_Exception);
        Terminate;
        Exit;
      end;

      Synchronize(Sync_EventsCheck);
      if FEventResult<0 then begin
        Synchronize(Inner_Exception);
        Terminate;
        Exit;
      end;
    end;
  until self.Terminated;
end;

//////////////////////////////////////////////////////////////////////
///
///       TscThreadTemplater
///
 procedure TscThreadTemplater.Inner_Exception;
 var
  LMs:string;
  Lerr:string;
  begin
      Lms:='';
      case FType of
       1:  Lerr:='Ошибка в цикле отправки команды в скайтер';
       2:  Lerr:='Ошибка в цикле отправки команды из скайтера';
       else Lerr:='Ошибка при работе со скайтером';
      end;
      Lerr:=Concat(Lerr, #13#10,
                   'Обмен данными со скайтером прекращен',#13#10
                   );
        case FOpResult of
           -1: LMs:=Concat(
                Lerr, #13#10, FIInterObject.GetLastData(false), ' code=',
                IntToStr(FOpResult), #13#10, scErr1
              );
        end;
      if LMs<>'' then
        Lms:=Concat(Lms, #13#10);
      if FExceptRegime=0 then
        MessageDlg(LMs, mtError, [mbOK], 0);
  end;

 constructor TscThreadTemplater.Create(aType:Integer; const AInterObj:TObject);
  begin
     inherited Create(true);
     Self.FType:=aType;
     FScFlag:=False;
     self.FDMsec:=33;
     self.Priority:=tpNormal;
     self.FExceptRegime:=0;
     FOpResult:=0;
     ///
     FInterObj:=AInterObj;
     AInterObj.GetInterface(IscInterface,FIInterObject);
     FISciter:=FIInterObject.GetscClass;
     self.Suspended:=true; // !
    ///// FreeOnTerminate:=True;
  end;

{ procedure TscThreadTemplater.Sync_SetFlag;
  begin
   Inc(F_scInnerSign);
  end;
}
 procedure TscThreadTemplater.SetParams(aDtime:Word; aPriority:TThreadPriority);
  begin
     self.FDMsec:=aDtime;
     self.Priority:=aPriority;
  end;

 destructor TscThreadTemplater.Destroy;
  begin
    inherited Destroy;
  end;

 procedure TscThreadTemplater.Sync_Proc;
  begin
    if Assigned(FInterObj) then
     begin
       case FType of
        1: FOpResult:=FIInterObject.RefreshInterface;
        2: begin
             FOpResult:=FIInterObject.EventsCheck;
            // FBrother.WaitScFlag;
           end;
       end;
     end;
  end;

 procedure TscThreadTemplater.WaitScFlag;
  begin
   FScFlag:=True;
   F_scInnerSign:=0;
   repeat
     Sleep(16);
   until (F_scInnerSign>=1);
   FScFlag:=False;
  end;

 procedure TscThreadTemplater.Execute;
  begin
   repeat
    if FDMsec>0 then
       sleep(FDMsec);
    if FISciter.isShowing then begin
      Synchronize(Sync_Proc);
      if FscFlag=true then
         Synchronize(procedure begin Inc(F_scInnerSign); end );
      if FOpResult<0 then begin
         Synchronize(Inner_Exception);
         Terminate;
         Exit;
      end;
    end;
  until self.Terminated;
 end;

/////////////////////////////////////////////////////////////////////
///
///
///
constructor TscQueue2.Create(const AInterObj:TObject; AHomeRunFlag:Boolean=True);
 begin
   inherited Create;
   InterThread:=TscThreadTemplater.Create(1,AInterObj);
   CommandThread:=TscThreadTemplater.Create(2,AInterObj);
   if AHomeRunFlag=true then
    begin
     InterThread.Start;
     CommandThread.Start;
    end;
 end;

destructor TscQueue2.Destroy;
 begin
  if InterThread <> nil then
    begin
     InterThread.Terminate;
     if Assigned(InterThread) then
       begin
         InterThread.WaitFor;
         InterThread.Free;
        end;
    end;
   if CommandThread <> nil then
    begin
     CommandThread.Terminate;
      if Assigned(InterThread) then
       begin
        CommandThread.WaitFor;
        CommandThread.Free;
       end;
    end;
    ///
   inherited Destroy;
 end;

procedure TscQueue2.SetParams(aDeltaInter,aDeltaCommands:Word; aprInter,aprCommands:TThreadPriority);
 begin
  InterThread.FDMsec:=aDeltaInter;
  CommandThread.FDMsec:=aDeltaCommands;
  InterThread.Priority:=aprInter;
  CommandThread.Priority:=aprCommands;
 end;

procedure TscQueue2.Start(aStartRegime:Integer=1);
  begin
    InterThread.Start;
    CommandThread.Start;
  end;

procedure TscQueue2.Wait_SendData;
  begin
    InterThread.WaitScFlag;
  end;
end.
