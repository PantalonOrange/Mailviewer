**FREE
// Copyright (c) 2019-2022 Christian Brunner
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Created by BRC on 09.08.2019 - 20.01.2020

// Simple imap viewer, without body

// CAUTION: ALPHA-VERSION

// TO-DOs:
//  + Improve field-extraction from incoming imap-stream
//  + Improve errorhandling and messages
//  + Decode base64-encoded subjects (different codepages)


/INCLUDE QRPGLECPY,H_SPECS
CTL-OPT MAIN(Main);

/INCLUDE QRPGLEH,IMAPVW_H


//#########################################################################
DCL-PROC Main;
 DCL-PI *N;
   pHost CHAR(64) CONST;
   pUser CHAR(64) CONST;
   pPassword CHAR(64) CONST;
   pUseTLS IND CONST;
   pPort UNS(5) CONST;
   pRefreshSeconds PACKED(2 :0) CONST;
 END-PI;
 //------------------------------------------------------------------------

 /INCLUDE QRPGLECPY,SQLOPTIONS

 Reset This;
 *INLR = TRUE;

 system('CRTDTAQ DTAQ(QTEMP/IMAPVW) MAXLEN(80)');
 system('OVRDSPF FILE(IMAPVWDF) OVRSCOPE(*ACTGRPDFN) DTAQ(QTEMP/IMAPVW)');

 If Not %Open(IMAPVWDF);
   Open IMAPVWDF;
 EndIf;

 DoU ( This.PictureControl = FM_END );

   Select;

     When ( This.PictureControl = FM_A );
       Monitor;
         loopFM_A(pHost :pUser :pPassword :pUseTLS :pPort :pRefreshSeconds);
         On-Error;
           This.PictureControl = FM_END;
           sendJobLog(PSDS.MessageID + ':' + PSDS.MessageData);
       EndMon;

     Other;
       This.PictureControl = FM_END;

   EndSl;

 EndDo;

 If %Open(IMAPVWDF);
   Close IMAPVWDF;
 EndIf;

 system('DLTOVR FILE(IMAPVWDF) LVL(*ACTGRPDFN)');
 system('DLTDTAQ DTAQ(QTEMP/IMAPVW)');

 Return;

On-Exit;
 If This.Connected;
   disconnectFromHost();
 EndIf;

END-PROC;


//**************************************************************************
DCL-PROC loopFM_A;
 DCL-PI *N;
   pHost CHAR(64) CONST;
   pUser CHAR(64) CONST;
   pPassword CHAR(64) CONST;
   pUseTLS IND CONST;
   pPort UNS(5) CONST;
   pRefreshSeconds PACKED(2 :0) CONST;
 END-PI;

 /INCLUDE QRPGLECPY,QRCVDTAQ
 /INCLUDE QRPGLECPY,QUSCMDLN

 DCL-S Success IND INZ(TRUE);

 DCL-DS IncomingData QUALIFIED INZ;
   Data CHAR(80);
   Length PACKED(5 :0);
 END-DS;

 DCL-DS FMA LIKEREC(IMAPVWAC :*ALL) INZ;
 //-------------------------------------------------------------------------

 Success = initFM_A(pHost :pUser :pPassword :pUseTLS :pPort :pRefreshSeconds);

 fetchRecordsFM_A();

 DoW ( This.PictureControl = FM_A );

   AC_Refresh = This.RefreshSeconds;

   Write IMAPVWAF;
   Write IMAPVWZC;
   Write IMAPVWAC;

   clearMessages(PgmQueue :CallStack);

   receiveDataQueue('IMAPVW' :'QTEMP' :IncomingData.Length :IncomingData.Data
                    :This.RefreshSeconds);

   If ( IncomingData.Data = '' );
     fetchRecordsFM_A();
     Iter;
   EndIf;

   Clear IncomingData;

   Read(E) IMAPVWAC FMA;
   This.RefreshSeconds = FMA.AC_Refresh;

   Select;

     When WSDS.Exit;
       This.PictureControl = FM_END;
       If This.Connected;
         disconnectFromHost();
       EndIf;

     When WSDS.Refresh;
       fetchRecordsFM_A();

     When WSDS.ReConnect;
       reConnectToHost();
       fetchRecordsFM_A();

     When WSDS.CommandLine;
       promptCommandLine();

     Other;
       fetchRecordsFM_A();

   EndSl;

 EndDo;


