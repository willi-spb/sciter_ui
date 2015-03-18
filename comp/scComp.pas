unit scComp;

interface

uses
  System.SysUtils, System.Classes, VCL.Controls,
  sc_Agent, SciterTypes;

type

 TscElemDStates=(
    elDisabled,
    elReadOnly,
    elChecked,
    elExpanded,
    elCollapsed,
    elTabFocused,
    elPressed);

 TscElemDState=set of TscElemDStates;

 /// преобразовать тип к скайтер-состоянию элемента
 procedure ConvertDSTypeToElementState( aDState: TscElemDState; var StBits,stClearBits:integer);
 function ConvertElementStateToDState(StBits:integer):TscElemDState;

type

 TscElementItem=class(TCollectionItem)
   private
    FhmFlag:boolean;
    FActive:boolean;
    dbl_scAgentRef:TscAgent; //  доп. поле ссылки на scAgent - связано с работой св-ва Active
    FTag:longint;
    FGroup:integer;
    FID:string;
    FVisible:boolean;
    FDState:TscElemDState;
    FScValue:string;
    procedure SetActive(value:boolean);
    procedure SetID(const Value:String);
    function GetId:string;
    function GetVisible:boolean;
    procedure SetVisible(Value:boolean);
    function GetDState:TscElemDState;
    procedure SetDState(Value:TscElemDState);
    /// Events
   private
    FOnMouseDown,FOnMouseUp:TMouseEvent;
    FOnMouseMove:TMouseMoveEvent;
    FOnMouseWheel:TMouseWheelEvent;
    FOnMouseEnter,FOnMouseLeave:TNotifyEvent;
    FOnKeyUp,FOnKeyDown:TKeyEvent;
    FOnKeyPress:TKeyPressEvent;
    FOnClick,FOnDblClick:TNotifyEvent;
    FOnResize,FOnTimerComplete,FOnEnter,FOnExit:TNotifyEvent;
   private
     fHE:SciterTypes.HELEMENT;
     fUID:cardinal;
     function _ISDesignState:boolean;
   protected
     procedure SetIndex(Value: Integer); override;
     function GetDisplayName: string; override;
     //
     // установить на ID - или сообщить об ошибке
     function AssignToID:boolean; virtual;
     /// назначить события
     function AssignHandlers:boolean; virtual; // связать события с агентом
   public
    scAgent:TscAgent; // !
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function ISAttached(refindFlag:boolean=false):boolean; // проверить подключен ли скайтер и был ли найден в нем HElement
                                                           // flag=true - проверить заново поиском
    function AssignToAgent(aAgent:TscAgent):boolean;       // assignate
    ///
    function SetHomeState(aSetRg:integer=1):boolean;      /// установить начальное состояние при Show скайтера
    //
    property hElem:SciterTypes.HELEMENT read FHE;
    property uID:Cardinal read FUID;
    ///
   published
     property Active:boolean read FActive write SetActive default true;
     property Id:string read GetId write SetId;
     property Visible:boolean read GetVisible write SetVisible default true;
     property DState:TscElemDState read GetDState write SetDState;
     property scValue:string read FscValue write FscValue;
     property Tag:longint read Ftag write FTag default 0;
     property Group:integer read FGroup write FGroup default 0;
     ///
     property OnMouseMove:TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
     property OnMouseUp:TMouseEvent read FOnMouseUp write FOnMouseUp;
     property OnMouseDown:TMouseEvent read FOnMouseDown write FOnMouseDown;
     property OnMouseEnter:TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
     property OnMouseLeave:TNotifyEvent read FOnMouseLeave write FOnMouseLeave;
     property OnKeyUp:TKeyEvent read FOnKeyUp write FOnKeyUp;
     property OnKeyDown:TKeyEvent read FOnKeyDown write FOnKeyDown;
     property OnKeyPress:TKeyPressEvent read FOnKeyPress write FOnKeyPress;
     property OnMouseWheel:TMouseWheelEvent read FOnMouseWheel write FOnMouseWheel;
     ///
     property OnClick:TNotifyEvent read FOnClick write FOnClick;
     property OnDblClick:TNotifyEvent read FOnDblClick write FOnDblClick;
     property OnResize:TNotifyEvent read FOnResize write FOnResize;
     property OnTimerComplete:TNotifyEvent read FOnTimerComplete write FOnTimerComplete;
     property OnEnter:TNotifyEvent read FOnEnter write FOnEnter;
     property OnExit:TNotifyEvent read FOnExit write FOnExit;

 end;

 TscElementItemClass = class of TscElementItem;

 //  collection

 TscElemCollection = class(TOwnedCollection)
  protected
    function GetItem(Index: Integer): TscElementItem;
    procedure SetItem(Index: Integer; Value: TscElementItem);
  public
    /// найти только на тек. уровне (в выбранной коллекции)
    function FindItemFromID(const aID:string):TscElementItem;
    /// заменить состояние в группе
    procedure ReplaceGroupDState(const aSrc:TscElementItem; newSt:TscElemDStates; aSign:integer=0);
    destructor Destroy; override;
    function AssignToAgent(aAgent:TscAgent):boolean; virtual;
    property Items[Index: Integer]: TscElementItem read GetItem write SetItem;
  end;

  TscComp = class(TComponent)
  private
    { Private declarations }
    FElements: TscElemCollection;
    FonScryptReceive:TscScryptHandlerEvent;
     function GetElemID(const aName:string):TscElementItem;
    // procedure SetElemID(const aName:string; Value:TscElementItem);
  protected
    { Protected declarations }
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function SetScryptHandler(aAgent:TscAgent):boolean; virtual;
    function InitElements(aAgent:TscAgent):boolean; virtual;
     property ElementByID[const aName: string]:TscElementItem read GetElemID;
  published
    { Published declarations }
     property Elements: TscElemCollection read FElements write FElements;
     property OnScryptReceive:TscScryptHandlerEvent read FonScryptReceive write FonScryptReceive;
  end;

