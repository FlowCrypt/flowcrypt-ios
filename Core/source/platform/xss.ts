import { Str } from '../core/common';

type Attributes = { [attr: string]: string };
type Tag = { tagName: string; attribs: Attributes; text?: string; };
type Transformer = (tagName: string, attribs: Attributes) => Tag;

export type SanitizeImgHandling = 'IMG-DEL' | 'IMG-KEEP' | 'IMG-TO-LINK';

declare const dereq_html_sanitize: (dirty: string, opts?: {
  allowedTags?: string[],
  selfClosing?: string[],
  exclusiveFilter?: (frame: { tag: string, attribs: Attributes, text: string, tagPosition: number }) => boolean,
  transformTags?: { [tagName: string]: string | Transformer };
  allowedAttributes?: { [tag: string]: string[] },
  allowedSchemes?: string[],
}) => string;

/**
 * This file needs to be in platform/ folder because its implementation is platform-dependant
 *  - on browser, it uses DOMPurify
 *  - in Node (targetting mobile-core environment) it uses sanitize-html
 * It would be preferable to use DOMPurify on all platforms, but on Node it has a JSDOM dependency which is itself 20MB of code, not acceptable on mobile.
 */
export class Xss {

  private static ALLOWED_BASIC_TAGS = ['p', 'div', 'br', 'u', 'i', 'em', 'b', 'ol', 'ul', 'pre', 'li', 'table', 'thead', 'tbody', 'tfoot', 'tr', 'td', 'th',
    'img', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'address', 'blockquote', 'dl', 'fieldset', 'a', 'font', 'strong', 'strike', 'code'];

  private static ALLOWED_ATTRS = {
    a: ['href', 'name', 'target'],
    img: ['src', 'width', 'height', 'alt'],
    font: ['size', 'color', 'face'],
    span: ['color'],
    div: ['color'],
    p: ['color'],
    em: ['style'], // tests rely on this, could potentially remove
    td: ['width', 'height'],
    hr: ['color', 'height'],
  };

  private static ALLOWED_SCHEMES = ['data', 'http', 'https', 'mailto'];

  /**
   * used whenever untrusted remote content (eg html email) is rendered, but we still want to preserve html
   * imgToLink is ignored on Node. Remote links are replaced with <a>, and local imgs are preserved
   */
  public static htmlSanitizeKeepBasicTags = (dirtyHtml: string, imgToLink?: SanitizeImgHandling): string => {
    const imgContentReplaceable = `IMG_ICON_${Str.sloppyRandom()}`;
    let remoteContentReplacedWithLink = false;
    let cleanHtml = dereq_html_sanitize(dirtyHtml, {
      allowedTags: Xss.ALLOWED_BASIC_TAGS,
      allowedAttributes: Xss.ALLOWED_ATTRS,
      allowedSchemes: Xss.ALLOWED_SCHEMES,
      transformTags: {
        'img': (tagName, attribs) => {
          const srcBegin = (attribs.src || '').substring(0, 10);
          if (srcBegin.startsWith('data:')) {
            return { tagName: 'img', attribs: { src: attribs.src, alt: attribs.alt || '' } };
          } else if (srcBegin.startsWith('http://') || srcBegin.startsWith('https://')) {
            remoteContentReplacedWithLink = true;
            return { tagName: 'a', attribs: { href: String(attribs.src), target: "_blank" }, text: imgContentReplaceable };
          } else {
            return { tagName: 'img', attribs: { alt: attribs.alt, title: attribs.title }, text: '[img]' } as Tag;
          }
        },
        '*': (tagName, attribs) => {
          // let the browser decide how big should elements be, based on their content, except for img
          // attribs.height|width === 1 are left in only so that they can be removed in exclusiveFilter below
          if (attribs.width && attribs.width !== '1' && tagName !== 'img') {
            delete attribs.width;
          }
          if (attribs.height && attribs.height !== '1' && tagName !== 'img') {
            delete attribs.width;
          }
          return { tagName, attribs };
        },
      },
      exclusiveFilter: ({ tag, attribs }) => {
        if (attribs.width === '1' || (attribs.height === '1' && tag !== 'hr')) {
          return true; // remove tiny elements (often contain hidden content, tracking pixels, etc)
        }
        return false;
      }
    });
    if (remoteContentReplacedWithLink) {
      cleanHtml = `<font size="-1" color="#31a217" face="monospace">[remote content blocked for your privacy]</font><br /><br />${cleanHtml}`;
      // clean it one more time in case something bad slipped in
      cleanHtml = dereq_html_sanitize(cleanHtml, { allowedTags: Xss.ALLOWED_BASIC_TAGS, allowedAttributes: Xss.ALLOWED_ATTRS, allowedSchemes: Xss.ALLOWED_SCHEMES });
    }
    cleanHtml = cleanHtml.replace(new RegExp(imgContentReplaceable, 'g'), `<font color="#D14836" face="monospace">[img]</font>`);
    return cleanHtml;
  }

