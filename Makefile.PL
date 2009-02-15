#!/usr/bin/perl
$|++;

use strict;
use warnings;

use File::Spec;
use File::HomeDir;

my $parrot_dir = $ENV{PARROT_DIR}
    or die 'Please set $PARROT_DIR (see README).'."\n";

$ENV{PERL6LIB}
    or die 'Please set $PERL6LIB (see README).'."\n";

if ( ! -d $parrot_dir ) {
    print STDERR "Not a directory $parrot_dir, exiting...\n";
    exit 1;
} elsif ( ! -x File::Spec->catfile( $parrot_dir, 'parrot' )) {
    print STDERR "Couldn't find parrot executable in $parrot_dir, "
                 . "have you compiled?";
    exit 1;
}

my @infiles = map { $_.'.in' } qw< Makefile test_wiki.sh wiki.sh >;

my %replacements = (
    PARROT_DIR => $parrot_dir,
);

if ( !-e 'lib/Test.pm' ) {
    !system("ln -s $parrot_dir/languages/rakudo/Test.pm lib/") or die @!;
    print "Symlinked Test.pm from the Rakudo directory \n";
}

for my $infile (@infiles) {
    if ((my $outfile = $infile) =~ s/\.in$//g) {
        open my $IN,  '<', $infile  or die "Couldn't open $infile, $!, $?";
        open my $OUT, '>', $outfile or die "Couldn't open $outfile, $!, $?";
        while (my $line = <$IN>) {
            while ( $line =~ /<(.*?)>/g ) {
                my $repl = $1;
                if (exists $replacements{$repl}) {
                    $line =~ s/<$repl>/$replacements{$repl}/g;
                }
            }
            print $OUT $line;
        }
        print "Created $outfile \n";
    }
}
