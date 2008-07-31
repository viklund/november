#!perl6

class CGI {
    has %.param is rw;
    #method param($param)      { return 'Main_Page' }

    # RAKUDO: BUILD method not supported
    method init() {
        # Get the query string
        my $debug = open('/tmp/debug.out', :w);
        my $query_string = %*ENV<QUERY_STRING>;
        if %*ENV<REQUEST_METHOD> eq 'POST' && %*ENV{CONTENT_LENGTH} > 0 {
            # Maybe check content_length here and only take that many bytes?
            $debug.say('POST');
            $query_string ~= $*IN.slurp();
        }

        # Parse it
        my @param_values = split('&' , $query_string);
        my %param_temp;
        for @param_values -> $param_value {
            my @kvs = split('=', $param_value);
            # TODO: Check if key exists, if so make an array
            %param_temp{@kvs[0]} = @kvs[1];
        }
        $.param = %param_temp;
        for %param_temp.kv -> $k, $v {
            $debug.say("$k :: $v");
        }
        $debug.close();
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
        return '<textarea name="snubbe" cols="' ~ ($opts<cols> // 50) ~ '" rows="'
               ~ ($opts<rows> // 4)
               ~ "\">$text</textarea>"
    }
    method start_form($opts) {
        return '<form method="' ~ ($opts<action>  // 'post')
               #~ '" action="'   ~ ($opts<method>  // '')
               ~ '" enctype="'  ~ ($opts<enctype> //
                                   'application/x-www-form-urlencoded' )
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