END-PROC;
//**************************************************************************
DCL-PROC initFM_A;
 DCL-PI *N IND;
   pHostDS LIKEDS(CommandVaryingParmDS_T) CONST;
   pUserDS LIKEDS(CommandVaryingParmDS_T) CONST;
   pPasswordDS LIKEDS(CommandVaryingParmDS_T) CONST;
   pUseTLS IND CONST;
   pPort UNS(5) CONST;
   pRefreshSeconds PACKED(2 :0) CONST;
 END-PI;

 DCL-S Success IND INZ(TRUE);
 //-------------------------------------------------------------------------

 Reset RecordNumber;
 Clear IMAPVWAC;
 Clear IMAPVWAS;

 AC_Device = PSDS.JobName;

 If ( pHostDS.Length > 0 );
   This.LogInDataDS.Host = pHostDS.Data;
 EndIf;

 If ( pUserDS.Data = '*CURRENT' );
   This.LogInDataDS.User = retrieveCurrentUserAddress();
 ElseIf ( pUserDS.Length > 0 );
   This.LogInDataDS.User = pUserDS.Data;
 EndIf;

 If ( pPasswordDS.Length > 0 );
   This.LogInDataDS.Password = pPasswordDS.Data;
 EndIf;

 This.LogInDataDS.UseTLS = pUseTLS;

 If ( pPort = 0 ) And This.LogInDataDS.UseTLS;
   This.LogInDataDS.Port = TLS_PORT;
 ElseIf ( pPort = 0 ) And Not This.LogInDataDS.UseTLS;
   This.LogInDataDS.Port = DEFAULT_PORT;
 Else;
   This.LogInDataDS.Port = pPort;
 EndIf;

 If ( pRefreshSeconds > 0 );
   This.RefreshSeconds = pRefreshSeconds;
 Else;
   This.RefreshSeconds = 60;
 EndIf;

 If ( This.LogInDataDS.Host = '' ) Or ( This.LogInDataDS.User = '' )
  Or ( This.LogInDataDS.Password = '' ) Or ( This.LogInDataDS.Port = 0 );
   Success = askForLogInData();
 EndIf;

 If Success;
   This.Connected = connectToHost();
   Success = This.Connected;
   If Success;
     AC_Mail = This.LogInDataDS.User;
     WSDS.LoginColorGreen = This.LogInDataDS.UseTLS;
     WSDS.LoginColorYellow = Not This.LogInDataDS.UseTLS;
     WSDS.LoginColorRed = FALSE;
   Else;
     AC_Mail = retrieveMessageText('M000003');
     WSDS.LoginColorGreen = FALSE;
     WSDS.LoginColorYellow = FALSE;
     WSDS.LoginColorRed = TRUE;
   EndIf;
 EndIf;

 Return Success;

