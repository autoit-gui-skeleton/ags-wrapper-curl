#Include 'Curl.au3'

Global $Curl, $iBufferSize, $Multi, $Running, $MsgsInQueue, $Code, $CURLMsg

$Curl = Curl_Easy_Init()
If Not $Curl Then Exit
$iBufferSize = 128
Curl_Easy_Setopt($Curl, $CURLOPT_URL, 'http://blogs.perl.org/users/kirk_kimmel/2012/08/q-when-not-to-use-regexp-a-html-parsing.html' ) ;'http://abload.de/img/20151105221326ttqd3.jpg' ) ; 'http://www.google.com')
;~  Curl_Easy_Setopt($Curl, $CURLOPT_URL, 'http://abload.de/img/20151105221326ttqd3.jpg' ) ; 'http://www.google.com')
;~  Curl_Easy_Setopt($Curl, $CURLOPT_URL, 'http://www.google.com')
Curl_Easy_Setopt ( $Curl, $CURLOPT_USERAGENT, 'AutoIt/Curl')
Curl_Easy_Setopt ( $Curl, $CURLOPT_FOLLOWLOCATION, 1 )
;~ An empty string creates an Accept-Encoding header containing all supported encodings.
Curl_Easy_Setopt ( $Curl, $CURLOPT_ACCEPT_ENCODING, '' ) ; 'identity', 'deflate' or 'gzip'
Curl_Easy_Setopt ( $Curl, $CURLOPT_BUFFERSIZE, $iBufferSize )
Curl_Easy_Setopt ( $Curl, $CURLOPT_RANGE, '0-' & $iBufferSize -1 ) ; get the first n bytes. (Content-Range: bytes 0-63/nTotal )
Curl_Easy_Setopt ( $Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback() )
Curl_Easy_Setopt ( $Curl, $CURLOPT_WRITEDATA, $Curl)
Curl_Easy_Setopt ( $Curl, $CURLOPT_HEADERFUNCTION, Curl_DataWriteCallback() )
Curl_Easy_Setopt ( $Curl, $CURLOPT_HEADERDATA, $Curl + 1 )
$Multi = Curl_Multi_Init()
If Not $Multi Then Exit
Curl_Multi_Add_Handle ( $Multi, $Curl )

Do
	Curl_Multi_Perform ( $Multi, $Running )
	$CURLMsg = Curl_Multi_Info_Read ( $Multi, $MsgsInQueue )
	If DllStructGetData ( $CURLMsg, 'msg' ) = $CURLMSG_DONE Then
		$Curl = DllStructGetData ( $CURLMsg, 'easy_handle' )
		$Code = DllStructGetData ( $CURLMsg, 'data' )
		If $Code = $CURLE_OK Then
			ConsoleWrite ( 'Content Type: ' & Curl_Easy_GetInfo ( $Curl, $CURLINFO_CONTENT_TYPE ) & @CRLF )
			ConsoleWrite ( 'Download Size: ' & Curl_Easy_GetInfo ( $Curl, $CURLINFO_SIZE_DOWNLOAD ) & @CRLF )
			ConsoleWrite ( '- Header : ' & BinaryToString ( Curl_Data_Get ( $Curl + 1 ) ) & @Crlf )
			ConsoleWrite ( '+ Html String : ' & BinaryToString ( Curl_Data_Get ( $Curl ) ) & @Crlf )
			ConsoleWrite ( @CRLF )
			ConsoleWrite ( '> Html Binary : ' & Curl_Data_Get ( $Curl ) & @Crlf )
		Else
			ConsoleWrite ( '! Curl_Easy_StrError : ' & Curl_Easy_StrError ( $Code ) & @CRLF )
		EndIf
		Curl_Multi_Remove_Handle ( $Multi, $Curl )
		Curl_Easy_Cleanup ( $Curl )
		Curl_Data_Cleanup ( $Curl )
		Curl_Data_Cleanup ( $Curl + 1 )
	EndIf
	Sleep ( 10 )
Until $Running = 0
Curl_Multi_Cleanup ( $Multi )
Exit