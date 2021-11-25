; ============================================================================================================================
; File		: Curl_Example_Post.au3 (2015.06.04)
; Purpose	: Demonstrate multipart/formdata HTTP POST
; Author	: Ward
; Dependency: Curl.au3
; ============================================================================================================================

#Include "Curl.au3"

Example_Post_1()
Example_Post_2()

; ============================================================================================================================
; Example Post 1 - Paste and get text from pastebin.com
; ============================================================================================================================
Func Example_Post_1()
	ConsoleWrite("Example Post 1" & @CRLF)
	ConsoleWrite("Paste data to pastebin.com..." & @LF)

	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	Curl_Easy_Setopt($Curl, $CURLOPT_URL, "http://pastebin.com")
	Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, "AutoIt/Curl")
	Curl_Easy_Setopt($Curl, $CURLOPT_ACCEPT_ENCODING, "")
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)

	Local $Code = Curl_Easy_Perform($Curl)
	If $Code <> $CURLE_OK Then Return ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
	Local $Data = BinaryToString(Curl_Data_Get($Curl))
	Curl_Easy_Cleanup($Curl)
	Curl_Data_Cleanup($Curl)

	Local $Match = StringRegExp($Data, '(?U)<input name="post_key" value="(.*)" type="hidden" />', 3)
	If @Error Then Return
	Local $PostKey = $Match[0]

	Local $PasteCode = "This is a test for AutoIt Curl UDF."
	Local $Post = 'post_key=' & $PostKey & '&submit_hidden=submit_hidden&paste_code=' & Curl_Escape($PasteCode) & '&paste_format=1&paste_expire_date=1H&paste_private=0&paste_name='

	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	Curl_Easy_Setopt($Curl, $CURLOPT_URL, "http://pastebin.com/post.php")
	Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, "AutoIt/Curl")
	Curl_Easy_Setopt($Curl, $CURLOPT_ACCEPT_ENCODING, "")
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_POST, 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_COPYPOSTFIELDS, $Post)

	Local $Code = Curl_Easy_Perform($Curl)
	If $Code <> $CURLE_OK Then Return ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
	Local $Data = BinaryToString(Curl_Data_Get($Curl))
	Local $EffectiveUrl = Curl_Easy_GetInfo($Curl, $CURLINFO_EFFECTIVE_URL)
	Curl_Easy_Cleanup($Curl)
	Curl_Data_Cleanup($Curl)

	ConsoleWrite("Paste link: " & $EffectiveUrl & @LF)
	Local $Match = StringRegExp($Data, "(?U)(?s)<textarea[^>]*>(.*)</textarea>", 3)
	If @Error Then Return
	ConsoleWrite("RAW Paste Data: " & $Match[0] & @LF)
	ConsoleWrite(@LF)
EndFunc

; ============================================================================================================================
; Example Post 2 - Upolad a file to ZippyShare.com
; ============================================================================================================================
Func Example_Post_2()
	ConsoleWrite("Example Post 2" & @CRLF)

	Local $Filename = FileOpenDialog("Please Select A File To Upload To ZippyShare.com", @ScriptDir, "All (*.*)", 3)
	If Not FileExists($Filename) Then Return

	ConsoleWrite("Uploading " & $Filename & " ..." & @CRLF)
	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	Curl_Easy_Setopt($Curl, $CURLOPT_URL, "http://www.zippyshare.com")
	Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, "AutoIt/Curl")
	Curl_Easy_Setopt($Curl, $CURLOPT_ACCEPT_ENCODING, "")
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)

	Local $Code = Curl_Easy_Perform($Curl)
	If $Code <> $CURLE_OK Then Return ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
	Local $Data = BinaryToString(Curl_Data_Get($Curl))
	Curl_Easy_Cleanup($Curl)
	Curl_Data_Cleanup($Curl)

	Local $Match = StringRegExp($Data, "var server = '(www\d+)';", 3)
	If @Error Then Return
	Local $WWW = $Match[0]

	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	Local $HttpPost, $LastItem
	Curl_FormAdd($HttpPost, $LastItem, $CURLFORM_COPYNAME, "name", $CURLFORM_COPYCONTENTS, "name", $CURLFORM_END)
	Curl_FormAdd($HttpPost, $LastItem, $CURLFORM_COPYNAME, "notprivate", $CURLFORM_COPYCONTENTS, "true", $CURLFORM_END)
	Curl_FormAdd($HttpPost, $LastItem, $CURLFORM_COPYNAME, "zipname", $CURLFORM_COPYCONTENTS, "", $CURLFORM_END)
	Curl_FormAdd($HttpPost, $LastItem, $CURLFORM_COPYNAME, "ziphash", $CURLFORM_COPYCONTENTS, "", $CURLFORM_END)
	Curl_FormAdd($HttpPost, $LastItem, $CURLFORM_COPYNAME, "embPlayerValues", $CURLFORM_COPYCONTENTS, "false", $CURLFORM_END)
	Curl_FormAdd($HttpPost, $LastItem, $CURLFORM_COPYNAME, "file", $CURLFORM_FILE, $Filename, $CURLFORM_END)

	Curl_Easy_Setopt($Curl, $CURLOPT_URL, "http://" & $WWW & ".zippyshare.com/upload")
	Curl_Easy_Setopt($Curl, $CURLOPT_USERAGENT, "AutoIt/Curl")
	Curl_Easy_Setopt($Curl, $CURLOPT_ACCEPT_ENCODING, "")
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_HTTPPOST, $HttpPost)

	Local $Code = Curl_Easy_Perform($Curl)
	If $Code <> $CURLE_OK Then Return ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
	Local $Data = BinaryToString(Curl_Data_Get($Curl))
	Curl_Easy_Cleanup($Curl)
	Curl_Data_Cleanup($Curl)
	Curl_FormFree($HttpPost)

	Local $Match = StringRegExp($Data, '<a target="top" href="([^"]+)">', 3)
	If @Error Then Return

	ConsoleWrite("Download link: " & $Match[0] & @LF)
	ConsoleWrite(@LF)
EndFunc