END-PROC;
//**************************************************************************
DCL-PROC fetchRecordsFM_A;

 DCL-S Success IND INZ(TRUE);
 DCL-S i UNS(3) INZ;

 DCL-DS MailDS LIKEDS(MailDS_T) DIM(MAX_ROWS_TO_FETCH);
 DCL-DS SubfileDS QUALIFIED INZ;
   Color1 CHAR(1);
   Sender CHAR(40);
   Color2 CHAR(3);
   SendDate CHAR(25);
   Color3 CHAR(3);
   Subject CHAR(50);
 END-DS;
 //-------------------------------------------------------------------------

 Reset RecordNumber;

 WSDS.SubfileClear = TRUE;
 WSDS.SubfileDisplayControl = TRUE;
 WSDS.SubfileDisplay = FALSE;
 WSDS.SubfileMore = FALSE;
 Write(E) IMAPVWAC;

 If This.Connected;
   sendStatus(retrieveMessageText('M000000'));
   Success = readMailsFromInbox(MailDS);
 EndIf;

 WSDS.SubfileClear = FALSE;
 WSDS.SubfileDisplayControl = TRUE;
 WSDS.SubfileDisplay = TRUE;
 WSDS.SubfileMore = TRUE;

 If ( This.RecordsFound > 0 ) And This.Connected;

   For i = 1 To This.RecordsFound;

     If MailDS(i).UnSeenFlag;
       SubfileDS.Color1 = COLOR_PNK;
     Else;
       SubfileDS.Color1 = COLOR_GRN;
     EndIf;

     SubfileDS.Sender = MailDS(i).Sender;
     SubfileDS.Color2 = COLOR_BLU + '|' + SubfileDS.Color1;
     SubfileDS.SendDate = MailDS(i).SendDate;
     SubfileDS.Color3 = COLOR_BLU + '|' + SubfileDS.Color1;
     SubfileDS.Subject = MailDS(i).Subject;

     RecordNumber += 1;
     AS_Subfile_Line = SubfileDS;
     AS_RecordNumber = RecordNumber;
     Write IMAPVWAS;

   EndFor;

   If ( AC_Current_Cursor > 0 ) And ( AC_Current_Cursor <= RecordNumber );
     RecordNumber = AC_Current_Cursor;
   Else;
     RecordNumber = 1;
   EndIf;

 ElseIf ( This.RecordsFound = 0 ) And This.Connected;
   RecordNumber = 1;
   AS_Subfile_Line = retrieveMessageText('M000004');
   AS_RecordNumber = RecordNumber;
   Write IMAPVWAS;

 Else;
   RecordNumber = 1;
   AS_Subfile_Line = COLOR_BLU + This.GlobalMessage;
   AS_RecordNumber = RecordNumber;
   Write IMAPVWAS;

 EndIf;

END-PROC;

//**************************************************************************
DCL-PROC askForLoginData;
 DCL-PI *N IND END-PI;

 DCL-S Success IND INZ(TRUE);
 //-------------------------------------------------------------------------

 WSDS.WindowErrorHost = FALSE;
 WSDS.WindowErrorUser = FALSE;
 W0_Window_Title = retrieveMessageText('C000010');
 W0_Host = This.LogInDataDS.Host;
 W0_User = This.LogInDataDS.User;
 W0_Password = This.LogInDataDS.Password;
 If This.LogInDataDS.UseTLS;
   W0_Use_TLS = '*YES';
 Else;
   W0_Use_TLS = '*NO';
 EndIf;
 Clear W0_Port;

 DoU WSDS.Exit;

   Write IMAPVWW0;
   ExFmt IMAPVWW0;

   If WSDS.Exit;
     Clear IMAPVWW0;
     Success = FALSE;
     Leave;

   Else;

     Select;

       When ( W0_Host = '' );
         W0_Current_Row = 2;
         W0_Current_Column = 12;
         WSDS.WindowErrorHost = TRUE;
         Iter;

       When ( W0_User = '' );
         W0_Current_Row = 3;
         W0_Current_Column = 12;
         WSDS.WindowErrorUser = TRUE;
         Iter;

       When ( Not validateMailAddress(W0_User) );
         W0_Current_Row = 3;
         W0_Current_Column = 12;
         WSDS.WindowErrorUser = TRUE;
         Iter;

       Other;
         This.LogInDataDS.Host = %Trim(W0_Host);
         If ( W0_User = '*CURRENT' );
           This.LogInDataDS.User = retrieveCurrentUserAddress();
         Else;
           This.LogInDataDS.User = %Trim(W0_User);
         EndIf;
         This.LogInDataDS.Password = %Trim(W0_Password);
         This.LogInDataDS.UseTLS = ( W0_Use_TLS = '*YES' );
         If ( W0_Port = 0 ) And This.LogInDataDS.UseTLS;
           This.LogInDataDS.Port = TLS_PORT;
         ElseIf ( W0_Port = 0 ) And Not This.LogInDataDS.UseTLS;
           This.LogInDataDS.Port = DEFAULT_PORT;
         Else;
           This.LogInDataDS.Port = W0_Port;
         EndIf;

         Leave;

     EndSl;

   EndIf;

 EndDo;

 Return Success;

END-PROC;


