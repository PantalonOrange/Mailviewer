**FREE
//- Copyright (c) 2019 Christian Brunner
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

DCL-C FM_A 'A';
DCL-C FM_END '*';
DCL-C DEFAULT_PORT 143;
DCL-C TLS_PORT 993;
DCL-C MAX_ROWS_TO_FETCH 60;
DCL-C LOCAL 0;
DCL-C UTF8 1208;
DCL-C ASCII 1252;
DCL-C CRLF X'0D25';

DCL-DS LogInDataDS_T QUALIFIED TEMPLATE;
  Host CHAR(64);
  User CHAR(64);
  Password CHAR(64);
  UseTLS IND;
  Port UNS(5);
END-DS;

DCL-DS SocketDS_T QUALIFIED TEMPLATE;
  ConnectTo POINTER;
  SocketHandler INT(10);
  Address UNS(10);
  AddressLength INT(10);
END-DS;

DCL-DS GSKDS_T QUALIFIED TEMPLATE;
  Environment POINTER;
  SecureHandler POINTER;
END-DS;

DCL-DS MailDS_T QUALIFIED TEMPLATE;
  Sender CHAR(128);
  SendDate CHAR(25);
  Subject CHAR(1024);
  UnseenFlag IND;
END-DS;
