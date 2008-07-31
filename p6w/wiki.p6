#!perl6

use CGI;

# writing 'package Wiki;' didn't work :)
class Wiki {

    my  $.content_path is rw;
    has $.cgi          is rw;

    method init {
        # a rakudo bug prevents us from setting the attribute
        # outside of a method
        $.content_path = 'wiki-content/';
    }

    method handle_request(CGI $cgi) {
        $.cgi = $cgi;
        my $action = $cgi.param<action> // 'view';

        # RAKUDO: when doesn't work properly yet
        my $handled = False;
        given $action {
            when 'view' { self.view_page(); $handled = True }
            when 'edit' { self.edit_page(); $handled = True }
        }

        if !$handled {
            self.not_found();
        }
    }

    method view_page() {
        my $page = $.cgi.param<page> // 'Main_Page';

        if !self.exists_wiki_page($page) {
            my $title = $page ~ ' not found';
            print $.cgi.header,
                  $.cgi.start_html($page ~ ' not found'),
                  $.cgi.h1($page),
                  $.cgi.a((hash 'href', "?action=edit&page=$page") ,"Create"),
                  $.cgi.p,
                 "The page $page does not exist.",
                 $.cgi.end_html;
            return;
        }

        print $.cgi.header,
              $.cgi.start_html($page),
              $.cgi.h1($page),
              $.cgi.a((hash 'href', "?action=edit&page=$page"),"Edit"),
              $.cgi.p,
              self.format_html(self.escape(self.read_page($page))),
              $.cgi.end_html;
    }

    method edit_page() {
        # $page should be an instance variable?
        my $page = $.cgi.param<page> // 'Main_Page';
        my $text = '';
        try {
            $text = self.read_page($page);
        }
        print $.cgi.header,
              $.cgi.start_html($page),
              $.cgi.h1("Editing $page"),
              $.cgi.start_form(hash <>),
              $.cgi.textarea( (hash <cols 50 rows 10>), $text),
              $.cgi.submit(<>),
              $.cgi.end_form,
              $.cgi.end_html;
    }

    method exists_wiki_page($page) {
        # RAKUDO: use :e
        my $exists = False;
        try {
            my $fh = open( $.content_path ~ $page );
            $exists = True;
        }
        return $exists;
    }

    method read_page($page) {
        slurp $.content_path ~ $page;
    }

    method escape($text is rw) {
        # HTML::EscapeEvil of course does this much better, deriving
        # HTML::Parser. Here we settle (for now) for the more crude
        # escape-everything solution.
#        $text ~~ s :g / \& /&amp;/;
#        $text ~~ s :g / \< /&lt;/;
#        $text ~~ s :g / \> /&gt;/;
#        $text ~~ s :g / \" /&quot;/;
#        $text ~~ s :g / \' /&#039;/;

        # RAKUDO: Oh, and you can't substitute using regexes yet, so we'll go
        # it with by stitching strings in a sub.
        $text = self.replace_all( '<', '&lt;',
                self.replace_all( '>', '&gt;',
                self.replace_all( '"', '&quot;',
                self.replace_all( "'", '&#039;',
                self.replace_all( '&', '&amp;', $text )))));

        return $text;
    }

    method replace_all($char, $replacement, $text is rw) {
        my $new_text = '';
        while index($text, $char) !~~ Failure {
            my $pos = index($text, $char);

            # RAKUDO: BUG 57434
            my $end = $pos;
            if ($end == 0) {
                $end = -$text.chars;
            }
            $new_text ~= substr($text, 0, $end)
                      ~ $replacement;
            $text = substr($text, $pos+1);
        }
        return $new_text ~ $text;
    }

    method format_html($text is rw) {
        # RAKUDO: we'd like to do $text ~~ m{ \[\[ (\w*) \]\] }
        # but that syntax is not implemented yet

        while (my $opening = index($text, '[[')) !~~ Failure
              && (my $closing = index($text, ']]')) !~~ Failure
              && $opening < $closing {

            my $alnum = ('a'..'z', 'A'..'Z', '0'..'9', '_').join('');
            my $substitute = True;
            for $opening+2..$closing-1 -> $pos {
                if index($alnum, substr($text, $pos, 1)) ~~ Failure {
                    $substitute = False;
                }
            }

            if $substitute {
                my $page = substr($text, $opening+2, $closing-($opening+2));
                my $link = self.make_link($page);

                # RAKUDO: BUG substr($text,0,0) == $text
                if ($opening == 0) {
                    $opening = -$text.chars
                }

                $text = substr($text, 0, $opening)
                        ~ $link
                        ~ substr($text, $closing+2);
            }
        }

        # Add paragraphs
#        $text ~~ s:g{\n\s*\n}{\n<p>};

        return $text;
    }

    method make_link($page) {
        if self.exists_wiki_page($page) {
            return $.cgi.a((hash 'href', "?action=view&page=$page"),$page),
        } 
        return $.cgi.a((hash 'href', "?action=edit&page=$page", 'class', 'new'),$page),
    }

    method not_found() {
        say $.cgi.header,
            $.cgi.start_html('Action Not found'),
            $.cgi.h1('Action Not found'),
            $.cgi.end_html;
    }
}

my Wiki $wiki = Wiki.new;
$wiki.init();
my      $cgi  = CGI.new does HTML; # mr. Ugly
$cgi.init();
$wiki.handle_request($cgi);
