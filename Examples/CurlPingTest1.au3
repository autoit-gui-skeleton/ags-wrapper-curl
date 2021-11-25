#Include 'Curl.au3'

;~     CURLOPT_RETURNTRANSFER => true,      // return web page
;~             CURLOPT_HEADER         => false,     // do not return headers
;~             CURLOPT_FOLLOWLOCATION => true,      // follow redirects
;~             CURLOPT_USERAGENT      => $useragent, // who am i
;~             CURLOPT_AUTOREFERER    => true,       // set referer on redirect
;~             CURLOPT_CONNECTTIMEOUT => 2,          // timeout on connect (in seconds)
;~             CURLOPT_TIMEOUT        => 2,          // timeout on response (in seconds)
;~             CURLOPT_MAXREDIRS      => 10,         // stop after 10 redirects
;~             CURLOPT_SSL_VERIFYPEER => false,     // SSL verification not required
;~             CURLOPT_SSL_VERIFYHOST => false,     // SSL verification not required

;~ Local $UrlList[] = ['http://www.google.com', 'http://www.yahoo.com', 'http://www.wikipedia.org', 'http://taiwan.net.tw']
Local $UrlList[] = ['HTTP://192.168.0.200', 'HTTP://192.168.0.248', 'HTTP://192.168.0.229', 'HTTP://192.168.0.254']
Local $Multi = Curl_Multi_Init()
If Not $Multi Then Exit
Local $Curl
For $i = 0 To UBound($UrlList) - 1
	$Curl = Curl_Easy_Init()
	ConsoleWrite ( '!->-- [' & StringFormat ( '%03i', @ScriptLineNumber ) & '] $Curl : ' & $Curl & @Crlf )
	If Not $Curl Then ContinueLoop
	Curl_Easy_Setopt($Curl, $CURLOPT_URL, $UrlList[$i] & ':80/ping' ) ; curl -v http://127.0.0.1:8098/ping
	Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, 'AutoIt/Curl')
	Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_ACCEPT_ENCODING, '')
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_VERBOSE, $Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_SSL_VERIFYPEER, 0)

;~  // make sure you only check the header - taken from the answer above
;~ 	Curl_Easy_Setopt ( $Curl, $CURLOPT_NOBODY, True )
;~  // max number of seconds to allow cURL function to execute
	Curl_Easy_Setopt ( $Curl, $CURLOPT_TIMEOUT, 5 )
;~  // timeout on connect (in seconds)
	Curl_Easy_Setopt ( $Curl, $CURLOPT_CONNECTTIMEOUT, 5 )

;~ 	Curl_Easy_Setopt($Curl, $CURLOPT_POST, 1)
;~ 	Curl_Easy_Setopt($Curl, $CURLOPT_COPYPOSTFIELDS, 'ping' )

	Curl_Multi_Add_Handle($Multi, $Curl)
Next
Local $Running, $MsgsInQueue, $CURLMsg, $Curl, $Code, $Url, $DownloadSize, $TotalTime, $Data

Do
	Curl_Multi_Perform($Multi, $Running)
	$CURLMsg = Curl_Multi_Info_Read($Multi, $MsgsInQueue)
	If DllStructGetData($CURLMsg, 'msg') = $CURLMSG_DONE Then
		$Curl = DllStructGetData($CURLMsg, 'easy_handle')
		$Code = DllStructGetData($CURLMsg, 'data')
		$Url = Curl_Easy_GetInfo($Curl, $CURLINFO_EFFECTIVE_URL)
		$DownloadSize = Curl_Easy_GetInfo($Curl, $CURLINFO_SIZE_DOWNLOAD)
		$TotalTime = Curl_Easy_GetInfo($Curl, $CURLINFO_TOTAL_TIME)
		$Data = Curl_Data_Get($Curl)
		ConsoleWrite ( $Url & ' spent ' & $TotalTime & ' secs, download size: ' & $DownloadSize & ', data size: ' & BinaryLen($Data) & @CRLF)
		If $Code <> $CURLE_OK Then ConsoleWrite(' (' & Curl_Easy_StrError($Code) & ')' & @CRLF )

		Curl_Multi_Remove_Handle($Multi, $Curl)
		Curl_Easy_Cleanup($Curl)
		Curl_Data_Cleanup($Curl)
	EndIf
	Sleep(10)
Until $Running = 0

Curl_Multi_Cleanup($Multi)