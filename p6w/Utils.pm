use v6;

sub get_unique_id is export {
    # hopefully pretty unique ID
    return int(time%1000000/100) ~ time%100
}

# vim:ft=perl6
