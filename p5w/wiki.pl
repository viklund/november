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
    $escapeevil->parse($string . ' ');
    return $escapeevil->filtered_html;
}

sub exists_wiki_page {
    my ($page) = @_;

    return $page && -e $CONTENT_PATH . $page;
}

sub build_wiki_links {
    my ($text) = @_;

    while ( $text =~ m{ \[\[   # starting marker
                        (\w*)  # alphanumerics and underscores
                        \]\]   # ending marker
                      }x ) {
        my $page = $1;

        my $link = exists_wiki_page( $page )
                   ? "<a href='/view?page=$1'>$1</a>"
                   : "<a href='/edit?page=$1' style='color: red'>$1</a>";

        $text =~ s{ \[\[ (\w*) \]\] }{$link}x;
    }

    return $text;
}

sub view_page {
    my ($cgi) = @_;
    return if !ref $cgi;

    my $page = $cgi->param('page') || 'Main_Page';

    if ( !exists_wiki_page($page) ) {
        print "HTTP/1.0 200 OK\r\n";
        print $cgi->header,
              $cgi->start_html($page . ' not found'),
              $cgi->h1($page),
              $cgi->a({href=>"/edit?page=$page"},"Create"),
              $cgi->p,
              "The page $page does not exist.",
              $cgi->end_html;
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

    my $page = $cgi->param('page') or return;

    my $action = "Editing";
    my $old_content = '';

    if ( !exists_wiki_page($page) ) {
        $action = "Creating";
    }
    else {
        $old_content = read_file($CONTENT_PATH . $page);
    }

    if ( my $article_text = $cgi->param('articletext') ) {
        write_file( $CONTENT_PATH . $page, $article_text );

        return view_page($cgi);
    }

    print "HTTP/1.0 200 OK\r\n";
    print $cgi->header,
          $cgi->start_html($page),
          $cgi->h1("$action $page"),
          $cgi->start_form,
          $cgi->hidden('page', $page),
          $cgi->textarea( -name => 'articletext',
                          -default => $old_content,
                          -rows => 10,
                          -columns => 50 ),
          $cgi->p,
          $cgi->submit,
          $cgi->end_form,
          $cgi->end_html;
}

# start the server on port 8080
Wiki->new(8080)->run();
