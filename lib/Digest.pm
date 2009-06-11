module Digest;

# Known digests: md5, sha1, sha256, sha512, ripemd160
sub digest(Str $text, Str $algo is copy = 'md5') is export {
	$algo = uc $algo;
	my $binary = Q:PIR {
		.local string text
		.local string algo
		.local pmc digest
		
		# Input
		$P0 = find_lex '$text'
		text = $P0
		$P0 = find_lex '$algo'
		algo = $P0
		
		# Choose the right digest.
		$P1 = loadlib 'digest_group'
		if algo == 'MD5' goto MD5
		if algo == 'SHA1' goto SHA1
		if algo == 'SHA256' goto SHA256
		if algo == 'SHA512' goto SHA512
		if algo == 'RIPEMD160' goto RIPEMD160
	MD5:
		digest = new 'MD5'
		goto COMPUTE
	SHA1:
		digest = new 'SHA1'
		goto COMPUTE
	SHA256:
		digest = new 'SHA256'
		goto COMPUTE
	SHA512:
		digest = new 'SHA512'
		goto COMPUTE
	RIPEMD160:
		digest = new 'RIPEMD160'
		goto COMPUTE
	
	COMPUTE:
		# Calculate the digest.
		digest.'Init'()
		digest.'Update'(text)
		$S0 = digest.'Final'()
		
		%r = box $S0
	};
	# Convert to hex.
	return join '', map { sprintf '%02x', (ord $^a) }, $binary.comb;
}
