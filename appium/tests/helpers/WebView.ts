export const CONTEXT_REF = {
  NATIVE: 'native',
  WEBVIEW: 'webview',
};
const DOCUMENT_READY_STATE = {
  COMPLETE: 'complete',
  INTERACTIVE: 'interactive',
  LOADING: 'loading',
};

class WebView {
  /**
   * Wait for the webview context to be loaded
   *
   * By default you have `NATIVE_APP` as the current context. If a webview is loaded it will be
   * added to the current contexts and will looks something like this for iOS
   * `["NATIVE_APP","WEBVIEW_28158.2"]`
   * The number behind `WEBVIEW` will be a random number in random order.
   */
  static waitForWebViewContextLoaded = async () => {
    await driver.waitUntil(
      async () => {
        const currentContexts = await this.getCurrentContexts();

        return (
          currentContexts.length > 1 &&
          currentContexts.find(context => context.toLowerCase().includes(CONTEXT_REF.WEBVIEW)) !== 'undefined'
        );
      },
      {
        // Wait a max of 45 seconds. Reason for this high amount is that loading
        // a webview for iOS might take longer
        timeout: 45000,
        timeoutMsg: 'Webview context not loaded',
        interval: 100,
      },
    );
  };

  /**
   * Switch to native or webview context
   */
  static switchToContext = async (context: string) => {
    // The first context will always be the NATIVE_APP,
    // the second one will always be the WebdriverIO web page
    await driver.switchContext((await this.getCurrentContexts())[context === CONTEXT_REF.NATIVE ? 0 : 1]);
  };

  /**
   * Wait for the document to be fully loaded
   */
  static waitForDocumentFullyLoaded = async () => {
    await driver.waitUntil(
      // A webpage can have multiple states, the ready state is the one we need to have.
      // This looks like the same implementation as for the w3c implementation for `browser.url('https://webdriver.io')`
      // That command also waits for the readiness of the page, see also the w3c specs
      // https://www.w3.org/TR/webdriver/#dfn-waiting-for-the-navigation-to-complete
      // eslint-disable-next-line @typescript-eslint/no-unsafe-return
      async () => (await driver.execute(() => document.readyState)) === DOCUMENT_READY_STATE.COMPLETE,
      {
        timeout: 15000,
        timeoutMsg: 'Website not loaded',
        interval: 100,
      },
    );
  };

  /**
   * Get document content
   */
  static getDocumentContent = async () => {
    await this.waitForWebViewContextLoaded();
    await this.switchToContext(CONTEXT_REF.WEBVIEW);
    await this.waitForDocumentFullyLoaded();
    const content = await driver.execute(() => String(document.body.innerText));
    await this.switchToContext(CONTEXT_REF.NATIVE);
    return content;
  };

  /**
   * Returns an object with the list of all available contexts
   */
  static getCurrentContexts = async (): Promise<string[]> => {
    const contexts = await driver.getContexts();
    return contexts.map(context => context.toString());
  };
}

export default WebView;