procedure Register;

implementation

uses VCL.Dialogs;

procedure Register;
begin
  RegisterComponents('SciterComps', [TscComp]);
end;


 procedure ConvertDSTypeToElementState( aDState: TscElemDState; var StBits,stClearBits:integer);
  begin
    StBits:=0;
    if elDisabled in aDState then StBits:=StBits or $80;
    if elReadOnly in aDState then StBits:=StBits or $100;
    if elChecked in aDState then StBits:=StBits or $40;
    if elExpanded in aDState then StBits:=StBits or $200;
    if elCollapsed in aDState then StBits:=StBits or $400;
    if elTabFocused in aDState then StBits:=StBits or $20000;  // or 2000 - focusable
    if elPressed in aDState then StBits:=StBits or $4000000;
    stClearBits:=$80 or $100 or $40 or $200 or $400 or $20000 or $4000000;
  end;

 function ConvertElementStateToDState(StBits:integer):TscElemDState;
  begin
    Result:=[];
    if StBits and $80>0 then Result:=Result+[elDisabled];
    if StBits and $100>0 then Result:=Result+[elReadOnly];
    if StBits and $40>0 then Result:=Result+[elChecked];
    if StBits and $200>0 then Result:=Result+[elExpanded];
    if StBits and $400>0 then Result:=Result+[elCollapsed];
    if StBits and $20000>0 then Result:=Result+[elTabFocused];
    if StBits and $4000000>0 then Result:=Result+[elPressed];
  end;

///////////////////////////////////////////////////////////////
///
///   Item
///
procedure TscElementItem.SetActive(value:boolean);
 begin
   if (value=FActive) and (FhmFlag=false) then exit;
   if (_ISDesignState=false) then
    begin
     if Value=false then
      begin
         dbl_scAgentRef:=scAgent;
         scAgent:=nil;
         FActive:=false;
      end
     else if Assigned(dbl_scAgentRef) then
             begin
               scAgent:=dbl_scAgentRef;
               FActive:=true;
             end;
    end
   else FActive:=Value;
 end;

procedure TscElementItem.SetID(const Value:String);
 begin
  if Trim(Value)<>'' then FID:=Trim(value);
 end;

function TscElementItem.GetId:string;
 begin
   Result:=FID;
 end;

function TscElementItem.GetVisible:boolean;
var LS:string;
 begin
   if (_ISDesignState=false) and (IsAttached=true) then
    begin
     LS:=scAgent.el_GetStyleAttribute(FHE,'visibility');
     FVisible:=Not(Lowercase(LS)='hidden');
     Result:=FVisible;
    end
   else
    Result:=Fvisible;
 end;

