use v6;
use CGI;

class Test::CGI is CGI {

    has $.response is rw;
    has %.response_opts is rw;

    method send_response($contents, %opts?) {
        $.response = $contents;
        if %opts {
            %.response_opts = %opts;
        }
    }

}

# vim:ft=perl6
