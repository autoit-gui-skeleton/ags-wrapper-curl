; ============================================================================================================================
; File		: Request_Example.au3 (2015.06.07)
; Purpose	: Demonstrate the Request.au3 UDF
; Author	: Ward
; Dependency: Request.au3, Curl.au3, Json.au3
; ============================================================================================================================

#Include "Json.au3"
#Include "Curl.au3"
#Include "Request.au3"

Request_Example_1()
Request_Example_2()
Request_Example_3()
Request_Example_4()
Request_Example_5()

; ============================================================================================================================
; Request Example 1 - Demonstrate the different request format
; ============================================================================================================================
Func Request_Example_1()
	Request_Example_Output("Request Example 1")
	Local $Backup = RequestDefault('{refer: "http://www.autoitscript.com"}')

	Local $Data = Request("http://www.google.com")
	Local $ResponseCode = @Extended
	Request_Example_Output("=== Request Url ===")
	Request_Example_Output("ResponseCode", $ResponseCode)
	Request_Example_Output("ReturnData", $Data)
	Request_Example_Output("")

	Local $Json = '{url: "http://www.google.com", agent: "AutoIt/Request"}'
	Local $Data = Request($Json)
	Local $ResponseCode = @Extended
	Request_Example_Output("=== Request Json ===")
	Request_Example_Output("ResponseCode", $ResponseCode)
	Request_Example_Output("ReturnData", $Data)
	Request_Example_Output("")

	Local $Obj = Json_ObjCreate()
	Json_ObjPut($Obj, "url", "http://www.google.com")
	Json_ObjPut($Obj, "agent", "AutoIt/Request")
	Local $Data = Request($Obj)
	Local $ResponseCode = @Extended
	Request_Example_Output("=== Request Object ===")
	Request_Example_Output("ResponseCode", $ResponseCode)
	Request_Example_Output("ReturnData", $Data)
	Request_Example_Output("")

	Local $Array[] = ["http://www.google.com", "http://wikipedia.org"]
	Local $Data = Request($Array)
	Request_Example_Output("=== Request Array ===")
	Request_Example_Output("ReturnData[0]", $Data[0])
	Request_Example_Output("ReturnData[1]", $Data[1])
	Request_Example_Output("")

	Local $Array[] = ["http://www.google.com", "http://wikipedia.org"]
	Local $Obj = Json_ObjCreate()
	Json_ObjPut($Obj, "url", $Array)
	Json_ObjPut($Obj, "agent", "AutoIt/Request")
	Local $Data = Request($Obj)
	Request_Example_Output("=== Request Array In Object ===")
	Request_Example_Output("ReturnData[0]", $Data[0])
	Request_Example_Output("ReturnData[1]", $Data[1])
	Request_Example_Output("")

	Local $Obj1, $Obj2
	Json_Put($Obj1, ".url", "http://www.google.com")
	Json_Put($Obj1, ".agent", "AutoIt/Request/1")
	Json_Put($Obj2, ".url", "http://wikipedia.org")
	Json_Put($Obj2, ".agent", "AutoIt/Request/2")
	Local $Array[] = [$Obj1, $Obj2]
	Local $Data = Request($Array)
	Request_Example_Output("=== Request Object In Array ===")
	Request_Example_Output("ReturnData[0]", $Data[0])
	Request_Example_Output("ReturnData[1]", $Data[1])
	Request_Example_Output("")

	Local $Json = '{url: ["http://www.google.com", "http://wikipedia.org"], agent: "AutoIt/Request"}'
	Local $Data = Request($Json)
	Request_Example_Output("=== Request Array In Json ===")
	Request_Example_Output("ReturnData[0]", $Data[0])
	Request_Example_Output("ReturnData[1]", $Data[1])
	Request_Example_Output("")

	Local $Array[] = ['{url: "http://www.google.com", agent: "AutoIt/Request/1"}', '{url: "http://wikipedia.org", agent: "AutoIt/Request/2"}']
	Local $Data = Request($Array)
	Request_Example_Output("=== Request Json In Array ===")
	Request_Example_Output("ReturnData[0]", $Data[0])
	Request_Example_Output("ReturnData[1]", $Data[1])
	Request_Example_Output("")

	RequestDefault($Backup)
EndFunc

; ============================================================================================================================
; Request Example 2 - Demonstrate the different HTTP POST format
; ============================================================================================================================
Func Request_Example_2()
	Request_Example_Output("Request Example 2")
	Local $Backup = RequestDefault('{agent: "AutoIt/Request", postencode: "utf8" }')

	Request_Example_Output("=== HTTP POST Test ===")
	Local $Json = Request("http://httpbin.org/post", "key=Post%20can%20be%20the%20raw%20data")
	Local $Obj = Json_Decode($Json)
	Request_Example_Output("PostResult", Json_Get($Obj, ".form.key"))

	Local $PostObj = Json_ObjCreate()
	Json_ObjPut($PostObj, "key", "Post can be an object")
	Local $Json = Request("http://httpbin.org/post", $PostObj)
	Local $Obj = Json_Decode($Json)
	Request_Example_Output("PostResult", Json_Get($Obj, ".form.key"))

	Local $Json = Request("http://httpbin.org/post", '{key: "Post can be a json object string"}')
	Local $Obj = Json_Decode($Json)
	Request_Example_Output("PostResult", Json_Get($Obj, ".form.key"))

	Local $Json = Request('{url: "http://httpbin.org/post", post:{key: "Post can be set as second paramemtr or \"post\" option"}}')
	Local $Obj = Json_Decode($Json)
	Request_Example_Output("PostResult", Json_Get($Obj, ".form.key"))

	Local $Json = Request('{url: "http://httpbin.org/post", form:{key: "Or user \"form\" option to generate multipart form data"}}')
	Local $Obj = Json_Decode($Json)
	Request_Example_Output("PostResult", Json_Get($Obj, ".form.key"))

	RequestDefault($Backup)
