#!perl6

# should probably be in its own file, yes
class CGI {
    method param($param)      { return 'Main_Page' }
    method header             { return
"Content-Type: text/html; charset=ISO-8859-1\r\n" }
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

# writing 'package Wiki;' didn't work :)
class Wiki {

    my %.dispatch is rw;

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
            $handler($cgi);
        }
        elsif $path eq '/' {
            view_page($cgi);
        }
        else {
            print not_found($cgi);
        }
    }

    sub view_page($cgi) {
        # could not write it with statement-modifier if. submitted bug.
        if $cgi !~~ CGI {
            return;
        };

        # would like to make this a class variable, but that doesn't work
        my $CONTENT_PATH = 'wiki-content/';
        my $page = $cgi.param('page') // 'Main_Page';

#        if ( !exists_wiki_page($page) ) {
#            print "HTTP/1.0 200 OK\r\n";
#
#            my $title = $page ~ ' not found';
#            print $cgi.header,
#                  $cgi.start_html($page ~ ' not found'),
#                  $cgi.h1($page),
#                  $cgi.a({href=>"/edit?page=$page"},"Create"),
#                  $cgi.p,
#                 "The page $page does not exist.",
#                 $cgi.end_html;
#            return;
#        }

        print "HTTP/1.0 200 OK\r\n";
        print $cgi.header,
              $cgi.start_html($page),
              $cgi.h1($page),
              $cgi.a((hash 'href', "/edit?page=$page"),"Edit"),
              $cgi.p,
              format_html(escape(read_file($CONTENT_PATH ~ $page))),
              $cgi.end_html;
    }

    sub exists_wiki_page($page) {
        # TODO: Implement
        return True;
    }

    sub escape($text) {
        # TODO: Implement
        return $text;
    }

    sub read_file($file) {
        # TODO: Implement
        return "This is the example content";
    }

    sub format_html($text) {
        # TODO: Implement
        return $text;
    }

    sub not_found($cgi) {
        return "the unbearable lightness of being";
    }
}

my Wiki $wiki = Wiki.new;
$wiki.handle_request(CGI.new);
