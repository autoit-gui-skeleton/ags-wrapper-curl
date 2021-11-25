; ============================================================================================================================
; File		: Curl_Example_Easy.au3 (2015.06.04)
; Purpose	: Demonstrate the easy interface for curl.au3
; Author	: Ward
; Dependency: Curl.au3
; ============================================================================================================================

#Include "../Curl.au3"

Example_Easy_1()

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
	Curl_Easy_Setopt($Curl, $CURLOPT_HTTPPROXYTUNNEL, false)
	Curl_Easy_Setopt($Curl, $CURLOPT_PROXY, '');

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