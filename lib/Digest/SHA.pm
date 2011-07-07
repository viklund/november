class Digest::SHA:auth<thou>:ver<0.01> {
    pir::load_bytecode('Digest/sha256.pbc');

    multi method sha256_hex (Str $str) {
        my $sha256_hex = Q:PIR {
            .local pmc f, g, str
            str = find_lex '$str'
            f = get_root_global ['parrot'; 'Digest'], '_sha256sum'
            $P1 = f(str)
            g = get_root_global ['parrot'; 'Digest'], '_sha256_hex'
            $S0 = g($P1)
            %r = box $S0
        };

        return $sha256_hex;
    }

    multi method sha256_hex (@strs) {
        return self.sha256_hex(@strs.join(""));
    }
}

