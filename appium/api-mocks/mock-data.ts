export type MockUser = {
  email: string;
  name: string;
  pub?: string;
  pubOther?: string;
};

export type MockUserAlias = {
  sendAsEmail: string;
  displayName: string;
  replyToAddress: string;
  signature: string;
  isDefault: boolean;
  isPrimary: boolean;
  treatAsAlias: boolean;
  verificationStatus: string;
};

export type MockUserName =
  | 'e2e'
  | 'flowcryptCompatibility'
  | 'dmitry'
  | 'demo'
  | 'robot'
  | 'expired'
  | 'revoked'
  | 'sunit'
  | 'ioan';

export const MockUserList: Record<MockUserName, MockUser> = {
  e2e: {
    email: 'e2e.enterprise.test@flowcrypt.com',
    name: 'e2e enterprise test',
    pub: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email

xjMEYUsiUhYJKwYBBAHaRw8BAQdAWssVJKjkDqTo78c6oRUWQzBU5EeM1jyt
sIYX7PzZh9bNOGUyZSBlbnRlcnByaXNlIHRlc3RzIDxlMmUuZW50ZXJwcmlz
ZS50ZXN0QGZsb3djcnlwdC5jb20+wngEExYKACAFAmFLIlICGwMFFgIDAQAE
CwkIBwUVCgkICwIeAQIZAQAKCRClTYK+FSHSDrWUAQDGmiilgW1Q97JzZ8eN
yevvnYl7FTNTGBiX+O9pFGaSdAEAukBYMV5fMXQihUdOQ8dL6Tfp7QQ4tuKo
I52QCvp1bQTOOARhSyJSEgorBgEEAZdVAQUBAQdApW7iwSvECJCJqHXevZCN
Pt3xHiaWNLd/gKeMyFuhYU0DAQgHwnUEGBYKAB0FAmFLIlICGwwFFgIDAQAE
CwkIBwUVCgkICwIeAQAKCRClTYK+FSHSDsUNAP9+YFUHDOCxJLmv6HZI6y2o
3HWm193CuAoB2mWLEg6cnAEAoiq3T6s5r5X880Yx+VdJSHposEtzbQtBrzl8
9//SbQE=
=n4ak
-----END PGP PUBLIC KEY BLOCK-----`,
  },
  flowcryptCompatibility: {
    email: 'flowcrypt.compatibility@gmail.com',
    name: 'FlowCrypt Compatibility',
    pub: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email

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
eg==
=CvEL
-----END PGP PUBLIC KEY BLOCK-----`,
  },
  dmitry: {
    email: 'dmitry@flowcrypt.com',
    name: 'Dmitry at FlowCrypt',
    pub: `-----BEGIN PGP PUBLIC KEY BLOCK-----

mQENBGO1G0UBCADsg6ya56eXsPYrY2dUSwv72bXIrkxBdw8QOLm7rSPZ7jcS7XAO
pK6LGNWZFVWRgIyBXRTCWn2oRT73xxhztQNg1T3pX+QvFR4zbzLwD45lD8NkRTgX
0MD5/f/lShmRsnUtlh9emnQ5GZHNZvCOhOl8Ns9h+I8VBwvXzkY+tkKnpHTuiR8w
dlZOEzUwL6PP8jsUHRBRzeriulCYEBlm302cOsc/GHnNzxVMp9bq4bKBjcf+FiEP
aMug4IGpbAP28qoBM1i1p9pktLmtlU5iUjgzAnZpmWCSITQICKQBc3FCb8WrOvqV
FvYH/m/zJOFY7Gyi0TKtDlZkOogpMx9LxRS5ABEBAAG0KkRtaXRyeSBhdCBGbG93
Q3J5cHQgPGRtaXRyeUBmbG93Y3J5cHQuY29tPokBVAQTAQgAPhYhBLafnGYUQ1jJ
FYMShEtuR/gJbQF6BQJjtRtFAhsDBQkHhh9xBQsJCAcCBhUKCQgLAgQWAgMBAh4B
AheAAAoJEEtuR/gJbQF6dD8H/jfsZXtLcW3hwo0CdzaGVghMX82sAJ1xeGPdzfCk
JcwP9kazph1T7Tfw8JRVXYwYtXgwFo/MqDHHYjS5qrHT2jq/QGkexTzTXa4ZgAYb
78my9oJSCAgu9Gu0V166gtSf1idS3UwsNt86R0TWab+BW27NTbyZWf/UeSjIuGYj
fa1MZn89BiY35PQ5pj6mxSLWFtSUqCqEdTTmwgU1g9TBVLZlY9YVjr4uKkAT42Mb
eEFeHqwvhIImhdWaV3zRG1ZLDvZqnWPVFXW5v2iSmURd6DqjTGCvUcc00v/88uCE
Z7RXV9dOvAnhXfFP4bE0RCnilnm4lzk2f5OrOAA4AOGYRay5AQ0EY7UbRQEIAOnn
/Airyjbb+ndI/LIsmlRmOy5lxCkisMNBrWPFNgQnZ3xheEVZJsGt9fUp+mzIxRE9
ZixQ3tSVNLQzBNSliR1khOEtpjrCosyCttR0Vi46sRtyD5gnWHOHNxYh0gU7XcWR
xHzNBp787hlOwjFDGhdttuTrvvfhzut0rrIq9VzGO5+zTKQlytTh/sY5Ph83Ey5z
DXS6RCWR+WG+RIVU+1CPnc3r+vOABYRSNGLT9CG+jSXU0TiH39cscoEOH51fQwW1
bTvoO6tk+hG7vGQZieHSilsVdrpLM9nePncgdkqiGkj3WqThC5cS7A9/Cu+arNt/
cDP/Aq67wzlLuzXDjj8AEQEAAYkBPAQYAQgAJhYhBLafnGYUQ1jJFYMShEtuR/gJ
bQF6BQJjtRtFAhsMBQkHhh9xAAoJEEtuR/gJbQF6ViIIALwYJkgivrUTGo1/OWWD
M/rW5clbIpZL1acDnX22UV0k1agWuOIM4Bxp3EK0CAb3ZCsL99I6e2bX4ahxgRdo
NHbaw0Pj5D4xJY+i1mQynGeZbFYHwZuua7EkSnaYbI2MQp8Ype3ddKOJq2vLpUtC
xK7YajkMQZoTD3mLCQJ3tEooPOpE5mwUXHFpECHmVYv4sZPmmHprHJZMM9AUbNWW
Ek3/pYmX990q/ImHS65gZtXIP+Yn9DBYYvTJB01SV3mBfJH+bUvf7b3zfrxaQdFH
ndymJ9sE8hw6DwM3MU6AODwq+xLV1c3l55LkOKs+rFFXEX0ksxZmHVxOZ1D8wgHQ
dko=
=2NQp
-----END PGP PUBLIC KEY BLOCK-----
`,
  },
  demo: {
    email: 'demo@flowcrypt.com',
    name: 'Demo User',
    pub: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email

xsFNBF9gkx8BEACbj4r6GTcJAMsQ0vV5EoHQ/hXuCOix8+2A0E1x2I/SryFk
ghe4cL7srUl1QXstoX+coc8ibDTZ6k66GcomvvEQf7LAtzl6hswFYUro1V1c
x85BtmuKnlVaUkbokxpS/NO0o1RSWq91SRh8OO8dPvVAV9JVoosg7vBhQMLr
xoeS/sH0nZYWwSyRVKJG01rM06/Hq6QK90KIneV37N8ocrKjm340w2o6EACw
dSMW0ATW1X3xmPkTci5WDG5VQlqdSWDEtBINMZbIKRilFNWD8NgOX8KjhPrZ
/eQSJYJYlB4slQYgQbJk58USb0GdmmB1nTyjXK58luxssjXhx1F1k37uGWao
R2PozMrhpie4CmaZP8pR+pd9v3Mt8DkTlnK1xOE2//KvbmdlsreimLMHsdDy
/Px0J4glPaDE3I8W7G5vV+3iB8KoIDB4rmOKt7pc13r9hKq9DXVyWzdHi56t
cAPIs0ZJx7h1iPkN14QqZkq/H8uwtm1GJ7EDUZPX89/ThW/XE0Qs1wM0ICwG
SXXhgsfAa8cfxG+Z7CsfVAV/h5pOLXqDUeGJ3UxFPWuBvHGabng4oSYY0CZC
rODbiIV94qKYx3FQMnEVPAkb+Wwr2nSYuqt49zyK4hAfZErTp/+GGjXe2Om9
5JMaHNKVZOuroLrmsm0UsfqmUYSsLi2++0OUnwARAQABzR5EZW1vIFVzZXIg
PGRlbW9AZmxvd2NyeXB0LmNvbT7CwZMEEAEIACYFAl9gkx8FCQHanAAGCwkH
CAMCBBUICgIEFgIBAAIZAQIbAwIeAQAhCRAki2DrbQRN+BYhBAmXf29RLKWt
dvDCECSLYOttBE34yz8P/jPR5Y6xBPiGotDxStU9rKprLjfTqjAMs8xUhr7z
bLC0dMcLYlPwR74I39t0iNl8/sr2f7dLfKANOnbngo9qAwg+0UQPFVLay4Yp
1w6MfYMGqtqC+0AgFwHGKUo1i4Z4ZSK6ZYJVE1cOztW80xCUP6PscHgxh7pk
+qMbF/ju8fGm7N5f4+eJ+5cq8GRKX4QyxWJbDqKjcNKFHYKj/wdu/l5eTNS5
w6dPMXmy5509aSGMSGriYPPehGJVTAy4tCP51H+tDa4gHd82KTOd+kDeof25
gB+ovWo4Hs1p/B8putBwFRYqrAwcr0ihirS3LZdIIF0yEaEm78PfGXtrissI
7H/DwNHAwmcd09ZXbiXp8rfOftKY+GxhnnpY/ahD5QXALQEnqBjVRNI32FYJ
jxDYWGksqrTq1SErltT+tPJlo1E07qi9jjjk0+Z3MrWOOBPjOlvD5aVMa3aU
XUu8ei/bR/GWOssZVmEV70z2+rDF0Y16i5ipmYzjF2QURjG7wT4IAv5FOdAq
tWfYg6UvGM5SwY5gASn11oaJnGVLxIY29tPy3YuM0hb/RtUo6n3HjmGYTQr3
sZuaEJT58OpxRYi7cMoWypKc34ICm2/7phNehOkiBqx8Z44TPsGKS/AZqYOj
LgjbT6DgLUcIDPbksrPkLgIJIXKEI68b61Pl/oebrcrkwsF8BBMBCAAmBgsJ
BwgDAgQVCAoCBBYCAQACGQECGwMCHgEFAmFJyyMFiQO8keAACgkQJItg620E
TfgLzxAAgUdGsOy6AgbipBquu1hoDgHGF07A/UWVATcyPFZIoRXonyHV3fxf
mCf4+ZlfIub+YT4/+/4baCqTbPr8SciK8UuMOaM1sG33HWz03jqP8MeaoprQ
ayxGKS8nDjMQ1y8oRXrSQLH/qKE636wv6dF7VCRDyhpUpaBAxvFZgEs68qjl
6MafagmrurFuSkT5WtIGBOS7LbjV2vrqoTYXga9jjvDjrWcSPuJfK1eomMEM
11dlsmwtRYTShoHyGpzQi8BrV09Qm0TiupIyKiasyG+sOLWRlKlJXOPBHBdb
vcofMnVENTA0KzjzEy2SQG7NCktXeiMOYdZN7QAnG9/rItUcMK+CmsxFbwMQ
LV2CS+BEPz8zEpAsP+0qI/qQd+z2ZM0Fyr6x1Pj2olnbo0wlYg6Bvldrj5A0
SRep3zcJnbdYbIjV77cZ2LALt1WZFjxXKRsoUX9aP3JxdK5v6TuQXeNZpBWu
YlbOLonYbtJPnGdbt7etSgJNmCkD/o2Aobyb9MmmaeUQaQoeBsxhrmiShFqb
OzyOcSpI8Xv31Hal1K6bLf2XJWcsNz5SgPpEaPKgMVFHLekQSSO1AT9a0ZHh
5B4MUUetjA26ePqPYJaKIV9qClPyWNWDwRMsCP8pwZfg6Eh/8STYzM4whYct
hjRFwuBIgB2kDJPk7lnIunSXL6P4NcjCwXwEEwEIACYGCwkHCAMCBBUICgIE
FgIBAAIZAQIbAwIeAQUCYW8CrwWJA7804AAKCRAki2DrbQRN+MtyEACThD+e
bjQD5ucjvW46rnn0vvNzNO1ipVQ0bNjpUI8zSegA3go/X//cbmqKXmmbxtjS
jncfSHzVkiFkzmXUWQWNrXYEh7cmy6qN1wG4CcNRklkqs3pjZJ8hqhsavFjE
KwORrNFGJy1gj37gKF0Stj3h37CxGjUB6vT46B+Or54HfKxDGPhrZDtkKOoC
UxGsnvGIZsOGFnkb6MugtOcxnCO3GB5adCJdQi0DZm7O3rRijpp+XUolhfq/
wx3daWu1PnopqAzsn4tDTKfldk7mxhn/Oxvy0ax53PwDnIbmVl/mnhphBj1q
ofJCtQdTlc4m3DGWM0M8JouvmmknOi4yO3woZHFQd0ecShC3o7H7ogAYS8aA
W8O+1PA7GjCImasJ0MFEaSfsTn9RTgi1d7Rj550dZdo6mXZ9j4hYNhbusvX7
ndHHNFIJFJ3EL3E1M3c21addMc1qy8gHXcOzOHjSJuGFExGPPyzFdJkoTD32
BcvU3O3VGVvayZhKJInF+90LKkkbdS68I017637Wz6RlsezcgRZ6oxB0lGZV
idlNpMChdUp83mvvjSK0OzbDJRhD47Pc76rDow3LASHUsKLomXmMslgWa76i
0udT3mIQYU7Hp9bIju4Pwd98ANu7c2wYLNhx6fDTNdtHB4b6YH/Rv00dOIYV
/t6pZNV8yiDy5Icfx87BTQRfYJMfARAAp+ciZ5kXt7YPRaMhHLyATintCxao
beLiq4BRSSYPnIvdGiMHzNst/n9AFUfQf5rZLOggfred5amhtqPvkyyxsKtZ
GXoeSqHN7lrZwI8ddjUHcJ9VZeT0+ABvGjqusk8r3pJPYLaSekk/QG3XiKiP
lfqiOXHI+TBrupdqkC34D3wshDaeAPXiKn6pRzfmF3EiQFOn2ltD28kqQYaD
fuNTwYNqxS+1cstZWc/8z87d8l8s95EqdmFt/5V5O2PNbzb6wrpsMD4Nk7E8
B+lNmRkikiBjAAL3f3efhwEjUiFCrp5PL847L0/CgxLC9Ps0p2Afyf9Raitb
W8UZ8wcujDD7lHkCSK7MBDe1dQTFRlrR5uA0noIDNxe19kWwOGsJCU/SO+eN
u7kd6dqhJLHF4dFsfFYVf4p8LixkE9gkefl1rXYUtBlA3QFh5C+e88I0lnbg
96WRJeM4TKb/kC2cw7AQt/RUIDnqNkQFt03fT8T9cTOnCAU3Tj5a3Pwlrd1Y
yz6HViZJxSkPSuZGz8PtlUF+5O9JvAT/6lmzSXvPhtPbR3ioCOVV7Za6y/Ue
512JIgVu7dXvckQvJjJYAZWH/E/Xayg5gEIhoP0daqVxqJs9cFzRGaHWULs0
hYwsvA/scsbAJkkxa4qBBsWJF8kLNTGog0G3dyjoamquQQ823N5j198AEQEA
AcLBfAQYAQgADwUCX2CTHwUJAdqcAAIbDAAhCRAki2DrbQRN+BYhBAmXf29R
LKWtdvDCECSLYOttBE34rqYQAJWjwTSinx+3C8lmJdIPrlBVAIRgUgMN6vJ2
/shSkaX3+0KiwaD7Dvi3OyoNHl5cgU1DJk9/B8cE3jiIlyjvAWGrvyZOzi3R
9RuPl0FaOad7trnw7vO3Ub5IwKJCAqmQZuq8t7PQL9SWXmF+6IakKM/kDS3i
8bsTnwOkd55p9XtsCDp43PAylqKdfYQSKGmECcJhF0tJMq6989OZdRjcE/ns
GuXe1k74mIF8jwKR3JIWdcJ2ugINv2fVgXlmE9IQQbOjqPUyP0Z6XREPTsXp
t/768KF7qmU/X4KJScLwohGezmhRx5UlzKKrxZTmeuEWF5ygvdsAZZPCf+k8
R1fHl5HfScch8HUGbBF0cvGk3MLr4W0QOk+I8AJyuCXjdOF+3I0EO7uANC2m
O6vmLHvx4e3AhyLcBSuMbgF7cAbJqTW5HgyxRQpa35afi9rKZcTgAXegAn96
hFMz8VL7En8pCzF7utY3C5NQyzaFdoZHIjvhkUjl+INVyj/Fh8I3DMqClhhq
EhwJUMQgnXc893dRevBoj5rXBTpR0tdaehDWE+eHLyjfZ3GtUw9cua04CVeM
AExwSlNZ1jbEIZJNFQTfOYPSwam+rdKY7LNKKhldQJEilg6K3e5gsIvCEcJS
v1f87EnNEeKNrhr3MbuOtTzlsmX6TfmGbu2URe/5ZmJr3MVywsFlBBgBCAAP
AhsMBQJhScsjBYkDvJHgAAoJECSLYOttBE34xogP/00Ehfnj0BVcYWMGdEo+
7CvxAq7t8Pl9KGc1a4V6T2E1IPpnFm2YlyCsxngufU5lQt/tvokAkMk2diZO
yOnsofTg/dTzmPa8WZINCfGji3TDoBHxMvMUDgEaTniRqptT/Q+NdhkQZcTq
mH8jFT7gbyTm/96EBWcv90f1qAng+wraTFnZH6Ndun8TgNyl2Yd68/wkROvk
X8/m/xsgwRxOjmt4FwHDllSvMrM7zMtl1QekmAeS/0fz3KNjWxBn5SeOdNYF
D39KoEwW2J84kbYGTxoLfrrSsvnm+XooPJqVwG8zdf9p/pN9GzbpuRDsm/0S
Q4DcDs/jivFVUYqD8TscVx2eIgFCmAsk28GXx1F5uAwFwYjlpmFAz2VeThFR
utERQhIj0cOBvkbiPuP9dgBoD0maVZcxPoCpAczVN5xsGUJbxgQld8DoNrdO
li/WpY/0pSN5cMraOgyi23XhA+D/zRvx4D/tSEtYzcyOF0dnz0XEDyVSN7Wx
u3N5SU3xhdYlLT2ntX6j0a5x3hgdGUFmc2KJiXJ6m/1XyCtkMpLPYaIEacYJ
yC8tRtP8DmAvrCCmQhheg6qeVaKfMZiFacMYB6Wikpr6d21erxrHSP4+W8qA
IAfWS9fNSAUUFZK+ad90iMVE7A7Em8G50Id3rFqmMNKUyvqOS59ADPFAYnYj
4Y7awsFlBBgBCAAPAhsMBQJhbwKvBYkDvzTgAAoJECSLYOttBE34004P/iLM
y8ICLJnc6evFBZQU7yrR8o41bsJtrANDBAs7k4+f89UhSSIOr/Lj5loTkxin
H7jRvkrLXFo7duqYYavULVHgURLrVvtSjSz/jscYimNsrJHTapR8G3OnJutm
hbt8jhsNw2sU0aGUH0C+p8VOlgf+dYuoC51ZypwwkeBmwcdvJg4SDpvesNHn
u9E6hUdcDPV9vIvUSv3aqGb2q/sNM9aC0/ND494YTr9tNJxcGOCagggZi7QA
Eu6UcdcbrmmIsgTcgruIsoX9jXhC73Jlnfs4aaB2P1pQrsR4t8/csAeQClRU
2UttLMgbgtfKRNJbgCr0fU2bUFbmFUbHCEJal+rsSWOH2BsRm5IbaEUtFVq+
MSkred9uyI2TJRZyTPKCc82b50dxahQVLsjybYFw3o1HJQXe7MUBf5x7cdy1
72qgrQa1k1ptlfZR8TqgHrQ0OA+wQaFxaht7uZxdDIOMVFFEkplMayiiPnlZ
IWhyPr8U2VSxoCMx2QH1MWTlH8QKn7gKPaLLa1b5vBNl2+Bu20HWiVYw4ruk
0frPF4L0oxwFLpdyv9RzcrqvIst5x3Wndvrxeu7OmzNRZ5Hn9rH+NE7lt7uk
RRf7gE5KdIPDRBA5ztKcGfQIpy7+c07GdnAOEm5/yGhJBvusONjQSlEsbtCm
WUDG9MWNHmBREnhXjo+5
=IT6i
-----END PGP PUBLIC KEY BLOCK-----`,
    pubOther: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email

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
Wed/zl8urp0GM8sLA2Q=
=q8Kj
-----END PGP PUBLIC KEY BLOCK-----`,
  },
  robot: {
    email: 'robot@flowcrypt.com',
    name: 'FlowCrypt Robot',
    pub: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email

xjMEYsM6KRYJKwYBBAHaRw8BAQdADKgbtPI+a+2y/fDh5CxVqvc6wbSvmMe3
TcSHCT+Go/XNJUZsb3dDcnlwdCBSb2JvdCA8cm9ib3RAZmxvd2NyeXB0LmNv
bT7CdwQQFgoAHwUCYsM6KQYLCQcIAwIEFQgKAgMWAgECGQECGwMCHgEACgkQ
9OtwbUUrhUR8qAEA802mHSF6vtppMqUFBAKduJX8LmrKtX8FssMcq/9HTT8A
/R615Nm1seyrNuC2J2TdTqYG5O2i6fUWlqGldOzrwpYOzjgEYsM6KRIKKwYB
BAGXVQEFAQEHQJ0nskrHuPK0drUMJOo3j3VPVxdEDudw1mlaLowJfl0TAwEI
B8JhBBgWCAAJBQJiwzopAhsMAAoJEPTrcG1FK4VEh4YBALYL4hcYE8/nUgHd
i0Bd7uutnnkRdCDPTvY5ub4ZDrHGAQCFIYc+Mp6zZdR1s/3kIpjrcg6mOtmj
7Xox/a0FLLQsCQ==
=+AGT
-----END PGP PUBLIC KEY BLOCK-----`,
  },
  expired: {
    email: 'expired@flowcrypt.com',
    name: 'expired key',
    pub: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email

xjMEYW8A6BYJKwYBBAHaRw8BAQdAcdakYLj0UoCYB+atCEkNjUP7SSD7r7iq
VRkrZjqpzafNI2V4cGlyZWQga2V5IDxleHBpcmVkQGZsb3djcnlwdC5jb20+
wngEExYKACAFAmFvAOgCGwMFFgIDAQAECwkIBwUVCgkICwIeAQIZAQAKCRAv
B68u47oY6BfyAP4/fDJuxAsvo8XQ3N4ovA9D/H7VyTnu89ku8pKIQImhgwEA
0Mkinhg3eYtc5eG8BVHXZyFNte+JIKLwJPxv3NZ6KQXCfgQTFgoAJgIbAwUW
AgMBAAQLCQgHBRUKCQgLAh4BAhkBBQJhbwE3BYkAAayXAAoJEC8Hry7juhjo
92sA/AovlTncTQHb2+JOnha3WCPraiiUjdZTPlVksz0yZTMlAQCfI0E0WnKV
1W9uXaBZMTkSzzv0BTtSr9MNAMhl+52HB844BGFvAOgSCisGAQQBl1UBBQEB
B0Ace7wKz8QEpIf3B17RiX185nwA0nUe8Ng+SYrT/inxXQMBCAfCdQQYFgoA
HQUCYW8A6AIbDAUWAgMBAAQLCQgHBRUKCQgLAh4BAAoJEC8Hry7juhjo4z8B
AIxiBFwVSeC80FX+DrBEPH2tZURnoJnqNzcf/Hz03gp5AP90vsuJHXLyd+xx
nGjRZ3go4jom7MU77w5GtHuvfObRC8J7BBgWCgAjAhsMBRYCAwEABAsJCAcF
FQoJCAsCHgEFAmFvATcFiQABrJcACgkQLwevLuO6GOgHPgEAhfcecP1GG/dp
1sbpsBfwJJKK+bJhiyYlB5izgpxslk4A/0wNujSC9MOusPziwgebviKxZQXP
T4gbgCg6JBONQ8MM
=Cabr
-----END PGP PUBLIC KEY BLOCK-----`,
  },
  revoked: {
    email: 'revoked@flowcrypt.com',
    name: 'revoekd@flowcrypt.com',
    pub: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email

xjMEYW8BThYJKwYBBAHaRw8BAQdAYtEoS4d+3cwQWXcs3lvMQueypexTYai7
uXQmxqyOoKrCjAQgFgoAHQUCYW8CLBYhBDkxt0E9uy+mDO+Fzl8Vl4kQoXgK
ACEJEF8Vl4kQoXgKFiEEOTG3QT27L6YM74XOXxWXiRCheAqk5AEApn8X3Oe7
EFgdfo5lkgh6ubpmgyRUpfYHkQE2/S6K+T0BAPGs2py515aUVAgiRy7bJuoY
DKKbOPL1Npd0bgenKgMGzRVyZXZvZWtkQGZsb3djcnlwdC5jb23CXgQTFgoA
BgUCYW8BawAKCRBfFZeJEKF4ChD/AP9gdm4riyAzyGhD4P8ZGW3GtREk56sW
RBB3A/+RUX+qbAEA3FWCs2bUl6pmasXP8QAi0/zoruZiShR2Y2mVAM3T1ATN
FXJldm9rZWRAZmxvd2NyeXB0LmNvbcJeBBMWCgAGBQJhbwFrAAoJEF8Vl4kQ
oXgKecoBALdrD8nkptLlT8Dg4cF+3swfY1urlbdEfEvIjN60HRDLAP4w3qeS
zZ+OyuqPFaw7dM2KOu4++WigtbxRpDhpQ9U8BQ==
=bMwq
-----END PGP PUBLIC KEY BLOCK-----`,
  },
  sunit: {
    email: 'sunitnandi834@gmail.com',
    name: 'Sunit Kumar Nandi',
    pub: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: FlowCrypt 5.4.5 Gmail Encryption flowcrypt.com
Comment: Seamlessly send, receive and search encrypted email

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
o1d1DZEzW3nPw0sDbc0+uM4bcmiI1HxCe4uScjdvyyiXtHEOjMdYC1wNdO8l
j+7NR1N1bml0IEt1bWFyIE5hbmRpIChTdXBlclggT1MgUHJvamVjdCBieSBM
aWJyZXNvZnQpIDxzdW5pdEBzdXBlcnhvcy5jb20+wsGOBBMBCAA4AhsDBQsJ
CAcCBhUKCQgLAgQWAgMBAh4BAheAFiEEglkq+DKBxFfUZtcuQwiLA24wZPsF
AlrbogoACgkQQwiLA24wZPviSQ//d6NvU/0/QKLZQKMpvAQp3o5XsIMqBA6K
Im1AzvdIK7xwtsxBp2viWSp8LgutZzQ4MejNzr8ptY6ABHcJOzKdBFHoP1ju
8ejCXWs2+5yihs5+5w33x6Epf9tj0ORf1A1RA1YVimJJBptiBMPkRFge+BSm
yYXRTlSyS5vw5YD/7ugeGWOnaH4UcXLQgnYr4IU3ieKiBVAg7XWY+UdpXVVd
CQ1BiERWtHmUPWL60MgaAGAKJvyByVSUuP7D4fWJGSfcdge3GKtO0EFI2CFW
Pgxc8tXCSSpeVBX7AQpCewR3iqJYpCNaUURahUzrGgR6vBXf0RNTNWKpW96s
PmEFgsKEbVu7WovRbYixuy7+a2ZTLE7WdaYn6rtNvQ32uFcNORXgEMlGbaJx
PGiBTkNZjZiZ4SZqIaRrdnUcm3d1JNwaSASO1Lm0CtWcnr4sUHVs1HAhrsK8
AIruATD+1AzAZdmTPXBuIE5xAnj1f2UnrUd6Gmrapu2Ut49HyuJENvTPQHz7
MRUPma6O/N0IWVJcReG1XTB6csCzoJxD/XpPAZsreDG1N5oLFX7EOZHzudcU
4P4AsiUFYofLK59Xs2NluGGI/9aREebk0F6r6DkXbMy3pHBUD+nFfMaGo/mA
wCi2CzgvjJ6gA9fZUbjfeRZA83/WHJ96PAcIWVavd+/LsDx08cXNN1N1bml0
IEt1bWFyIE5hbmRpIChOYW5kaSBGYW1pbHkpIDxzdW5pdEBuYW5kaWZhbWls
eS5pbj7CwY4EEwEIADgCGwMFCwkIBwIGFQoJCAsCBBYCAwECHgECF4AWIQSC
WSr4MoHEV9Rm1y5DCIsDbjBk+wUCWtuh9AAKCRBDCIsDbjBk+9JmEACfOmZo
bM/ltMBvzNR5T/8wjEAj09BotmCtEfqyxwsN1pM7FNeqsvsE1EBz6Vh4dFjO
kDVx2/P4YjopXNDYvBnWnSYdk74BE+4XjZ4t+dereB+KPmdbQGp7X5wVLv13
dIciBIbQc0NGLHFEAN2ZxXi0CX+yZy4fQlYwp6ejPTbe2Ayd5mM347LIuRo+
zl7oRvziBueFHLBbs4OE9RWYlQwKji5k8k+eqWDwyG/VeuIcVdR7/jlDOjlI
/baKi/nwrHe3oF1t2j/m30NHnZdc9vZXVDhlyv9wS4Bv+nS1v+g0KkDZZdlJ
gCjIB6c5+escMbSPTsNEEDmZ/abZNzgEZRj9JQ2CPIgPhLJUH2e8hc82BON4
txtTrXxixb2fBD1W/H6VtcOMv6prKRIbUh3dyozfKKosBd9CnkLrKC3UZCj9
TQxfWvHdGA3Vc9jpiCDxHfoe1mwVSMU0tHknk4pLvUOyqxdZ4l70RHv4dOoj
EAJQAcQvC8mbfXjxLv3nzBynBVQfwLpcBOuv/LdgEoSqVJpgaVJ09YVag5MU
mFKQ8bfg7aFv+YHu3vywK1drH4tdFNdyklq6GBznGwH1lHREVG7ChLYq6GIH
mBt1Vp7Au1ay12jiMp7v/qXz0g38r4xliRSIdV0WAHFaVZG18hjT1yzmm0/P
U1p8ko9FCCC4WLIdGs1SU3VuaXQgS3VtYXIgTmFuZGkgKEV6ZW4gU29mdHdh
cmUgYW5kIFRlY2hub2xvZ3kgUHJpdmF0ZSBMaW1pdGVkKSA8c3VuaXRAZXpl
bi50ZWNoPsLBjgQTAQgAOAIbAwULCQgHAgYVCgkICwIEFgIDAQIeAQIXgBYh
BIJZKvgygcRX1GbXLkMIiwNuMGT7BQJa26HhAAoJEEMIiwNuMGT72YgP+wcy
TwaPYnLvJZ0lY3BIoNEK3hAmq5qdvsuAGxW+34TeGHO0gfKRpZr04wu+JFVO
a0pE/QihTxNuy8qNCl3Fb+YkIfZy02jjR5OA7/okLZeCphFkC6vsxjf0LOs0
lbSaz8cb2vsa6OaezCHZ3coUbpyvxs/Dn6781Baw+fI/VtlBl6sXXcHuJKg9
sr7tq5CH65ez8hUzfqjIUrwzGrBCauwNcf+dP4ZsrykMTCYIpJ1JaaZDeuKU
OPGe7ToIQ21XAXha37jwWQRxTwvbEFoTHu98DEl9RDRQrshLYh9m0saNvoK5
v+2mVsCwfXZMnMgv7Z2bnnHjFpq1Yd8CwKF38K7Q26gHURybSNNryHMSEeOx
5vC1sCiaySB2fbc7gaB7a3W2kUH70a1ZLo/BcyXqdQDnP6MT5NffSkPhe/z7
MZubFC30OZ27XFF+yz8qY9ztJMudnUNbFZ96tnVQCAnJZL4qNBmy9spkrWfV
5gHOWxtspdC1lA5XriZV0W/xxffuzivGN7no5W9x+0Nrp1Dey9P8R9wfFbF4
La2QSLiO6Ojl+YHqPHLQYL46pWjaBz/SzKIDPZvxpCjIwsyEHqHIz6NRSLr0
/0PSyst7Bh+oQgI4ZMqNF+9RvhsJ63uZsymhsn/gyU2IWDR1jigjrKT4aVhO
PKSb4DZm2Rh/tBTp91FGzTZTdW5pdCBLdW1hciBOYW5kaSAoUGVyc29uYWwp
IDxzdW5pdG5hbmRpODM0QGdtYWlsLmNvbT7CwZEEEwEIADsCGwMFCwkIBwIG
FQoJCAsCBBYCAwECHgECF4AWIQSCWSr4MoHEV9Rm1y5DCIsDbjBk+wUCWtui
JQIZAQAKCRBDCIsDbjBk+3LND/4tySeoMfKleQBJID1nKOdRmDOk9MgcxD9r
WmMR9hR3HskQ3CoiWzhG+NXMthyp2Z8mdZtP62XbGiuXUVe3Ed3fF1DiQmZH
lRKHP5k0hXMDBCc4B+L+GZnOB9qwq4D1zMCxtfcQ+pr5D5iAAnjqxYgTXSOa
A/ejutqEbv0PLqoD4xBbwOURQyPaTbBjkzppq9B/Vk05xhFcs+0DcbWG6Cmb
eNCmHMfBopj4AOIfvn6G2wHG6N0jCFFNBtiVVFFL5kiyfGAbwD8EEDdFy10X
/d0K5zC9H8jS7/pjI5/KfL0+8PBBOsNjbdKmvhaHN5H4T4HWTUc+s9RVUYXx
p+O1QCvvTwOdVVQC76TewvwMh9rUFVIx8+InRAo8ZSnQwNt8S62hGrBS9v5X
cchKqlr4/xpVTmK9yfh13t/DQT5fvOcUuIFZa45UXsBXMtR+UnS4YNFn/V7b
Bn4bbNOEPPrnaK37Y3jsTEnZjhp6E7nm1zhW3OTuJa5ZS/gGhZ4AixzoaP0+
7nkW2swM17M4T3h1jy/WKKPuIc6bBDmrEOjvHl2W8soxmAv+sFoc1P88Ls55
VAGJiPjNnpTHmxdW6BN7BT6x5vBsLj4re6tneQaMCSFtB8PKeVoqRVy9Vu6P
t2pQSrD/ewTpRo545guEQsoP5vLc7kyIj0UbHo9ELJD+z8vFOs7BTQRa26Dj
ARAA3gsdQmxoidyA1fSXzxzoZ7+ZTctP1SS8gsbi35X52OidCJLE8kquqwiz
oZ6Y1ixTPKbm3nyMSL73jhx0noJ7LnhDTmDFmvuyjb1WZH3H5mRxARXJdo3L
YZyRmPflpXdmeEquMXdDuy3xkOGag2sZ75Dy1a4gjQd6t1ALkxF+5GLQreKf
Xi9yJD2+papbxgD2OjyNI9P6ootPd0Z6X2IIdwm1UqRp0RYmOCutEnv/YQHY
sbVC2vM3UoL1e6quaipQWb4TsrEysYoPjUP284frDRr07hJbt4vJzAmgF5dS
Xf30ExphDHFnsLihreFfkB5SpZ5SWu0Li565b4YF6scvhsdHvKMnr4qEucmc
85wyZJ9/sEn5pLIqp4SGiLmltsh+6Wl9F/nRI+Xv0bPLy+ZL58QM+dN83Z9T
erUwTGBLD69AFml6rFrCPchGmYlcHarcp2lm6+wv9/YIvOBlaPEwe5vLm85N
kwNcMqqA6WTZyjIfRhfixABlZHjV3S7TOdNznALANA/3/tN12dymWgXqhiXK
8YKeSMA/+erOyZ8QQ9UXVjIQXgVJUBZuqwMsaq9rNSoje/FM1xKLNWFX/dJr
/7oGbxqDql2Rqooc+2RtzZv06WVR5wXf7OCQI420SUIlKbMu6xhopsbKLNNB
mWEmePeraCdG6LiGavLpTRSWvXUAEQEAAcLBdQQYAQgAIBYhBIJZKvgygcRX
1GbXLkMIiwNuMGT7BQJa26DjAhsMAAoJEEMIiwNuMGT70xkP9iVPIWCrYd75
umbYRvaDlTEeL/63MYGnfjUAn6qq+bh3imiIbjPxqxHTLtPIECAVo+LiPofh
qELclmhq2QzBgTvGO1mq4d7nkwCTmgFKCvLtkMsPzbV0MEBSZwYybrTEX7ne
51oTdARJMmFns3vyYaSK8u1ty3Y3T+cMd+/50kQOGhA+45ytBk/JwVl59Jgp
ryutKu+ZU4NSGeMsvaBTJ9LRoHpwqsUfkTMiRuJFFvIAGcapnzNrcSQHyMcF
iztt0RqVMwPLaKDiwn9I/gVyw6o9Sxq7zK/J29RpAgLFJ5jYZUHEKjdZe89g
lfz5vMYwMzkP7ub3fEFZqM3pgJnEwDOl7SRAVQJ9JBbMNFx86y9YwjbwKttc
Qtfk+8v37uTWfSiVJZXrh5nLxls+YfgRny4eCynVysd+uIQPM8oxR3BNSWFk
iC3oEQQTwzrxEJbZ6NNfaoR3pQeQKT4qhH782Ysnhh2kH++gFl69xyp11mY3
Zvwqbkhs+GgMGT0LoJoqtvPtCYbVekT+wuB2DTZ9IKrRU9cDhAf+gy27Re8a
254tyzKXsOhw2XaG3cq7Fb3yYTzvUQWFI0Ft5xjA59FJxpGZ4XLYniDAT4h6
JNAEPnEeB8Ywe8USuycxZUS3IDdGWS0RTPheDHe3XghmzkD3WP0+bcL9fyMt
klJDb3YZ2cI=
=qnsQ
-----END PGP PUBLIC KEY BLOCK-----`,
  },
  ioan: {
    email: 'ioan@flowcrypt.com',
    name: 'Ioan at FlowCrypt',
    pub: `-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: FlowCrypt iOS 0.2 Gmail Encryption
Comment: Seamlessly send and receive encrypted email

xjMEYicmihYJKwYBBAHaRw8BAQdAoVcOeCHFBigukEd2irPaUmVPBdTDrpgj
/vZdryBFvUHNJklvYW4gYXQgRmxvd0NyeXB0IDxpb2FuQGZsb3djcnlwdC5j
b20+wrYEExYKAEcFAmInJooJkJs5ASDX+41RFqEE94GZ7D0/50t8iXqnmzkB
INf7jVECngECmwMFlgIDAQAEiwkIBwWVCgkICwWJAYmmdQKZAQAhCRCbOQEg
1/uNURYhBPeBmew9P+dLfIl6p5s5ASDX+41RVEgBAJmD6RMfDIwD8pQHz9BQ
a7N6P6TE5p6/Y8wZLxuMJmBDAQC9l5RrjHHx0MnmsJ+7MLXMjoy9FKqW/1cm
qJXJIsbFDs44BGInJooSCisGAQQBl1UBBQEBB0Ars/VEsgvjuRWNdaW5raXk
j86TScsuwsaIyzZ5plpcYQMBCAfCdQQYFgoAHQUCYicmigKeAQKbDAWWAgMB
AASLCQgHBZUKCQgLAAoJEJs5ASDX+41RueYA/ixPnWLYX6tP0oR81hOWS6dH
r9FLVFOGo9cLLDfqwMR5AP9A4dgF5OprbpTvNJDeuTwfKOWREm/HNYyiBuUb
yBWYAw==
=n23p
-----END PGP PUBLIC KEY BLOCK-----`,
  },
};
