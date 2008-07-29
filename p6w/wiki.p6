#!perl6

# should probably be in its own file, yes
class CGI {
    method param($param)      { return 'Main_Page' }
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

        if !exists_wiki_page($page) {
            print "HTTP/1.0 200 OK\r\n";

            my $title = $page ~ ' not found';
            print $cgi.header,
                  $cgi.start_html($page ~ ' not found'),
                  $cgi.h1($page),
                  $cgi.a({href=>"/edit?page=$page"},"Create"),
                  $cgi.p,
                 "The page $page does not exist.",
                 $cgi.end_html;
            return;
        }

        print $cgi.header,
              $cgi.start_html($page),
              $cgi.h1($page),
              $cgi.a((hash 'href', "/edit?page=$page"),"Edit"),
              $cgi.p,
              format_html(escape(slurp($CONTENT_PATH ~ $page))),
              $cgi.end_html;
    }

    sub exists_wiki_page($page) {
        # TODO: Implement
        return True;
    }

    sub escape($text is rw) {
        # HTML::EscapeEvil of course does this much better, deriving
        # HTML::Parser. Here we settle (for now) for the more crude
        # escape-everything solution.
#        $text ~~ s :g / \& /&amp;/;
#        $text ~~ s :g / \< /&lt;/;
#        $text ~~ s :g / \> /&gt;/;
#        $text ~~ s :g / \" /&quot;/;
#        $text ~~ s :g / \' /&#039;/;

        # Oh, and you can't substitute using regexes yet, so we'll go
        # it with by stitching strings in a sub.
        $text = replace_all( '&', '&amp;',
                replace_all( '<', '&lt;',
                replace_all( '>', '&gt;',
                replace_all( '"', '&quot;',
                replace_all( "'", '&#039;', $text )))));

        return $text;
    }

    sub replace_all($char, $replacement, $text is rw) {
        while index($text, $char) !~~ Failure {
            my $pos = index($text, $char);
            $text = substr($text, 0, $pos)
                    ~ $replacement
                    ~ substr($text, $pos+1);
        }
        return $text;
    }

    sub format_html($text is rw) {
        # we'd like to do $text ~~ m{ \[\[ (\w*) \]\] }
        # but that syntax is not implemented yet

        while (my $opening = index($text, '[[')) !~~ Failure
              && (my $closing = index($text, ']]')) !~~ Failute
              && $opening < $closing {

            my $alnum = ('a'..'z', 'A'..'Z', '0'..'9').join('');
            my $substitute = True;
            for $opening+2..$closing-1 -> $pos {
                if index($alnum, substr($text, $pos, 1)) ~~ Failure {
                    $substitute = False;
                }
            }

            if $substitute {
                my $page = substr($text, $opening+2, $closing-1-($opening+2));
                my $link = make_link($page);

                $text = substr($text, 0, $opening)
                        ~ $link
                        ~ substr($text, $closing+2);
            }
        }

        # Add paragraphs
#        $text ~~ s:g{\n\s*\n}{\n<p>};

        return $text;
    }

    sub make_link($page) {
        # TODO: Implement
        return "look, a link!";
    }

    sub not_found($cgi) {
        return "HTTP/1.0 404 Not found\r\n",
            $cgi.header,
            $cgi.start_html('Not found'),
            $cgi.h1('Not found'),
            $cgi.end_html;
    }
}

my Wiki $wiki = Wiki.new;
$wiki.handle_request(CGI.new);
