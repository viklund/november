use v6;
use November__Impatience;  # RAKUDO: :: in module names doesn't fully work

class CGI {
    has %.param is rw;
    has %.cookie is rw;
    has @.keywords is rw;

    # RAKUDO: BUILD method not supported
    method init() {
        my %params;
        self.parse_params(%params, %*ENV<QUERY_STRING>);

        # It's prudent to handle CONTENT_LENGTH too, but right now that's not
        # a priority. It would make our tests scripts more complicated, with
        # little gains. It would look like this:
        # if %*ENV<REQUEST_METHOD> eq 'POST' && %*ENV{CONTENT_LENGTH} > 0 {
        if %*ENV<REQUEST_METHOD> eq 'POST' {
            # Maybe check content_length here and only take that many bytes?
            my $input = $*IN.slurp();
            self.parse_params(%params, $input);
        }
        $.param = %params;

        self.eat_cookie( %*ENV<HTTP_COOKIE> );
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

    method redirect($uri, %opts?) {
        my $status = '302 Moved' || %opts<status>;
        print "Status: $status\r\n";
        print "Location: $uri";
        print "\r\n\r\n";
    }

    method parse_params(Hash %params is rw, $string) {
        if $string ~~ / '&' | ';' | '=' / {
            my @param_values = $string.split(/ '&' | ';' /);

            for @param_values -> $param_value {
                my @kvs = split('=', $param_value);
                self.add_param( %params, @kvs[0], unescape(@kvs[1]) );
            }
        } 
        else {
            self.parse_keywords($string);
        }
    }

    method parse_keywords (Str $string is copy) {
        my $kws = unescape($string); 
        @.keywords = $kws.split(/ \s+ /);
    }

    method eat_cookie(Str $http_cookie) {
        # RAKODO: split(/ ; ' '? /) produce [""] on "" 
        # and ["foo;", ""] on 'foo;'
        my @param_values  = $http_cookie.split('; ');

        for @param_values -> $param_value {
            my @kvs = split('=', $param_value);
            %.cookie{ @kvs[0] } = unescape( @kvs[1] );
        }
    }

    sub unescape($string is rw) {
        # RAKUDO: :g plz
        while $string ~~ /\+/ {
            $string .= subst('+', ' ');
        }
        # RAKUDO: This could also be rewritten as a single .subst :g call.
        while $string ~~ /\%(..)/ {
            my $match = $0;
            my $character = chr(:16($match));
            # RAKUDO: DOTTY
            $string .= subst('%' ~ $match, $character);
        }
        return $string;
    }

    method add_param ( Hash %params is rw, Str $key, $value ) {
        # RAKUDO: синтаксис Hash.:exists{key} еще не реализован 
        #        (Hash.:exists{key} not implemented yet)
        # if %params.:exists{$key} {

        if %params.exists($key) {
            # RAKUDO: ~~ Scalar
            if %params{$key} ~~ Str | Int {
                %params{$key} = [ %params{$key}, $value ];
            } 
            elsif %params{$key} ~~ Array {
                %params{$key}.push( $value );
            } 
        }
        else {
            %params{$key} = $value;
        }
    }

}

# vim:ft=perl6
