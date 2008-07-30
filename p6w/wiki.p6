#!perl6

use CGI;

# writing 'package Wiki;' didn't work :)
class Wiki {

    my $.content_path is rw;

    method init {
        # a rakudo bug prevents us from setting the attribute
        # outside of a method
        $.content_path = 'wiki-content/';
    }

    method handle_request($cgi) {
        my $action = $cgi.param<action> // 'view';

        given $action {
            when 'view' { self.view_page($cgi) }
        }
    }

    method view_page(CGI $cgi) {
        my $page = $cgi.param<page> // 'Main_Page';

        if !exists_wiki_page($page) {
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
              format_html(escape(slurp($.content_path ~ $page))),
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
        return $text;
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
        return $text;

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
$wiki.init();
my      $cgi  = CGI.new does HTML # mr. Ugly;
$cgi.init();
$wiki.handle_request($cgi);
