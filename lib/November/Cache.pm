role November::Cache;

use November::Config;

method cache-dir {
    return $.config.server_root ~ 'data/cache';
}

method set-cache-entry( $key, $value ) {
    my $file = self.cache-dir ~ '/' ~ $key;
    my $fh = open( $file, :w );
    $fh.say( $value );
    $fh.close;
}

method get-cache-entry( $key ) {
    my $file = self.cache-dir ~ '/' ~ $key;
    return undef unless $file ~~ :e;
    my $string = slurp( $file );
    return $string;
}

method remove-cache-entry( $key ) {
    my $file = self.cache-dir ~ '/' ~ $key;
    return unless $file ~~ :e;
    unlink( $file );
}

# vim:ft=perl6
