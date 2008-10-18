use v6;

sub r_remove( $str is rw ) {
    # RAKUDO: :g not implemented yet :( 
    while $str ~~ /\\r/ {
        $str = $str.subst( /\\r/, '' );
    }
}

# vim:ft=perl6
