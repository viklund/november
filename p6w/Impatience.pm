use v6;

sub r_remove( $str is rw ) is export {
    # RAKUDO: :g not implemented yet :( 
    while $str ~~ /\\r/ {
        $str = $str.subst( /\\r/, '' );
    }
}

sub delete_key(Hash $hash is rw, $key) is export {
    my $new_hash = {};
    for $hash.kv -> $k, $v {
        $new_hash{$k} = $v unless $k eq $key;
    }
    # RAKUDO: Cannot morph a Perl6Scalar. Argh! :(
    $hash = $new_hash;
}
# vim:ft=perl6
