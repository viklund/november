use v6;

sub file_exists( $file ) {
    # RAKUDO: use ~~ :e
    my $exists = False;
    try {
        my $fh = open( $file );
        $exists = True;
    }
    return $exists;
}

sub r_remove( $str is rw ) {
    # RAKUDO: :g not implemented yet :( 
    while $str ~~ /\\r/ {
        $str = $str.subst( /\\r/, '' );
    }
}

# vim:ft=perl6
