unit sc_handler;

interface

uses sc_Agent,Vcl.Controls, SciterTypes;
 // for: TscElementHandlerEvent=procedure(aTag,hPval: Pointer;  hUId,evTG: LongWord; prms: Pointer; var HRes:boolean) of object;

type

 TscHandler=class(TObject)
  ///
  public
    procedure el_Event(aTag,hPval: Pointer;  hUId,evTG: LongWord; prms: Pointer;
                                       ascEvent:TSCITER_EVENTS;
                                       aEventPtr:pointer; var HRes:boolean); virtual;
  ///
 end;

implementation

 uses Sciter, Types, Classes;

 procedure TscHandler.el_Event;
 var LMM:TMouseMoveEvent;
     LM:TMouseEvent;
     LMWheel:TMouseWheelEvent;
     LMPar:MOUSE_PARAMS;
     LPt:TPoint;
     LMBtn:TMouseButton;
     LMState:TShiftState;
     LHandled:Boolean;
     LMWDelta:integer;
    ///
     LC:TNotifyEvent;
     LKPar:KEY_PARAMS;
     LK:TKeyEvent;
     LKey: Word;
     LKP:TKeyPressEvent;
     LKPChar: Char;
     //
     LTmPar:TIMER_PARAMS;
     LTm:integer;
  begin
   ///
   Hres:=false;
   if (aEventPtr=nil) then exit;
   LHandled:=false;
   LMState:=[];
   ///
   case ascEvent of
   eOnClick,eOnDblClick: begin
                           @LC:=aEventPtr;
                            LC(nil);
                            Hres:=true;
                         end;
   eOnSetFocus,eOnLostFocus: begin
                               @LC:=aEventPtr;
                                LC(nil);
                                Hres:=true;
                             end;
   ///
   eOnMouseEnter,eOnMouseLeave,eOnMouseMove, eOnMouseDown,
                    eOnMouseUp, eOnMouseWheel,eOnMouseIdle:
     begin
        LMPar:=PMOUSE_PARAMS(prms)^;
        LPt:=LMPar.pos;
        LMBtn:=mbLeft;
        if LMPar.button_state and 1>0 then
           LMState:=LMState+[ssLeft]
        else LMBtn:=mbRight;
        if LMPar.button_state and 2>0 then
           LMState:=LMState+[ssRight]
        else if LMBtn=mbRight then LMBtn:=mbMiddle;
        if LMPar.button_state and 4>0 then
           LMState:=LMState+[ssMiddle]
        else if LMBtn=mbMiddle then LMBtn:=mbLeft;
        /// alt_States
        if ascEvent=eOnMouseWheel then LMState:=[];
        if LMPar.alt_state and 1>0 then LMState:=LMState+[ssCtrl];
        if LMPar.alt_state and 2>0 then LMState:=LMState+[ssShift];
        if LMPar.alt_state and 4>0 then LMState:=LMState+[ssAlt];
        ///
        case ascEvent of
        eOnMouseMove:  begin
                         @LMM:=aEventPtr;
                         LMM(nil,LMState,Lpt.X,Lpt.Y);
                         Hres:=true;
                       end;
        eOnMouseWheel: begin
                         @LMWheel:=aEventPtr;
                         LMWDelta:=LMPar.button_state; // ``
                         LMWheel(nil,LMState,LMWDelta,Lpt,LHandled);
                         Hres:=true;
                       end;
         else begin
               @LM:=aEventPtr;
               LM(nil,LMBtn,LMState,Lpt.X,Lpt.Y);
               Hres:=true;
           end;
        end;
     end;
   eOnKeyDown,eOnKeyUp,eOnKeyChar:
          begin
             LKPar:=PKEY_PARAMS(prms)^;
             LKey:=Word(LKpar.key_code);
             if LKPar.alt_state and 1>0 then LMState:=LMState+[ssCtrl];
             if LKPar.alt_state and 2>0 then LMState:=LMState+[ssShift];
             if LKPar.alt_state and 4>0 then LMState:=LMState+[ssAlt];
             if ascEvent<>eOnKeyChar then
                begin
                 @LK:=aEventPtr;
                 LK(nil,LKey,LMState);
                 Hres:=true;
                end
             else begin
                    @LKP:=aEventPtr;
                    LKPChar:=Char(LKey);
                    LKP(nil,LKPChar);
                    Hres:=true;
             end;
          end;
   eOnScroll: begin

              end;
   eOnDrawBackGround,eOnDrawContent,eOnDrawForeground:
    begin
     LTm:=0;
    // Hres:=true;
    end;
   eOnSizeChanged: begin
                      LTm:=0;
                      @LC:=aEventPtr;
                      LC(nil);
                      Hres:=true;
                   end;
   eOnTimer:  begin
                LTmPar:=PTIMER_Params(prms)^;
               LTm:=Integer(LTmPar.timerId);
               @LC:=aEventPtr;
               LC(nil);
               Hres:=true;
              end;
   end; // case
  end;


end.