//**************************************************************************
DCL-PROC connectToHost;
 DCL-PI *N IND END-PI;

 DCL-S Success IND INZ(TRUE);
 DCL-S RC INT(10) INZ;
 DCL-S ErrorNumber INT(10) INZ;
 DCL-S Data CHAR(32766) INZ;

 DCL-DS TimeOutDS QUALIFIED INZ;
   Seconds INT(10);
   MicroSeconds INT(10);
 END-DS;
 //-------------------------------------------------------------------------

 sendStatus(retrieveMessageText('M000001'));

 This.SocketDS.Address = inet_Address(%TrimR(This.LogInDataDS.Host));
 If ( This.SocketDS.Address = INADDR_NONE );
   pHostEntry = getHostByName(%TrimR(This.LogInDataDS.Host));
   If ( pHostEntry = *NULL );
     This.GlobalMessage = %Str(strError(ErrNo));
     Success = FALSE;
   Else;
     This.SocketDS.Address = HAddress;
   EndIf;
 EndIf;

 If Success;
   If This.LogInDataDS.UseTLS;
     This.LogInDataDS.UseTLS = generateGSKEnvironment();
   EndIf;

   This.SocketDS.SocketHandler = socket(AF_INET :SOCK_STREAM :IPPROTO_IP);
   If ( This.SocketDS.SocketHandler < 0 );
     This.GlobalMessage = %Str(strError(ErrNo));
     cleanUp_Socket();
     Success = FALSE;
   Else;
     TimeOutDS.Seconds = 2;
     setSockOpt98(This.SocketDS.SocketHandler :SOL_SOCKET :SO_RCVTIMEO
                  :%Addr(TimeOutDS) :%Size(TimeOutDS));
     setSockOpt98(This.SocketDS.SocketHandler :SOL_SOCKET :SO_SNDTIMEO
                  :%Addr(TimeOutDS) :%Size(TimeOutDS));
   EndIf;
 EndIf;

 If Success;
   This.SocketDS.AddressLength = %Size(SocketAddress);
   This.SocketDS.ConnectTo = %Alloc(This.SocketDS.AddressLength);

   pSocketAddress = This.SocketDS.ConnectTo;
   SocketAddressIn.Family = AF_INET;
   SocketAddressIn.Address = This.SocketDS.Address;
   SocketAddressIn.Port = This.LogInDataDS.Port;
   SocketAddressIn.Zero = *ALLx'00';

   If ( connect(This.SocketDS.SocketHandler :This.SocketDS.ConnectTo
                :This.SocketDS.AddressLength) < 0 );
     This.GlobalMessage = %Str(strError(ErrNo));
     cleanUp_Socket();
     Success = FALSE;
   EndIf;

   If Success And This.LogInDataDS.UseTLS;
     This.LogInDataDS.UseTLS = initGSKEnvironment();
   EndIf;
 EndIf;

 If Success;
   RC = receiveData(%Addr(Data) :%Size(Data));
   translateData(%Addr(Data) :ASCII :LOCAL);
   Success = ( %Scan('OK' :Data) > 0 );
   If Success;
     This.DominoSpecial = ( %Scan('Domino' :Data) > 0 );
     Data = 'a LOGIN ' + %TrimR(This.LogInDataDS.User) + ' ' +
            %TrimR(This.LogInDataDS.Password) + CRLF;
     translateData(%Addr(Data) :LOCAL :ASCII);
     sendData(%Addr(Data) :%Len(%TrimR(Data)));
     RC = receiveData(%Addr(Data) :%Size(Data));
     If ( RC <= 0 );
       This.GlobalMessage = %Str(strError(ErrNo));
       disconnectFromHost();
       Success = This.Connected;
     Else;
       translateData(%Addr(Data) :ASCII :LOCAL);
       This.Connected = ( %Scan('OK' :Data) > 0 );
       If Not This.Connected;
         This.GlobalMessage = retrieveMessageText('E000000');
         disconnectFromHost();
         Success = This.Connected;
       EndIf;
     EndIf;

   Else;
     This.GlobalMessage = %Str(strError(ErrNo));
     disconnectFromHost();
     Success = This.Connected;
   EndIf;
 EndIf;

 Return Success;

END-PROC;


//**************************************************************************
DCL-PROC disconnectFromHost;

 DCL-S Data CHAR(32) INZ;
 //-------------------------------------------------------------------------

 Data = 'a LOGOUT' + CRLF;
 translateData(%Addr(Data) :LOCAL :ASCII);
 sendData(%Addr(Data) :%Len(%TrimR(Data)));
 This.Connected = FALSE;
 cleanUp_Socket();

