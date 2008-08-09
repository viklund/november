#!/usr/bin/perl -w
use strict;

package Wiki;

use HTTP::Server::Simple::CGI;
use HTML::EscapeEvil;
use File::Slurp;
use DateTime;
use Data::Dumper;
use HTML::Template;
use Digest::MD5 qw(md5_base64);

use base qw(HTTP::Server::Simple::CGI);

my %dispatch = (
    'view'           => \&view_page,
    'edit'           => \&edit_page,
    'log_in'         => \&log_in,
    'log_out'        => \&log_out,
    'recent_changes' => \&list_recent_changes,
);

my $TEMPLATE_PATH = 'template/';
my $CONTENT_PATH = 'wiki-content/';
my $RECENT_CHANGES_PATH = 'wiki-recent-changes';
my $USERFILE_PATH = 'wiki-users';

my %sessions;

sub status_ok        { return "HTTP/1.0 200 OK\r\n\r\n"; }
sub status_not_found { return "HTTP/1.0 404 Not found\r\n\r\n"; }

sub handle_request {
    my ($self, $cgi) = @_;

    my $path = $cgi->path_info();
    if ( $path eq '/wiki.css' ) {
        print status_ok(),
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

sub unknown_action {
    my ($cgi) = @_;

    my $template = HTML::Template->new(
        filename => $TEMPLATE_PATH.'unknown_action.tmpl');

    $template->param(ACTION => $cgi->param('action'));

    return status_not_found(),
           $template->output();
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
    my ($page, $contents, $author) = @_;

    my @recent_changes = @{read_recent_changes()};
    unshift @recent_changes, # put most recent first
            [ $page, DateTime->now()->epoch(), $contents, $author ];
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

        print status_ok(),
              $template->output();

        return;
    }

    my $template = HTML::Template->new(
        filename => $TEMPLATE_PATH.'view.tmpl');

    $template->param(TITLE => $page);
    my $content = format_html(escape(scalar read_file($CONTENT_PATH . $page)));
    $template->param(CONTENT => $content);

    print status_ok(),
        $template->output();

    return;
}

sub redirect_to_view_page {
    my ($cgi) = @_;
    return if !ref $cgi;

    my $page = $cgi->param('page') or return;

    print $cgi->redirect("http://localhost:8080/?page=$page");

    return;
}

sub edit_page {
    my ($cgi) = @_;
    return if !ref $cgi;

    my $session_id = $cgi->cookie('session_id');
    if ( !$session_id || !exists $sessions{$session_id} ) {

        return not_authorized($cgi);
    }

    my $page = $cgi->param('page') or return;

    my $already_exists
                    = exists_wiki_page($page);
    my $action      = $already_exists ? 'Editing' : 'Creating';
    my $old_content = $already_exists ? read_file($CONTENT_PATH . $page) : '';

    if ( my $article_text = $cgi->param('articletext') ) {
        write_file( $CONTENT_PATH . $page, $article_text );

        my $author = $sessions{$session_id}{user_name};
        add_recent_change( $page, $article_text, $author );

        return view_page($cgi);
    }

    my $template = HTML::Template->new(
            filename => $TEMPLATE_PATH.'edit.tmpl');

    $template->param(PAGE => $page);
    my $title = $action . ' ' . $page;
    $template->param(TITLE => $title);
    $template->param(CONTENT => $old_content);

    print status_ok(),
          $template->output();
}

sub not_authorized {
    my ($cgi) = @_;
    return if !ref $cgi;

    my $template = HTML::Template->new(
        filename => $TEMPLATE_PATH.'action_not_authorized.tmpl');

    $template->param(DISALLOWED_ACTION => 'edit pages');

    print status_ok(),
          $template->output();

    return;
}

sub read_users {
    return [] unless -e $USERFILE_PATH;
    return eval( read_file( $USERFILE_PATH ) );
}

sub log_in {
    my ($cgi) = @_;
    return if !ref $cgi;

    if ( my $user_name = $cgi->param('user_name') ) {
        my $password = $cgi->param('password');

        my %users = %{read_users()};

        if ( md5_base64(md5_base64($user_name).$password)
             eq $users{$user_name}->{password} ) {

            my $template = HTML::Template->new(
                filename => $TEMPLATE_PATH.'login_succeeded.tmpl');

            my $session_id = md5_base64(time);
            my $session_cookie = $cgi->cookie(
                -name    => 'session_id',
                -value   => $session_id,
                -expires => '+1h'
            );

            $sessions{$session_id} = {
                'user_name' => $user_name,
            };

            print "HTTP/1.0 200 OK\r\n",
                  $cgi->header( -cookie => $session_cookie ),
                  $template->output();

            return;
        }

        my $template = HTML::Template->new(
            filename => $TEMPLATE_PATH.'login_failed.tmpl');

        print status_ok(),
              $template->output();

        return;
    }

    my $template = HTML::Template->new(
        filename => $TEMPLATE_PATH.'log_in.tmpl');

    print status_ok(),
        $template->output();

    return;
}

sub log_out {
    my ($cgi) = @_;
    return if !ref $cgi;

    if ( defined $cgi->cookie('session_id') ) {
        my $template = HTML::Template->new(
                filename => $TEMPLATE_PATH.'logout_succeeded.tmpl');

        my $session_id = $cgi->cookie('session_id');
        delete $sessions{$session_id};

        my $session_cookie = $cgi->cookie(
            -name    => 'session_id',
            -value   => '',
        );

        print "HTTP/1.0 200 OK\r\n",
              $cgi->header( -cookie => $session_cookie ),
              $template->output();

        return;
    }

    my $template = HTML::Template->new(
        filename => $TEMPLATE_PATH.'logout_succeeded.tmpl');

    print status_ok(),
        $template->output();

    return;
}

sub list_recent_changes {
    my ($cgi) = @_;
    return if !ref $cgi;

    my @recent_changes = @{read_recent_changes()};

    my $changes = [ map { { page => make_link( $_->[0] ),
                            time => $_->[1],
                            author => $_->[3] || 'nobody' } }
                    @recent_changes ];

    my $template = HTML::Template->new(
            filename => $TEMPLATE_PATH.'recent_changes.tmpl');

    $template->param(CHANGES => $changes);

    print status_ok(),
          $template->output();
}

# start the server on port 8080
Wiki->new(8080)->run();
