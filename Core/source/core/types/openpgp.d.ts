// Type definitions for openpgpjs
// Project: http://openpgpjs.org/
// Definitions by: Guillaume Lacasa <https://blog.lacasa.fr>
//                 Errietta Kostala <https://github.com/errietta>
//                 FlowCrypt Limited <https://flowcrypt.com>
// Definitions: https://github.com/DefinitelyTyped/DefinitelyTyped

/* tslint:disable:only-arrow-functions variable-name max-line-length no-null-keyword ban-types */

declare namespace OpenPGP {

  type DataPacketType = 'utf8' | 'binary' | 'text' | 'mime';

  export interface UserId {
    name?: string;
    email?: string;
  }

  export interface SessionKey {
    data: Uint8Array;
    algorithm: string;
  }

  interface BaseStream<T extends Uint8Array | string> { }
  interface WebStream<T extends Uint8Array | string> extends BaseStream<T> { // copied+simplified version of ReadableStream from lib.dom.d.ts
    readonly locked: boolean; cancel(reason?: any): Promise<void>; getReader: Function; pipeThrough: Function; pipeTo: Function; tee: Function;
  }
  interface NodeStream<T extends Uint8Array | string> extends BaseStream<T> { // copied+simplified version of ReadableStream from @types/node/index.d.ts
    readable: boolean; read(size?: number): string | Uint8Array; setEncoding(encoding: string): this; pause(): this; resume(): this;
    isPaused(): boolean; pipe: Function; unpipe: Function; unshift(chunk: string | Uint8Array): void; wrap: Function;
  }
  type Stream<T extends Uint8Array | string> = WebStream<T> | NodeStream<T>;

  /**
   * EncryptArmorOptions or EncryptBinaryOptions will be used based on armor option (boolean), defaults to armoring
   */
  interface BaseEncryptOptions {
    /** message to be encrypted as created by openpgp.message.fromText or openpgp.message.fromBinary */
    message: message.Message;
    /** (optional) array of keys or single key, used to encrypt the message */
    publicKeys?: key.Key | key.Key[];
    /** (optional) private keys for signing. If omitted message will not be signed */
    privateKeys?: key.Key | key.Key[];
    /** (optional) array of passwords or a single password to encrypt the message */
    passwords?: string | string[];
    /** (optional) session key in the form: { data:Uint8Array, algorithm:String } */
    sessionKey?: SessionKey;
    /** (optional) which compression algorithm to compress the message with, defaults to what is specified in config */
    compression?: enums.compression;
    /** (optional) whether to return data as a stream. Defaults to the type of stream `message` was created from, if any. */
    streaming?: 'web' | 'node' | false;
    /** (optional) if the signature should be detached (if true, signature will be added to returned object) */
    detached?: boolean;
    /** (optional) a detached signature to add to the encrypted message */
    signature?: signature.Signature;
    /** (optional) if the unencrypted session key should be added to returned object */
    returnSessionKey?: boolean;
    /** (optional) encrypt as of a certain date */
    date?: Date;
    /** (optional) use a key ID of 0 instead of the public key IDs */
    wildcard?: boolean;
    /** (optional) user ID to sign with, e.g. { name:'Steve Sender', email:'steve@openpgp.org' } */
    fromUserId?: UserId;
    /** (optional) user ID to encrypt for, e.g. { name:'Robert Receiver', email:'robert@openpgp.org' } */
    toUserId?: UserId;
  }

  export type EncryptOptions = BaseEncryptOptions | EncryptArmorOptions | EncryptBinaryOptions;

  export interface EncryptArmorOptions extends BaseEncryptOptions {
    /** if the return values should be ascii armored or the message/signature objects */
    armor: true;
  }

  export interface EncryptBinaryOptions extends BaseEncryptOptions {
    /** if the return values should be ascii armored or the message/signature objects */
    armor: false;
  }

  export namespace packet {

    export class List<PACKET_TYPE> extends Array<PACKET_TYPE> {
      [index: number]: PACKET_TYPE;
      length: number;
      read(bytes: Uint8Array): void;
      write(): Uint8Array;
      push(...packet: PACKET_TYPE[]): number;
      pop(): PACKET_TYPE;
      filter(callback: (packet: PACKET_TYPE, i: number, self: List<PACKET_TYPE>) => void): List<PACKET_TYPE>;
      filterByTag(...args: enums.packet[]): List<PACKET_TYPE>;
      forEach(callback: (packet: PACKET_TYPE, i: number, self: List<PACKET_TYPE>) => void): void;
      map<RETURN_TYPE>(callback: (packet: PACKET_TYPE, i: number, self: List<PACKET_TYPE>) => RETURN_TYPE): List<RETURN_TYPE>;
      // some()
      // every()
      // findPacket()
      // indexOfTag()
      // slice()
      // concat()
      // fromStructuredClone()
    }

    function fromStructuredClone(packetClone: object): AnyPacket;

    function newPacketFromTag(tag: enums.packetNames): AnyPacket;

    class BasePacket {
      tag: enums.packet;
      read(bytes: Uint8Array): void;
      write(): Uint8Array;
    }

