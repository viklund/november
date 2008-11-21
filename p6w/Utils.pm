use v6;

sub r_remove( $str is rw ) is export {
    # RAKUDO: :g not implemented yet :( 
    while $str ~~ /\\r/ {
        $str = $str.subst( /\\r/, '' );
    }
}

sub get_unique_id is export {
    # hopefully pretty unique ID
    return int(time%1000000/100) ~ time%100
}

# vim:ft=perl6
