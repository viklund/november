role Cache;

use Config;

has $.cache_dir = Config.server_root ~ 'data/cache';

method set-cache-entry( $key, $value ) {
    my $file = $.cache_dir ~ '/' ~ $key;
    my $fh = open( $file, :w );
    say 'DOUBLE SETTING';
    $fh.say( $value.perl );
    say 'TRIPPLE SETTING';
    $fh.close;
}

method get-cache-entry( $key ) {
    my $file = $.cache_dir ~ '/' ~ $key;
    return undef unless $file ~~ :e;
    my $string = slurp( $file );
    my $stuff = eval( $string );
    return $stuff;
}

method remove-cache-entry( $key ) {
    my $file = $.cache_dir ~ '/' ~ $key;
    return unless $file ~~ :e;
    unlink( $file );
}

# vim:ft=perl6
