#!/usr/bin/perl -w
use strict;

package Wiki;

use HTTP::Server::Simple::CGI;
use HTML::EscapeEvil;
use File::Slurp;
use DateTime;
use Data::Dumper;
use HTML::Template;

use base qw(HTTP::Server::Simple::CGI);

my %dispatch = (
    'view' => \&view_page,
    'edit' => \&edit_page,
    'recentchanges' => \&list_recent_changes,
);

my $TEMPLATE_PATH = 'template/';
my $CONTENT_PATH = 'wiki-content/';
my $RECENT_CHANGES_PATH = 'wiki-recent-changes';

sub unknown_action {
    my ($cgi) = @_;

    my $template = HTML::Template->new(
        filename => $TEMPLATE_PATH.'unknown_action.tmpl');

    $template->param(ACTION => $cgi->param('action'));

    return # "HTTP/1.0 404 Not found\r\n",
           $template->output();
}

sub handle_request {
    my ($self, $cgi) = @_;

    my $path = $cgi->path_info();
    if ( $path eq '/wiki.css' ) {
        print "HTTP/1.0 200 OK\r\n",
              read_file('wiki.css');
        return;
    }

    my $action = $cgi->param('action') || 'view';
    my $handler = $dispatch{$action};

    if (ref($handler) eq "CODE") {
        $handler->($cgi);

    }
    else {
        print unknown_action($cgi);
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
        my $template = HTML::Template->new(
            filename => $TEMPLATE_PATH.'not_found.tmpl');

        $template->param(PAGE => $page);

        print # "HTTP/1.0 200 OK\r\n",
              $template->output();

        return;
    }

    my $template = HTML::Template->new(
        filename => $TEMPLATE_PATH.'view.tmpl');

    $template->param(TITLE => $page);
    my $content = format_html(escape(scalar read_file($CONTENT_PATH . $page)));
    $template->param(CONTENT => $content);

    print #"HTTP/1.0 200 OK\r\n",
        $template->output();

    return;
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

    my $template = HTML::Template->new(
            filename => $TEMPLATE_PATH.'edit.tmpl');

    $template->param(PAGE => $page);
    my $title = $action . ' ' . $page;
    $template->param(TITLE => $title);

    print # "HTTP/1.0 200 OK\r\n",
          $template->output();
}

sub list_recent_changes {
    my ($cgi) = @_;
    return if !ref $cgi;

    my @recent_changes = @{read_recent_changes()};

    my $title = 'Recent changes';

    my $list = [ map { make_link( $_->[0] )
                       . ' was changed on ' . $_->[1]
                       . ' by an anonymous gerbil' } @recent_changes ];

    my $template = HTML::Template->new(
            filename => $TEMPLATE_PATH.'recent_changes.tmpl');

    $template->param(CHANGES => $list);

    print # "HTTP/1.0 200 OK\r\n",
          $template->output();
}

# start the server on port 8080
Wiki->new(8080)->run();
