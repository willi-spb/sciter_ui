///////
//  Модуль работы с TscAction   -  смысл - реализация механизма действий 
//  
//  setActionExecute("Test1",1);  // привязка к кнопке Test1  действия (т.е. TAction с scID = Test1
//  аналогично  OnIdle зацепить на  "  if SciterMediator.UpdateActions=true then ; "
//  в этом случае получаем отслеживание состояний кнопок в зависимости от OnUpdate в части Delphi
//
//   Используем механизм событий и отправки сообщений из модуля:  include "W:/Willi/WXE5/Common/sciter_ui/js/d_InterfaceFuncs.js";
//  Принцип: 1. отправить setState, в сообщении декодировать состояние, 
//           2. отправить getState и проинициировать обратную отправку команды, т.е. отправить состояние назад в команде getState от Sc

// var ac_ErrorFlag=false; // ошибки и показ сообщений останавливают выполнение процедур 

// послать состояние в программу Delphi
function ac_SendElementState(aElem)
{
  var LCommand="getState";
  var LText="";
       var Lvis="0";
       aElem.isVisible==true ? Lvis="1" : Lvis="0";	  
	  //if (LElem.state.collapsed==false) {Lena="1";}
	   var Lena="0";
	   aElem.state.disabled==false ? Lena="1" : Lena="0";
	   var Lch="0";  
	   aElem.state.checked==true ? Lch="1" : Lch="0";
	   LText=Lvis+","+Lena+","+Lch;
	   //
  	w_pLogStr("send_State: ID="+aElem.id+" command="+LCommand+" data="+LText);
  view.int_ReceiveData(aElem.id, LCommand, LText);
}
//
function ac_SendEventState()
{
  // w_pLogStr("kkk");
  ac_SendElementState(this);
  return;
}
// установить состояние элемента - прицепляется к функции обработки сообщений (центральной) int_SendData
function ac_SetElementState(aId,aElem,aCommand,aData)
{ var LData=eval(aData);
  // w_pLogA(LData);
  if (aCommand=="setState") 
   {  w_pLogStr("setState: input_ID="+aId+" data="+aData);
    // первый 1 0 - это визуальность    второй - disabled третий - check (если допускается) 
	//  Вним.:   параметры идут массивом с именем элемента и командой в первых двух [0]  [1]
    if (LData[0]==1) { aElem.style["visibility"]="visible"; aElem.update(true); }
	   else { if (LData[0]==0) {aElem.style["visibility"]="hidden"}
	          else {aElem.style["visibility"]="collapse"}
			 }
	    if (LData[1]==0) {aElem.state.disabled=true} else {aElem.state.disabled=false}
		if (LData[2]==1) {aElem.state.checked=true} else {aElem.state.checked=false}     
   }
}

function as_Event()
{ w_pLogStr(this.id+" command=execute");
 int_PostData(this.id,"execute");
 return true;
}

 //////////////////////////////////////////////
 //
 //
 //
 function a_addAttribute(aClassName)
 {
  var LA=$$(button);
  var i=0;
  while (i<LA.length)
  { 
   w_pLog(LA[i]);
   i++;
   }
 }
 