END-PROC;


//**************************************************************************
DCL-PROC reConnectToHost;

 DCL-S Success IND INZ(TRUE);
 //-------------------------------------------------------------------------

 Clear This.LogInDataDS.Password;
 Success = askForLogInData();

 If Success And This.Connected;
   disconnectFromHost();
 EndIf;

 If Success;
   This.Connected = connectToHost();
   Success = This.Connected;
   If Success;
     AC_Mail = This.LogInDataDS.User;
     WSDS.LoginColorGreen = This.LogInDataDS.UseTLS;
     WSDS.LoginColorYellow = Not This.LogInDataDS.UseTLS;
     WSDS.LoginColorRed = FALSE;
   Else;
     AC_Mail = retrieveMessageText('M000003');
     WSDS.LoginColorGreen = FALSE;
     WSDS.LoginColorYellow = FALSE;
     WSDS.LoginColorRed = TRUE;
   EndIf;
 EndIf;

END-PROC;


//**************************************************************************
DCL-PROC generateGSKEnvironment;
 DCL-PI *N IND END-PI;

 DCL-S Success IND INZ(TRUE);
 DCL-S RC INT(10) INZ;
 //--------------------------------------------------------------------------

 RC = gsk_Environment_Open(This.GSKDS.Environment);
 If ( RC <> GSK_OK );
   Success = FALSE;
   This.GlobalMessage = %Str(gsk_StrError(RC));
 EndIf;

 If Success;
   gsk_Attribute_Set_Buffer(This.GSKDS.Environment :GSK_KEYRING_FILE :'*SYSTEM' :0);

   gsk_Attribute_Set_eNum(This.GSKDS.Environment :GSK_SESSION_TYPE :GSK_CLIENT_SESSION);

   gsk_Attribute_Set_eNum(This.GSKDS.Environment :GSK_SERVER_AUTH_TYPE :GSK_SERVER_AUTH_PASSTHRU);
   gsk_Attribute_Set_eNum(This.GSKDS.Environment :GSK_CLIENT_AUTH_TYPE :GSK_CLIENT_AUTH_PASSTHRU);

   gsk_Attribute_Set_eNum(This.GSKDS.Environment :GSK_PROTOCOL_SSLV2 :GSK_PROTOCOL_SSLV2_OFF);
   gsk_Attribute_Set_eNum(This.GSKDS.Environment :GSK_PROTOCOL_SSLV3 :GSK_PROTOCOL_SSLV3_OFF);
   gsk_Attribute_Set_eNum(This.GSKDS.Environment :GSK_PROTOCOL_TLSV1 :GSK_PROTOCOL_TLSV1_ON);
   gsk_Attribute_Set_eNum(This.GSKDS.Environment :GSK_PROTOCOL_TLSV1_1 :GSK_TRUE);
   gsk_Attribute_Set_eNum(This.GSKDS.Environment :GSK_PROTOCOL_TLSV1_2 :GSK_TRUE);

   RC = gsk_Environment_Init(This.GSKDS.Environment);
   If ( RC <> GSK_OK );
     gsk_Environment_Close(This.GSKDS.Environment);
     Success = FALSE;
     This.GlobalMessage = %Str(gsk_StrError(RC));
   EndIf;
 EndIf;

 Return Success;

END-PROC;


//**************************************************************************
DCL-PROC initGSKEnvironment;
 DCL-PI *N IND END-PI;

 DCL-S Success IND INZ(TRUE);
 DCL-S RC INT(10) INZ;
 //--------------------------------------------------------------------------

 sendStatus(retrieveMessageText('M000002'));
 RC = gsk_Secure_Soc_Open(This.GSKDS.Environment :This.GSKDS.SecureHandler);
 If ( RC <> GSK_OK );
   cleanUp_Socket();
   Success = FALSE;
   This.GlobalMessage = %Str(gsk_StrError(RC));
 EndIf;

 If Success;
   RC = gsk_Attribute_Set_Numeric_Value(This.GSKDS.SecureHandler :GSK_FD
                                        :This.SocketDS.SocketHandler);
   If ( RC <> GSK_OK );
     cleanUp_Socket();
     Success = FALSE;
     This.GlobalMessage = %Str(gsk_StrError(RC));
   EndIf;
 EndIf;

 If Success;
   RC = gsk_Attribute_Set_Numeric_Value(This.GSKDS.SecureHandler :GSK_HANDSHAKE_TIMEOUT :10);
   If ( RC <> GSK_OK );
     cleanUp_Socket();
     Success = FALSE;
     This.GlobalMessage = %Str(gsk_StrError(RC));
   EndIf;
 EndIf;

 If Success;
   RC = gsk_Secure_Soc_Init(This.GSKDS.SecureHandler);
   If ( RC <> GSK_OK );
     cleanUp_Socket();
     Success = FALSE;
     This.GlobalMessage = %Str(gsk_StrError(RC));
   EndIf;
 EndIf;

 Return Success;

END-PROC;


//**************************************************************************
DCL-PROC readMailsFromInbox;
 DCL-PI *N IND;
   pMailDS LIKEDS(MailDS_T) DIM(MAX_ROWS_TO_FETCH);
 END-PI;

 DCL-C IMAP_FLAGS '(FLAGS BODY[HEADER.FIELDS (FROM DATE SUBJECT)])';

 DCL-S Success IND INZ(TRUE);
 DCL-S a INT(10) INZ;
 DCL-S b INT(10) INZ;
 DCL-S RC INT(10) INZ;
 DCL-S ErrorNumber INT(10) INZ;
 DCL-S Data CHAR(32766) INZ;
 //-------------------------------------------------------------------------

 Data = 'a EXAMINE INBOX' + CRLF;
 translateData(%Addr(Data) :LOCAL :ASCII);
 sendData(%Addr(Data) :%Len(%TrimR(Data)));
 RC = receiveData(%Addr(Data) :%Size(Data));
 If ( RC <= 0 );
   This.GlobalMessage = %Str(strError(ErrNo));
   Success = FALSE;
 Else;
   translateData(%Addr(Data) :ASCII :LOCAL);
   If ( %Scan('NO EXAMINE' :Data) > 0 );
     This.GlobalMessage = retrieveMessageText('E000001');
     Success = FALSE;
   Else;
     Monitor;
       This.RecordsFound = %Uns(%SubSt(Data :3 :%Scan('EXISTS' :Data) - 4));
       On-Error;
         Clear This.RecordsFound;
     EndMon;
   EndIf;
 EndIf;

 If Success And ( This.RecordsFound > 0 );
   For a = This.RecordsFound DownTo 1;
     Data = 'a FETCH ' + %Char(a) + ' ' + IMAP_FLAGS + CRLF;
     translateData(%Addr(Data) :LOCAL :ASCII);
     sendData(%Addr(Data) :%Len(%TrimR(Data)));
     RC = receiveData(%Addr(Data) :%Size(Data));
     If ( RC > 0 );
       translateData(%Addr(Data) :ASCII :LOCAL);
       If ( %Scan('From' :Data) > 0 );
         If ( b = MAX_ROWS_TO_FETCH );
           Leave;
         EndIf;
         b += 1;
         pMailDS(b) = extractFieldsFromStream(%Addr(Data));
         If Not This.DominoSpecial;
           RC = receiveData(%Addr(Data) :%Size(Data));
         EndIf;
       EndIf;
     EndIf;
   EndFor;
 EndIf;

 This.RecordsFound = b;

 Return Success;

END-PROC;


//**************************************************************************
DCL-PROC extractFieldsFromStream;
 DCL-PI *N LIKEDS(MailDS_T);
   pData POINTER VALUE;
 END-PI;

 DCL-S s INT(10) INZ;
 DCL-S e INT(10) INZ;
 DCL-S Data CHAR(32766) BASED(pData);

 DCL-DS MailDS LIKEDS(MailDS_T) INZ;
 //-------------------------------------------------------------------------

 s = %Scan('From:' :Data) + 6;
 e = %Scan(CRLF :Data :s) - 1;
 If ( s > 0 ) And ( e > s );
   MailDS.Sender = %SubSt(Data :s :(e - s) + 1);
   If ( %Scan('@' :MailDS.Sender) = 0 );
     Clear MailDS.Sender;
   EndIf;
   MailDS.Sender = %ScanRpl('"' :'' :MailDS.Sender);
   s = %Scan(MailDS.Sender :'<');
   If ( s > 0 );
     MailDS.Sender = %SubSt(MailDS.Sender :1 :(s - 1));
   EndIf;
 EndIf;

 s = %Scan('Date:' :Data) + 6;
 e = %Scan(CRLF :Data :s) - 1;
 If ( s > 0 ) And ( e > s );
   MailDS.SendDate = %SubSt(Data :s :(e - s) + 1);
 EndIf;

 s = %Scan('Subject:' :Data) + 9;
 e = %Scan(CRLF :Data :s) - 1;
 If ( s > 0 ) And ( e > s );
   MailDS.Subject = %SubSt(Data :s :(e - s) + 1);
   If ( %SubSt(MailDS.Subject :1 :2) = '=?' );
     Clear MailDS.Subject;
   EndIf;
 EndIf;

 MailDS.UnseenFlag = ( %Scan('\Seen' :Data) = 0 );

 Return MailDS;

END-PROC;


//**************************************************************************
DCL-PROC sendData;
 DCL-PI *N INT(10);
   pData POINTER VALUE;
   pLength INT(10) CONST;
 END-PI;

 DCL-S RC INT(10) INZ;
 DCL-S GSKLength INT(10) INZ;
 DCL-S Buffer VARCHAR(32766) BASED(pData);
 //--------------------------------------------------------------------------

 If This.LogInDataDS.UseTLS;
   RC = gsk_Secure_Soc_Write(This.GSKDS.SecureHandler :%Addr(Buffer) :pLength :GSKLength);
   If ( RC = GSK_OK );
     RC = GSKLength;
   Else;
     Clear RC;
   EndIf;
 Else;
   RC = send(This.SocketDS.SocketHandler :%Addr(Buffer) :pLength :0);
 EndIf;

 Return RC;

END-PROC;


//**************************************************************************
DCL-PROC receiveData;
 DCL-PI *N INT(10);
   pData POINTER VALUE;
   pLength INT(10) VALUE;
 END-PI;

 DCL-S RC INT(10) INZ;
 DCL-S GSKLength INT(10) INZ;
 DCL-S Buffer VARCHAR(32766) BASED(pData);
 //--------------------------------------------------------------------------

 If This.LogInDataDS.UseTLS;
   RC = gsk_Secure_Soc_Read(This.GSKDS.SecureHandler :%Addr(Buffer) :pLength :GSKLength);
   If ( RC = GSK_OK ) And ( GSKLength > 0 );
     Buffer = %SubSt(Buffer :1 :GSKLength);
   EndIf;
   RC = GSKLength;
 Else;
   RC = recv(This.SocketDS.SocketHandler :%Addr(Buffer) :pLength :0);
 EndIf;

 Return RC;

END-PROC;


//**************************************************************************
DCL-PROC cleanUp_Socket;

 If This.LogInDataDS.UseTLS;
   gsk_Secure_Soc_Close(This.GSKDS.SecureHandler);
   gsk_Environment_Close(This.GSKDS.Environment);
 EndIf;
 closeSocket(This.SocketDS.SocketHandler);

END-PROC;


//**************************************************************************
DCL-PROC retrieveCurrentUserAddress;
 DCL-PI *N CHAR(64) END-PI;

 DCL-S MailAddress CHAR(64) INZ;
 //-------------------------------------------------------------------------

 Exec SQL SELECT RTRIM(SMTPUID) CONCAT '@' CONCAT RTRIM(DOMROUTE)
            INTO :MailAddress
            FROM QUSRSYS.QATMSMTPA
            JOIN QUSRSYS.QAOKL02A ON (USERID = WOS1DDEN AND ADDRESS = WOS1DDGN)
           WHERE WOS1USRP = USER;
 If ( SQLCode = 100 );
   Clear MailAddress;
 EndIf;

 Return MailAddress;

END-PROC;


//**************************************************************************
DCL-PROC validateMailAddress;
 DCL-PI *N IND;
   pMailAddress CHAR(64) CONST;
 END-PI;

 DCL-S Success IND INZ(FALSE);
 //-------------------------------------------------------------------------

 Exec SQL SET :Success =
                REGEXP_COUNT(RTRIM(:pMailAddress),
                             '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,20}$');

 Return Success;

