import { Data, MaybeStream } from "openpgp";

declare module "@openpgp/web-stream-tools" {
    export function readToEnd<T extends Data>(input: MaybeStream<T>, concat?: (list: T[]) => T): Promise<T>;
}
