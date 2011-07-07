module Digest;

use Digest::MD5;
use Digest::SHA;

# Known digests: md5, sha1, sha256, sha512, ripemd160
sub digest(Str $text, Str $algo = 'md5') is export {
	given $algo {
		when 'md5' { return Digest::MD5.md5_hex($text) }
		when 'sha256' { return Digest::SHA.sha256_hex($text) }
		default { !!! "digest for $algo not yet implemented" }
	}
}
