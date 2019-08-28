             CMD        PROMPT(C000000) PMTFILE(*LIBL/IMAPMSG) +
                          TEXT(*CMDPMT) ALWLMTUSR(*NO) HLPID(*CMD) +
                          HLPPNLGRP(IMAPVW) AUT(*USE)
             PARM       KWD(HOST) TYPE(*CHAR) LEN(16) CASE(*MIXED) +
                          PROMPT(C000001)
             PARM       KWD(USER) TYPE(*CHAR) LEN(32) CASE(*MIXED) +
                          PROMPT(C000002)
             PARM       KWD(PASS) TYPE(*CHAR) LEN(32) CASE(*MIXED) +
                          DSPINPUT(*NO) PROMPT(C000003)
             PARM       KWD(TLS) TYPE(*CHAR) LEN(1) RSTD(*YES) +
                          DFT(*NO) SPCVAL((*YES '1') (*NO '0')) +
                          PROMPT(C000004)
             PARM       KWD(REFRESH) TYPE(*DEC) LEN(2 0) DFT(10) +
                          RANGE(1 60) CHOICE(C000006) PROMPT(C000005)
