; ============================================================================================================================
; File		: Curl_Example_Easy.au3 (2015.06.04)
; Purpose	: Demonstrate the easy interface for curl.au3
; Author	: Ward
; Dependency: Curl.au3
; ============================================================================================================================

#Include "../Curl.au3"

; Your own proxy server
Global $ProxySever = "http://myProxy.com:8080"

Example_Easy_1()
Example_Easy_2()
Example_Easy_3()
Example_Easy_4()

; ============================================================================================================================
; Example Easy 1 - Get http header and content from google
; ============================================================================================================================
Func Example_Easy_1()
	; How to get html or header data?
	;   1. Set $CURLOPT_WRITEFUNCTION and $CURLOPT_HEADERFUNCTION to Curl_DataWriteCallback()
	;   2. Set $CURLOPT_WRITEDATA or $CURLOPT_HEADERDATA to any number as identify
    ;   3. Use Curl_Data_Get() to read the returned data in binary format
	;   4. Use Curl_Data_Cleanup() to remove the data

	ConsoleWrite("Example Easy 1" & @LF)

	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	Local $Html = $Curl ; any number as identify
	Local $Header = $Curl + 1 ; any number as identify

	Curl_Easy_Setopt($Curl, $CURLOPT_URL, "https://www.google.com")
	Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, "AutoIt/Curl")
	Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_ACCEPT_ENCODING, "gzip") ; or set "" use all built-in supported encodings
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Html)
	Curl_Easy_Setopt($Curl, $CURLOPT_HEADERFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_HEADERDATA, $Header)
	Curl_Easy_Setopt($Curl, $CURLOPT_COOKIE, "tool=curl; script=autoit; fun=yes;")
	Curl_Easy_Setopt($Curl, $CURLOPT_TIMEOUT, 30)
	Curl_Easy_Setopt($Curl, $CURLOPT_SSL_VERIFYPEER, 0)

	Local $Code = Curl_Easy_Perform($Curl)
	If $Code = $CURLE_OK Then
		ConsoleWrite("Content Type: " & Curl_Easy_GetInfo($Curl, $CURLINFO_CONTENT_TYPE) & @LF)
		ConsoleWrite("Download Size: " & Curl_Easy_GetInfo($Curl, $CURLINFO_SIZE_DOWNLOAD) & @LF)

		MsgBox(0, 'Header', BinaryToString(Curl_Data_Get($Header)))
		MsgBox(0, 'Html', BinaryToString(Curl_Data_Get($Html)))
	Else
		ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
	EndIf

	Curl_Easy_Cleanup($Curl)
	Curl_Data_Cleanup($Header)
	Curl_Data_Cleanup($Html)

	ConsoleWrite(@LF)
EndFunc

; ============================================================================================================================
; Example Easy 2 - Advanced setting test
; ============================================================================================================================
Func Example_Easy_2()
	; How to write html data into file?
	;   1. Set $CURLOPT_WRITEFUNCTION to Curl_FileWriteCallback()
	;   2. Set $CURLOPT_WRITEDATA to file handle returned from FileOpen()
	;   3. Don't forget to close it by FileClose()

	ConsoleWrite("Example Easy 2" & @LF)

	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	Local $CookieFile = "cookie.txt"
	Local $HtmlFile = "google.html"
	Local $File = FileOpen($HtmlFile, 2 + 16)

	Local $Slist = Curl_Slist_Append(0, "Shoesize: 10")
	$Slist = Curl_Slist_Append($Slist, "Accept: text/html;")

	; You can combine it into one line (set $AutoSplit = True)
	; Local $Slist = Curl_Slist_Append(0, "Shoesize: 10" & @LF & "Accept: text/html;", True)

	Curl_Easy_Setopt($Curl, $CURLOPT_URL, "http://www.google.com")
	Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, "AutoIt/Curl")
	Curl_Easy_Setopt($Curl, $CURLOPT_ACCEPT_ENCODING, "")
	Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_FileWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $File)
	Curl_Easy_Setopt($Curl, $CURLOPT_COOKIEJAR, $CookieFile)
	Curl_Easy_Setopt($Curl, $CURLOPT_COOKIEFILE, $CookieFile)
	Curl_Easy_Setopt($Curl, $CURLOPT_HTTPHEADER, $Slist)

	Local $Code = Curl_Easy_Perform($Curl)

	Curl_Slist_Free_All($Slist)
	Curl_Easy_Cleanup($Curl)
	FileClose($File)

	If $Code = $CURLE_OK Then
		MsgBox(0, 'Cookie', FileRead($CookieFile))
		MsgBox(0, 'Html', FileRead($HtmlFile))
	Else
		ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
	EndIf

	FileDelete($CookieFile)
	FileDelete($HtmlFile)

	ConsoleWrite(@LF)
