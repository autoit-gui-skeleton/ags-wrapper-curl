; ============================================================================================================================
; File		: Curl_Example_Multi.au3 (2015.06.04)
; Purpose	: Demonstrate the multi interface for curl.au3
; Author	: Ward
; Dependency: Curl.au3
; ============================================================================================================================

#Region    ;************ Includes ************
#Include <Array.au3>
#Include 'Curl.au3'
#EndRegion ;************ Includes ************

Global $aRunning_3[1], $ahCurls_3[1], $ahFiles[1], $asFilePaths[1], $ahProgress_3[1], $aIndex_1[1], $aFirstBytes[1], $iBufferSize = 128
Global $Multi, $Running, $MsgsInQueue, $CURLMsg, $Code, $Curl
$Ret = _CurlGetFirstBytes ( 'http://www.google.com' )
ConsoleWrite ( '!->-- [' & StringFormat ( '%03i', @ScriptLineNumber ) & '] $Ret : ' & $Ret & @Crlf )

While 1
	For $i = UBound ( $aRunning_3 ) -1 To 1 Step -1
;~ 		ConsoleWrite ( '!->-- [' & StringFormat ( '%03i', @ScriptLineNumber ) & '] $ahCurls_3[' & $i & '] : ' & $ahCurls_3[$i] & @Crlf )
		If $aRunning_3[$i] Then
			Curl_Multi_Perform ( $Multi, $aRunning_3[$i] )
			$CURLMsg = Curl_Multi_Info_Read ( $Multi, $MsgsInQueue )
			$Curl = DllStructGetData ( $CURLMsg, 'easy_handle' )
			ConsoleWrite ( '>->-- [' & StringFormat ( '%03i', @ScriptLineNumber ) & '] $Curl : ' & $Curl & @Crlf )
;~ 			ConsoleWrite ( '+->-- [' & StringFormat ( '%03i', @ScriptLineNumber ) & '] $ahCurls_3[' & $i & '] : ' & $ahCurls_3[$i] & @Crlf )
			$iIndex = _ArraySearch ( $ahCurls_3, $Curl, 1, 0, 0, 2 ) ; 2 comparison match if variables have same type and same value
			ConsoleWrite ( '!->-- [' & StringFormat ( '%03i', @ScriptLineNumber ) & '] $iIndex : ' & $iIndex & @Crlf )


			Local $Code = DllStructGetData($CURLMsg, 'data')
			If $iIndex <> -1 And $Code = $CURLE_OK Then

				ConsoleWrite ( 'Content Type : ' & Curl_Easy_GetInfo ( $ahCurls_3[$iIndex], $CURLINFO_CONTENT_TYPE ) & @LF )
				ConsoleWrite ( 'Download Size : ' & Curl_Easy_GetInfo ( $ahCurls_3[$iIndex], $CURLINFO_SIZE_DOWNLOAD ) & @LF )
				ConsoleWrite ( '+ Binary : ' &  Curl_Data_Get ( $ahCurls_3[$iIndex] ) & @Crlf )
				ConsoleWrite ( '> String : ' & BinaryToString ( Curl_Data_Get ( $ahCurls_3[$iIndex] ) ) & @Crlf )
				$aRunning_3[$iIndex] = 0
				Curl_Multi_Remove_Handle ( $Multi, $ahCurls_3[$iIndex] )
				Curl_Easy_Cleanup ( $ahCurls_3[$iIndex] )
				Curl_Data_Cleanup ( $ahCurls_3[$iIndex] )
				Curl_Data_Cleanup ( $ahCurls_3[$iIndex] + 1 )
				$ahCurls_3[$iIndex] = 0
				_ArrayDelete ( $aRunning_3, $iIndex )
				_ArrayDelete ( $ahCurls_3, $iIndex )
				DllCallbackFree ( $ahProgress_3[$iIndex] )
				_ArrayDelete ( $ahProgress_3, $iIndex )
;~              _ArrayDelete ( $aIndex_3, $iIndexIndex )
				ExitLoop 2
			EndIf
		EndIf
	Next
	Sleep(10)
WEnd

Curl_Multi_Cleanup ( $Multi )
Exit

Func _CurlGetFirstBytes ( $sUrl )
	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return
	ConsoleWrite ( '!->-- [' & StringFormat ( '%03i', @ScriptLineNumber ) & '] $Curl : ' & $Curl & @Crlf )
	Curl_Easy_Setopt($Curl, $CURLOPT_URL, $sUrl )
	Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, 'Mozilla')
	Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_ACCEPT_ENCODING, '')

	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_HEADERFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_HEADERDATA, $Curl + 1)

	Curl_Easy_Setopt ( $Curl, $CURLOPT_BUFFERSIZE, $iBufferSize ) ; Set buffer size. ($CURL_MAX_WRITE_SIZE = 16384)
