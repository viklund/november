use v6;

sub r_remove( $str is rw ) is export {
    $str .= subst( /\\r/, '', :g );
}

sub get_unique_id is export {
    # hopefully pretty unique ID
    return int(time%1000000/100) ~ time%100

    # mb that? just for simple time extracts after?
    # return int rand ~ ':' ~ time;
}

sub get_period ($modif_time, $time_now?) is export {
    my $time = $time_now || int(time);
    my $period = $time - $modif_time;

    my $mins  = int($period / 60);
    my $hours = int($period / 60 / 60);
    my $days  = int($period / 60 / 60 / 24);

    if $days >= 1 {
        $hours = $hours - $days * 24;
        $mins = $mins - $days * 60 * 24;
    } else {
        $days = 0;
    }

    if $hours >= 1 {
        $mins = $mins - $hours * 60;
    }
    else {
        $hours = 0;
    }

    $mins = 1 if $mins < 1;
    return ($days, $hours, $mins)
}

sub time_to_period_str ($time) {
    return False unless $time;
    my $t = get_period($time);
    my $str =  '~'; 

    # return only days if period > day
    if $t[0] -> $days {
        $str ~= $days;
        $str ~= (+$days == 1 ) ?? ' day' !! ' days';
        $str ~= ' ago';
        return $str;
    }

    $str ~= $t[1] ~ 'h ' if $t[1];
    $str ~= $t[2] ~ 'm ago';
    return $str;
}


# vim:ft=perl6