    class BaseKeyPacket extends BasePacket {
      // fingerprint: Uint8Array|null; - not included because not recommended to use. Use getFingerprint() or getFingerprintBytes()
      algorithm: enums.publicKey;
      created: Date;
      getBitSize(): number;
      getAlgorithmInfo(): key.AlgorithmInfo;
      getFingerprint(): string;
      getFingerprintBytes(): Uint8Array | null;
      getCreationTime(): Date;
      getKeyId(): Keyid;

      version: number;
      expirationTimeV3: number | null;
      keyExpirationTime: number | null;
    }

    class BasePrimaryKeyPacket extends BaseKeyPacket {
    }

    export class Compressed extends BasePacket {
      tag: enums.packet.compressed;
    }

    export class SymEncryptedIntegrityProtected extends BasePacket {
      tag: enums.packet.symEncryptedIntegrityProtected;
    }

    export class SymEncryptedAEADProtected extends BasePacket {
      tag: enums.packet.symEncryptedAEADProtected;
    }

    export class PublicKeyEncryptedSessionKey extends BasePacket {
      tag: enums.packet.publicKeyEncryptedSessionKey;
    }

    export class SymEncryptedSessionKey extends BasePacket {
      tag: enums.packet.symEncryptedSessionKey;
    }

    export class Literal extends BasePacket {
      tag: enums.packet.literal;
    }

    export class PublicKey extends BasePrimaryKeyPacket {
      tag: enums.packet.publicKey;
      isDecrypted(): null;
    }

    export class SymmetricallyEncrypted extends BasePacket {
      tag: enums.packet.symmetricallyEncrypted;
    }

    export class Marker extends BasePacket {
      tag: enums.packet.marker;
    }

    export class PublicSubkey extends BaseKeyPacket {
      tag: enums.packet.publicSubkey;
      isDecrypted(): null;
    }

    export class UserAttribute extends BasePacket {
      tag: enums.packet.userAttribute;
    }

    export class OnePassSignature extends BasePacket {
      tag: enums.packet.onePassSignature;
      correspondingSig?: Promise<Signature>;
    }

    export class SecretKey extends BasePrimaryKeyPacket {
      tag: enums.packet.secretKey;
      isDecrypted(): boolean;
      encrypt(passphrase: string): Promise<boolean>;
      decrypt(passphrase: string): Promise<true>;
      // encrypted: null | unknown[]; // Encrypted secret-key data, not meant for public use
      s2k: { type: string } | null;
    }

    export class Userid extends BasePacket {
      tag: enums.packet.userid;
      userid: string;
    }

    export class SecretSubkey extends BaseKeyPacket {
      tag: enums.packet.secretSubkey;
      isDecrypted(): boolean;
      encrypt(passphrase: string): Promise<boolean>;
      decrypt(passphrase: string): Promise<true>;
      // encrypted: null | unknown[]; // Encrypted secret-key data, not meant for public use
      s2k: { type: string } | null;
    }

    export class Signature extends BasePacket {
      tag: enums.packet.signature;
      version: number;
      signatureType: null | number;
      hashAlgorithm: null | number;
      publicKeyAlgorithm: null | number;
      signatureData: null | Uint8Array;
      unhashedSubpackets: null | Uint8Array;
      signedHashValue: null | Uint8Array;
      created: Date;
      signatureExpirationTime: null | number;
      signatureNeverExpires: boolean;
      exportable: null | boolean;
      trustLevel: null | number;
      trustAmount: null | number;
      regularExpression: null | number;
      revocable: null | boolean;
      keyExpirationTime: null | number;
      keyNeverExpires: null | boolean;
      preferredSymmetricAlgorithms: null | number[];
      revocationKeyClass: null | number;
      revocationKeyAlgorithm: null | number;
      revocationKeyFingerprint: null | Uint8Array;
      issuerKeyId: Keyid;
      notation: null | { [name: string]: string };
      preferredHashAlgorithms: null | number[];
      preferredCompressionAlgorithms: null | number[];
      keyServerPreferences: null | number[];
      preferredKeyServer: null | string;
      isPrimaryUserID: null | boolean;
      policyURI: null | string;
      keyFlags: null | number[];
      signersUserId: null | string;
      reasonForRevocationFlag: null | number;
      reasonForRevocationString: null | string;
      features: null | number[];
      signatureTargetPublicKeyAlgorithm: null | number;
      signatureTargetHashAlgorithm: null | number;
      signatureTargetHash: null | string;
      embeddedSignature: null | Signature;
      issuerKeyVersion: null | number;
      issuerFingerprint: null | Uint8Array;
      preferredAeadAlgorithms: null | Uint8Array;
      verified: null | boolean;
      revoked: null | boolean;
      sign(key: SecretKey | SecretSubkey, data: Uint8Array): true;
      isExpired(date?: Date): boolean;
      getExpirationTime(): Date | typeof Infinity;
    }

    export class Trust extends BasePacket {
      tag: enums.packet.trust;
    }

    export type AnyPacket = Compressed | SymEncryptedIntegrityProtected | SymEncryptedAEADProtected | PublicKeyEncryptedSessionKey | SymEncryptedSessionKey | Literal
      | PublicKey | SymmetricallyEncrypted | Marker | PublicSubkey | UserAttribute | OnePassSignature | SecretKey | Userid | SecretSubkey | Signature | Trust;
    export type AnySecretPacket = SecretKey | SecretSubkey;
    export type AnyKeyPacket = PublicKey | SecretKey | PublicSubkey | SecretSubkey;
  }

