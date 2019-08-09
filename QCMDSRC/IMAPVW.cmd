             CMD        PROMPT('Simple Mailviewer') +
                          TEXT('Simple Mailviewer') +
                          ALWLMTUSR(*NO) AUT(*USE)
             PARM       KWD(HOST) TYPE(*CHAR) LEN(16) CASE(*MIXED) +
                          PROMPT('Host')
             PARM       KWD(USER) TYPE(*CHAR) LEN(32) CASE(*MIXED) +
                          PROMPT('User')
             PARM       KWD(PASS) TYPE(*CHAR) LEN(32) CASE(*MIXED) +
                          DSPINPUT(*NO) PROMPT('Password')
             PARM       KWD(SECURE) TYPE(*CHAR) LEN(1) RSTD(*YES) +
                          DFT(*NO) SPCVAL((*YES '1') (*NO '0')) +
                          PROMPT('Secure Connection')
             PARM       KWD(REFRESH) TYPE(*DEC) LEN(2 0) DFT(10) +
                          RANGE(1 60) CHOICE('Seconds') +
                          PROMPT('Auto refresh')