;~ 	Curl_Easy_Setopt ( $Curl, $CURLOPT_NOPROGRESS, False )
;~ 	Local $hProgress = DllCallbackRegister ( '_FirstBytesProgress', 'uint:cdecl', 'int;double;double;double;double' )
;~ 	Curl_Easy_Setopt ( $Curl, $CURLOPT_PROGRESSFUNCTION, DllCallbackGetPtr ( $hProgress ) )
;~ 	Curl_Easy_Setopt ( $Curl, $CURLOPT_PROGRESSDATA, $hProgress ) ; set dlIdx instead of clientp.
	Curl_Easy_Setopt ( $Curl, $CURLOPT_RANGE, '0-' & $iBufferSize -1 ) ; get the first n bytes. (Content-Range: bytes 0-63/210158 )
	; limit downlod speed
;~  Local $Curl_Max_Speed = 1000*25 ; 25 kB/s
;~  Curl_Easy_Setopt ( $Curl, $CURLOPT_MAX_RECV_SPEED_LARGE, $Curl_Max_Speed )

	_ArrayAdd ( $ahCurls_3, $Curl )
;~ 	_ArrayAdd ( $ahProgress_3, $hProgress )
;~ 	_ArrayAdd ( $aFirstBytes, $hProgress )
	_ArrayAdd ( $aRunning_3, 1 )
	$Multi = Curl_Multi_Init()
	If Not $Multi Then Return
	Curl_Multi_Add_Handle ( $Multi, $Curl )

	Return $Multi
EndFunc ;

Func _FirstBytesProgress ( $dlIdx, $Dltotal, $Dlnow, $Ultotal, $Ulnow )
	#forceref $dlIdx, $Dltotal, $Dlnow, $Ultotal, $Ulnow
;~  int function(int dlIdx double dltotal double dlnow double ultotal double ulnow)
	Local $fProgress = Round ( 100*$dlnow / $dltotal, 0 )
	If IsInt ( $fProgress ) Then
		For $i = 1 To UBound ( $ahProgress_3 ) -1
			If $dlIdx = $ahProgress_3[$i] Then
;~              _GUICtrlListView_AddSubItem ( $hListView, $aIndex_1[$i], $fProgress, 3 )
				ConsoleWrite ( '-->-- [' & StringFormat ( '%03i', @ScriptLineNumber ) & '][' & @HOUR & @MIN & @SEC & @MSEC & '] $i : ' & $i& ' $Dlnow : ' & $Dlnow & @Crlf )
				Return
			EndIf
		Next
	EndIf
EndFunc ;==> _FirstBytesProgress()

; ============================================================================================================================
; Example Multi 2 - Download diferent websites simultaneously
; ============================================================================================================================
Func Example_Multi_2()
	ConsoleWrite ( 'Example Multi 2' & @LF )

	Local $UrlList[] = ['http://www.google.com', 'http://www.yahoo.com', 'http://www.wikipedia.org', 'http://taiwan.net.tw']
	Local $Multi = Curl_Multi_Init()
	If Not $Multi Then Return

	For $i = 0 To UBound ( $UrlList ) - 1
		Local $Curl = Curl_Easy_Init()
		If Not $Curl Then ContinueLoop

		Curl_Easy_Setopt ( $Curl, $CURLOPT_URL, $UrlList[$i] )
		Curl_Easy_Setopt ( $Curl, $CURLOPT_USERAGENT, 'AutoIt/Curl' )
		Curl_Easy_Setopt ( $Curl, $CURLOPT_FOLLOWLOCATION, 1 )
		Curl_Easy_Setopt ( $Curl, $CURLOPT_ACCEPT_ENCODING, '' )

		Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
		Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)
		Curl_Easy_Setopt($Curl, $CURLOPT_SSL_VERIFYPEER, 0)

		Curl_Multi_Add_Handle($Multi, $Curl)
	Next

	Local $Running, $MsgsInQueue
	Do
		Curl_Multi_Perform($Multi, $Running)
		Local $CURLMsg = Curl_Multi_Info_Read($Multi, $MsgsInQueue)
		If DllStructGetData($CURLMsg, 'msg') = $CURLMSG_DONE Then
			Local $Curl = DllStructGetData($CURLMsg, 'easy_handle')
			Local $Code = DllStructGetData($CURLMsg, 'data')

			Local $Url = Curl_Easy_GetInfo($Curl, $CURLINFO_EFFECTIVE_URL)
			Local $DownloadSize = Curl_Easy_GetInfo($Curl, $CURLINFO_SIZE_DOWNLOAD)
			Local $TotalTime = Curl_Easy_GetInfo($Curl, $CURLINFO_TOTAL_TIME)
			Local $Data = Curl_Data_Get($Curl)
			ConsoleWrite(''' & $Url & '' spent ' & $TotalTime & ' secs, download size: ' & $DownloadSize & ', data size: ' & BinaryLen($Data))

			If $Code <> $CURLE_OK Then ConsoleWrite(' (' & Curl_Easy_StrError($Code) & ')')
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