  export interface EncryptArmorResult {
    data: string;
    signature?: string;
  }

  export interface EncryptBinaryResult {
    message: message.Message;
    signature?: signature.Signature;
  }

  export type EncryptResult = EncryptArmorResult | EncryptBinaryResult;

  export interface SignArmorResult {
    data: string | Stream<string>;
    signature: string | Stream<string>;
  }

  export interface SignBinaryResult {
    message: message.Message | cleartext.CleartextMessage;
    signature: signature.Signature;
  }

  export type SignResult = SignArmorResult | SignBinaryResult;

  export interface DecryptOptions {
    /** the message object with the encrypted data */
    message: message.Message;
    /** (optional) private keys with decrypted secret key data or session key */
    privateKeys?: key.Key | key.Key[];
    /** (optional) passwords to decrypt the message */
    passwords?: string | string[];
    /** (optional) session keys in the form: { data:Uint8Array, algorithm:String } */
    sessionKeys?: SessionKey | SessionKey[];
    /** (optional) array of public keys or single key, to verify signatures */
    publicKeys?: key.Key | key.Key[];
    /** (optional) whether to return data as a string(Stream) or Uint8Array(Stream). If 'utf8' (the default), also normalize newlines. */
    format?: string;
    /** (optional) whether to return data as a stream. Defaults to the type of stream `message` was created from, if any. */
    streaming?: 'web' | 'node' | false;
    /** (optional) detached signature for verification */
    signature?: signature.Signature;
  }

  export interface SignOptions {
    message: cleartext.CleartextMessage | message.Message;
    privateKeys?: key.Key | key.Key[];
    armor?: boolean;
    streaming?: 'web' | 'node' | false;
    dataType?: DataPacketType;
    detached?: boolean;
    date?: Date;
    fromUserId?: UserId;
  }

  export interface KeyContainer {
    key: key.Key;
  }

  export interface KeyPair extends KeyContainer {
    privateKeyArmored: string;
    publicKeyArmored: string;
  }

  export interface KeyOptions {
    userIds: UserId[]; // generating a key with no user defined results in error
    passphrase?: string;
    numBits?: number;
    keyExpirationTime?: number;
    curve?: key.EllipticCurveName;
    date?: Date;
    subkeys?: KeyOptions[];
  }

  /**
   * Intended for internal use with openpgp.key.generate()
   * It's recommended that users choose openpgp.generateKey() that requires KeyOptions instead
   */
  export interface FullKeyOptions {
    userIds: UserId[];
    passphrase?: string;
    numBits?: number;
    keyExpirationTime?: number;
    curve?: key.EllipticCurveName;
    date?: Date;
    subkeys: KeyOptions[]; // required unline KeyOptions.subkeys
  }

  export interface Keyid {
    bytes: string;
  }

  export interface DecryptMessageResult {
    data: Uint8Array | string;
    signatures: signature.Signature[];
    filename: string;
  }

  export interface OpenPGPWorker {
    randomCallback(): void;
    configure(config: any): void;
    seedRandom(buffer: ArrayBuffer): void;
    delegate(id: number, method: string, options: any): void;
    response(event: any): void;
  }

  export interface WorkerOptions {
    path?: string;
    n?: number;
    workers?: OpenPGPWorker[];
    config?: any;
  }

  export class AsyncProxy {
    constructor(options: WorkerOptions);
    getId(): number;
    seedRandom(workerId: number, size: number): Promise<void>;
    terminate(): void;
    delegate(method: string, options: any): void;

    workers: OpenPGPWorker[];
  }

  /**
   * Set the path for the web worker script and create an instance of the async proxy
   * @param {String} path            relative path to the worker scripts, default: 'openpgp.worker.js'
   * @param {Number} n               number of workers to initialize
   * @param {Array<Object>} workers  alternative to path parameter: web workers initialized with 'openpgp.worker.js'
   */
  export function initWorker(options: WorkerOptions): boolean;

  /**
   * Returns a reference to the async proxy if the worker was initialized with openpgp.initWorker()
   * @returns {module:worker/async_proxy.AsyncProxy|null} the async proxy or null if not initialized
   */
  export function getWorker(): AsyncProxy;

  /**
   * Cleanup the current instance of the web worker.
   */
  export function destroyWorker(): void;

  /**
   * Encrypts message text/data with public keys, passwords or both at once. At least either public keys or passwords
   *   must be specified. If private keys are specified, those will be used to sign the message.
   * @param {EncryptOptions} options               See `EncryptOptions`
   * @returns {Promise<EncryptResult>}             Promise of `EncryptResult` (and optionally signed message) in the form:
   *                                                 {data: ASCII armored message if 'armor' is true;
   *                                                  message: full Message object if 'armor' is false, signature: detached signature if 'detached' is true}
   * @async
   * @static
   */
  export function encrypt(options: EncryptBinaryOptions): Promise<EncryptBinaryResult>;
  export function encrypt(options: EncryptArmorOptions | BaseEncryptOptions): Promise<EncryptArmorResult>;

