#!/usr/bin/perl -w
use strict;

package Wiki;

use HTTP::Server::Simple::CGI;
use HTML::EscapeEvil;
use File::Slurp;
use base qw(HTTP::Server::Simple::CGI);

my %dispatch = (
    '/view' => \&view_page,
    '/edit' => \&edit_page,
);

my $CONTENT_PATH = 'wiki-content/';

sub not_found {
    my ($cgi) = @_;

    return "HTTP/1.0 404 Not found\r\n",
           $cgi->header,
           $cgi->start_html('Not found'),
           $cgi->h1('Not found'),
           $cgi->end_html;
}

sub handle_request {
    my ($self, $cgi) = @_;

    my $path = $cgi->path_info();
    my $handler = $dispatch{$path};

    if (ref($handler) eq "CODE") {
        $handler->($cgi);

    }
    elsif ($path eq '/') {
        view_page($cgi);
    }
    else {
        print not_found($cgi);
    }
}

sub escape {
    my ($string) = @_;

    my $escapeevil = HTML::EscapeEvil->new(allow_entity_reference => 0);
    $escapeevil->parse($string);
    return $escapeevil->filtered_html;
}

sub build_wiki_links {
    my ($text) = @_;

    $text =~ s{ \[\[   # starting marker
                (\w*)  # alphanumerics and underscores
                \]\]   # ending marker
              }
              {<a href="/view?page=$1">$1</a>}xg;

    return $text;
}

sub view_page {
    my ($cgi) = @_;
    return if !ref $cgi;

    my $page = $cgi->param('page') || 'Main_Page';

    if ( $page eq '' || !-e $CONTENT_PATH . $page ) {
        print not_found($cgi);
        return;
    }

    print "HTTP/1.0 200 OK\r\n";
    print $cgi->header,
          $cgi->start_html($page),
          $cgi->h1($page),
          $cgi->a({href=>"/edit?page=$page"},"Edit"),
          $cgi->p,
          build_wiki_links(escape(scalar read_file($CONTENT_PATH . $page))),
          $cgi->end_html;
}

sub edit_page {
    my ($cgi) = @_;
    return if !ref $cgi;

    my $page = $cgi->param('page') || 'Main_Page';

    if ( $page eq '' || !-e $CONTENT_PATH . $page ) {
        print not_found($cgi);
        return;
    }

    if ( my $article_text = $cgi->param('articletext') ) {
        write_file( $CONTENT_PATH . $page, $article_text );

        return view_page($cgi);
    }

    print "HTTP/1.0 200 OK\r\n";
    print $cgi->header,
          $cgi->start_html($page),
          $cgi->h1("Editing $page"),
          $cgi->start_form,
          $cgi->textarea( -name => 'articletext',
                          -default => scalar read_file($CONTENT_PATH . $page),
                          -rows => 10,
                          -columns => 50 ),
          $cgi->p,
          $cgi->submit,
          $cgi->end_form,
          $cgi->end_html;
}

# start the server on port 8080
my $pid = Wiki->new(8080)->background();
print "Use 'kill $pid' to stop server.\n";
