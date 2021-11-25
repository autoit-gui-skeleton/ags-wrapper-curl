; ============================================================================================================================
; File		: Curl_Example_Basic.au3 (2015.06.04)
; Purpose	: Demonstrate the basic usage for Curl.au3
; Author	: Ward
; Dependency: Curl.au3
; ============================================================================================================================

#Include <Date.au3>
#Include "../Curl.au3"

Example_Basic_1()
Example_Basic_2()
Example_Basic_3()
Example_Basic_4()

; ============================================================================================================================
; Example Basic 1 - Get version info
; ============================================================================================================================
Func Example_Basic_1()
	ConsoleWrite("Example Basic 1" & @LF)
	ConsoleWrite("Curl Version: " & Curl_Version() & @LF & @LF)

	Local $Info = Curl_Version_Info()
	ConsoleWrite("Age: " & DllStructGetData($Info, 'age') & @LF)
	ConsoleWrite("Version: " & DllStructGetData($Info, 'version') & @LF)
	ConsoleWrite("Version Number: 0x" & Hex(DllStructGetData($Info, 'version_num'), 6) & @LF)
	ConsoleWrite("Host: " & DllStructGetData($Info, 'host') & @LF)
	ConsoleWrite("Features: " & DllStructGetData($Info, 'features') & @LF)
	ConsoleWrite("SSL Version: " & DllStructGetData($Info, 'ssl_version') & @LF)
	ConsoleWrite("Libz Version: " & DllStructGetData($Info, 'libz_version') & @LF)
	ConsoleWrite("Protocols: " & DllStructGetData($Info, 'protocols') & @LF)
	ConsoleWrite("libidn:" & DllStructGetData($Info, 'libidn') & @LF)
	ConsoleWrite("iconv_ver_num: " & DllStructGetData($Info, 'iconv_ver_num') & @LF)
	ConsoleWrite(@LF)
EndFunc

; ============================================================================================================================
; Example Basic 2 - Url escape and unescape, chr(0) is supported
; ============================================================================================================================
Func Example_Basic_2()
	ConsoleWrite("Example Basic 2" & @LF)
	Local $String = 'http://www.google.com' & Chr(0) & 'http://www.yahoo.com'
	Local $Encode = Curl_Easy_Escape(0, $String)
	ConsoleWrite("Curl_Easy_Escape " & $Encode & @LF)

	Local $Decode = Curl_Easy_Unescape(0, $Encode)
	ConsoleWrite("Curl_Easy_Unescape " & StringReplace($Decode, Chr(0), "\0") & @LF)
	ConsoleWrite(@LF)
EndFunc

; ============================================================================================================================
; Example Basic 3 - Error code to string
; ============================================================================================================================
Func Example_Basic_3()
	ConsoleWrite("Example Basic 3" & @LF)
	Local $ErrorCode = Curl_Easy_Perform(0)
	ConsoleWrite("Error Message: " & Curl_Easy_StrError($ErrorCode) & @LF)
	ConsoleWrite(@LF)
EndFunc

; ============================================================================================================================
; Example Basic 4 - GetDate
; ============================================================================================================================
Func Example_Basic_4()
	ConsoleWrite("Example Basic 4" & @LF)
	Local $Strings[22] = [ _
		"Sun, 06 Nov 1994 08:49:37 GMT", _
		"Sunday, 06-Nov-94 08:49:37 GMT", _
		"Sun Nov  6 08:49:37 1994", _
		"06 Nov 1994 08:49:37 GMT", _
		"06-Nov-94 08:49:37 GMT", _
		"Nov  6 08:49:37 1994", _
		"06 Nov 1994 08:49:37", _
		"06-Nov-94 08:49:37", _
		"1994 Nov 6 08:49:37", _
		"GMT 08:49:37 06-Nov-94 Sunday", _
		"94 6 Nov 08:49:37", _
		"1994 Nov 6", _
		"06-Nov-94", _
		"Sun Nov 6 94", _
		"1994.Nov.6", _
		"Sun/Nov/6/94/GMT", _
		"Sun, 06 Nov 1994 08:49:37 CET", _
		"06 Nov 1994 08:49:37 EST", _
		"Sun, 12 Sep 2004 15:05:58 -0700", _
		"Sat, 11 Sep 2004 21:32:11 +0200", _
		"20040912 15:05:58 -0700", _
		"20040911 +0200" ]

	For $i = 0 To UBound($Strings) - 1
		Local $Second = Curl_GetDate($Strings[$i])
		ConsoleWrite(_DateAdd("s", $Second, "1970/01/01 00:00:00") & " (" & $Strings[$i] & ")" & @LF)
	Next
	ConsoleWrite(@LF)
EndFunc