EndFunc

; ============================================================================================================================
; Request Example 3 - Demonstrate the callback and returnobj options
; ============================================================================================================================
Func Request_Example_3()
	Request_Example_Output("Request Example 3")
	Local $Opt = Json_ObjCreate()
	Json_ObjPut($Opt, "callback", MyCallback)
	Json_ObjPut($Opt, "returnobj", True)
	Json_ObjPut($Opt, "multi", True)
	Json_ObjPut($Opt, "max", 5)
	Local $Backup = RequestDefault($Opt)

	Request_Example_Output("=== Invoke MyCallback ===")
	Local $Obj = Request("http://www.google.com")
	Request_Example_Output("")

	Request_Example_Output("=== Object Returned ===")
	Json_ObjPut($Obj, "Data", StringLeft(Json_ObjGet($Obj, "Data"), 100) & "...")
	Local $Json = Json_Encode($Obj, $JSON_PRETTY_PRINT + $JSON_UNESCAPED_UNICODE + $JSON_UNESCAPED_SLASHES)
	ConsoleWrite("Object: " & $Json & @LF & @LF)

	Request_Example_Output("=== 10 websites, 5 connections at once ===")
	Local $Array[] = ["http://www.google.com", "http://www.facebook.com", "http://www.youtube.com", "http://www.baidu.com", "http://www.yahoo.com", "http://www.wikipedia.com", "http://www.amazon.com", "http://www.twitter.com", "http://www.bing.com", "http://www.ebay.com"]
	Request($Array)

	RequestDefault($Backup)
EndFunc

Func MyCallback($Obj)
	Local $Curl = Json_ObjGet($Obj, "Handle")
	Local $Code = Json_ObjGet($Obj, "Code")
	Local $EffectiveUrl = Json_ObjGet($Obj, "EffectiveUrl")
	If $Code = $CURLE_OK Then
		Local $Speed = Curl_Easy_GetInfo($Curl, $CURLINFO_SPEED_DOWNLOAD)

		Request_Example_Output("Effective url", $EffectiveUrl)
		Request_Example_Output("Download speed", Round($Speed / 1024, 2))
	EndIf
EndFunc


; ============================================================================================================================
; Request Example 4 - Paste text to pastebin.com
; ============================================================================================================================
Func Request_Example_4()
	Request_Example_Output("Request Example 4")
	Local $Backup = RequestDefault('{agent: "AutoIt/Request", cookiefile: "cookie.txt", cookiejar: "cookie.txt", }')

	Request_Example_Output("Get post_key ...")
	Local $Data = Request('http://pastebin.com/')
	Local $Match = StringRegExp($Data, '(?U)<input name="post_key" value="(.*)" type="hidden" />', 3)
	If @Error Then Return
	Local $PostKey = $Match[0]

	Request_Example_Output("Send post data ...")
	Local $Post
	Json_Put($Post, ".post_key", $PostKey)
	Json_Put($Post, ".submit_hidden", "submit_hidden")
	Json_Put($Post, ".paste_code", "quick fox jumps over the lazy dog")
	Json_Put($Post, ".paste_format", "1")
	Json_Put($Post, ".paste_expire_date", "1H")
	Json_Put($Post, ".paste_name", "")
	Local $Obj = Request('{url: "http://pastebin.com/post.php", returnobj: true}', $Post)
	Local $Url = Json_ObjGet($Obj, "EffectiveUrl")

	Request_Example_Output("Pastebin link", $Url)
	RequestDefault($Backup)
EndFunc

; ============================================================================================================================
; Request Example 5 - ZippyShare.com uploader
; ============================================================================================================================
Func Request_Example_5()
	Request_Example_Output("Request Example 5")

	Local $Filename = FileOpenDialog("Please Select A File To Upload To ZippyShare.com", @ScriptDir, "All (*.*)", 3)
	If Not FileExists($Filename) Then Return
	Request_Example_Output("Uploading " & $Filename & "...")

	Local $Data = Request("http://www.zippyshare.com")
	Local $Match = StringRegExp($Data, "var server = '(www\d+)';", 3)
	If @Error Then Return
	Local $WWW = $Match[0]

	Local $Opt
	Json_Put($Opt, ".url", StringFormat("http://%s.zippyshare.com/upload", $WWW))
	Json_Put($Opt, ".form.name", "name")
	Json_Put($Opt, ".form.notprivate", "true")
	Json_Put($Opt, ".form.zipname", "")
	Json_Put($Opt, ".form.ziphash", "")
	Json_Put($Opt, ".form.embPlayerValues", "false")
	Json_Put($Opt, ".form.file.type", "application/octet-stream")
	Json_Put($Opt, ".form.file.name", "test.bin")
	Json_Put($Opt, ".form.file.path", $Filename)

	Local $Data = Request($Opt)
	$Match = StringRegExp($Data, '<a target="top" href="([^"]+)">', 3)
	If @Error Then Return

	Request_Example_Output("Download link", $Match[0])
EndFunc

Func Request_Example_Output($Name, $Data = "")
	If $Data Then
		If StringLen($Data) > 100 Or StringInStr($Data, @LF) Then $Data = StringFormat('"%s..."', Json_StringEncode(StringLeft($Data, 100)))
		ConsoleWrite(StringFormat($Name & ": %s\n", $Data))
	Else
		ConsoleWrite(StringFormat($Name & "\n"))
	EndIf
EndFunc
