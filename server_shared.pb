﻿CompilerIf #PB_Compiler_OS <> #PB_OS_Windows
  #MB_ICONERROR=0
  Global libext$=".so"
CompilerElse
  Global libext$=".dll"
CompilerEndIf

XIncludeFile "shared_headers.pb"

Global NewList Plugins.Plugin()

Prototype.i PPluginVersion()
Prototype.l PPluginName()
Prototype.l PPluginDescription()
Prototype.i PPluginRAW()


Global Dim areas.area(100)
Define iniarea
For iniarea=0 To 100 
  areas(iniarea)\wait=0
  areas(iniarea)\lock=0
  areas(iniarea)\mlock=0
  areas(iniarea)\status="[IDLE]"
  areas(iniarea)\nameset="default"
Next


Global Dim Characters.ACharacter(100)

Structure Track
  TrackName.s
  Length.i
EndStructure
Global NewList Music.Track()


Global Server.Client
Server\ClientID=-1
Server\IP="$HOST"
Server\AID=-3
Server\CID=-3
Server\perm=3
Server\ignore=0
Server\ignoremc=0
Server\hack=0
Server\area=-1
Server\last=""
Server\cconnect=0
Server\ooct=0
Server\RAW=0
Server\username="$HOST"
Global NewMap Clients.Client()

Global NewList Actions.Action()

Procedure.s ValidateChars(source.s)
  Protected i, *ptrChar.Character, length = Len(source), result.s
  *ptrChar = @source
  For i = 1 To length
    If *ptrChar\c > 31
      If *ptrChar\c<>127 And *ptrChar\c<>129
        result + Chr(*ptrChar\c)
      EndIf
    EndIf
    *ptrChar + SizeOf(Character)
  Next
  ProcedureReturn result 
EndProcedure

