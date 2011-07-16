class November::Request;

use November::URI;

has %.params;
has %.cookie;
has @.keywords;
has November::URI $.uri;

submethod BUILD (:%env) {
    self.parse_params(%env<QUERY_STRING> // '');
    # It's prudent to handle CONTENT_LENGTH too, but right now that's not
    # a priority. It would make our tests scripts more complicated, with
    # little gains. It would look like this:
    # if %env<REQUEST_METHOD> eq 'POST' && %env{CONTENT_LENGTH} > 0 {
    if %env<REQUEST_METHOD> eq 'POST' {
        # Maybe check content_length here and only take that many bytes?
        my $fh = %env.delete('psgi.input');
        my $input = $fh ?? $fh.slurp !! '';
        self.parse_params($input);
    }

    self.eat_cookie( %env<HTTP_COOKIE> ) if %env<HTTP_COOKIE>;

    my $uri_str = 'http://' ~ %env<SERVER_NAME>;
    $uri_str ~= ':' ~ %env<SERVER_PORT> if %env<SERVER_PORT>;
    $uri_str ~= %env<REQUEST_URI>;

    $!uri = November::URI.new( uri => $uri_str );
}

# For debugging
method save_params() {
    my $debug = open('/tmp/debug.out', :w);
    for $.param.kv -> $k, $v {
        $debug.say("$k => $v");
    }
    $debug.close;
}

method parse_params($string) {
    if $string ~~ / '&' | ';' | '=' / {
        my @param_values = $string.split(/ '&' | ';' /);

        for @param_values -> $param_value {
            my @kvs = $param_value.split("=");
            self.add_param( @kvs[0], unescape(@kvs[1]) );
        }
    }
    else {
        self.parse_keywords($string);
    }
}

method parse_keywords (Str $string is copy) {
    my $kws = unescape($string);
    @!keywords = $kws.split(/ \s+ /);
}

method eat_cookie(Str $http_cookie) {
    # RAKODO: split(/ ; ' '? /) produce [""] on "", perl #60228 should cure that
    my @param_values  = $http_cookie.split('; ');

    for @param_values -> $param_value {
        my @kvs = $param_value.split('=');
        %!cookie{ @kvs[0] } = unescape( @kvs[1] );
    }
}

our sub unescape($string is copy) {
    $string .= subst('+', ' ', :g);
    # RAKUDO: This could also be rewritten as a single .subst :g call.
    #         ...when the semantics of .subst is revised to change $/,
    #         that is.
    # The percent_hack can be removed once the bug is fixed and :g is
    # added
    while $string ~~ / ( [ '%' <[0..9A..F]>**2 ]+ ) / {
        $string .= subst( ~$0,
        percent_hack_start( decode_urlencoded_utf8( ~$0 ) ) );
    }
    return percent_hack_end( $string );
}

sub percent_hack_start($str is rw) {
    if $str ~~ '%' {
        $str = '___PERCENT_HACK___';
    }
    return $str;
}

sub percent_hack_end($str) {
    return $str.subst('___PERCENT_HACK___', '%', :g);
}

sub decode_urlencoded_utf8($str) {
    my $r = '';
    my @chars = map { :16($_) }, $str.split('%').grep({$^w});
    while @chars {
        my $bytes = 1;
        my $mask  = 0xFF;
        given @chars[0] {
            when { $^c +& 0xF0 == 0xF0 } { $bytes = 4; $mask = 0x07 }
            when { $^c +& 0xE0 == 0xE0 } { $bytes = 3; $mask = 0x0F }
            when { $^c +& 0xC0 == 0xC0 } { $bytes = 2; $mask = 0x1F }
        }
        my @shift = (^$bytes).reverse.map({6 * $_});
        my @mask  = $mask, 0x3F xx $bytes-1;
        $r ~= chr( [+] @chars.splice(0,$bytes) »+&« @mask »+<« @shift );
    }
    return $r;
}

method add_param ( Str $key, $value ) {
    # RAKUDO: (Hash :exists not implemented yet)
    # if %.params{$key} :exists {
    if %.params.exists($key) {
        if %.params{$key} ~~ Array {
            %!params{$key}.push( $value );
        }
        else {
            my $old_param = %.params{$key};
            %!params{$key} = [ $old_param, $value ];
        }
    }
    else {
        %!params{$key} = $value;
    }
}

method param ($key) {
   return %.params{$key};
}


# vim:set ft=perl6:
