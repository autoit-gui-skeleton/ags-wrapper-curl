#Include "Curl.au3"


	ConsoleWrite("Example Post 1" & @CRLF)
	ConsoleWrite("Paste data to pastebin.com..." & @LF)

	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Exit

	Curl_Easy_Setopt($Curl, $CURLOPT_URL, "http://pastebin.com")
	Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, "AutoIt/Curl")
	Curl_Easy_Setopt($Curl, $CURLOPT_ACCEPT_ENCODING, "")
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)

	Local $Code = Curl_Easy_Perform($Curl)
	If $Code <> $CURLE_OK Then Exit ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
	Local $Data = BinaryToString(Curl_Data_Get($Curl))
	Curl_Easy_Cleanup($Curl)
	Curl_Data_Cleanup($Curl)

	Local $Match = StringRegExp($Data, '(?U)<input name="post_key" value="(.*)" type="hidden" />', 3)
	If @Error Then Exit
	Local $PostKey = $Match[0]

	Local $PasteCode = "This is a test for AutoIt Curl UDF."
	Local $Post = 'post_key=' & $PostKey & '&submit_hidden=submit_hidden&paste_code=' & Curl_Escape($PasteCode) & '&paste_format=1&paste_expire_date=1H&paste_private=0&paste_name='

	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Exit

	Curl_Easy_Setopt($Curl, $CURLOPT_URL, "http://pastebin.com/post.php")
	Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, "AutoIt/Curl")
	Curl_Easy_Setopt($Curl, $CURLOPT_ACCEPT_ENCODING, "")
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_POST, 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_COPYPOSTFIELDS, $Post)

	Local $Code = Curl_Easy_Perform($Curl)
	If $Code <> $CURLE_OK Then Exit ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
	Local $Data = BinaryToString(Curl_Data_Get($Curl))
	Local $EffectiveUrl = Curl_Easy_GetInfo($Curl, $CURLINFO_EFFECTIVE_URL)
	Curl_Easy_Cleanup($Curl)
	Curl_Data_Cleanup($Curl)

	ConsoleWrite("Paste link: " & $EffectiveUrl & @LF)
	Local $Match = StringRegExp($Data, "(?U)(?s)<textarea[^>]*>(.*)</textarea>", 3)
	If @Error Then Exit
	ConsoleWrite("RAW Paste Data: " & $Match[0] & @LF)
	ConsoleWrite(@LF)
