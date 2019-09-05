             CMD        PROMPT(C000000) PMTFILE(*LIBL/IMAPMSG) +
                          TEXT(*CMDPMT) ALWLMTUSR(*NO) HLPID(*CMD) +
                          HLPPNLGRP(IMAPVW) AUT(*USE)

             PARM       KWD(HOST) TYPE(*CHAR) LEN(64) VARY(*YES +
                          *INT2) CASE(*MIXED) INLPMTLEN(32) +
                          PROMPT(C000001)

             PARM       KWD(USER) TYPE(*CHAR) LEN(64) DFT(*CURRENT) +
                          VARY(*YES *INT2) CASE(*MIXED) +
                          INLPMTLEN(32) PROMPT(C000002)

             PARM       KWD(PASS) TYPE(*CHAR) LEN(64) VARY(*YES +
                          *INT2) CASE(*MIXED) DSPINPUT(*NO) +
                          INLPMTLEN(32) PROMPT(C000003)

             PARM       KWD(TLS) TYPE(*CHAR) LEN(1) RSTD(*YES) +
                          DFT(*NO) SPCVAL((*YES '1') (*NO '0')) +
                          PMTCTL(*PMTRQS) PROMPT(C000004)

             PARM       KWD(PORT) TYPE(*DEC) LEN(5) DFT(*DFT) +
                          RANGE(1 65535) SPCVAL((*DFT 0)) +
                          PMTCTL(*PMTRQS) PROMPT(C000005)

             PARM       KWD(REFRESH) TYPE(*DEC) LEN(2 0) DFT(*DFT) +
                          RANGE(1 60) SPCVAL((*DFT 10)) +
                          CHOICE(C000007) PMTCTL(*PMTRQS) +
                          PROMPT(C000006)
