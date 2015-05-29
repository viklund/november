unit module November::Utils;

sub r_remove( $str is rw ) is export {
    $str .= subst( /\\r/, '', :g );
}

sub get_unique_id is export {
    # hopefully pretty unique ID
    return (time%1000000/100).Int ~ time%100

    # mb that? just for simple time extracts after?
    # return int rand ~ ':' ~ time;
}

sub get_period ($modif_time, $time_now?) is export {
    my $time = $time_now || time.Int;
    my $period = $time - $modif_time;

    my $mins  = ($period / 60).Int;
    my $hours = ($period / 60 / 60).Int;
    my $days  = ($period / 60 / 60 / 24).Int;

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

sub time_to_period_str ($time) is export {
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
