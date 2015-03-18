﻿
// /////////////////////////////////////
//
// логирование 


var pLogConnStr="127.0.0.1:45567";
var pLogRegime=0;
var pMaxTimeout=4;
var pLogStream = null;

var pLogEnabled=true; //    флаг позволяет отключать логирование на участках

// if( !sock ) return;

function w_activatepLog(attt)
{
  try
    {
	  pLogStream = Stream.openSocket(pLogConnStr,pMaxTimeout /*seconds timeout*/ );
	 }
   finally {
          var LRes;
          if (pLogStream==null) {LRes=false;} else {LRes=true; }
          return LRes;
      }	   
}

// не используется - т.к. сделан цикл обращений на стороне сервера
function w_reopenpLog()
{ var LLL=false;
  try
    {
	  pLogStream.openSocket(pLogConnStr,pMaxTimeout /*seconds timeout*/ );
	  LLL=true;
	 }
   finally { return LLL}
}

function w_closepLog()
{ pLogStream.println("CLOSE"); pLogStream.close; }
 

function w_pLogStr(aVal)
{
 if (pLogEnabled==false || pLogStream==null) { return false; };
 if (pLogStream.println(aVal)==true) {return true;}//w_reopenpLog();}
 else {view.msgbox(#information,"ss-null");}
}

function w_pLog(aVal,aComment="")
{ var Ls="";
 if (pLogEnabled==false || pLogStream==null) { return false; };
 if (typeof aVal==#string) {Ls=aVal;}
 if (typeof aVal==#integer) {Ls=aVal.toString();}
 if (typeof aVal==#float) {Ls=aVal.toString();}
 if (typeof aVal==#boolean) {if (aVal==true) {Ls="true";} else {Ls="false";}}
 if (typeof aVal==#object) { Ls="obj="+aVal.className+"";}
 if (Ls=="" && aVal.isElement==true) {
   Ls="tag="+aVal.tag+">>>ID="+aVal.id+" >>>c_model="+aVal.contentModel+" >>>outerhtml="+aVal.outerHtml;//" >>>text="+aVal.text;
 }  
 if (aComment!="") {pLogStream.println(aComment); }
 if (pLogStream.println(Ls)==true) {return true;}
 else {view.msgbox(#information,"obj ss-null");}
}

function w_pTrace(aComment="")
{ if (pLogEnabled==false || pLogStream==null) { return false; };
  if (aComment!="") {pLogStream.println(aComment); }
  var tr = __TRACE__; // !
  var fnme = tr[1][1];
  var L_file = tr[1][2];
  var L_line = tr[1][0];
  if (pLogStream.println("LINE="+L_line.toString()+" FUNC="+fnme+" (file="+L_file+")")==true) {return true;}
}

function w_pLogA(avR)
{ if (pLogEnabled==false || pLogStream==null) { return false; };
  var LRes=""; var Ls="";
  for (var (i,aVal) in avR) 
   { Ls="";
    if (typeof aVal==#string) {Ls=aVal;}
    if (typeof aVal==#integer) {Ls=aVal.toString();}
	if (typeof aVal==#float) {Ls=aVal.toString();}
    if (typeof aVal==#boolean) {if (aVal==true) {Ls="true";} else {Ls="false";}}
    if (typeof aVal==#object) { Ls="obj="+aVal.className+"";}
    if (Ls=="" && aVal.isElement==true) {
       Ls="tag="+aVal.tag+">>>ID="+aVal.id+" >>>c_model="+aVal.contentModel;
     }   
	 if (LRes=="") {LRes=i.toString()+":"+Ls;}
	 else {LRes=LRes+" "+i.toString()+":"+Ls;}
   }
  if (pLogStream.println(LRes)==true) {return true;}  
}

function w_clearpLog() 
 { if (pLogStream==null) { return false; };  if (pLogStream.println(":CLEAR")==true) {return true;} }