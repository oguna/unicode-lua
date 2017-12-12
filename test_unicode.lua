require("unicode")

utf32_abc = unicode.utf8_to_utf32('abc')
assert(#utf32_abc == 3)
assert(utf32_abc[1] == 97)
assert(utf32_abc[2] == 98)
assert(utf32_abc[3] == 99)
utf8_abc = unicode.utf32_to_utf8(utf32_abc)
assert(utf8_abc == "abc")

utf32_hiragana = unicode.utf8_to_utf32('あいう')
assert(#utf32_hiragana == 3)
assert(utf32_hiragana[1] == 0x3042)
assert(utf32_hiragana[2] == 0x3044)
assert(utf32_hiragana[3] == 0x3046)
utf8_hiragana = unicode.utf32_to_utf8(utf32_hiragana)
assert(utf8_hiragana == 'あいう')

utf16_abc = unicode.utf8_to_utf16('abc')
assert(#utf16_abc == 3)
assert(utf16_abc[1] == 97)
assert(utf16_abc[2] == 98)
assert(utf16_abc[3] == 99)
utf8_abc = unicode.utf16_to_utf8(utf16_abc)
assert(utf8_abc == "abc")

utf16_hiragana = unicode.utf8_to_utf16('あいう')
assert(#utf16_hiragana == 3)
assert(utf16_hiragana[1] == 0x3042)
assert(utf16_hiragana[2] == 0x3044)
assert(utf16_hiragana[3] == 0x3046)
utf8_hiragana = unicode.utf16_to_utf8(utf16_hiragana)
assert(utf8_hiragana == 'あいう')

utf16_tuchiyoshi = {0xd842, 0xdfb7}
utf32_tuchiyoshi = unicode.utf16_to_utf32(utf16_tuchiyoshi)
assert(#utf32_tuchiyoshi == 1)
assert(utf32_tuchiyoshi[1] == 134071)
utf16_tuchiyoshi_2 = unicode.utf32_to_utf16(utf32_tuchiyoshi)
assert(#utf16_tuchiyoshi_2 == 2)
assert(utf16_tuchiyoshi_2[1] == 0xd842)
assert(utf16_tuchiyoshi_2[2] == 0xdfb7)

print("DONE")