  /**
   * Signs a cleartext message.
   * @param {String | Uint8Array} data           cleartext input to be signed
   * @param {utf8|binary|text|mime} dataType     (optional) data packet type
   * @param {Key|Array<Key>} privateKeys         array of keys or single key with decrypted secret key data to sign cleartext
   * @param {Boolean} armor                      (optional) if the return value should be ascii armored or the message object
   * @param {Boolean} detached                   (optional) if the return value should contain a detached signature
   * @param {Date} date                          (optional) override the creation date signature
   * @param {Object} fromUserId                  (optional) user ID to sign with, e.g. { name:'Steve Sender', email:'steve@openpgp.org' }
   * @returns {Promise<Object>}                    signed cleartext in the form:
   *                                               {data: ASCII armored message if 'armor' is true;
   *                                                message: full Message object if 'armor' is false, signature: detached signature if 'detached' is true}
   * @async
   * @static
   */
  export function sign(options: SignOptions): Promise<SignResult>;

  /**
   * Decrypts a message with the user's private key, a session key or a password. Either a private key;
   *   a session key or a password must be specified.
   * @param {DecryptOptions} options           see `DecryptOptions`
   * @returns {Promise<DecryptMessageResult>}  Promise of `DecryptMessageResult` and verified message in the form:
   *                                        { data:Uint8Array|String, filename:String, signatures:[{ keyid:String, valid:Boolean }] }
   * @async
   * @static
   */
  export function decrypt(options: DecryptOptions): Promise<DecryptMessageResult>;

  /**
   * Generates a new OpenPGP key pair. Supports RSA and ECC keys. Primary and subkey will be of same type.
   * @param {Array<Object>} userIds   array of user IDs e.g. [{ name:'Phil Zimmermann', email:'phil@openpgp.org' }]
   * @param {String} passphrase       (optional) The passphrase used to encrypt the resulting private key
   * @param {Number} numBits          (optional) number of bits for RSA keys: 2048 or 4096.
   * @param {Number} keyExpirationTime (optional) The number of seconds after the key creation time that the key expires
   * @param {String} curve            (optional) elliptic curve for ECC keys:
   *                                              curve25519, p256, p384, p521, secp256k1;
   *                                              brainpoolP256r1, brainpoolP384r1, or brainpoolP512r1.
   * @param {Date} date               (optional) override the creation date of the key and the key signatures
   * @param {Array<Object>} subkeys   (optional) options for each subkey, default to main key options. e.g. [{sign: true, passphrase: '123'}]
   *                                              sign parameter defaults to false, and indicates whether the subkey should sign rather than encrypt
   * @returns {Promise<Object>}         The generated key object in the form:
   *                                    { key:Key, privateKeyArmored:String, publicKeyArmored:String }
   * @async
   * @static
   */
  export function generateKey(options: KeyOptions): Promise<KeyPair>;

  /**
   * Reformats signature packets for a key and rewraps key object.
   * @param {Key} privateKey          private key to reformat
   * @param {Array<Object>} userIds   array of user IDs e.g. [{ name:'Phil Zimmermann', email:'phil@openpgp.org' }]
   * @param {String} passphrase       (optional) The passphrase used to encrypt the resulting private key
   * @param {Number} keyExpirationTime (optional) The number of seconds after the key creation time that the key expires
   * @returns {Promise<Object>}         The generated key object in the form:
   *                                    { key:Key, privateKeyArmored:String, publicKeyArmored:String }
   * @async
   * @static
   */
  export function reformatKey(options: {
    privateKey: key.Key;
    userIds?: (string | UserId)[];
    passphrase?: string;
    keyExpirationTime?: number;
  }): Promise<KeyPair>;

  /**
   * Unlock a private key with your passphrase.
   * @param {Key} privateKey                    the private key that is to be decrypted
   * @param {String|Array<String>} passphrase   the user's passphrase(s) chosen during key generation
   * @returns {Promise<Object>}                  the unlocked key object in the form: { key:Key }
   * @async
   */
  export function decryptKey(options: {
    privateKey: key.Key;
    passphrase?: string | string[];
  }): Promise<KeyContainer>;

  export function encryptKey(options: {
    privateKey: key.Key;
    passphrase?: string
  }): Promise<KeyContainer>;

  export namespace armor {
    /** Armor an OpenPGP binary packet block
     * @param messagetype type of the message
     * @param body
     * @param partindex
     * @param parttotal
     */
    function armor(messagetype: enums.armor, body: object, partindex: number, parttotal: number): string;

    /** DeArmor an OpenPGP armored message; verify the checksum and return the encoded bytes
     *
     *  @param text OpenPGP armored message
     */
    function dearmor(text: string): object;
  }

  export namespace cleartext {
    /** Class that represents an OpenPGP cleartext signed message.
     */
    interface CleartextMessage {
      /** Returns ASCII armored text of cleartext signed message
       */
      armor(): string;

      /** Returns the key IDs of the keys that signed the cleartext message
       */
      getSigningKeyIds(): Array<Keyid>;

      /** Get cleartext
       */
      getText(): string;

      /** Sign the cleartext message
       *
       *  @param privateKeys private keys with decrypted secret key data for signing
       */
      sign(privateKeys: Array<key.Key>): void;

      /** Verify signatures of cleartext signed message
       *  @param keys array of keys to verify signatures
       */
      verify(keys: key.Key[], date?: Date, streaming?: boolean): Promise<message.Verification[]>;
    }