EndFunc

; ============================================================================================================================
; Example Easy 3 - Proxy test, set your own proxy server to $ProxySever before this test
; ============================================================================================================================
Func Example_Easy_3()
	ConsoleWrite("Example Easy 3" & @LF)

	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	Curl_Easy_Setopt($Curl, $CURLOPT_URL, "http://www.ip-adress.com")
	Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, "AutoIt/Curl")
	Curl_Easy_Setopt($Curl, $CURLOPT_ACCEPT_ENCODING, "")
	Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)

	Local $Code = Curl_Easy_Perform($Curl)
	If $Code = $CURLE_OK Then
		Local $Html = BinaryToString(Curl_Data_Get($Curl))
		Local $Match = StringRegExp($Html, "IP address is: (\d+\.\d+\.\d+\.\d+)", 3)
		If IsArray($Match) Then ConsoleWrite("IP address without proxy: " & $Match[0] & @LF)
	Else
		ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
	EndIf

	Curl_Easy_Cleanup($Curl)
	Curl_Data_Cleanup($Curl)

	If Not $ProxySever Then Return

	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	Curl_Easy_Setopt($Curl, $CURLOPT_URL, "http://www.ip-adress.com")
	Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, "AutoIt/Curl")
	Curl_Easy_Setopt($Curl, $CURLOPT_ACCEPT_ENCODING, "")
	Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_PROXY, $ProxySever)
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)

	Local $Code = Curl_Easy_Perform($Curl)
	If $Code = $CURLE_OK Then
		Local $Html = BinaryToString(Curl_Data_Get($Curl))
		Local $Match = StringRegExp($Html, "IP address is: (\d+\.\d+\.\d+\.\d+)", 3)
		If IsArray($Match) Then ConsoleWrite("IP address with proxy: " & $Match[0] & @LF)
	Else
		ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
	EndIf

	Curl_Easy_Cleanup($Curl)
	Curl_Data_Cleanup($Curl)

	ConsoleWrite(@LF)
EndFunc

; ============================================================================================================================
; Example Easy 4 - Show downloading progress
; ============================================================================================================================
Func Example_Easy_4()
	ConsoleWrite("Example Easy 4" & @LF)

	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	Local $ProgressCallback = DllCallbackGetPtr(DllCallbackRegister("ShowProgress", "int:cdecl", "ptr;uint64;uint64;uint64;uint64"))

	Curl_Easy_Setopt($Curl, $CURLOPT_URL, "http://www.google.com")
	Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, "AutoIt/Curl")
	Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_NOPROGRESS, 0)
	Curl_Easy_Setopt($Curl, $CURLOPT_XFERINFOFUNCTION, $ProgressCallback)

	Local $Code = Curl_Easy_Perform($Curl)
	If $Code <> $CURLE_OK Then ConsoleWrite(Curl_Easy_StrError($Code) & @LF)

	Curl_Data_Cleanup($Curl)
	Curl_Easy_Cleanup($Curl)

	ConsoleWrite(@LF)
EndFunc

Func ShowProgress($Ptr, $dltotal, $dlnow, $ultotal, $ulnow)
	ConsoleWrite($dltotal & @TAB)
	ConsoleWrite($dlnow & @TAB)
	ConsoleWrite($ultotal & @TAB)
	ConsoleWrite($ulnow & @LF)
	If $dlnow > 1024  Then
		ConsoleWrite("Stop download..." & @LF)
		Return 1
	EndIf
	Return 0
EndFunc
