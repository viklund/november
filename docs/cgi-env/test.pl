#!/usr/bin/perl

my @in=();
push @in, $_ while (<>);

print "Content-type: text/html\r\n\r\n";

print "<h1>ENV</h1>\n";
print "<table>\n";
while (my ($key, $value) = each %ENV) {
    print "<tr><td>$key</td><td>$value</td></tr>\n";
}
print "</table>\n";

print "<h1>STDIN</h1>\n";
print "<p>$_\n" for @in;

print <<__END__;
<h1>POST IT</h1>
<form method='post'>
    <input type='hidden' name='parameter1' value='value1' />
    <input type='hidden' name='parameter2' value='value2' />
    <input type='submit'>
</form>
__END__

