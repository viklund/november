#!perl6

use Impatience;

class CGI {
    has %.param is rw;
    has %.cookie is rw;
    #method param($param)      { return 'Main_Page' }

    # RAKUDO: BUILD method not supported
    method init() {
        my %params = parse_params( %*ENV<QUERY_STRING> );

        #if %*ENV<REQUEST_METHOD> eq 'POST' && %*ENV{CONTENT_LENGTH} > 0 {
        if %*ENV<REQUEST_METHOD> eq 'POST' {
            # Maybe check content_length here and only take that many bytes?
            my $input = $*IN.slurp();
            my %post_params = parse_params( $input );
            for %post_params.kv -> $k, $v {
            # TODO: Check if key exists, if so make an array
                %params{$k} = $v;
            }
        }
        $.param = %params;

        my %cookie = parse_params(%*ENV<HTTP_COOKIE>);
        $.cookie = %cookie;
    }

    # For debugging
    method save_params() {
        my $debug = open('/tmp/debug.out', :w);
        for $.param.kv -> $k, $v {
            $debug.say("$k => $v");
        }
        $debug.close;
    }

    method send_response($contents, %opts?) {
        # The header
        print "Content-Type: text/html\r\n";
        if %opts && %opts<cookie> {
            print 'Set-Cookie: ' ~ %opts<cookie> ~ "; path=/;\r\n";
        }
        print "\r\n";
        print $contents;
    }

    sub parse_params($string is rw) {
        my @param_values = split('&' , $string);
        my %param_temp;
        for @param_values -> $param_value {
            my @kvs = split('=', $param_value);
            # TODO: Check if key exists, if so make an array
            %param_temp{@kvs[0]} = unescape(@kvs[1]);
        }
        return %param_temp;
    }

    sub unescape($string is rw) {
        # RAKUDO: :g plz
        while $string ~~ /\+/ {
            $string = $string.subst('+', ' ');
        }
        while ( $string ~~ /\%(..)/ ) {
            my $match = $0;
            my $character = chr(:16($match));
            # RAKUDO: DOTTY
            $string = $string.subst('%' ~ $match, $character);
        }
        return $string;
    }
}