END-PROC;


//**************************************************************************
DCL-PROC translateData;
 DCL-PI *N;
   pData POINTER VALUE;
   pFromCCSID INT(10) CONST;
   pToCCSID INT(10) CONST;
 END-PI;

 /INCLUDE QRPGLECPY,ICONV

 DCL-S Data CHAR(32766) BASED(pData);
 //-------------------------------------------------------------------------

 iConvDS.iConvHandler = %Addr(Data);
 iConvDS.Length = %Len(%TrimR(Data));
 FromDS.FromCCSID = pFromCCSID;
 ToDS.ToCCSID = pToCCSID;
 ToASCII = iConv_Open(ToDS :FromDS);
 If ( ToASCII.ICORV_A >= 0 );
   iConv(ToASCII :iConvDS.iConvHandler :iConvDS.Length :iConvDS.iConvHandler :iConvDS.Length);
 EndIf;
 iConv_Close(ToASCII);

END-PROC;


//**************************************************************************
DCL-PROC sendStatus;
 DCL-PI *N;
   pMessage CHAR(256) CONST;
 END-PI;

 DCL-DS MessageDS LIKEDS(MessageHandling_T) INZ;
 //-------------------------------------------------------------------------

 MessageDS.Length = %Len(%TrimR(pMessage));
 If ( MessageDS.Length >= 0 );
   sendProgramMessage('CPF9897' :CPFMSG :pMessage :MessageDS.Length
                      :'*STATUS' :'*EXT' :0 :MessageDS.Key :MessageDS.Error);
 EndIf;

END-PROC;


//**************************************************************************
DCL-PROC sendJobLog;
 DCL-PI *N;
   pMessage CHAR(256) CONST;
 END-PI;

 DCL-DS MessageDS LIKEDS(MessageHandling_T) INZ;
 //-------------------------------------------------------------------------

 MessageDS.Length = %Len(%TrimR(pMessage));
 If ( MessageDS.Length >= 0 );
   sendProgramMessage('CPF9897' :CPFMSG :pMessage :MessageDS.Length
                      :'*DIAG' :'*PGMBDY' :1 :MessageDS.Key :MessageDS.Error);
 EndIf;

END-PROC;


//**************************************************************************
DCL-PROC clearMessages;
 DCL-PI *N;
   pMessageProgramQueue CHAR(10) CONST;
   pMessageCallStack INT(10) CONST;
 END-PI;

 /INCLUDE QRPGLECPY,QMHRMVPM

 DCL-S Error CHAR(128) INZ;
 //-------------------------------------------------------------------------

 removeProgramMessage(pMessageProgramQueue :pMessageCallStack :'' :'*ALL' :Error);

END-PROC;


//**************************************************************************
DCL-PROC retrieveMessageText;
 DCL-PI *N CHAR(256);
   pMessageID CHAR(7) CONST;
   pMessageData CHAR(16) CONST OPTIONS(*NOPASS);
 END-PI;

 /INCLUDE QRPGLECPY,QMHRTVM

 DCL-C IMAPMSG 'IMAPMSG   *LIBL';

 DCL-S MessageData CHAR(16) INZ;
 DCL-S Error CHAR(128) INZ;
 DCL-DS RTVM0100 LIKEDS(RTVM0100_T) INZ;
 //-------------------------------------------------------------------------

 If ( %Parms() = 1 );
   Clear MessageData;
 Else;
   MessageData = pMessageData;
 EndIf;

 retrieveMessageData(RTVM0100 :%Size(RTVM0100) :'RTVM0100' :pMessageID :IMAPMSG :MessageData
                     :%Len(%TrimR(MessageData)) :'*YES' :'*NO' :Error);

 If ( RTVM0100.BytesMessageReturn > 0 );
   RTVM0100.MessageAndHelp = %SubSt(RTVM0100.MessageAndHelp :1 :RTVM0100.BytesMessageReturn);
 Else;
   Clear RTVM0100;
 EndIf;

 Return %SubSt(RTVM0100.MessageAndHelp :1 :256);

END-PROC;


/DEFINE LOAD_ERRNO_PROCEDURE
/INCLUDE QRPGLECPY,ERRNO_H