Procedure.s Encode(smes$)
  smes$=ValidateChars(smes$)
  smes$=ReplaceString(smes$,"%n",#CRLF$)
  smes$=ReplaceString(smes$,"$n",#CRLF$)
  smes$=ReplaceString(smes$,"#","<num>")
  smes$=ReplaceString(smes$,"&","<and>")
  smes$=ReplaceString(smes$,"%","<percent>")
  smes$=ReplaceString(smes$,"$","<dollar>")
  ProcedureReturn smes$
EndProcedure

Procedure.s Escape(smes$)
  smes$=ReplaceString(smes$,"<num>","#")
  smes$=ReplaceString(smes$,"<pound>","#")
  smes$=ReplaceString(smes$,"<and>","&")
  smes$=ReplaceString(smes$,"<percent>","%")
  smes$=ReplaceString(smes$,"<dollar>","$")
  ProcedureReturn smes$
EndProcedure

Procedure WriteLog(string$,*lclient.Client)
  Define mstr$,logstr$
  ; [23:21:05] David Skoland: (If mod)[M][IP][Timestamp, YYYYMMDDHHMM][Character][Message]
  Select *lclient\perm
    Case 1
      mstr$="[M]"
    Case 2
      mstr$="[A]"
    Case 3
      mstr$="[S]"
    Default
      mstr$="[U]"
  EndSelect
  logstr$=mstr$+"["+LSet(*lclient\IP,15)
  logstr$=logstr$+"]"+"["+FormatDate("%yyyy.%mm.%dd %hh:%ii:%ss",Date())+"]"+string$
  If Logging
    WriteStringN(1,logstr$)
  EndIf
  CompilerIf #CONSOLE
    PrintN(logstr$)
  CompilerElse
    If Quit=0
      AddGadgetItem(#listbox_event,-1,string$)
      SetGadgetItemData(#listbox_event,CountGadgetItems(#listbox_event)-1,*lclient\ClientID)
    EndIf
  CompilerEndIf   
EndProcedure

;- Signal handling on linux
CompilerIf #PB_Compiler_OS = #PB_OS_Linux
  #SIGINT = 2
  #SIGQUIT   =   3
  #SIGABRT   =   6
  #SIGKILL       =   9
  #SIGTERM   =   15
  
  ProcedureC on_killed_do(signum)
    WriteLog("stopping server...",Server)
    LockMutex(ListMutex)
    ResetMap(Clients())
    While NextMapElement(Clients())
      If Clients()\ClientID
        CloseNetworkConnection(Clients()\ClientID)
      EndIf
      DeleteMapElement(Clients())
    Wend
    killed=1
    UnlockMutex(ListMutex)    
    CloseNetworkServer(0)
    FreeMemory(*Buffer)
    WriteLog("KILLED",Server)
    End
  EndProcedure
  signal_(#SIGINT,@on_killed_do())
  signal_(#SIGQUIT,@on_killed_do())
  signal_(#SIGABRT,@on_killed_do())
  signal_(#SIGKILL,@on_killed_do())
  signal_(#SIGTERM,@on_killed_do())
CompilerEndIf

CompilerIf #WEB
  Enumeration ;WebsocketOpcodes
    #ContinuationFrame
    #TextFrame
    #BinaryFrame
    #Reserved3Frame
    #Reserved4Frame
    #Reserved5Frame
    #Reserved6Frame
    #Reserved7Frame
    #ConnectionCloseFrame
    #PingFrame
    #PongFrame
    #ReservedBFrame
    #ReservedCFrame
    #ReservedDFrame
    #ReservedEFrame
    #ReservedFFrame
  EndEnumeration
  
  #ServerSideMasking = #False
  CompilerIf #ServerSideMasking
    #ServerSideMaskOffset = 4
  CompilerElse
    #ServerSideMaskOffset = 0
  CompilerEndIf
  
  #GUID$ = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
  
  Procedure.s SecWebsocketAccept(Client_Key.s)
    
    Protected *Temp_Data, *Temp_Data_2, *Temp_Data_3
    Protected Temp_String.s, Temp_String_ByteLength.i
    Protected Temp_SHA1.s
    Protected i
    Protected Result.s
    
    Temp_String.s = Client_Key + #GUID$
    
    ; #### Convert to ASCII
    Temp_String_ByteLength = StringByteLength(Temp_String, #PB_Ascii)
    *Temp_Data = AllocateMemory(Temp_String_ByteLength + SizeOf(Character))
    PokeS(*Temp_Data, Temp_String, -1, #PB_Ascii)
    
    ; #### Generate the SHA1
    *Temp_Data_2 = AllocateMemory(20)
    Temp_SHA1.s = SHA1Fingerprint(*Temp_Data, Temp_String_ByteLength)
    For i = 0 To 19
      PokeA(*Temp_Data_2+i, Val("$"+Mid(Temp_SHA1, 1+i*2, 2)))
    Next
    
    ; #### Encode the SHA1 as Base64
    *Temp_Data_3 = AllocateMemory(30)
    Base64Encoder(*Temp_Data_2, 20, *Temp_Data_3, 30)
    
    Result = PeekS(*Temp_Data_3, -1, #PB_Ascii)
    
    FreeMemory(*Temp_Data)
    FreeMemory(*Temp_Data_2)
    FreeMemory(*Temp_Data_3)
    
    ProcedureReturn Result
  EndProcedure
  
  Procedure.i Websocket_SendTextFrame(ClientID.i, Text$)
    
    Protected.a Byte
    Protected.i Result, Length, Add, i, Ptr
    Protected *Buffer
    Protected Dim bKey.a(3)
    
    
    Length = StringByteLength(Text$, #PB_UTF8)
    Debug Length
    If Length < 65535
      
      If Length < 126
        Add = 2 + #ServerSideMaskOffset
      Else
        Add = 4 + #ServerSideMaskOffset
      EndIf
      
      *Buffer = AllocateMemory(Length + Add + 1)
      If *Buffer
        
        Ptr = 0
        Byte = %10000000 | #TextFrame
        PokeA(*Buffer + Ptr, Byte)
        Ptr + 1
        If Add = 2 + #ServerSideMaskOffset
          CompilerIf #ServerSideMasking
            PokeA(*Buffer + Ptr, %10000000 | Length)
          CompilerElse
            PokeA(*Buffer + Ptr, %00000000 | Length)
          CompilerEndIf
          Ptr + 1
        Else
          CompilerIf #ServerSideMasking
            PokeA(*Buffer + Ptr, %10000000 | 126)
          CompilerElse
            PokeA(*Buffer + Ptr, %00000000 | 126)
          CompilerEndIf
          Ptr + 1
          PokeA(*Buffer + Ptr, Length >> 8)
          Ptr + 1
          PokeA(*Buffer + Ptr, Length & $FF)
          Ptr + 1
        EndIf
        
        CompilerIf #ServerSideMasking
          For i = 0 To 3
            bKey(i) = Random(255)
            PokeA(*Buffer + Ptr + i, bKey(i))
          Next i
          Ptr + 4
        CompilerEndIf
        
        PokeS(*Buffer + Ptr, Text$, -1, #PB_UTF8)
        
        CompilerIf #ServerSideMasking
          For i = 0 To Length - 1       
            PokeA(*Buffer + Ptr + i, PeekA(*Buffer + Ptr + i) ! bKey(i % 4))
          Next i
        CompilerEndIf
        
        If SendNetworkData(ClientID, *Buffer, Length + Add) > 0
          Result = #True
        EndIf
        
        FreeMemory(*Buffer)
      EndIf
    EndIf
    
    ProcedureReturn Result
    
  EndProcedure
CompilerEndIf

Procedure.s GetCharacterName(*nclient.Client)
  Define name$
  If *nclient\CID>=0 And *nclient\CID<=CharacterNumber
    name$=Characters(*nclient\CID)\name
  ElseIf *nclient\CID=-1
    name$="$UNOWN"
  ElseIf *nclient\CID=-3
    name$="$HOST"
  Else
    name$="HACKER"
    *nclient\hack=1
    rf=1
  EndIf
  ProcedureReturn name$
EndProcedure

Procedure.s GetAreaStatus(*nclient.Client)
  Define areastatus$
  If *nclient\area>=0 And *nclient\area<=AreaNumber
    areastatus$=Areas(*nclient\area)\status
  EndIf
  ProcedureReturn areastatus$
EndProcedure

Procedure.s GetNameStatus(*nclient.Client) ;Returns the character name of the last person to set the area status
  Define lastset$
  If *nclient\area>=0 And *nclient\area<=AreaNumber
    lastset$=Areas(*nclient\area)\nameset
  EndIf
  ProcedureReturn lastset$
EndProcedure

Procedure.s GetAreaDoc(*nclient.Client)
  Define areadoc$
  If *nclient\area>=0 And *nclient\area<=AreaNumber
    areadoc$=Areas(*nclient\area)\docurl
  EndIf
  ProcedureReturn areadoc$
  EndProcedure


Procedure.s GetAreaName(*nclient.Client)
  Define name$
  If *nclient\area>=0 And *nclient\area<=AreaNumber
    name$=Areas(*nclient\area)\name
  ElseIf *nclient\area=-3
    name$="RAM"
  Else
    name$="$NONE"
  EndIf
  ProcedureReturn name$
EndProcedure
; IDE Options = PureBasic 5.30 (Windows - x86)
; CursorPosition = 28
; FirstLine = 8
; Folding = ----
; EnableXP