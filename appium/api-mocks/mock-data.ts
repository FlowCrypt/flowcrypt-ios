export type MockUser = {
  email: string;
  name: string;
  pub?: string;
  pubNew?: string;
  pubOther?: string;
  pubSignOnly?: string;
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
  | 'ioan'
  | 'signOnlyKey';

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

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
=ANR6
-----END PGP PUBLIC KEY BLOCK-----`,
    pubNew: `-----BEGIN PGP PUBLIC KEY BLOCK-----

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
=nz5x
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
    pubSignOnly: `-----BEGIN PGP PUBLIC KEY BLOCK-----

mQENBGU/ys4BCADvxv0RSWGalR4/xD+axR4tLlgUxaZWYg6Yd6s8xAWsZ/ygZCAW
RaLplLa33uqbtuK2KLZMk8VdtmkmlAN3L9qMLwG9eVPlqjVAROsbJNTil5jBKeTI
OaK98Lx2WML/J7lZHZZmlDWQsWBZUDKagQKn2uqVhI/A+uzDy0SLBZAqhgBBM44P
iwJiIx0TJJ/CBEjZDJ8yzg+Aa0oEGh9uULwwA21wES9t8UZ/s0FxyPbpL3Th1ovN
Cs3cpLPqkbOY6REMMAb5pdDLM0KtXjTST34bHNvFdDLhldY69XL1x7D4wvVvUFpc
u7wrwnTqPgb8SC+GF3SH3nVJjQQ5Qnolc6VlABEBAAG0JUZsb3dDcnlwdCBSb2Jv
dCA8cm9ib3RAZmxvd2NyeXB0LmNvbT6JAVQEEwEIAD4WIQTT3thevVcV8N5aA7W0
KflQf/+crQUCZT/KzgIbAwUJB4YfXAULCQgHAgYVCgkICwIEFgIDAQIeAQIXgAAK
CRC0KflQf/+crS8JCAC44zw7JkyYPjBW17NDdq+VeiD8qasO6qOzmt+y1wI0a/Ve
cpk4jGZO5XoWGgRrDuppS4bPumXcMzQVO6z0YKain51j51Rah4WC0eS6fJU6+vLZ
foKw1nKVgfp4ezwCZp3fL2/J66F3lqpM5Shj4u3kd9qeumh/CqJzgE1ld0Urk/lc
9fkM4BBBf5enQ4mT0wHZfi/nawg7zfy7moJNqRkGp+TNmK3N4I0RMA+fPl4OPdv7
H6xmypVPdCZmZCDBeGr3n9cR/qz5OEvrDUb0fTdvpf2NGYW0Mco5bprtOIvtRhje
/s+m3hBbMBOaM6v+JFPtm8SjqjvLMuYVnvnXwyFp
=kQbU
-----END PGP PUBLIC KEY BLOCK-----
`,
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
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
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
