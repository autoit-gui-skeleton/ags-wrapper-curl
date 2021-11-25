; ============================================================================================================================
; File		: Curl_Example_Multi.au3 (2015.06.04)
; Purpose	: Demonstrate the multi interface for curl.au3
; Author	: Ward
; Dependency: Curl.au3
; ============================================================================================================================

#Region    ;************ Includes ************
#Include <Array.au3>
#Include "Curl.au3"
#EndRegion ;************ Includes ************
Global $aRunning_1[1], $ahCurls_1[1], $ahFiles[1], $asFilePaths[1], $ahProgress[1], $aIndex_1[1], $iBufferSize = 256

Example_Multi_2()

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

;~      Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
;~      Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)

		Curl_Easy_Setopt ( $Curl, $CURLOPT_NOPROGRESS, False )
		Local $hProgress = DllCallbackRegister ( '_FileDownloadProgress', 'uint:cdecl', 'int;double;double;double;double' )
		Curl_Easy_Setopt ( $Curl, $CURLOPT_PROGRESSFUNCTION, DllCallbackGetPtr ( $hProgress ) )
		Curl_Easy_Setopt ( $Curl, $CURLOPT_PROGRESSDATA, $hProgress ) ; set dlIdx instead of clientp.
		Curl_Easy_Setopt ( $Curl, $CURLOPT_WRITEFUNCTION, Curl_FileWriteCallback() )
		Curl_Easy_Setopt ( $Curl, $CURLOPT_WRITEDATA, $Curl )
		Curl_Easy_Setopt ( $Curl, $CURLOPT_HEADERFUNCTION, Curl_DataWriteCallback() )
		Curl_Easy_Setopt ( $Curl, $CURLOPT_HEADERDATA, $Curl + 1 )
		Curl_Easy_Setopt($Curl, $CURLOPT_SSL_VERIFYPEER, 0)

		Curl_Easy_Setopt ( $Curl, $CURLOPT_BUFFERSIZE, $iBufferSize ) ; Set buffer size. ($CURL_MAX_WRITE_SIZE = 16384)

		Curl_Multi_Add_Handle($Multi, $Curl)
		_ArrayAdd ( $ahCurls_1, $Curl )
		_ArrayAdd ( $ahProgress, $hProgress )
	Next

	Local $Running, $MsgsInQueue
	Do
		Curl_Multi_Perform($Multi, $Running)
		Local $CURLMsg = Curl_Multi_Info_Read($Multi, $MsgsInQueue)
		If DllStructGetData($CURLMsg, "msg") = $CURLMSG_DONE Then
			Local $Curl = DllStructGetData($CURLMsg, "easy_handle")
			Local $Code = DllStructGetData($CURLMsg, "data")

			$iIndex = _ArraySearch ( $ahCurls_1, $Curl, 1, 0, 0, 2 ) ; 2 comparison match if variables have same type and same value
			ConsoleWrite ( '!->-- [' & StringFormat ( '%03i', @ScriptLineNumber ) & '] $iIndex : ' & $iIndex & @Crlf )
			If $iIndex <> -1 Then
				Local $Url = Curl_Easy_GetInfo($Curl, $CURLINFO_EFFECTIVE_URL)
				Local $DownloadSize = Curl_Easy_GetInfo($Curl, $CURLINFO_SIZE_DOWNLOAD)
				Local $TotalTime = Curl_Easy_GetInfo($Curl, $CURLINFO_TOTAL_TIME)
				Local $Data = Curl_Data_Get($Curl)
				ConsoleWrite('"' & $Url & '" spent ' & $TotalTime & ' secs, download size: ' & $DownloadSize & ", data size: " & BinaryLen($Data))

				If $Code <> $CURLE_OK Then ConsoleWrite("Curl_Easy_StrError (" & Curl_Easy_StrError($Code) & ")")
				ConsoleWrite(@LF)

				Curl_Multi_Remove_Handle($Multi, $Curl)
				Curl_Easy_Cleanup($Curl)
				Curl_Data_Cleanup($Curl)
				$ahCurls_1[$iIndex] = 0

				_ArrayDelete ( $ahCurls_1, $iIndex )
				DllCallbackFree ( $ahProgress[$iIndex] )
				_ArrayDelete ( $ahProgress, $iIndex )
			EndIf
		EndIf
		Sleep(10)
	Until $Running = 0
	Curl_Multi_Cleanup($Multi)
	ConsoleWrite(@LF)
EndFunc

Func _FileDownloadProgress ( $dlIdx, $Dltotal, $Dlnow, $Ultotal, $Ulnow )
	#forceref $dlIdx, $Dltotal, $Dlnow, $Ultotal, $Ulnow
;~  int function(int dlIdx double dltotal double dlnow double ultotal double ulnow)
	Local $fProgress = Round ( 100*$dlnow / $dltotal, 0 )
	If IsInt ( $fProgress ) Then

		$fProgressOld = $fProgress
		For $i = 1 To UBound ( $ahProgress ) -1
			If $dlIdx = $ahProgress[$i] Then
;~              _GUICtrlListView_AddSubItem ( $hListView, $aIndex_1[$i], $fProgress, 3 )
				ConsoleWrite ( '-->-- [' & StringFormat ( '%03i', @ScriptLineNumber ) & '][' & @HOUR & @MIN & @SEC & @MSEC & '] $i : ' & $i& ' $Dlnow : ' & $Dlnow & @Crlf )
				Return
			EndIf
		Next
	EndIf
EndFunc ;==> _FileDownloadProgress()