procedure TscElementItem.SetVisible(Value:boolean);
var LS:string;
 begin
   if (Value=GetVisible) and (FhmFlag=false) then exit;
   if (_ISDesignState=false) and (IsAttached=true) then
    begin
     if Value then LS:='visible' else LS:='hidden';
     if scAgent.el_SetStyleAttribute(FHE,'visibility',LS)=true then
      begin
        FVisible:=Value;
      end;
    end
   else
    Fvisible:=value;
 end;

function TscElementItem.GetDState:TscElemDState;
var i:Integer;
 begin
  if (_ISDesignState=false) and (IsAttached=true) then
    begin
      i:=scAgent.el_GetState(FHE);
      if i>=0 then
         FDState:=ConvertElementStateToDState(i);
    end;
   Result:=FDState;
 end;

procedure TscElementItem.SetDState(Value:TscElemDState);
var i,iC:integer;
 begin
  if (value<>FDState) or (FhmFlag=true) then
   begin
   if (_ISDesignState=false) and (IsAttached=true) then
    begin
      ConvertDSTypeToElementState(Value,i,iC);
      if scAgent.el_SetStateEx(FHE,i,iC,true)=true then
       begin
         FDState:=Value;
       end;
    end
    else FDState:=Value;
   end;
 end;

function TscElementItem._ISDesignState:boolean;
 begin
   Result:=(csDesigning in TComponent(TCollection(GetOwner).Owner).ComponentState);
 end;

procedure TscElementItem.SetIndex(Value: Integer);
begin
  inherited SetIndex(Value);
 /// ShowMessage(IntToStr(Value));
end;

function  TscElementItem.GetDisplayName: string;
var LS:string;
begin
  //
  LS:='';
  if FID='' then LS:='<EMPTY>' else LS:=FID;
  Result :=Concat('id=',LS);
end;

function TscElementItem.AssignToID:boolean;
var LHE:Helement;
 begin
   Result:=false;
    if Assigned(scAgent) then
    with scAgent do
     begin
      if FID<>'' then
         Result:=el_FindFromID(FID,LHE);
         if Result=true then FHE:=LHE; // !
     end;
 end;

function TscElementItem.AssignHandlers:boolean;
 begin
   Result:=false;
   if Assigned(scAgent) then
    with scAgent do
     begin
      el_SetHandler(FHE,eOnMouseDown,@FOnMouseDown);
      el_SetHandler(FHE,eOnMouseUP,@FOnMouseUp);
      el_SetHandler(FHE,eOnMouseMove,@FOnMouseMove);
      el_SetHandler(FHE,eOnMouseEnter,@FOnMouseEnter);
      el_SetHandler(FHE,eOnMouseLeave,@FOnMouseLeave);
      el_SetHandler(FHE,eOnMouseWheel,@FOnMouseWheel);
      el_SetHandler(FHE,eOnKeyUp,@FOnKeyUp);
      el_SetHandler(FHE,eOnKeyDown,@FOnKeyDown);
      el_SetHandler(FHE,eOnKeyChar,@FOnKeyPress);
      el_SetHandler(FHE,eOnClick,@FOnClick);
      el_SetHandler(FHE,eOnDblClick,@FOnDblClick);
      el_SetHandler(FHE,eOnSizeChanged,@FOnResize);
      el_SetHandler(FHE,eOnTimer,@FOnTimerComplete);
      el_SetHandler(FHE,eOnSetFocus,@FOnEnter);
      el_SetHandler(FHE,eOnLostFocus,@FOnExit);
      Result:=true;
     end;
 end;


constructor TscElementItem.Create(Collection: TCollection);
 begin
    FTag:=0;  FGroup:=0;
    dbl_scAgentRef:=nil;
   inherited Create(Collection);
    FActive:=true;
    Fvisible:=true;
    FHE.pval:=nil;
    scAgent:=nil;
    FUId:=0;
    FID:='';
    FOnMouseUp:=nil;
 end;

destructor TscElementItem.Destroy;
 begin
  inherited Destroy;
 end;

procedure TscElementItem.Assign(Source: TPersistent);
var SR:TscElementItem;
 begin
  if Source is TscElementItem then
   begin
     SR:=TscElementItem(Source);
     FID:=SR.ID;
   end;
 end;

