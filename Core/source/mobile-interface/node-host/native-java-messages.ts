/* © 2016-present FlowCrypt Limited. Limitations apply. Contact human@flowcrypt.com */

'use strict';

import * as EventEmitter from 'events';

import { Dict, Str } from '../../core/common';

declare const APP_ENV: 'dev' | 'prod';

const ASYNC_REQUEST_HEADER = "ASYNC_REQUEST|";
const ASYNC_RESPONSE_HEADER = "ASYNC_RESPONSE|";
const ASYNC_RESPONSE_SUCCESS_HEADER = `${ASYNC_RESPONSE_HEADER}SUCCESS|`;
const ASYNC_RESPONSE_ERROR_HEADER = `${ASYNC_RESPONSE_HEADER}ERROR|`;
const ID_LENGTH = 10;
const ASYNC_RESPONSE_TIMEOUT = 60000;

let send = (msg: string) => {
  if (APP_ENV === 'prod') {
    console.error(`-------------------- native bridge not present for message --------------------\n${msg}\n--------------------`);
  } else {
    console.log(`dev:rn-bridge:${msg}`);
  }
};

const listeners: Dict<(success: boolean, msg: string) => void> = {};

try {
  const mybridgeaddon = (process as any).binding('rn_bridge');
  class MyEmitter extends EventEmitter {
    public send = function (msg: string) {
      mybridgeaddon.sendMessage(msg);
    };
  }
  const channel = new MyEmitter();
  mybridgeaddon.registerListener(function (msg: string) {
    if (msg.startsWith(ASYNC_RESPONSE_HEADER)) {
      let isSuccess = false;
      let headerLen = ASYNC_RESPONSE_ERROR_HEADER.length;
      if (msg.startsWith(ASYNC_RESPONSE_SUCCESS_HEADER)) {
        isSuccess = true;
        headerLen = ASYNC_RESPONSE_SUCCESS_HEADER.length;
      }
      let id = msg.substr(headerLen, ID_LENGTH);
      let response = msg.substr(headerLen + ID_LENGTH + 1);
      if (listeners[id]) {
        listeners[id](isSuccess, response);
      } else {
        console.log(`Message from host with id ${id} has no listener available (possibly result of timeout)`);
      }
    } else {
      console.log(`Message from Host: ${msg}`);
    }
  });
  send = channel.send;
} catch (e) {
  if (!(e instanceof Error) || e.message !== 'No such module: rn_bridge') {
    throw e;
  }
}

export const sendNativeMessageToJava = send;

export const hostAsyncRequest = (name: string, req: string): Promise<string> => new Promise((resolve, reject) => {
  let id = Str.sloppyRandom(10);
  let timeout = setTimeout(() => {
    delete listeners[id];
    reject(Error(`Host response timeout for request ${name} ${id}`));
  }, ASYNC_RESPONSE_TIMEOUT);
  listeners[id] = (isSuccess, responseOrStack) => {
    delete listeners[id];
    clearTimeout(timeout);
    setTimeout(() => {
      try {
        if (isSuccess) {
          resolve(responseOrStack);
        } else {
          let e = Error(`Error response from NodeHost for request ${name} ${id}`);
          e.stack += `\n${responseOrStack}`;
          reject(e);
        }
      } catch (e) {
        reject(e);
      }
    }, 0); // next eventloop cycle
  };
  setTimeout(() => sendNativeMessageToJava(`${ASYNC_REQUEST_HEADER}${id}|${name}|${req}`), 0); // next eventloop cycle
});

(global as any).hostAsyncRequest = hostAsyncRequest
