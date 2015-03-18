//
//  вспомогательные функции - показ информационных диалогов  используя msgbox
//
//  логирование - по вызову объекта возвращаем информацию по нету в диалоге (стандартном для Скайтера) 
  function w_TraceBox(aObj,aType=0)
  { var Lt;
   switch (aType)
   {
   case 0: {Lt=#information; break; }
   case 1: {Lt=#warning; break; }
   case 2: {Lt=#alert; break; }
   default: Lt=#information
   }
   view.msgbox(Lt,">>>ID="+aObj.id+" >>>text="+aObj.text+" >>>c_model="+aObj.contentModel+" >>>outerhtml="+aObj.outerHtml) ;  
  }
 
 function w_TraceMsg(aMs,aPlace="information")
 { var L_P="";
   if (aPlace!={}) L_P=aPlace;
  view.msgbox(L_P,aMs) ;  
  // например для целых чисел:    w_TraceMsg("info:",ir.toString());
 }
 
 function w_ShowMessage(aStr,aType=0)
 {
  var Lt;
   switch (aType)
   {
   case 0: {Lt=#information; break; }
   case 1: {Lt=#warning; break; }
   case 2: {Lt=#alert; break; }
   default: Lt=#information;
   }
   view.msgbox(Lt,aStr);
 }

 // диалог - аналог MessageDlg   - возвращает индекс в массиве нажатой кнопки 
 //                                 если кнопка не была нажата - (просто close ) - вернет -1
  //  aImage - картинка - заменяет стандартную 
 //   aDim = размер окна показа w,h  если 0,0 - вычисляется по умолчанию
 //   aJust=0    по левому краю  1 по центру 2 - по правому 
 function w_MessageDlg(aType,aCapt,aText,aBtns,aImageFile,aJust=0,aDim=[0,0])
 {
   var Lt;
   switch (aType)
   {
   case 0: {Lt=#information; break; }
   case 1: {Lt=#warning; break; }
   case 2: {Lt=#alert; break; }  //  в трeугольнике !
   case 3: {Lt=#question; break; }
   case 4: {Lt=#error; break; }
   default: Lt=#information;
   }
   var Ltext=aText;
   //
   var aButtons=new Array();
   for (var (i,bVal) in aBtns) { 
                                aButtons.push( {id:"btn"+i.toString(), text:bVal});
								}
   //
  var LRes=null;
  LRes=view.msgbox { type:Lt, 
                    content:Ltext, 
                    title:" "+aCapt,
				  //buttons:[#yes,#no]
				    buttons: aButtons,
                    onLoad: function(root){  // w_pLog(root.$(#content));
					                        if (aDim[0]>0) {root.style["width"]=px(aDim[0]); }
											if (aDim[1]>0) {root.style["height"]=px(aDim[1]); }
											// root.$(#content).style["foreground-position"]="30% 20%";
											// root.$(#content).style["float"]="none";
											// root.$(#content[type="question"]).style.set({position:#fixed, bottom:0, right:0});
											
											if  (aJust==1) 
											{
											  var LContRef=root.$(#content);
											  LContRef.style["foreground-image"]="none";
											  var img1=new Element("img");
											  if (typeof aImageFile!=#string || aImageFile=="")
											     {if (aType==1) { img1.attributes["src"]="res:icon-alert.png"; }
											      else
											          { img1.attributes["src"]="res:icon-"+Lt+".png"; }
												  }
											  else {img1.attributes["src"]=aImageFile; } // !
											  var div1=new Element(#div);											  
											 // view.msgbox(#warning,"hh");
											  div1.insert(img1);											  
											  LContRef.clear();
											  LContRef.style["padding-left"]=px(10);
											  var LPtxt=new Element("p",Ltext);											  
											  LContRef.insert(div1);
											  LContRef.insert(LPtxt);
											  if (Ltext.length>0) 
											     {
												 // LPtxt.html=Ltext;
												 // w_pLog(LPtxt.html);
												 // w_pLog(Ltext);
												 }
											  div1.style.set({align:#center, text-align: #center, margin-top:px(16)});
											  LPtxt.style.set({align:#center, text-align: #center});
										      root.$(#button-bar).style["horizontal-align"]="center";
											  }
										     //   для 2  я не делал - редкий случай по правому краю выравнивать
					                       }
                 // onClose: function(root,buttonSym){ stdout.printf("msgbox closed with #%s\n",buttonSym); }
                };
  var LID=-1;
  var ii=0;
  while (ii<aButtons.length)				
   {
    if (aButtons[ii].id==LRes) 
	   {LID=ii; break; }
	ii++;   
   }
 // w_pLog(LID); 
  return LID;				
 }
//
//    Внимание!   загрузка ресурса из того же каталога что и скрипт!
// 
var res_progressBox_ImageFile="progress_loader.gif";
var res_progressBox_Text="Подождите...";
var div_progressBox=null; //  ссылка на глоб. объект - т.к. сообщение может быть только одно
var f_processBox=false;

function wtimer_ProcessBox()
{
 if (div_progressBox!==null) { 
       if (f_processBox==true) { // view.root.style["cursor"]="wait";
	                             // 
								 view.root.style["cursor"]="wait";
								 //  // !!
	                             div_progressBox.style["visibility"]="visible";
								 div_progressBox.style["cursor"]="wait";
								 view.eventsRoot=div_progressBox;
                                 // view.root.style["cursor"]="wait"; 
								// view.root.state.disabled=true;	// применение дает обычный курсор :(					 
								 }
  }
}
//  Надпись прямо сверху центр. окна    - с прогресс баром и т.д. - "подождите, идет процесс"
//  aDelay - задержка перед показом 
function w_ProcessLvlBox(aProgressFlag,aText,aState,aDelay=0)
{// w_pLog("w_ProcessLvlBox ENTER");
 if (div_progressBox!==null) {
                                       if (aState==true) {
									                      div_progressBox.style["visibility"]="visible";
														  f_processBox=true;
														  }
										else { f_processBox=false;
										       div_progressBox.style["visibility"]="collapse";
											  }
										return true;
									 }
									 
 var LPar=$(body); 
 var LText=res_progressBox_Text;
 //w_pLog("w_ProcessLvlBox b0");
 if (typeof aText==#string && aText!=="") {LText=aText;}
 var Lww=220;
 var Lhh=76;
 //w_pLog("w_ProcessLvlBox b1");
 var Ltxt=new Element("p",LText);
 // w_pLog(LText.length*8);
     if (LText.length*8>Lww) {Lww=LText.length*8+20; }
 var LDiv= Element.create {div, id:"CenterProgressBox1"};
 LDiv.insert(Ltxt);
 var LImg=null;
 var LDiv1=null;
 //w_pLog("w_ProcessLvlBox b5");
 if (aProgressFlag==true && res_progressBox_ImageFile!="")
     { LImg=new Element("img");
	  // w_pLog("w_ProcessLvlBox b7");
       LImg.attributes["src"]=res_progressBox_ImageFile;
	   LDiv1=new Element(#div);	
      // w_pLog("w_ProcessLvlBox b9");	   
	   LDiv1.insert(LImg);	   	
	   LDiv.insert(LDiv1);
	  // w_pLog("w_ProcessLvlBox b11");	   
	  // LDiv1.style.set({text-align: #center, align:#center});
	  /* LDiv1.style.set({  background-image:"url(res:icon-information.png)",
	                      background-repeat:#expand,
                          background-position:"11px 11px 11px 11px"}); 
	  */
    
      }	
else {Lhh=44;}
     //w_pLog("w_ProcessLvlBox b14"); 
     LPar.insert(LDiv);
	// w_pLog("w_ProcessLvlBox b15");
	 // LDiv1.style.set({text-align: #center, align:#center});	
	///// LImg.style.set({vertical-align: "bottom"});
	 Ltxt.style.set({align:#center, text-align: #center, font-family: "Tahoma", font-size: px(12), // font-style:#italic, 
	                                font-weight:#bold, color: "#445577" });
	//
	// if (LDiv1!==null) {LDiv.style.set({align: #center, text-align: #center}); }
	 LDiv.style.set({position:#fixed, left:"*", right:"*", width:px(Lww), top:"*",  bottom:"*", height:px(Lhh),
                    padding:px(10),
					border-radius:px(4),
					// box-shadow: "inset -3px -3px 8px #555",
					// box-shadow: "inset 0 0 5px 15px #fff, inset 0 0 5px 5px #222",
					box-shadow: "inset 0 0 4px 8px #ccd",
					//background-color:"window",
				    background-color: "rgba(230,240,255,0.6)",
					cursor: "default",
					 // border-color: "#eeeeff #888888 #888888 #eeeeff",
					 border-color: "#558",
					 border-width: px(1),   // почему-то 4х сторонние(цветные) бордюры затирает тень
					 border-style: "inset"
                   // background-image:"url(content_bg.png)",
                   // background-repeat:#expand,
                   // background-position:"11px 11px 11px 11px"
				     
					});					
	LDiv.style["text-align"]=#center;
	w_pLog("w_ProcessLvlBox -- div_progressBox c_set");
    div_progressBox=LDiv;
	div_progressBox.style["visibility"]="hidden"; 
	w_pLog("w_ProcessLvlBox d1");
	if (aState==true) {
	  f_processBox=true;
	  if (aDelay>0) {div_progressBox.timer(aDelay,wtimer_ProcessBox); }
	  else { wtimer_ProcessBox(); }
	 }
	else {
	      // div_progressBox.style["visibility"]="hidden"; 
	      f_processBox=false;
		  }
    w_pLog("w_ProcessLvlBox EXIT");		  
	return true;
}

function w_ProcessLvlBoxState(aState)
{ 
 w_ProcessLvlBox("",aState);
 return true;
}
 
function w_ProcessLvlBoxClear()
{ f_processBox=false; 
  if (div_progressBox==null) {return false; } 
 // LDiv=$(#CenterProgressBox1};
 div_progressBox.clear();
 div_progressBox.remove();
 //view.root.state.disabled=false; // !
 
 div_progressBox=null;
 view.eventsRoot=null;
 view.root.style["cursor"]="default";
}