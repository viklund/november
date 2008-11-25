use v6;

class CGI {
    has %.params;
    has %.cookie;
    has @.keywords;

    has $!crlf;

    # RAKUDO: BUILD method not supported
    method init() {
        self.parse_params(%*ENV<QUERY_STRING>);

        # It's prudent to handle CONTENT_LENGTH too, but right now that's not
        # a priority. It would make our tests scripts more complicated, with
        # little gains. It would look like this:
        # if %*ENV<REQUEST_METHOD> eq 'POST' && %*ENV{CONTENT_LENGTH} > 0 {
        if %*ENV<REQUEST_METHOD> eq 'POST' {
            # Maybe check content_length here and only take that many bytes?
            my $input = $*IN.slurp();
            self.parse_params($input);
        }

        self.eat_cookie( %*ENV<HTTP_COOKIE> );
        $!crlf = "\x[0D]\x[0A]";
    }

    # For debugging
    method save_params() {
        my $debug = open('/tmp/debug.out', :w);
        for $.param.kv -> $k, $v {
            $debug.say("$k => $v");
        }
        $debug.close;
    }

# From `perldoc perlop`:
#
#      All systems use the virtual "\n" to represent a line terminator, called
#      a "newline".  There is no such thing as an unvarying, physical newline
#      character.  It is only an illusion that the operating system, device
#      drivers, C libraries, and Perl all conspire to preserve.  Not all
#      systems read "\r" as ASCII CR and "\n" as ASCII LF.  For example, on a
#      Mac, these are reversed, and on systems without line terminator,
#      printing "\n" may emit no actual data.  In general, use "\n" when you
#      mean a "newline" for your system, but use the literal ASCII when you
#      need an exact character.  For example, most networking protocols expect
#      and prefer a CR+LF ("\015\012" or "\cM\cJ") for line terminators, and
#      although they often accept just "\012", they seldom tolerate just
#      "\015".  If you get in the habit of using "\n" for networking, you may
#      be burned some day.

    method send_response($contents, %opts?) {
        # The header
        print "Content-Type: text/html$!crlf";
        if %opts && %opts<cookie> {
            print "Set-Cookie: {%opts<cookie>}; path=/;$!crlf";
        }
        print "$!crlf";
        print $contents;
    }

    method redirect($uri, %opts?) {
        my $status = '302 Moved' || %opts<status>;
        print "Status: $status$!crlf";
        print "Location: $uri";
        print "$!crlf$!crlf";
    }

    method parse_params($string) {
        if $string ~~ / '&' | ';' | '=' / {
            my @param_values = $string.split(/ '&' | ';' /);

            for @param_values -> $param_value {
                my @kvs = split('=', $param_value);
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
            my @kvs = split('=', $param_value);
            %!cookie{ @kvs[0] } = unescape( @kvs[1] );
        }
    }

    sub unescape($string is rw) {
        # RAKUDO: :g plz
        while $string ~~ /\+/ {
            $string .= subst('+', ' ');
        }
        # RAKUDO: This could also be rewritten as a single .subst :g call.
        while $string ~~ /\%(<[0..9A..F]>**2)/ {
            my $match = $0;
            my $character = chr(:16($match));
            # RAKUDO: DOTTY
            $string .= subst('%' ~ $match, $character);
        }
        return $string;
    }

    method add_param ( Str $key, $value ) {
        # RAKUDO: синтаксис Hash :exists{key} еще не реализован 
        #        (Hash :exists{key} not implemented yet)
        # if %.params :exists{$key} {
        if %.params.exists($key) {
            # RAKUDO: ~~ Scalar
            if %.params{$key} ~~ Str | Int {
                my $old_param = %.params{$key};
                %!params{$key} = [ $old_param, $value ];
            } 
            elsif %.params{$key} ~~ Array {
                %!params{$key}.push( $value );
            } 
        }
        else {
            %!params{$key} = $value;
        }
    }

    method param ($key) {
       return %.params{$key};
    }
}

# vim:ft=perl6
