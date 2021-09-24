# flowcrypt-mobile-core

This repo hosts TS Core with added interfaces to run it on iOS or Android.


## Build, test, assets

```bash
npm install
npm test
```

When built (with `npm test` or `npm run-script build`), you'll see the final product in `./build/final`:
 - `flowcrypt-android-dev.js`: for running tests, pre-configured with dev secrets (for desktop Nodejs)
 - `flowcrypt-android-prod.js`: for use on Android, run with [nodejs-mobile](https://github.com/janeasystems/nodejs-mobile) which is a full-fledged Nodejs background process. The Android app will generate self-signed HTTPS certs for use by Nodejs. Nodejs will expose a port for the app to listen to, secured by these HTTPS certs for encryption as well as two-way authentication.
 - `flowcrypt-ios-prod.js`: for use on iOS, run with [JavaScriptCore](https://developer.apple.com/documentation/javascriptcore) which is a bare JS engine. The iOS app is calling JS methods directly, without the need for HTTP stack unlike Android.

## TS Core

Code in [source/core](https://github.com/FlowCrypt/flowcrypt-mobile-core/tree/master/source/core) is reused across iOS, Android, browser extension and backend code. Commonly, this code is developed along with [browser extension](https://github.com/FlowCrypt/flowcrypt-browser/tree/master/extension/js/common/core) and then merged into this repo after important changes land there.

## Endpoints

The TS Core API meant to be used on Android/iOS has the following methods (see [entrypoint.ts](https://github.com/FlowCrypt/flowcrypt-mobile-core/blob/master/source/node/endpoints.ts)):
 - `generateKey`: generate a `curve25519|rsa2048|rsa4096` key
 - `composeEmail`: compose a MIME message as `encrypt-inline|encrypt-pgpmime|plain`
 - `parseDecryptMsg`: parse a MIME message into `MsgBlock[]` (representing text, html, attachments, encrypted parts, ...), decrypt encrypted blocks with available keys
 - `encryptFile`, `decryptFile`: encrypt/decrypt OpenPGP data without armoring/dearmoring
 - `zxcvbnStrengthBar`: turn estimated pass phrase guess count into actionable representation of strength, and how long would it take to bruteforce it using 20k cores. Uses [zxcvbn](https://github.com/dropbox/zxcvbn) to estimate bruteforce guesses.
 - `parseKeys`: parse armored or binary keys to get their details/parameters
 - `decryptKey`, `encryptKey`: accepts armored key, returns armored key either encrypted or decrypted with provided pass phrase
 
## Endpoint call input/output format

For both Android (nodejs) and iOS (bare engine), the contents of inputs/outputs are the same but formatted slightly differently.

Call input:
 - `endpoint`: method name, one from the list above such as `generateKey`
 - `request`: JSON encoded request fields, MUST BE ON SINGLE LINE (for proper request parsing on Android)
 - `data`: binary data, if any (such as a MIME message for `parseDecryptMsg`, or file contents for `encryptFile`)

Call output:
 - `response`: JSON encoded response, MUST BE ON SINGLE LINE (for proper response parsing on Android)
 - `data`: binary data, if any (such as unarmored encrypted data as a response from `encryptFile`)
 
This output is encoded together into a single blob of binary output: `utf(json(response))` + `0x0A (newline)` + `data`, called "COMBINED OUTPUT". Example COMBINED OUTPUT response of `decryptFile`:

```
{"success":true,"name":"file.png"}
�PNGIHDR��a	pHYs........
```

### iOS request handling + formatting (bare engine)
 
On iOS, requests are sent from the host to TS Core by calling `handleRequestFromHost` from the host. This method is defined in `entrypoint-bare.ts` (where "bare" means code is run in bare JS engine, as opposed to "node" which means Nodejs).
 
Inputs are `endpointName: string, request: string, data: string` which correspond to the inputs above, with `data` being a base64-encoded string of the binary data, if any.

Output is a callback `(b64response: string) => void` which is a base64-encoded string of "COMBINED OUTPUT".

### Android request handling + formatting (nodejs http)
 
On Android, the host app will look for an empty port and start a nodejs-mobile instance (see `entrypoint-node.ts`) on that port. The host will also pass self-signed HTTPS certs it created, to encrypt and authenticate http trafic on this port.

Requests are sent as POST HTTP requests to `https://localhost:PORT/`, in the http request body, in the following format: `utf(endpointName)` + `0x0A (newline)` + `utf(json(request))` + `0x0A (newline)` + `data`. The complete request body may look like this:

```
generateKey
{"variant":"curve25519","passphrase":"hBRhfzK77vKMmYe3AnCb22X8","userIds":[{"name":"John","email":"john@corp.co"}]}

```

Responses are returned in HTTP response body as "COMBINED OUTPUT". All http response status codes are 200. If there is any error, it is indicated in `utf(json(response))` (see below).

### Error responses on both iOS and Android

Errors are returned back to host as part of the response JSON, in the following format: `{"message": "Something failed","stack": "..."}`. When there is an error, the full COMBINED OUTPUT may look like this:

```
{"message": "Something failed","stack": "..."}

```
The first line is the JSON line, then there is `0x0A (newline)`, and zero bytes of binary data.

## JavaScript code can utilize host app methods

On both iOS and Android, JavaScript has a way to call back into the host app, sort of a reverse request. The only time this will happen is when the JavaScript code is processing a request from the host, and needs host's help to get it done, typically to take advantage of faster cryptographic implementations in Kotlin and Swift as opposed to JavaScript, or to fill gaps in missing functionality on JavaScriptCore.

On iOS this is done through `CoreHost` (swift class) which is exposed to JavaScript as `coreHost` (global object containing methods).

On Android, we set `global.coreHost` directly in JS in `native-crypto.js`. These methods on Android use `hostAsyncRequest` which uses `sendNativeMessageToJava` which uses `EventEmitter` to send messages back to Java and await responses.

CoreHost usage examples:

```js
// defining timeout methods that are missing in JavaScriptCore
const setTimeout = (cb, ms) => coreHost.setTimeout(cb, ms);
const clearTimeout = (id) => coreHost.clearTimeout(id);
```
```js
// getting random bytes in JavaScriptCore
let bytesAsNumberArr = coreHost.getSecureRandomByteNumberArray(byteCount);
```
```js
// decrypt RSA, both platforms
let decryptedBase64 = await coreHost.decryptRsaNoPadding(derRsaPrvBase64, encryptedBase64);
```
```js
// decrypt AES, JavaScriptCore
return Uint8Array.from(coreHost.decryptAesCfbNoPadding(ct, key, iv));
```