    /**
     * reads an OpenPGP cleartext signed message and returns a CleartextMessage object
     * @param armoredText text to be parsed
     * @returns new cleartext message object
     * @async
     * @static
     */
    function readArmored(armoredText: string): Promise<CleartextMessage>;

    function fromText(text: string): CleartextMessage;
  }

  export namespace config {
    let prefer_hash_algorithm: enums.hash;
    let encryption_cipher: enums.symmetric;
    let compression: enums.compression;
    let show_version: boolean;
    let show_comment: boolean;
    let integrity_protect: boolean;
    let debug: boolean;
    let deflate_level: number;
    let aead_protect: boolean;
    let ignore_mdc_error: boolean;
    let checksum_required: boolean;
    let rsa_blinding: boolean;
    let password_collision_check: boolean;
    let revocations_expire: boolean;
    let use_native: boolean;
    let zero_copy: boolean;
    let tolerant: boolean;
    let versionstring: string;
    let commentstring: string;
    let keyserver: string;
    let node_store: string;
  }

  export namespace crypto {
    interface Mpi {
      data: number;
      read(input: string): number;
      write(): string;
    }

    /** Generating a session key for the specified symmetric algorithm
     *   @param algo Algorithm to use
     */
    function generateSessionKey(algo: enums.symmetric): string;

    /** generate random byte prefix as string for the specified algorithm
     *   @param algo Algorithm to use
     */
    function getPrefixRandom(algo: enums.symmetric): string;

    /** Returns the number of integers comprising the private key of an algorithm
     *  @param algo The public key algorithm
     */
    function getPrivateMpiCount(algo: enums.symmetric): number;

    /** Decrypts data using the specified public key multiprecision integers of the private key, the specified secretMPIs of the private key and the specified algorithm.
        @param algo Algorithm to be used
        @param publicMPIs Algorithm dependent multiprecision integers of the public key part of the private key
        @param secretMPIs Algorithm dependent multiprecision integers of the private key used
        @param data Data to be encrypted as MPI
    */
    function publicKeyDecrypt(algo: enums.publicKey, publicMPIs: Array<Mpi>, secretMPIs: Array<Mpi>, data: Mpi): Mpi;

    /** Encrypts data using the specified public key multiprecision integers and the specified algorithm.
        @param algo Algorithm to be used
        @param publicMPIs Algorithm dependent multiprecision integers
        @param data Data to be encrypted as MPI
    */
    function publicKeyEncrypt(algo: enums.publicKey, publicMPIs: Array<Mpi>, data: Mpi): Array<Mpi>;

    namespace cfb {
      /** This function decrypts a given plaintext using the specified blockcipher to decrypt a message
          @param cipherfn the algorithm cipher class to decrypt data in one block_size encryption
          @param key binary string representation of key to be used to decrypt the ciphertext. This will be passed to the cipherfn
          @param ciphertext to be decrypted provided as a string
          @param resync a boolean value specifying if a resync of the IV should be used or not. The encrypteddatapacket uses the "old" style with a resync. Decryption within an encryptedintegrityprotecteddata packet is not resyncing the IV.
      */
      function decrypt(cipherfn: string, key: string, ciphertext: string, resync: boolean): string;

      /** This function encrypts a given with the specified prefixrandom using the specified blockcipher to encrypt a message
          @param prefixrandom random bytes of block_size length provided as a string to be used in prefixing the data
          @param cipherfn the algorithm cipher class to encrypt data in one block_size encryption
          @param plaintext data to be encrypted provided as a string
          @param key binary string representation of key to be used to encrypt the plaintext. This will be passed to the cipherfn
          @param resync a boolean value specifying if a resync of the IV should be used or not. The encrypteddatapacket uses the "old" style with a resync. Encryption within an encryptedintegrityprotecteddata packet is not resyncing the IV.
      */
      function encrypt(prefixrandom: string, cipherfn: string, plaintext: string, key: string, resync: boolean): string;

      /** Decrypts the prefixed data for the Modification Detection Code (MDC) computation
          @param cipherfn cipherfn.encrypt Cipher function to use
          @param key binary string representation of key to be used to check the mdc This will be passed to the cipherfn
          @param ciphertext The encrypted data
      */
      function mdc(cipherfn: object, key: string, ciphertext: string): string;
    }

    namespace hash {
      /** Create a hash on the specified data using the specified algorithm
          @param algo Hash algorithm type
          @param data Data to be hashed
      */
      function digest(algo: enums.hash, data: Uint8Array): Promise<Uint8Array>;

      /** Returns the hash size in bytes of the specified hash algorithm type
          @param algo Hash algorithm type
      */
      function getHashByteLength(algo: enums.hash): number;
    }

    namespace random {
      /** Retrieve secure random byte string of the specified length
          @param length Length in bytes to generate
      */
      function getRandomBytes(length: number): Promise<Uint8Array>;
    }

    namespace signature {
      /** Create a signature on data using the specified algorithm
          @param hash_algo hash Algorithm to use
          @param algo Asymmetric cipher algorithm to use
          @param publicMPIs Public key multiprecision integers of the private key
          @param secretMPIs Private key multiprecision integers which is used to sign the data
          @param data Data to be signed
      */
      function sign(hash_algo: enums.hash, algo: enums.publicKey, publicMPIs: Array<Mpi>, secretMPIs: Array<Mpi>, data: string): Mpi;

