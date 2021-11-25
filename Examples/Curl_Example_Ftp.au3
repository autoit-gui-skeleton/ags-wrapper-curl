; ============================================================================================================================
; File		: Curl_Example_Ftp.au3 (2015.06.04)
; Purpose	: Demonstrate FTP protocols
; Author	: Ward
; Dependency: Curl.au3
; ============================================================================================================================

#Include "Curl.au3"

; A test account at drivehq.com, please don't modify the password
Global $FTP_Server = "ftp.drivehq.com"
Global $FTP_Username = "g4678255"
Global $FTP_Password = "g4678255"
Global $FTP_Url = "ftp://" & $FTP_Username & ":" & $FTP_Password & "@" & $FTP_Server

Example_Ftp_1()
Example_Ftp_2()

; ============================================================================================================================
; Example Ftp 1 - Upload, download, list, and delete etc.
; ============================================================================================================================
Func Example_Ftp_1()
	ConsoleWrite("Example FTP 1" & @LF)

	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	ConsoleWrite("Uploading Test1.txt ..." & @LF)
	Curl_Data_Put($Curl, "The quick brown fox jumps over the lazy dog")
	Curl_Easy_Setopt($Curl, $CURLOPT_URL, $FTP_Url & "/test1.txt")
	Curl_Easy_Setopt($Curl, $CURLOPT_UPLOAD, 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_READFUNCTION, Curl_DataReadCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_READDATA, $Curl)
	Local $Code = Curl_Easy_Perform($Curl)
	If $Code <> $CURLE_OK Then ConsoleWrite(Curl_Easy_StrError($Code) & @LF)

	ConsoleWrite("Uploading Test2.txt ..." & @LF)
	Curl_Data_Put($Curl, "How quickly daft jumping zebras vex")
	Curl_Easy_Reset($Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_URL, $FTP_Url & "/test2.txt")
	Curl_Easy_Setopt($Curl, $CURLOPT_UPLOAD, 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_READFUNCTION, Curl_DataReadCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_READDATA, $Curl)
	Local $Code = Curl_Easy_Perform($Curl)
	If $Code <> $CURLE_OK Then ConsoleWrite(Curl_Easy_StrError($Code) & @LF)

	ConsoleWrite("Getting Server Dir List ..." & @LF)
	Curl_Data_Cleanup($Curl)
	Curl_Easy_Reset($Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_URL, $FTP_Url)
	Curl_Easy_Setopt($Curl, $CURLOPT_DIRLISTONLY, 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)
	Local $Code = Curl_Easy_Perform($Curl)
	If $Code <> $CURLE_OK Then ConsoleWrite(Curl_Easy_StrError($Code) & @LF)

	MsgBox(0, 'List', BinaryToString(Curl_Data_Get($Curl)))

	ConsoleWrite("Downloading Test1.txt ..." & @LF)
	Curl_Data_Put($Curl, "")
	Curl_Easy_Reset($Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_URL, $FTP_Url & "/test1.txt")
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Curl)
	Local $Code = Curl_Easy_Perform($Curl)
	If $Code <> $CURLE_OK Then ConsoleWrite(Curl_Easy_StrError($Code) & @LF)

	MsgBox(0, 'Download Test1.txt From FTP Server', BinaryToString(Curl_Data_Get($Curl)))

	ConsoleWrite("Deleting Test1.txt and Test2.txt ..." & @LF)
	Local $SList = Curl_Slist_Append(0, "DELE test1.txt")
	$SList = Curl_Slist_Append($SList, "DELE test2.txt")
	Curl_Easy_Reset($Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_URL, $FTP_Url)
	Curl_Easy_Setopt($Curl, $CURLOPT_QUOTE, $SList)
	Curl_Easy_Setopt($Curl, $CURLOPT_NOBODY, 1)
	Local $Code = Curl_Easy_Perform($Curl)
	If $Code <> $CURLE_OK Then ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
	Curl_Slist_Free_All($SList)
	Curl_Easy_Cleanup($Curl)

	ConsoleWrite(@LF)
EndFunc


; ============================================================================================================================
; Example Ftp 2 - Upload and download files
; ============================================================================================================================
Func Example_Ftp_2()
	ConsoleWrite("Example FTP 2" & @LF)

	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	Local $Upload = FileOpen("Upload.txt", 2 + 16)
	Local $Download = FileOpen("Download.txt", 2 + 16)

	FileWrite($Upload, "The quick brown fox jumps over the lazy dog")
	FileSetPos($Upload, 0, 0)

	ConsoleWrite("Uploading File ..." & @LF)
	Curl_Easy_Setopt($Curl, $CURLOPT_URL, $FTP_Url & "/test1.txt")
	Curl_Easy_Setopt($Curl, $CURLOPT_UPLOAD, 1)
	Curl_Easy_Setopt($Curl, $CURLOPT_READFUNCTION, Curl_FileReadCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_READDATA, $Upload)
	Local $Code = Curl_Easy_Perform($Curl)
	If $Code <> $CURLE_OK Then ConsoleWrite(Curl_Easy_StrError($Code) & @LF)

	ConsoleWrite("Downloading File ..." & @LF)
	Curl_Easy_Reset($Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_URL, $FTP_Url & "/test1.txt")
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_FileWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Download)
	Local $Code = Curl_Easy_Perform($Curl)
	If $Code <> $CURLE_OK Then ConsoleWrite(Curl_Easy_StrError($Code) & @LF)

	ConsoleWrite("Deleting File ..." & @LF)
	Local $SList = Curl_Slist_Append(0, "DELE test1.txt")
	Curl_Easy_Reset($Curl)
	Curl_Easy_Setopt($Curl, $CURLOPT_URL, $FTP_Url)
	Curl_Easy_Setopt($Curl, $CURLOPT_QUOTE, $SList)
	Curl_Easy_Setopt($Curl, $CURLOPT_NOBODY, 1)
	Local $Code = Curl_Easy_Perform($Curl)
	If $Code <> $CURLE_OK Then ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
	Curl_Slist_Free_All($SList)
	Curl_Easy_Cleanup($Curl)

	FileClose($Upload)
	FileClose($Download)

	MsgBox(0, 'Download.txt', FileRead("Download.txt"))

	FileDelete("Upload.txt")
	FileDelete("Download.txt")

	ConsoleWrite(@LF)
EndFunc
