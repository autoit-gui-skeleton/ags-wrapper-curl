; ============================================================================================================================
; File		: Request.au3 (2015.06.07)
; Purpose	: AutoIt HTTP request UDF
; Author	: Ward
; Dependency: Curl.au3, Json.au3
; ============================================================================================================================

; ============================================================================================================================
; Public Functions:
;   RequestDefault($Default = Null)
;   Request($Request, $Post = Null)
;
; Avaliable Options:
;   Global Options:
;     multi
;       Use multi interface, by default True
;     max = multimax
;       Maximum connection at once
;     delay = multidelay
;       Delay during internal loop, by default 10 (in milliseconds)
;
;   Curl Options:
;     url
;       URL to work on (http, https, ftp, ftps)
;     post
;       Send a POST with this data
;     postencode = postencoding
;       If post is an object, how to encode it (utf8 or ansi, by default utf8)
;     proxy
;       Proxy to use (http://, socks4://, socks4a://, socks5://)
;     timeout
;       Timeout for the entire request, default 30 (in sec)
;	  cookiejar
;       File to write cookies to
;	  cookiefile
;       File to read cookies from
;	  cookie
;       Cookie to send
;	  agent = useragent
;       User-Agent: header
;	  refer
;       Referer: header
;     autorefer
;       Automatically set Referer: header
;	  header = httpheader
;       Custom HTTP headers. String split by @LF, or string array
;	  follow = followlocation
;       Follow HTTP redirects, by default true
;     maxredirs
;       Maximum number of redirects to follow, -1 = unlimited
;     maxdownloadspeed
;       Cap the download speed to this
;     maxuploadspeed
;       Cap the upload speed to this
;     form
;       Pass a json object. It will be converted to multipart HTTP POST data.
;	  httppost
;       Create your own multipart HTTP POST by Curl_FormAdd().
;
;   Data Options:
;     encode = encoding
;       How to convert returned data ("ansi", "unicode", "utf16be", "utf8", "binary")
;	  debug
;       The function to output the error string, by default set to ConsoleWrite
;	  returnobj
;       Reutrn object data instead of string (or binary) data.
;	  callback
;       Set callback function to receive object data
; ============================================================================================================================

#Include-once
#Include <Array.au3>
#Include "Curl.au3"
#Include "Json.au3"

Func RequestDefault($Default = Null)
	Static $DefaultObj = Json_ObjCreate()

	Local $Backup = Json_ObjCreate()
	__Request_OptionCopy($DefaultObj, $Backup)

	If Not IsKeyword($Default) Then
		If IsString($Default) Then
			$Default = StringStripWS($Default, 3)
			If StringLeft($Default, 1) = "{" And StringRight($Default, 1) = "}" Then
				$Default = Json_Decode($Default)
			EndIf
		EndIf

		If Json_IsObject($Default) Then
			Local $Obj = Json_ObjCreate()
			__Request_OptionCopy($Default, $Obj)
			$DefaultObj = $Obj
		Else
			$DefaultObj = Json_ObjCreate()
		EndIf
	EndIf
	Return $Backup
EndFunc

#cs
	acceptable $Request type
	string (input is url, use default option)
	object, url is string or string array (url or url array, use input object as option)
	array, item is string or object (url array, use default option Or every url has different option)
#ce

Func Request($Request, $Post = Null)
	Local $UrlList[0], $OptList[0]
	Local $Multi = True, $MultiMax = 10, $MultiDelay = 10, $MultiOpt = "", $Unwind = False

	If IsString($Request) Then
		; input is url, use default option
		$Request = StringStripWS($Request, 3)
		If (StringLeft($Request, 1) = "[" And StringRight($Request, 1) = "]") Or (StringLeft($Request, 1) = "{" And StringRight($Request, 1) = "}") Then
			$Request = Json_Decode($Request)
		Else
			$OptList = RequestDefault()
			If Not IsKeyword($Post) Then Json_ObjPut($OptList, "post", $Post)
			$MultiOpt = $OptList

			_ArrayAdd($UrlList, $Request)
			$Unwind = True
		EndIf
	EndIf

	If Json_IsObject($Request) Then
		; input is url or url array, use input object as option

		$OptList = RequestDefault()
		If Not IsKeyword($Post) Then Json_ObjPut($OptList, "post", $Post)
		__Request_OptionCopy($Request, $OptList)
		$MultiOpt = $OptList

		Local $Url = Json_ObjGet($OptList, "url")
		If IsArray($Url) Then
			$UrlList = $Url
		Else
			_ArrayAdd($UrlList, $Url)
			$Unwind = True
		EndIf

	ElseIf IsArray($Request) Then
		; input is url array (use default option) or object array (every url or url array has different option)

		For $i = 0 To UBound($Request) - 1
			Local $Req = $Request[$i]
			Local $Opt = RequestDefault()
			If Not IsKeyword($Post) Then Json_ObjPut($Opt, "post", $Post)

			If IsString($Req) Then
				$Req = StringStripWS($Req, 3)
				If StringLeft($Req, 1) = "{" And StringRight($Req, 1) = "}" Then
					$Req = Json_Decode($Req)
				Else
					_ArrayAdd($UrlList, $Req)
					_ArrayAdd($OptList, $Opt)
					ContinueLoop
				EndIf
			EndIf

			If Json_IsObject($Req) Then
				__Request_OptionCopy($Req, $Opt)
				Local $Url = Json_ObjGet($Opt, "url")
				If IsArray($Url) Then
					For $j = 0 To UBound($Url) - 1
						_ArrayAdd($UrlList, $Url[$j])
						_ArrayAdd($OptList, $Opt)
					Next
				Else
					_ArrayAdd($UrlList, $Url)
					_ArrayAdd($OptList, $Opt)
				EndIf
			EndIf
		Next

		If UBound($OptList) > 0 Then $MultiOpt = $OptList[0]
	EndIf

	If UBound($UrlList) = 0 Then Return SetError(1, 0, "")

	If Json_IsObject($MultiOpt) Then
		If Json_ObjExists($MultiOpt, "multi") Then $Multi = Json_ObjGet($MultiOpt, "multi")
		If Json_ObjExists($MultiOpt, "max") Then $MultiMax = Json_ObjGet($MultiOpt, "max")
		If Json_ObjExists($MultiOpt, "multimax") Then $MultiMax = Json_ObjGet($MultiOpt, "multimax")
		If Json_ObjExists($MultiOpt, "delay") Then $MultiDelay = Json_ObjGet($MultiOpt, "delay")
		If Json_ObjExists($MultiOpt, "multidelay") Then $MultiDelay = Json_ObjGet($MultiOpt, "multidelay")
	EndIf

	Local $LastResponseCode = 0
	Local $RetList[UBound($UrlList)]
	If $Multi Then
		Local $Multi = Curl_Multi_Init()
		If Not $Multi Then Return SetError(1, 0, "")

		Local $ListIndex = 0, $Running = 0, $MsgsInQueue
		Local $CurlMap = Json_ObjCreate()
		While 1
			While $Running < $MultiMax And $ListIndex < UBound($UrlList)
				Local $Slist = 0, $HttpPost = 0
				Local $Opt = (IsArray($OptList) ? $OptList[$ListIndex] : $OptList)
				Local $Curl = __Request_CurlEasyInit($UrlList[$ListIndex], $Opt, $Slist, $HttpPost)
				If $Curl Then
					Local $Info[3] = [$ListIndex, $Slist, $HttpPost]
					Json_ObjPut($CurlMap, $Curl, $Info)
					Curl_Multi_Add_Handle($Multi, $Curl)
				EndIf
				$ListIndex += 1
				$Running += 1
			WEnd

			Curl_Multi_Perform($Multi, $Running)
			Do
				Local $CURLMsg = Curl_Multi_Info_Read($Multi, $MsgsInQueue)
				If DllStructGetData($CURLMsg, "msg") = $CURLMSG_DONE Then
					Local $Curl = DllStructGetData($CURLMsg, "easy_handle")
					Local $Code = DllStructGetData($CURLMsg, "data")
					Curl_Multi_Remove_Handle($Multi, $Curl)

					Local $Info = Json_ObjGet($CurlMap, $Curl)
					If UBound($Info) = 3 Then
						Local $Index = $Info[0]
						Local $Slist = $Info[1]
						Local $HttpPost = $Info[2]
						Local $Opt = (IsArray($OptList) ? $OptList[$Index] : $OptList)

						$RetList[$Index] = __Request_CurlEasyFinish($Index, $Curl, $Code, $UrlList[$Index], $Opt, $Slist, $HttpPost)
						$LastResponseCode = @Extended
					EndIf
				EndIf
			Until $MsgsInQueue = 0

			If $Running = 0 And $ListIndex = UBound($UrlList) Then ExitLoop
			Sleep($MultiDelay)
		WEnd
		Curl_Multi_Cleanup($Multi)

	Else
		For $i = 0 To UBound($UrlList) - 1
			Local $Slist = 0, $HttpPost = 0
			Local $Opt = (IsArray($OptList) ? $OptList[$i] : $OptList)
			Local $Curl = __Request_CurlEasyInit($UrlList[$i], $Opt, $Slist, $HttpPost)
			Local $Code = Curl_Easy_Perform($Curl)

			$RetList[$i] = __Request_CurlEasyFinish($i, $Curl, $Code, $UrlList[$i], $Opt, $Slist, $HttpPost)
			$LastResponseCode = @Extended
		Next
	EndIf

	Return SetExtended($LastResponseCode, (($Unwind And UBound($RetList) = 1) ? $RetList[0] : $RetList))
EndFunc

Func __Request_OptionCopy(ByRef $From, ByRef $To)
	Local $Keys = Json_ObjGetKeys($From)
	For $i = 0 To UBound($Keys) - 1
		Json_ObjPut($To, StringLower($Keys[$i]), Json_ObjGet($From, $Keys[$i]))
	Next
EndFunc

Func __Request_DataEncoding(ByRef $Data, $Encode = "", $ContentType = "")
	Select
		Case $Encode = "utf8" Or $Encode = "utf-8" Or $Encode == 4
			$Encode = 4

		Case $Encode = "utf16be" Or $Encode = 3
			$Encode = 3

		Case $Encode = "ansi" Or $Encode = "ascii" Or $Encode == 1
			$Encode = 1

		Case $Encode = "unicode" Or $Encode = "utf16" Or $Encode = "utf16le" Or $Encode == 2
			$Encode = 2

		Case $Encode = "binary" Or $Encode = "bin" Or $Encode == 0
			$Encode = 0

		Case Else
			If StringInStr($ContentType, "utf-8") Or StringInStr($ContentType, "utf8") Then
				$Encode = 4
			ElseIf StringInStr($ContentType, "text") Or StringInStr($ContentType, "json") Then
				$Encode = 1
			Else
				$Encode = 0
			EndIf
	EndSelect

	If $Encode Then $Data = BinaryToString($Data, $Encode)
EndFunc

Func __Request_CurlEasyInit($Url, $Opt, ByRef $Slist, ByRef $HttpPost)
	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return SetError(1, 0, 0)

	Local $Obj = RequestDefault()
	Local $Keys = Json_ObjGetKeys($Opt)
	For $i = 0 To UBound($Keys) - 1
		Json_ObjPut($Obj, StringLower($Keys[$i]), Json_ObjGet($Opt, $Keys[$i]))
	Next

	Curl_Easy_Setopt($Curl, $CURLOPT_URL, StringStripWS($Url, 3))
	If Json_ObjExists($Obj, "proxy") Then Curl_Easy_Setopt($Curl, $CURLOPT_PROXY, Json_ObjGet($Obj, "proxy"))
	If Json_ObjExists($Obj, "refer") Then Curl_Easy_Setopt($Curl, $CURLOPT_REFERER, Json_ObjGet($Obj, "refer"))
	If Json_ObjExists($Obj, "autorefer") Then Curl_Easy_Setopt($Curl, $CURLOPT_AUTOREFERER, Json_ObjGet($Obj, "autorefer"))
	If Json_ObjExists($Obj, "maxredirs") Then Curl_Easy_Setopt($Curl, $CURLOPT_MAXREDIRS, Json_ObjGet($Obj, "maxredirs"))
	If Json_ObjExists($Obj, "maxdownloadspeed") Then Curl_Easy_Setopt($Curl, $CURLOPT_MAX_RECV_SPEED_LARGE, Json_ObjGet($Obj, "maxdownloadspeed"))
	If Json_ObjExists($Obj, "maxuploadspeed") Then Curl_Easy_Setopt($Curl, $CURLOPT_MAX_SEND_SPEED_LARGE, Json_ObjGet($Obj, "maxuploadspeed"))
	If Json_ObjExists($Obj, "httppost") Then Curl_Easy_Setopt($Curl, $CURLOPT_HTTPPOST, Json_ObjGet($Obj, "httppost"))
	If Json_ObjExists($Obj, "sslversion") Then Curl_Easy_Setopt($Curl, $CURLOPT_SSLVERSION, Json_ObjGet($Obj, "sslversion"))
	If Json_ObjExists($Obj, "cookiejar") Then Curl_Easy_Setopt($Curl, $CURLOPT_COOKIEJAR, Json_ObjGet($Obj, "cookiejar"))
	If Json_ObjExists($Obj, "cookiefile") Then Curl_Easy_Setopt($Curl, $CURLOPT_COOKIEFILE, Json_ObjGet($Obj, "cookiefile"))
	If Json_ObjExists($Obj, "cookie") Then Curl_Easy_Setopt($Curl, $CURLOPT_COOKIE, Json_ObjGet($Obj, "cookie"))

	; "agent" = "useragent"
	If Json_ObjExists($Obj, "agent") Then Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, Json_ObjGet($Obj, "agent"))
	If Json_ObjExists($Obj, "useragent") Then Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, Json_ObjGet($Obj, "useragent"))

	; "header" = "httpheader"
	Local $Header = Null
	If Json_ObjExists($Obj, "header") Then $Header = Json_ObjGet($Obj, "header")
	If Json_ObjExists($Obj, "httpheader") Then $Header = Json_ObjGet($Obj, "httpheader")

	If IsString($Header) Or IsArray($Header) Or Json_IsObject($Header) Then
		$Slist = 0

		If IsString($Header) Then
			$Header = StringStripWS($Header, 3)
			If (StringLeft($Header, 1) = "[" And StringRight($Header, 1) = "]") Or (StringLeft($Header, 1) = "{" And StringRight($Header, 1) = "}") Then
				$Header = Json_Decode($Header)
			EndIf
		EndIf

		If Json_IsObject($Header) Then
			Local $Keys = Json_ObjGetKeys($Header)
			For $i = 0 To UBound($Keys) - 1
				Local $Key = $Keys[$i]
				Local $Value = Json_ObjGet($Header, $Key)
				$Slist = Curl_Slist_Append($Slist, $Key & ": " & $Value)
			Next
		ElseIf IsArray($Header) Then
			For $i = 0 To UBound($Header) - 1
				$Slist = Curl_Slist_Append($Slist, $Header[$i])
			Next
		Else
			$Slist = Curl_Slist_Append(0, $Header, True)
		EndIf
		Curl_Easy_Setopt($Curl, $CURLOPT_HTTPHEADER, $Slist)
	EndIf

	; "follow" = "followlocation", default = true
	Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)
	If Json_ObjExists($Obj, "follow") Then Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, Json_ObjGet($Obj, "follow"))
	If Json_ObjExists($Obj, "followlocation") Then Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, Json_ObjGet($Obj, "followlocation"))

	; timeout, default = 30
	Curl_Easy_Setopt($Curl, $CURLOPT_TIMEOUT, (Json_ObjExists($Obj, "timeout") ? Json_ObjGet($Obj, "timeout") : 30))

	If Json_ObjExists($Obj, "post") Then
		Local $Post = Json_ObjGet($Obj, "post")

		If IsString($Post) Then
			$Post = StringStripWS($Post, 3)
			If StringLeft($Post, 1) = "{" And StringRight($Post, 1) = "}" Then
				$Post = Json_Decode($Post)
			EndIf
		EndIf

		If Json_IsObject($Post) Then
			Local $PostEncode = 4
			If Json_ObjExists($Obj, "postencode") Then $PostEncode = Json_ObjGet($Obj, "postencode")
			If Json_ObjExists($Obj, "postencoding") Then $PostEncode = Json_ObjGet($Obj, "postencoding")
			$PostEncode = ($PostEncode = "ansi" Or $PostEncode = "ascii" Or $PostEncode = 1 ? 1 : 4)

			Local $Str = ""
			Local $Keys = Json_ObjGetKeys($Post)
			For $i = 0 To UBound($Keys) - 1
				Local $Key = $Keys[$i]
				Local $Value = Json_ObjGet($Post, $Key)
				$Str &= ($Str ? "&" : "") & Curl_Escape($Key, $PostEncode) & "=" & Curl_Escape($Value, $PostEncode)
			Next
			$Post = $Str
		EndIf

		Curl_Easy_Setopt($Curl, $CURLOPT_POST, 1)
		Curl_Easy_Setopt($Curl, $CURLOPT_COPYPOSTFIELDS, $Post)
	EndIf

	If Json_ObjExists($Obj, "form") Then
		Local $LastItem
		Local $Form = Json_ObjGet($Obj, "form")
		Local $Keys = Json_ObjGetKeys($Form)
		For $i = 0 To UBound($Keys) - 1
			Local $Key = $Keys[$i]
			Local $Value = Json_ObjGet($Form, $Key)
			If IsString($Value) And StringLen($Value) Then
				Curl_FormAdd($HttpPost, $LastItem, $CURLFORM_COPYNAME, $Key, $CURLFORM_COPYCONTENTS, $Value, $CURLFORM_END)

			ElseIf IsBinary($Value) And BinaryLen($Value) Then
				Local $Buffer = DllStructCreate("byte[" & BinaryLen($Value) & "]")
				DllStructSetData($Buffer, 1, $Value)
				Curl_FormAdd($HttpPost, $LastItem, $CURLFORM_COPYNAME, $Key, $CURLFORM_COPYCONTENTS, DllStructGetPtr($Buffer), $CURLFORM_CONTENTSLENGTH, BinaryLen($Value), $CURLFORM_END)

			ElseIf Json_IsObject($Value) Then
				Local $Script = ', $CURLFORM_COPYNAME, $Key', $Path, $Name, $Type

				If Json_ObjExists($Value, "path") Then
					Local $Path = Json_ObjGet($Value, "path")
					$Script &= ', $CURLFORM_FILE, $Path'
				EndIf

				If Json_ObjExists($Value, "name") Then
					Local $Name = Json_ObjGet($Value, "name")
					$Script &= ', $CURLFORM_FILENAME, $Name'
				EndIf

				If Json_ObjExists($Value, "type") Then
					Local $Type = Json_ObjGet($Value, "type")
					$Script &= ', $CURLFORM_CONTENTTYPE, $Type'
				EndIf

				Execute(StringFormat('Curl_FormAdd($HttpPost, $LastItem%s, $CURLFORM_END)', $Script))
			EndIf
		Next
		Curl_Easy_Setopt($Curl, $CURLOPT_HTTPPOST, $HttpPost)
	EndIf

	Curl_Easy_Setopt($Curl, $CURLOPT_HEADERFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_HEADERDATA, $Curl + 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_ACCEPT_ENCODING, "")
	Curl_Easy_Setopt($Curl, $CURLOPT_SSL_VERIFYPEER, 0)

	Return $Curl