      /**
          @param algo public Key algorithm
          @param hash_algo Hash algorithm
          @param msg_MPIs Signature multiprecision integers
          @param publickey_MPIs Public key multiprecision integers
          @param data Data on where the signature was computed on
      */
      function verify(algo: enums.publicKey, hash_algo: enums.hash, msg_MPIs: Array<Mpi>, publickey_MPIs: Array<Mpi>, data: string): boolean;
    }
  }

  export namespace enums {

    function read(type: typeof armor, e: armor): armorNames | string | any;
    function read(type: typeof compression, e: compression): compressionNames | string | any;
    function read(type: typeof hash, e: hash): hashNames | string | any;
    function read(type: typeof packet, e: packet): packetNames | string | any;
    function read(type: typeof publicKey, e: publicKey): publicKeyNames | string | any;
    function read(type: typeof symmetric, e: symmetric): symmetricNames | string | any;
    function read(type: typeof keyStatus, e: keyStatus): keyStatusNames | string | any;
    function read(type: typeof keyFlags, e: keyFlags): keyFlagsNames | string | any;

    export type armorNames = 'multipart_section' | 'multipart_last' | 'signed' | 'message' | 'public_key' | 'private_key';
    enum armor {
      multipart_section = 0,
      multipart_last = 1,
      signed = 2,
      message = 3,
      public_key = 4,
      private_key = 5,
      signature = 6,
    }

    enum reasonForRevocation {
      no_reason = 0, // No reason specified (key revocations or cert revocations)
      key_superseded = 1, // Key is superseded (key revocations)
      key_compromised = 2, // Key material has been compromised (key revocations)
      key_retired = 3, // Key is retired and no longer used (key revocations)
      userid_invalid = 32, // User ID information is no longer valid (cert revocations)
    }

    export type compressionNames = 'uncompressed' | 'zip' | 'zlib' | 'bzip2';
    enum compression {
      uncompressed = 0,
      zip = 1,
      zlib = 2,
      bzip2 = 3,
    }

    export type hashNames = 'md5' | 'sha1' | 'ripemd' | 'sha256' | 'sha384' | 'sha512' | 'sha224';
    enum hash {
      md5 = 1,
      sha1 = 2,
      ripemd = 3,
      sha256 = 8,
      sha384 = 9,
      sha512 = 10,
      sha224 = 11,
    }

    export type packetNames = 'publicKeyEncryptedSessionKey' | 'signature' | 'symEncryptedSessionKey' | 'onePassSignature' | 'secretKey' | 'publicKey'
      | 'secretSubkey' | 'compressed' | 'symmetricallyEncrypted' | 'marker' | 'literal' | 'trust' | 'userid' | 'publicSubkey' | 'userAttribute'
      | 'symEncryptedIntegrityProtected' | 'modificationDetectionCode' | 'symEncryptedAEADProtected';
    enum packet {
      publicKeyEncryptedSessionKey = 1,
      signature = 2,
      symEncryptedSessionKey = 3,
      onePassSignature = 4,
      secretKey = 5,
      publicKey = 6,
      secretSubkey = 7,
      compressed = 8,
      symmetricallyEncrypted = 9,
      marker = 10,
      literal = 11,
      trust = 12,
      userid = 13,
      publicSubkey = 14,
      userAttribute = 17,
      symEncryptedIntegrityProtected = 18,
      modificationDetectionCode = 19,
      symEncryptedAEADProtected = 20,
    }

    export type publicKeyNames = 'rsa_encrypt_sign' | 'rsa_encrypt' | 'rsa_sign' | 'elgamal' | 'dsa' | 'ecdh' | 'ecdsa' | 'eddsa' | 'aedh' | 'aedsa';
    enum publicKey {
      rsa_encrypt_sign = 1,
      rsa_encrypt = 2,
      rsa_sign = 3,
      elgamal = 16,
      dsa = 17,
      ecdh = 18,
      ecdsa = 19,
      eddsa = 22,
      aedh = 23,
      aedsa = 24,
    }

    export type symmetricNames = 'plaintext' | 'idea' | 'tripledes' | 'cast5' | 'blowfish' | 'aes128' | 'aes192' | 'aes256' | 'twofish';
    enum symmetric {
      plaintext = 0,
      idea = 1,
      tripledes = 2,
      cast5 = 3,
      blowfish = 4,
      aes128 = 7,
      aes192 = 8,
      aes256 = 9,
      twofish = 10,
    }

    export type keyStatusNames = 'invalid' | 'expired' | 'revoked' | 'valid' | 'no_self_cert';
    enum keyStatus {
      invalid = 0,
      expired = 1,
      revoked = 2,
      valid = 3,
      no_self_cert = 4,
    }

    export type keyFlagsNames = 'certify_keys' | 'sign_data' | 'encrypt_communication' | 'encrypt_storage' | 'split_private_key' | 'authentication'
      | 'shared_private_key';
    enum keyFlags {
      certify_keys = 1,
      sign_data = 2,
      encrypt_communication = 4,
      encrypt_storage = 8,
      split_private_key = 16,
      authentication = 32,
      shared_private_key = 128,
    }

  }

  export namespace key {

    export type EllipticCurveName = 'curve25519' | 'p256' | 'p384' | 'p521' | 'secp256k1' | 'brainpoolP256r1' | 'brainpoolP384r1' | 'brainpoolP512r1';

