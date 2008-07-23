#!perl6

# writing 'package Wiki;' didn't work :)
class Wiki {

    has %.dispatch is rw;

    my $CONTENT_PATH = 'wiki-content/';

    method handle_request($cgi) {
#        my $path = $cgi.path_info();
        my $path = "/view";   # faking it for now

        # a rakudo bug prevents us from setting the attribute
        # outside of a method
        %.dispatch = (
            '/view' => &view_page,
        );

        my $handler = %.dispatch{$path};

        if $handler ~~ Code {
            $handler();
        }
        elsif ( $path eq '/' ) {
            view_page($cgi);
        }
        else {
            print not_found($cgi);
        }
    }

    sub view_page($cgi) {
        say "whoa!";
    }

    sub not_found($cgi) {
        say "the unbearable lightness of being";
    }
}

my Wiki $wiki = Wiki.new;
$wiki.handle_request("fake cgi object");
