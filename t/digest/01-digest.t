
use Test;
use Digest;

plan 3;

my $text = "The quick brown fox jumps over the lazy dog";

ok(digest($text)
    eq "9e107d9d372bb6826bd81d3542a419d6",
    'Default is MD5');
ok(digest($text, "md5")
    eq "9e107d9d372bb6826bd81d3542a419d6",
    'MD5 is correct');
#ok(Digest::digest($text, "sha1")
#    eq "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12",
#    'SHA1 is correct');
ok(digest($text, "sha256")
    eq "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592",
    'SHA256 is correct');
#ok(Digest::digest($text, "sha512")
#    eq "07e547d9586f6a73f73fbac0435ed76951218fb7d0c8d788a309d785436bbb642e93a252a954f23912547d1e8a3b5ed6e1bfd7097821233fa0538f3db854fee6",
#    'SHA512 is correct');
#ok(Digest::digest($text, "ripemd160")
#    eq "37f332f68db77bd9d7edd4969571ad671cf9dd3b",
#    'ripemd160 is correct');
