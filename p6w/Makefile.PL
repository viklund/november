#!/usr/bin/perl
$|++;

use strict;
use warnings;

use File::Spec;
use File::HomeDir;

# Really simple Makefile.PL

my @infiles = map { $_.'.in' } qw< Makefile test_wiki.sh wiki.sh >;

print <<'__END__';
Hello, this is a simple Makefile.PL that will set up the basic bits so you can
run November, you will be asked a few questions (currently one) type in the
answers as best as you can.

You need a fairly recent checkout of parrot. 

To check out parrot:

$ svn co https://svn.perl.org/parrot/trunk parrot

To compile parrot and rakudo:

$ cd parrot
$ perl Makefile.PL \
    && make        \
    && cd languages/perl6 \
    && make perl6

--

__END__

# First try to grab the parrot dir from the environment
my $parrot_dir = $ENV{PARROT_DIR};

if (   ! $parrot_dir 
    || ! -d $parrot_dir
    || ! -x File::Spec->catfile( $parrot_dir, 'parrot' )) {
    $parrot_dir = File::HomeDir->my_home() . '/parrot';
}

print "Parrot checkout location: [$parrot_dir] ";
my $answer = <>;
chomp $answer;
if ($answer ne '') {
    $parrot_dir = glob $answer;
}

if ( ! $parrot_dir ) {
    print STDERR "Didn't get a parrot dir, exiting...\n";
    exit 1;
} elsif ( ! -d $parrot_dir ) {
    print STDERR "Not a directory $parrot_dir, exiting...\n";
    exit 1;
} elsif ( ! -x File::Spec->catfile( $parrot_dir, 'parrot' )) {
    print STDERR "Couldn't find parrot executable in $parrot_dir, have you compiled?";
    exit 1;
}

my %replacements = (
    PARROT_DIR => $parrot_dir,
);

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
    }
}

system('chmod +x *.sh');
