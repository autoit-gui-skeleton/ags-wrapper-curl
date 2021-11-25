AGS-wrapper-curl
================

> [AutoIt Gui Skeleton](https://autoit-gui-skeleton.github.io/) package for wrapping the library [Curl.au3](https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn/) created by Ward. See this package on [npmjs.com](https://www.autoitscript.com/forum/topic/173067-curl-udf-autoit-binary-code-version-of-libcurl-with-ssl-support/)



<br/>

## Curl Ward library

### Introduction

This library provides an implementation of libcurl with SSL support. It's built with another Ward library [BinaryCall](https://www.autoitscript.com/forum/topic/162366-binarycall-udf-write-subroutines-in-c-call-in-autoit/)

The Features:

* Pure AutoIt script, no DLLs needed.
* Build with SSL/TLS and zlib support (without libidn, libiconv, libssh2).
* Full easy-interface and partial multi-interface support.
* Data can read from or write to autoit variables or files.
* Smaller code size (compare to most libcurl DLL).

The version information of this build:
 - Curl Version: libcurl/7.42.1
 - SSL Version: mbedTLS/1.3.10
 - Libz Version: 1.2.8
 - Protocols: ftp,ftps,http,https

Here are the helper functions (not include in libcurl library).

    Curl_DataWriteCallback()
    Curl_DataReadCallback()
    Curl_FileWriteCallback()
    Curl_FileReadCallback()
    Curl_Data_Put()
    Curl_Data_Get()
    Curl_Data_Cleanup()

### Examples

#### Get HTTP header and content from google

```autoit
#Include "../Curl.au3"

; How to get html or header data?
;   1. Set $CURLOPT_WRITEFUNCTION and $CURLOPT_HEADERFUNCTION to Curl_DataWriteCallback()
;   2. Set $CURLOPT_WRITEDATA or $CURLOPT_HEADERDATA to any number as identify
;   3. Use Curl_Data_Get() to read the returned data in binary format
;   4. Use Curl_Data_Cleanup() to remove the data

Local $Curl = Curl_Easy_Init()
If Not $Curl Then Return

Local $Html = $Curl ; any number as identify
Local $Header = $Curl + 1 ; any number as identify

; Curl configuration
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

; Perform curl request
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
```


### Deals with proxy settings

By default, libcurl respects the proxy environment variables named `http_proxy`, `ftp_proxy`, `sftp_proxy` etc. If set, libcurl will use the specified proxy for that URL scheme. So for a "FTP://" URL, the ftp_proxy is considered. all_proxy is used if no protocol specific proxy was set. If `no_proxy` is set, it is the exact equivalent of setting the CURLOPT_NOPROXY option. But if you want to ovveride envrionnement variables, it's possible with the `$CURLOPT_PROXY` and `CURLOPT_NOPROXY` options.

To set a proxy, use :

```
Curl_Easy_Setopt($Curl, $CURLOPT_PROXY, 'https://myProxy.com:8080');
```

To disable default proxy configuration, use :

```autoit
Curl_Easy_Setopt($Curl, $CURLOPT_PROXY, '');
```

### Make request with multi interface for non-GUI blocking

The multi interface provides in libcurl offers several abilities that the easy interface (default mode use in libcurl) does not. They are mainly:

1. Enable a "pull" interface. The application that uses libcurl decides where and when to ask libcurl to get/send data.

2. Enable multiple simultaneous transfers in the same thread without making it complicated for the application.

3. Enable the application to wait for action on its own file descriptors and curl's file descriptors simultaneously.

4. Enable event-based handling and scaling transfers up to and beyond thousands of parallel connections.

> See more : [https://curl.se/libcurl/c/libcurl-multi.html](https://curl.se/libcurl/c/libcurl-multi.html)


```autoit

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
```

### Another examples

See the [Examples](./Examples) script for detail usage.


<br/>

## How to install AGS-wrapper-curl ?

We assume that you have already install [Node.js](https://nodejs.org/) and [Yarn](https://yarnpkg.com/lang/en/), for example by taking a [Chocolatey](https://chocolatey.org/). AGS framework use Yarn for manage dependencies.

To add this package into your AutoIt project, just type in the root folder of your AGS project where the `package.json` is stored. You can also modify the `dependencies` property of this json file and use the yarn [install](https://yarnpkg.com/en/docs/usage) command. It is easier to use the add command :

```
λ  yarn add @autoit-gui-skeleton/ags-wrapper-curl --modules-folder vendor
```

The property `dependencies` of the  `package.json` file is updated consequently, and all package dependencies, as well as daughter dependencies of parent dependencies, are installed in the `./vendor/@autoit-gui-skeleton/` directory. Note that with an AGS project, it is not necessary to explicitly write this option `--modules-folder vendor` on the command line, thanks to the `.yarnrc` file stored at the root of the project. Yarn automatically use `.yarnrc` file to add an additional configuration of options.

```
 #./.yarnrc
 --modules-folder vendor
 ```

Finally to use this library in your AutoIt program, you need to include this library in the main program. There is no need for additional configuration to use it.

```autoit
#include './vendor/@autoit-gui-skeleton/ags-wrapper-curl/Curl.au3'
```


<br/>

## What is AGS (AutoIt Gui Skeleton) ?

[AutoIt Gui Skeleton](https://autoit-gui-skeleton.github.io/) give an environment for developers, that makes it easy to build AutoIt applications. To do this AGS proposes to use conventions and a standardized architecture in order to simplify the code organization, and thus its maintainability. It also gives tools to help developers in recurring tasks specific to software engineering.

> More information about [AGS framework](https://autoit-gui-skeleton.github.io/)

AGS provides a dependency manager for AutoIt library. It uses the Node.js ecosystem and its dependency manager npm and its evolution Yarn. All AGS packages are hosted in npmjs.org repository belong to the [@autoit-gui-skeleton](https://www.npmjs.com/search?q=autoit-gui-skeleton) organization. And in AGS you can find two types of package :

- An **AGS-component** is an AutoIt library, that you can easy use in your AutoIt project built with the AGS framework. It provides some features for application that can be implement without painless.
- An **AGS-wrapper** is a simple wrapper for an another library created by another team/developer.

> More information about [dependency manager for AutoIt in AGS](https://autoit-gui-skeleton.github.io//2018/07/10/ags_dependencies_manager_for_AutoIt.html)


<br/>

## About

### Acknowledgments

Acknowledgments for [Ward](https://www.autoitscript.com/forum/profile/10768-ward/) work and its library Curl.au3 and BinaryCall.au3.

### Contributing

Comments, pull-request & stars are always welcome !

### License

Copyright (c) 2018 by [v20100v](https://github.com/v20100v). Released under the MIT license.
