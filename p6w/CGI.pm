#!perl6

class CGI {
    has %.param is rw;
    #method param($param)      { return 'Main_Page' }

    # RAKUDO: BUILD method not supported
    method init() {
        my $query_string = '';

        # Get the query string
        if %*ENV<REQUEST_METHOD> eq 'GET' {
            $query_string = %*ENV<QUERY_STRING>
        } 
        elsif %*ENV<REQUEST_METHOD> eq 'POST' {
            # Maybe check content_length here and only take that many bytes?
            $query_string = $*IN.slurp();
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
    }
}

role HTML {
    method header             { return
"Content-Type: text/html; charset=ISO-8859-1\r\n\r\n" }
    method start_html($title) { return "<!DOCTYPE html
	PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"
	 \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en-US\" xml:lang=\"en-US\">
<head>
<title>$title</title>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\" />
</head>
<body>\r\n" }
    method h1($text)          { return "<h1>$text</h1>" }
    method a($opts,$text)     { return '<a href="' ~ $opts<href> ~ "\">$text</a>" }
    method p                  { return '<p />' }
    method end_html           { return "\r\n</body>\r\n" }
}

