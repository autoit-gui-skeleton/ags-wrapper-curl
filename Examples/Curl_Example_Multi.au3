; ============================================================================================================================
; File		: Curl_Example_Multi.au3 (2015.06.04)
; Purpose	: Demonstrate the multi interface for curl.au3
; Author	: Ward
; Dependency: Curl.au3
; ============================================================================================================================

#Include "../Curl.au3"

Example_Multi_1()
Example_Multi_2()

; ============================================================================================================================
; Example Multi 1 - Download file with non-GUI-blocking technique
; ============================================================================================================================
Func Example_Multi_1()
	ConsoleWrite("Example Multi 1" & @LF)

	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	Curl_Easy_Setopt($Curl, $CURLOPT_URL, "http://www.google.com")
	Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, "AutoIt/Curl")
	Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_ACCEPT_ENCODING, "")

	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_HEADERFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_HEADERDATA, $Curl + 1)

	Local $Multi = Curl_Multi_Init()
	If Not $Multi Then Return
	Curl_Multi_Add_Handle($Multi, $Curl)

	Local $Running, $MsgsInQueue
	Do
		Curl_Multi_Perform($Multi, $Running)
		Local $CURLMsg = Curl_Multi_Info_Read($Multi, $MsgsInQueue)
		If DllStructGetData($CURLMsg, "msg") = $CURLMSG_DONE Then
			Local $Curl = DllStructGetData($CURLMsg, "easy_handle")
			Local $Code = DllStructGetData($CURLMsg, "data")
			If $Code = $CURLE_OK Then
				ConsoleWrite("Content Type: " & Curl_Easy_GetInfo($Curl, $CURLINFO_CONTENT_TYPE) & @LF)
				ConsoleWrite("Download Size: " & Curl_Easy_GetInfo($Curl, $CURLINFO_SIZE_DOWNLOAD) & @LF)

				MsgBox(0, 'Header', BinaryToString(Curl_Data_Get($Curl + 1)))
				MsgBox(0, 'Html', BinaryToString(Curl_Data_Get($Curl)))
			Else
				ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
			EndIf
			Curl_Multi_Remove_Handle($Multi, $Curl)
			Curl_Easy_Cleanup($Curl)
			Curl_Data_Cleanup($Curl)
			Curl_Data_Cleanup($Curl + 1)
		EndIf
		ConsoleWrite("non-GUI-blocking" & @LF)
		Sleep(10)
	Until $Running = 0
	Curl_Multi_Cleanup($Multi)
	ConsoleWrite(@LF)
EndFunc

; ============================================================================================================================
; Example Multi 2 - Download diferent websites simultaneously
; ============================================================================================================================
Func Example_Multi_2()
	ConsoleWrite("Example Multi 2" & @LF)

	Local $UrlList[] = ["http://www.google.com", "http://www.yahoo.com", "http://www.wikipedia.org", "http://taiwan.net.tw"]
	Local $Multi = Curl_Multi_Init()
	If Not $Multi Then Return

	For $i = 0 To UBound($UrlList) - 1
		Local $Curl = Curl_Easy_Init()
		If Not $Curl Then ContinueLoop

		Curl_Easy_Setopt($Curl, $CURLOPT_URL, $UrlList[$i])
		Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, "AutoIt/Curl")
		Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)
		Curl_Easy_Setopt($Curl, $CURLOPT_ACCEPT_ENCODING, "")

		Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
		Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)
		Curl_Easy_Setopt($Curl, $CURLOPT_SSL_VERIFYPEER, 0)

		Curl_Multi_Add_Handle($Multi, $Curl)
	Next

	Local $Running, $MsgsInQueue
	Do
		Curl_Multi_Perform($Multi, $Running)
		Local $CURLMsg = Curl_Multi_Info_Read($Multi, $MsgsInQueue)
		If DllStructGetData($CURLMsg, "msg") = $CURLMSG_DONE Then
			Local $Curl = DllStructGetData($CURLMsg, "easy_handle")
			Local $Code = DllStructGetData($CURLMsg, "data")

			Local $Url = Curl_Easy_GetInfo($Curl, $CURLINFO_EFFECTIVE_URL)
			Local $DownloadSize = Curl_Easy_GetInfo($Curl, $CURLINFO_SIZE_DOWNLOAD)
			Local $TotalTime = Curl_Easy_GetInfo($Curl, $CURLINFO_TOTAL_TIME)
			Local $Data = Curl_Data_Get($Curl)
			ConsoleWrite('"' & $Url & '" spent ' & $TotalTime & ' secs, download size: ' & $DownloadSize & ", data size: " & BinaryLen($Data))

			If $Code <> $CURLE_OK Then ConsoleWrite(" (" & Curl_Easy_StrError($Code) & ")")
			ConsoleWrite(@LF)

			Curl_Multi_Remove_Handle($Multi, $Curl)
			Curl_Easy_Cleanup($Curl)
			Curl_Data_Cleanup($Curl)
		EndIf
		Sleep(10)
	Until $Running = 0
	Curl_Multi_Cleanup($Multi)
	ConsoleWrite(@LF)
EndFunc