EndFunc

Func __Request_CurlEasyFinish($Index, $Curl, $Code, $Url, $Opt, $Slist, $HttpPost)
	Local $Encode = "", $Debug = ConsoleWrite, $ReturnObj = False, $Callback = Null
	If Json_ObjExists($Opt, "encode") Then $Encode = Json_ObjGet($Opt, "encode")
	If Json_ObjExists($Opt, "encoding") Then $Encode = Json_ObjGet($Opt, "encoding")
	If Json_ObjExists($Opt, "debug") Then $Debug = Json_ObjGet($Opt, "debug")
	If Json_ObjExists($Opt, "returnobj") Then $ReturnObj = Json_ObjGet($Opt, "returnobj")
	If Json_ObjExists($Opt, "callback") Then $Callback = Json_ObjGet($Opt, "callback")
	If IsString($Callback) And IsFunc(Execute($Callback))Then $Callback = Execute($Callback)

	Local $ResponseCode = Curl_Easy_GetInfo($Curl, $CURLINFO_RESPONSE_CODE)
	Local $ContentType = Curl_Easy_GetInfo($Curl, $CURLINFO_CONTENT_TYPE)
	Local $EffectiveUrl = Curl_Easy_GetInfo($Curl, $CURLINFO_EFFECTIVE_URL)

	Local $Data = "", $Header = ""
	If $Code = $CURLE_OK Then
		$Data = Curl_Data_Get($Curl)
		$Header = Curl_Data_Get($Curl + 1)
		__Request_DataEncoding($Data, $Encode, $ContentType)
		__Request_DataEncoding($Header, "utf8")
	ElseIf $Code <> $CURLE_OK And IsFunc($Debug) Then
		$Debug(StringFormat("Request error on '%s': %s\n", $Url, Curl_Easy_StrError($Code)))
	EndIf

	Local $Ret
	If $ReturnObj Or IsFunc($Callback) Then
		Local $Obj = Json_ObjCreate()
		Json_ObjPut($Obj, "Index", $Index)
		Json_ObjPut($Obj, "Handle", $Curl)
		Json_ObjPut($Obj, "Code", $Code)
		Json_ObjPut($Obj, "Error", Curl_Easy_StrError($Code))

		Json_ObjPut($Obj, "Url", $Url)
		Json_ObjPut($Obj, "EffectiveUrl", $EffectiveUrl)
		Json_ObjPut($Obj, "ResponseCode", $ResponseCode)
		Json_ObjPut($Obj, "ContentType", $ContentType)

		Json_ObjPut($Obj, "Header", $Header)
		Json_ObjPut($Obj, "Data", $Data)

		If IsFunc($Callback) Then $Callback($Obj)
		Json_ObjDelete($Obj, "Handle")
		$Ret = $ReturnObj ? $Obj : $Data
	Else
		$Ret = $Data
	EndIf

	Curl_Easy_Cleanup($Curl)
	Curl_Data_Cleanup($Curl)
	Curl_Data_Cleanup($Curl + 1)
	If $Slist Then Curl_Slist_Free_All($Slist)
	If $HttpPost Then Curl_FormFree($HttpPost)

	Return SetExtended($ResponseCode, $Ret)
EndFunc
