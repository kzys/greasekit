/*
 * Copyright (c) 2005-2006 KATO Kazuyoshi
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */

#import "JapaneseString.h"

const char *guess_jp(const char *buf, int buflen, void *data);

@implementation JapaneseString

+ (NSStringEncoding) detectEncoding: (NSData*) data
{
    unsigned char* ptr = (unsigned char*) [data bytes];
    
	// Too short
	if ( ptr == NULL || *ptr == '\0') {
		return NSASCIIStringEncoding;
	}
	
	// UTF-16 LE or BE
	if (*ptr == 0xff && *(ptr + 1) == 0xfe) {
		return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF16LE);		
	}
	if (*ptr == 0xfe && *(ptr + 1) == 0xff) {
		return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF16BE);		
	}
    
    const char* s = guess_jp((char*) ptr, [data length], NULL);
    if (s == NULL) {
        return NSASCIIStringEncoding;
    } else if (strcmp(s, "EUC-JP") == 0) {
        return NSJapaneseEUCStringEncoding;
    } else if (strcmp(s, "UTF-8") == 0) {
        return NSUTF8StringEncoding;
    } else if (strcmp(s, "Shift_JIS") == 0) {
        return NSShiftJISStringEncoding;
    } else if (strcmp(s, "ISO-2022-JP") == 0) {
        return NSISO2022JPStringEncoding;
    }
	
	return NSASCIIStringEncoding;
}

@end
