// обработка обмена с Delphi - класс TscInterface
//
// указатель на CallBack функцию - её следует создать и в ней описать реакции отличные по именам свойст от описанных ниже
// затем этот указатель выставить на свою функцию
//
var int_SendUserFunc = null; // function(aID,aElement,aParamName,aValue) 

// получить данные из Delphi в скайтере
function int_SendData(aID, aParamName, aValue)
{
	var LElem=null;
	function L_f1()
	{
		if (LElem == view)
		{
			if (aParamName == "state")
			{
				view.state = aValue.toInteger();
			}
		
			return null;
		}
	
		if (aParamName=="value") { LElem.value=aValue; return null; }
		if (aParamName=="progress") { LElem.value=aValue.toFloat(); return null; }
		if (aParamName=="text") { LElem.text=aValue; return null; }
		if (aParamName=="html") { LElem.html=aValue; return null; }
		if (aParamName=="title") { LElem.attributes["title"] = aValue; return null; }
		if (aParamName=="hover") { aValue=="1" ? LElem.state.hover=true : LElem.state.hover=false; return null; }
		if (aParamName=="checked") { aValue=="1" ? LElem.state.checked=true : LElem.state.checked=false; return null; }
		if (aParamName=="disabled") { aValue=="1" ? LElem.state.disabled=true : LElem.state.disabled=false; return null; }
		if (aParamName=="enabled") { aValue=="1" ? LElem.state.disabled=false : LElem.state.disabled=true; return null; }
		if (aParamName=="collapsed") { aValue=="1" ? LElem.state.collapsed=true : LElem.state.collapsed=false; return null; }
		if (aParamName=="pressed") { aValue=="1" ? LElem.state.pressed=true : LElem.state.pressed=false; return null; }	
		
		if (aParamName=="display") { LElem.style#display = aValue ; return null; }
	}

	// if (aID != "scanfilename") { w_pLogStr("id="+aID+" aParamname="+aParamName+" Value="+aValue)};
	
	// найти по ID нужный элемент   
	if (aID == "view")
	{
		LElem = view;
	}
    else if (aID != "*" && aID != "")
    {	
		LElem = parseData("$(#"+aID+")");
		if (LElem==null)
		{
			w_ShowMessage(" int_SendData: not found Element id="+aID,2);
			return null;
		} 
	}

	// w_pLogStr(aParamName);
	L_f1();

	// вызвать свою
	if (int_SendUserFunc !== null) 
	{  // w_pLogStr("USER: aID="+aID+" param="+aParamName+" aValue="+aValue);
		int_SendUserFunc(aID, LElem, aParamName, aValue);
	}
}

// отправить команду в Delphi
function int_PostData(aID, aCommand, aData="")
{
	view.int_ReceiveData(aID, aCommand, aData);
}

// аналог - использовать для событий
function int_PostEvent(aElem, aCommand="")
{ 
	view.int_ReceiveData(aElem.id, aCommand);
}

// доп. - задать функцию реакции для указанного ID из файла htm
function int_SetEvent(aID, aEventType, aEventFunc)
{
	var LElem=null;   
	LElem = parseData("$(#" + aID + ")");  //  элемент должен быть в файле - ищем его по ID
	
	if (LElem==null) { w_ShowMessage("int_SetEvent: not found Element id=" + aID, 2); return null; } 
	
	LElem.subscribe(aEventType, aEventFunc);
}

function ii_Event()
{
 int_PostData(this.id,"");
 return;
}

// отправить команду в D
function int_SetDataEvent(aID,aEventType="click")
{
 int_SetEvent(aID,ii_Event,aEventType);
 return;
}
