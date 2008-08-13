#!perl6

use Future;

class CGI {
    has %.param is rw;
    #method param($param)      { return 'Main_Page' }

    # RAKUDO: BUILD method not supported
    method init() {
        my %params = parse_params( %*ENV<QUERY_STRING> );

        #if %*ENV<REQUEST_METHOD> eq 'POST' && %*ENV{CONTENT_LENGTH} > 0 {
        if %*ENV<REQUEST_METHOD> eq 'POST' {
            # Maybe check content_length here and only take that many bytes?
            my %post_params = parse_params( $*IN.slurp() );
            for %post_params.kv -> $k, $v {
                %params{$k} = $v;
            }
        }
        $.param = %params;
    }

    # For debugging
    method save_params() {
        my $debug = open('/tmp/debug.out', :w);
        for $.param.kv -> $k, $v {
            $debug.say("$k => $v");
        }
        $debug.close;
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

role HTML {
    method header                { return
"Content-Type: text/html; charset=ISO-8859-1\r\n\r\n" }
    method start_html($title)    { return "<!DOCTYPE html
	PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"
	 \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en-US\" xml:lang=\"en-US\">
<head>
<title>$title</title>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\" />
</head>
<body>\n" }
    method h1($text)             { return "<h1>$text</h1>" }
    method a($opts,$text)        { return '<a href="' ~ $opts<href> ~ "\">$text</a>" }
    method p                     { return '<p />' }
    method end_html              { return "\n</body>\n" }
    method textarea($opts,$text) { 
        return '<textarea name="' ~ ( $opts<name> // 'textarea' )
               ~ '" cols="' ~ ($opts<cols> // 50) ~ '" rows="'
               ~ ($opts<rows> // 4)
               ~ "\">$text</textarea>"
    }
    method start_form($opts) {
        return '<form method="' ~ ($opts<method>  // 'post')
               ~ '" enctype="'  ~ ($opts<enctype> //
                                   'application/x-www-form-urlencoded' ) # Default anyway
               ~ '">'
    }
    method submit($opts) {
        return '<input type="submit"' 
               ~ val_check($opts, 'name')
               ~ val_check($opts, 'value')
               ~ '>';
    }
    method end_form              { return '</form>' }
    sub val_check($opts, $name) {
        if $opts{$name} {
            return " $name=\"$opts{$name}'\"";
        }
        return ''
    }
}