  public static htmlSanitizeAndStripAllTags = (dirtyHtml: string, outputNl: string): string => {
    let html = Xss.htmlSanitizeKeepBasicTags(dirtyHtml);
    const random = Str.sloppyRandom(5);
    const br = `CU_BR_${random}`;
    const blockStart = `CU_BS_${random}`;
    const blockEnd = `CU_BE_${random}`;
    html = html.replace(/<br[^>]*>/gi, br);
    html = html.replace(/\n/g, '');
    html = html.replace(/<\/(p|h1|h2|h3|h4|h5|h6|ol|ul|pre|address|blockquote|dl|div|fieldset|form|hr|table)[^>]*>/gi, blockEnd);
    html = html.replace(/<(p|h1|h2|h3|h4|h5|h6|ol|ul|pre|address|blockquote|dl|div|fieldset|form|hr|table)[^>]*>/gi, blockStart);
    html = html.replace(RegExp(`(${blockStart})+`, 'g'), blockStart).replace(RegExp(`(${blockEnd})+`, 'g'), blockEnd);
    html = html.split(br + blockEnd + blockStart).join(br).split(blockEnd + blockStart).join(br).split(br + blockEnd).join(br);
    let text = html.split(br).join('\n').split(blockStart).filter(v => !!v).join('\n').split(blockEnd).filter(v => !!v).join('\n');
    text = text.replace(/\n{2,}/g, '\n\n');
    // not all tags were removed above. Remove all remaining tags
    text = dereq_html_sanitize(text, {
      allowedTags: ['img', 'span'],
      allowedAttributes: { img: ['src'] },
      allowedSchemes: Xss.ALLOWED_SCHEMES,
      transformTags: {
        'img': (tagName, attribs) => {
          return { tagName: 'span', attribs: {}, text: `[image: ${attribs.alt || attribs.title || 'no name'}]` };
        },
      }
    });
    text = dereq_html_sanitize(text, { allowedTags: [] }); // clean it one more time to replace leftover spans with their text
    text = text.trim();
    if (outputNl !== '\n') {
      text = text.replace(/\n/g, outputNl);
    }
    return text;
  }

  public static escape = (str: string) => {
    return str.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/'/g, '&#39;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\//g, '&#x2F;');
  }

  public static escapeTextAsRenderableHtml = (text: string) => {
    return Xss.escape(text)
      .replace(/\n/g, '<br>\n') // leave newline so that following replaces work
      .replace(/^ +/gm, spaces => spaces.replace(/ /g, '&nbsp;'))
      .replace(/^\t+/gm, tabs => tabs.replace(/\t/g, '&#9;'))
      .replace(/\n/g, ''); // strip newlines, already have <br>
  }

  public static htmlUnescape = (str: string) => {
    // the &nbsp; at the end is replaced with an actual NBSP character, not a space character. IDE won't show you the difference. Do not change.
    return str.replace(/&#x2F;/g, '/').replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&').replace(/&nbsp;/g, ' ');
  }

}
