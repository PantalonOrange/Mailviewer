**FREE
//- Copyright (c) 2019 - 2021 Christian Brunner
//-
//- Permission is hereby granted, free of charge, to any person obtaining a copy
//- of this software and associated documentation files (the "Software"), to deal
//- in the Software without restriction, including without limitation the rights
//- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//- copies of the Software, and to permit persons to whom the Software is
//- furnished to do so, subject to the following conditions:

//- The above copyright notice and this permission notice shall be included in all
//- copies or substantial portions of the Software.

//- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//- SOFTWARE.

/IF DEFINED (IMAPVW_H)
/EOF
/ENDIF

/DEFINE IMAPVW_H


DCL-F IMAPVWDF WORKSTN INDDS(WSDS) MAXDEV(*FILE) EXTFILE('IMAPVWDF') ALIAS
               SFILE(IMAPVWAS :RecordNumber) USROPN;


DCL-PR Main EXTPGM('IMAPVWRG');
  Host CHAR(64) CONST;
  User CHAR(64) CONST;
  Password CHAR(64) CONST;
  UseTLS IND CONST;
  Port UNS(5) CONST;
  RefreshSeconds PACKED(2 :0) CONST;
END-PR;


/INCLUDE QRPGLECPY,PSDS


/INCLUDE QRPGLECPY,SOCKET_H
/INCLUDE QRPGLECPY,GSKSSL_H
/INCLUDE QRPGLECPY,ERRNO_H
/INCLUDE QRPGLECPY,SYSTEM
/INCLUDE QRPGLECPY,QMHSNDPM


/INCLUDE QRPGLECPY,BOOLIC
/INCLUDE QRPGLECPY,HEX_COLORS


DCL-C FM_A 'A';
DCL-C FM_END '*';
DCL-C DEFAULT_PORT 143;
DCL-C TLS_PORT 993;
DCL-C MAX_ROWS_TO_FETCH 60;
DCL-C LOCAL 0;
DCL-C UTF8 1208;
DCL-C ASCII 1252;
DCL-C CRLF X'0D25';

DCL-S RecordNumber UNS(10) INZ;
DCL-S PgmQueue CHAR(10) INZ('MAIN');
DCL-S CallStack INT(10) INZ;

DCL-DS LogInDataDS_T TEMPLATE QUALIFIED;
  Host CHAR(64);
  User CHAR(64);
  Password CHAR(64);
  UseTLS IND;
  Port UNS(5);
END-DS;
DCL-DS SocketDS_T TEMPLATE QUALIFIED;
  ConnectTo POINTER;
  SocketHandler INT(10);
  Address UNS(10);
  AddressLength INT(10);
END-DS;
DCL-DS GSKDS_T TEMPLATE QUALIFIED;
  Environment POINTER;
  SecureHandler POINTER;
END-DS;
DCL-DS MailDS_T TEMPLATE QUALIFIED;
  Sender CHAR(128);
  SendDate CHAR(25);
  Subject CHAR(1024);
  UnseenFlag IND;
END-DS;
DCL-DS CommandVaryingParmDS_T TEMPLATE QUALIFIED;
  Length UNS(5);
  Data CHAR(62);
END-DS;
DCL-DS MessageHandling_T TEMPLATE QUALIFIED;
  Length INT(10);
  Key CHAR(4);
  Error CHAR(128);
END-DS;

DCL-DS This QUALIFIED;
  PictureControl CHAR(1) INZ(FM_A);
  RefreshSeconds PACKED(2 :0) INZ;
  GlobalMessage CHAR(130) INZ;
  RecordsFound UNS(10) INZ;
  Connected IND INZ(FALSE);
  DominoSpecial IND INZ(FALSE);
  LogInDataDS LIKEDS(LogInDataDS_T) INZ;
  SocketDS LIKEDS(SocketDS_T) INZ;
  GSKDS LIKEDS(GSKDS_T) INZ;
END-DS;

DCL-DS WSDS QUALIFIED;
  Exit IND POS(3);
  Refresh IND POS(5);
  ReConnect IND POS(6);
  CommandLine IND POS(9);
  Cancel IND POS(12);
  SubfileClear IND POS(20);
  SubfileDisplayControl IND POS(21);
  SubfileDisplay IND POS(22);
  SubfileMore IND POS(23);
  LoginColorGreen IND POS(30);
  LoginColorYellow IND POS(31);
  LoginColorRed IND POS(32);
  WindowErrorHost IND POS(40);
  WindowErrorUser IND POS(41);
END-DS;
