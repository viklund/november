#!/usr/bin/perl -w
use strict;

package Wiki;

use HTTP::Server::Simple::CGI;
use HTML::EscapeEvil;
use File::Slurp;
use DateTime;
use Data::Dumper;

use base qw(HTTP::Server::Simple::CGI);

my %dispatch = (
    'view' => \&view_page,
    'edit' => \&edit_page,
    'recentchanges' => \&list_recent_changes,
);

my $CONTENT_PATH = 'wiki-content/';
my $RECENT_CHANGES_PATH = 'wiki-recent-changes';

sub not_found {
    my ($cgi) = @_;

    return "HTTP/1.0 404 Not found\r\n",
           $cgi->header,
           $cgi->start_html('Not found'),
           $cgi->h1('Not found'),
           $cgi->p("The action wasn't found."),
           $cgi->end_html;
}

sub handle_request {
    my ($self, $cgi) = @_;

    my $action = $cgi->param('action') || 'view';
    my $handler = $dispatch{$action};

    if (ref($handler) eq "CODE") {
        $handler->($cgi);

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

sub make_link {
    my ($page) = @_;

    return exists_wiki_page( $page )
           ? "<a href='/?page=$page'>$page</a>"
           : "<a href='/?page=$page&action=edit' style='color: red'>$page</a>";
}

sub format_html {
    my ($text) = @_;

    while ( $text =~ m{ \[\[   # starting marker
                        (\w*)  # alphanumerics and underscores
                        \]\]   # ending marker
                      }x ) {
        my $page = $1;
        my $link = make_link($page);

        $text =~ s{ \[\[ (\w*) \]\] }{$link}x;
    }

    # Add paragraphs
    $text =~ s{\n\s*\n}{\n<p>}xg;

    return $text;
}

sub read_recent_changes {
    return [] unless -e $RECENT_CHANGES_PATH;
    return eval( read_file( $RECENT_CHANGES_PATH ) );
}

sub write_recent_changes {
    my ($recent_changes_ref) = @_;

    $Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 1;
    write_file( $RECENT_CHANGES_PATH, Dumper( $recent_changes_ref ) );
}

sub add_recent_change {
    my ($page, $contents) = @_;

    my @recent_changes = @{read_recent_changes()};
    unshift @recent_changes, # put most recent first
            [ $page, DateTime->now()->epoch(), $contents ];
    write_recent_changes( \@recent_changes );
}

sub view_page {
    my ($cgi) = @_;
    return if !ref $cgi;

    my $page = $cgi->param('page') || 'Main_Page';

    if ( !exists_wiki_page($page) ) {
        print "HTTP/1.0 200 OK\r\n";

        my $title = $page . ' not found';
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
          $cgi->a({href=>"/?page=$page&action=edit"},"Edit"),
          $cgi->p,
          format_html(escape(scalar read_file($CONTENT_PATH . $page))),
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
        add_recent_change( $page, $article_text );

        return view_page($cgi);
    }

    my $title = $action . ' ' . $page;

    print "HTTP/1.0 200 OK\r\n";
    print $cgi->header,
          $cgi->start_html($title),
          $cgi->h1($title),
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

sub list_recent_changes {
    my ($cgi) = @_;
    return if !ref $cgi;

    my @recent_changes = @{read_recent_changes()};

    my $title = 'Recent changes';

    my $list = [ map { make_link( $_->[0] )
                       . ' was changed on ' . $_->[1]
                       . ' by an anonymous gerbil' } @recent_changes ];

    print "HTTP/1.0 200 OK\r\n";
    print $cgi->header,
          $cgi->start_html($title),
          $cgi->h1($title),
          $cgi->ul( $cgi->li($list) ),
          $cgi->end_html;
}

# start the server on port 8080
Wiki->new(8080)->run();