    /** Class that represents an OpenPGP key. Must contain a primary key. Can contain additional subkeys, signatures, user ids, user attributes.
     */
    class Key {
      constructor(packetlist: packet.List<packet.AnyPacket>);
      armor(): string;
      decrypt(passphrase: string | string[], keyId?: Keyid): Promise<boolean>;
      encrypt(passphrase: string | string[]): Promise<void>;
      getExpirationTime(capability?: 'encrypt' | 'encrypt_sign' | 'sign' | null, keyId?: Keyid | null, userId?: UserId | null): Promise<Date | typeof Infinity | null>; // Returns null if `capabilities` is passed and the key does not have the specified capabilities or is revoked or invalid.
      getKeyIds(): Keyid[];
      getPrimaryUser(): Promise<PrimaryUser | null>;
      getUserIds(): string[];
      isPrivate(): boolean;
      isPublic(): boolean;
      toPublic(): Key;
      update(key: Key): void;
      verifyPrimaryKey(): Promise<enums.keyStatus>;
      isRevoked(): Promise<boolean>;
      revoke(reason: { flag?: enums.reasonForRevocation; string?: string; }, date?: Date): Promise<Key>;
      getRevocationCertificate(): Promise<Stream<string> | string | undefined>;
      getEncryptionKey(keyid?: Keyid | null, date?: Date, userId?: UserId | null): Promise<packet.PublicSubkey | packet.SecretSubkey | packet.SecretKey | packet.PublicKey | null>;
      getSigningKey(): Promise<packet.PublicSubkey | packet.SecretSubkey | packet.SecretKey | packet.PublicKey | null>;
      getKeys(keyId?: Keyid): (Key | SubKey)[];
      // isDecrypted(): boolean;
      isFullyEncrypted(): boolean;
      isFullyDecrypted(): boolean;
      isPacketDecrypted(keyId: Keyid): boolean;
      getFingerprint(): string;
      getCreationTime(): Date;
      getAlgorithmInfo(): AlgorithmInfo;
      getKeyId(): Keyid;
      primaryKey: packet.PublicKey | packet.SecretKey;
      subKeys: SubKey[];
      users: User[];
      revocationSignatures: packet.Signature[];
      keyPacket: packet.PublicKey | packet.SecretKey;
    }

    class SubKey {
      constructor(subKeyPacket: packet.SecretSubkey | packet.PublicSubkey);
      subKey: packet.SecretSubkey | packet.PublicSubkey;
      keyPacket: packet.SecretKey;
      bindingSignatures: packet.Signature[];
      revocationSignatures: packet.Signature[];
      verify(primaryKey: packet.PublicKey | packet.SecretKey): Promise<enums.keyStatus>;
      isDecrypted(): boolean;
      getFingerprint(): string;
      getCreationTime(): Date;
      getAlgorithmInfo(): AlgorithmInfo;
      getKeyId(): Keyid;
    }

    export interface User {
      userId: packet.Userid | null;
      userAttribute: packet.UserAttribute | null;
      selfCertifications: packet.Signature[];
      otherCertifications: packet.Signature[];
      revocationSignatures: packet.Signature[];
    }

    export interface PrimaryUser {
      index: number;
      user: User;
    }

    interface KeyResult {
      keys: Key[];
      err?: Error[];
    }

    type AlgorithmInfo = {
      algorithm: enums.publicKeyNames;
      bits: number;
    };

    /** Generates a new OpenPGP key. Currently only supports RSA keys. Primary and subkey will be of same type.
      *  @param options
      */
    function generate(options: FullKeyOptions): Promise<Key>;

    /** Reads an OpenPGP armored text and returns one or multiple key objects

        @param armoredText text to be parsed
    */
    function readArmored(armoredText: string): Promise<KeyResult>;

    /** Reads an OpenPGP binary data and returns one or multiple key objects

        @param data to be parsed
    */
    function read(data: Uint8Array): Promise<KeyResult>;
  }

  export namespace signature {
    class Signature {
      constructor(packetlist: packet.List<packet.Signature>);
      armor(): string;
      packets: packet.List<packet.Signature>;
    }

    /** reads an OpenPGP armored signature and returns a signature object

        @param armoredText text to be parsed
    */
    function readArmored(armoredText: string): Promise<Signature>;

    /** reads an OpenPGP signature as byte array and returns a signature object

        @param  input   binary signature
    */
    function read(input: Uint8Array): Promise<Signature>;
  }

  export namespace message {
    /** Class that represents an OpenPGP message. Can be an encrypted message, signed message, compressed message or literal message
     */
    class Message {
      constructor(packetlist: packet.List<packet.AnyPacket>);

      /** Returns ASCII armored text of message
       */
      armor(): string;

      /** Decrypt the message
          @param privateKey private key with decrypted secret data
      */
      decrypt(privateKeys?: key.Key[] | null, passwords?: string[] | null, sessionKeys?: SessionKey[] | null, streaming?: boolean): Promise<Message>;

      /** Encrypt the message
          @param keys array of keys, used to encrypt the message
      */
      encrypt(keys: key.Key[]): Promise<Message>;

      /** Returns the key IDs of the keys to which the session key is encrypted
       */
      getEncryptionKeyIds(): Keyid[];

