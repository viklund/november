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

    # mb that? just for simple time extracts after?
    # return int rand ~ ':' ~ time;
}

sub get_period ($modif_time, $time_now?) is export {
    my $time = $time_now || int time;
    my $period = $time - $modif_time;
    my $min = int($period / 60);
    my $hour = int($period / 60 / 60);

    if $hour >= 1 {
        $min = $min - $hour * 60;
    }
    else {
        $hour = 0;
    }
    $min = 1 if $min < 1;
    return ($hour, $min)
}

# vim:ft=perl6