function TscElementItem.ISAttached(refindFlag:boolean=false):boolean;
 begin
   Result:=false;
   if Assigned(scAgent)=false then exit;
   if refindFlag=false then
      Result:=(FHE.pval<>nil)
   else begin
      Result:=AssignToID;
   end;
 end;

function TscElementItem.AssignToAgent(aAgent:TscAgent):boolean;
 begin
  Result:=false;
  if Assigned(aAgent)=false then exit;
  scAgent:=aAgent;
  dbl_scAgentRef:=aAgent; // !
  if AssignToID=false then exit;
  if AssignHandlers=false then exit;
  Result:=true; // !
 end;

function TscElementItem.SetHomeState(aSetRg:integer=1):boolean;
 begin
   Result:=ISAttached(false);
   if Result=false then exit;
   FhmFlag:=true;
   SetActive(FActive);
   SetVisible(FVisible);
   SetDState(FDState);
   FhmFlag:=false; // !!
   Result:=true;
 end;

////////////////////////////////////////////////////////////////
///
///   Collection
///
  function TscElemCollection.GetItem(Index: Integer): TscElementItem;
   begin
     Result :=  TscElementItem(inherited GetItem(Index));
   end;

  procedure TscElemCollection.SetItem(Index: Integer; Value: TscElementItem);
    begin
      inherited SetItem(Index, Value);
    end;

  function TscElemCollection.FindItemFromID(const aID:string):TscElementItem;
  var i:integer;
   begin
     Result:=nil;
     i:=0;
     while i<Self.Count do begin
        if (Items[i].ID=aID) then begin
          Result:=Items[i];
          break;
        end;
       Inc(i);
      end;
   end;

  procedure TscElemCollection.ReplaceGroupDState(const aSrc:TscElementItem; newSt:TscElemDStates; aSign:integer=0);
  var i:integer;
   begin
     if (Assigned(aSrc)=false) then exit;
     if (aSrc.Group=0) then exit;
     i:=0;
     while i<Self.Count do begin
        if (Items[i]<>aSrc) and (Items[i].Group=aSrc.Group) then
          begin
           case aSign of
            -1:   Items[i].DState:=Items[i].DState+[newSt];
            else
                 Items[i].DState:=Items[i].DState-[newSt];
           end;
          end;
       Inc(i);
      end;
   end;


  destructor TscElemCollection.Destroy;
   begin
      inherited Destroy;
   end;

 function TscElemCollection.AssignToAgent(aAgent:TscAgent):boolean;
   var i:integer;
   begin
     Result:=false;
     i:=0;
     while i<Self.Count do begin
        if (Items[i].AssignToAgent(aAgent)=true) then
          Result:=true;
       Inc(i);
      end;
   end;

///////////////////////////////////////////////////////////////////////////
///
///   Component
///
 constructor TscComp.Create(AOwner: TComponent);
  begin
     inherited Create(AOwner);
     FElements := TscElemCollection.Create(TPersistent(Self),TscElementItem);
  end;

 destructor TscComp.Destroy;
  begin
    FElements.Free;
    FElements:=nil;
    inherited Destroy;
  end;

 function TscComp.SetScryptHandler(aAgent:TscAgent):boolean;
  begin
     if Assigned(FonScryptReceive) then
        aAgent.ScryptHandlerEvent:=FonScryptReceive;
     Result:=true;
    // Result:=FElements.AssignToAgent(aAgent);
  end;

 function TscComp.InitElements(aAgent:TscAgent):boolean;
 var i:integer;
   begin
     if Assigned(FonScryptReceive) then
        aAgent.ScryptHandlerEvent:=FonScryptReceive;
     ///
     Result:=FElements.AssignToAgent(aAgent);
     if Result=false then exit;
     i:=0;
     while i<FElements.Count do
      begin
        if FElements.Items[i].Active=true then
           FElements.Items[i].SetHomeState(1);
        Inc(i);
      end;
      Result:=true;
   end;

 function TscComp.GetElemID(const aName:string):TscElementItem;
  begin
    Result:=FElements.FindItemFromID(aName);
    Result.Visible:=false;
  end;

{ procedure TscComp.SetElemID(const aName:string; Value:TscElementItem);
  begin
    // LV:=FElements.FindItemFromID(aName);
  end;
 }



end.