      /** Get literal data that is the body of the message
       */
      getLiteralData(): Uint8Array | null | Stream<Uint8Array>;

      /** Returns the key IDs of the keys that signed the message
       */
      getSigningKeyIds(): Keyid[];

      /** Get literal data as text
       */
      getText(): string | null | Stream<string>;

      getFilename(): string | null;

      /** Sign the message (the literal data packet of the message)
          @param privateKey private keys with decrypted secret key data for signing
      */
      sign(privateKey: key.Key[]): Promise<Message>;

      /** Unwrap compressed message
       */
      unwrapCompressed(): Message;

      /** Verify message signatures
          @param keys array of keys to verify signatures
      */
      verify(keys: key.Key[], date?: Date, streaming?: boolean): Promise<Verification[]>;

      /**
       * Append signature to unencrypted message object
       * @param {String|Uint8Array} detachedSignature The detached ASCII-armored or Uint8Array PGP signature
       */
      appendSignature(detachedSignature: string | Uint8Array): Promise<void>;

      packets: packet.List<packet.AnyPacket>;
    }

    class SessionKey { // todo

    }

    export interface Verification {
      keyid: Keyid;
      verified: Promise<null | boolean>;
      signature: Promise<signature.Signature>;
    }

    /** creates new message object from binary data
        @param bytes
    */
    function fromBinary(bytes: Uint8Array | Stream<Uint8Array>, filename?: string, date?: Date, type?: DataPacketType): Message;

    /** creates new message object from text
        @param text
    */
    function fromText(text: string | Stream<string>, filename?: string, date?: Date, type?: DataPacketType): Message;

    /** reads an OpenPGP armored message and returns a message object

        @param armoredText text to be parsed
    */
    function readArmored(armoredText: string | Stream<string>): Promise<Message>;

    /**
     * reads an OpenPGP message as byte array and returns a message object
     * @param {Uint8Array} input  binary message
     * @returns {Message}           new message object
     * @static
     */
    function read(input: Uint8Array): Promise<Message>;
  }

  export class HKP {
    constructor(keyServerBaseUrl?: string);
    lookup(options: { keyid?: string, query?: string }): Promise<string | undefined>;
  }

  /**
   * todo - some of these are outdated - check OpenPGP.js api
   */
  export namespace util {
    /** Convert an array of integers(0.255) to a string
        @param bin An array of (binary) integers to convert
    */
    function bin2str(bin: Array<number>): string;

    /** Calculates a 16bit sum of a string by adding each character codes modulus 65535
        @param text string to create a sum of
    */
    function calc_checksum(text: string): number;

    /** Convert a string of utf8 bytes to a native javascript string
        @param utf8 A valid squence of utf8 bytes
    */
    function decode_utf8(utf8: string): string;

    /** Convert a native javascript string to a string of utf8 bytes
        param str The string to convert
    */
    function encode_utf8(str: string): string;

    /** Return the algorithm type as string
     */
    function get_hashAlgorithmString(): string;

    /** Get native Web Cryptography api. The default configuration is to use the api when available. But it can also be deactivated with config.useWebCrypto
     */
    function getWebCrypto(): object;

    /** Helper function to print a debug message. Debug messages are only printed if
        @param str string of the debug message
    */
    function print_debug(str: string): void;

    /** Helper function to print a debug message. Debug messages are only printed if
        @param str string of the debug message
    */
    function print_debug_hexstr_dump(str: string): void;

    /** Shifting a string to n bits right
        @param value The string to shift
        @param bitcount Amount of bits to shift (MUST be smaller than 9)
    */
    function shiftRight(value: string, bitcount: number): string;

    /**
     * Convert a string to an array of 8-bit integers
     * @param {String} str String to convert
     * @returns {Uint8Array} An array of 8-bit integers
     */
    function str_to_Uint8Array(str: string): Uint8Array;

    /**
     * Convert an array of 8-bit integers to a string
     * @param {Uint8Array} bytes An array of 8-bit integers to convert
     * @returns {String} String representation of the array
     */
    function Uint8Array_to_str(bin: Uint8Array): string;

    /**
     * Convert an array of 8-bit integers to a hex string
     * @param {Uint8Array} bytes Array of 8-bit integers to convert
     * @returns {String} Hexadecimal representation of the array
     */
    function Uint8Array_to_hex(bytes: Uint8Array): string;

    /**
     * Convert a hex string to an array of 8-bit integers
     * @param {String} hex  A hex string to convert
     * @returns {Uint8Array} An array of 8-bit integers
     */
    function hex_to_Uint8Array(hex: string): Uint8Array;

    /**
     * Create hex string from a binary
     * @param {String} str String to convert
     * @returns {String} String containing the hexadecimal values
     */
    function str_to_hex(str: string): string;

    /**
     * Create binary string from a hex encoded string
     * @param {String} str Hex string to convert
     * @returns {String}
     */
    function hex_to_str(hex: string): string;

    function parseUserId(userid: string): UserId;

    function formatUserId(userid: UserId): string;

    function normalizeDate(date: Date | null): Date | null;
  }

  export namespace stream {
    function readToEnd<T extends Uint8Array | string>(input: Stream<T> | T, concat?: (list: T[]) => T): Promise<T>;
    // concat
    // slice
    // clone
    // webToNode
    // nodeToWeb
  }

}
