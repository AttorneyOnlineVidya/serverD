﻿#CRLF$ = Chr(13)+Chr(10)

Structure Action
  IP.s
  type.i  
EndStructure

Structure Plugin
  ID.i
  version.i
  name.s
  description.s
  *rawfunction
  *gtarget
  *gmessage
  *gcallback
  active.b
EndStructure

Enumeration ;plugin status
  #NONE
  #DATA
  #CONN
  #DISC
  #SEND
EndEnumeration

Structure area
  name.s
  bg.s
  wait.l
  lock.l
  mlock.w
  pw.s
  hidden.b
  players.w
  good.w
  evil.w
  track.s
  trackstart.l
  trackwait.i
  status.s
  docurl.s
  List ClientStringList.s()
EndStructure

Structure ACharacter
  name.s
  desc.s
  dj.b
  evinumber.w
  evidence.s
  pw.s
EndStructure

Structure ItemData
  name.s
  price.w
  filename.s
  desc.s
EndStructure

Structure Client
  ClientID.l
  IP.s
  AID.w
  CID.w
  sHD.b
  HD.s
  perm.w
  ignore.b
  ignoremc.b
  hack.b
  gimp.b
  pos.s
  area.w
  last.s
  cconnect.b
  ooct.b
  judget.b
  websocket.b
  username.s
  RAW.b
  master.b
  skip.b
  Inventory.i[20]
EndStructure

Structure TempBan
  banned.s
  reason.s
  type.b
  time.l
EndStructure

Enumeration
  #KICK
  #DISCO
  #BAN
  #IDBAN
  #MUTE
  #UNMUTE
  #CIGNORE
  #UNIGNORE
  #UNDJ
  #DJ
  #GIMP
  #UNGIMP
  #SWITCH
  #MOVE
EndEnumeration
; IDE Options = PureBasic 5.30 (Windows - x86)
; CursorPosition = 42
; FirstLine = 14
; EnableXP