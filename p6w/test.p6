#!perl6

my @in;
push @in, $_ for =$*IN;

print "Content-type: text/html\r\n\r\n";

say "<h1>ENV</h1>";
say "<table>";
for %*ENV.kv -> $key, $value {
    say "<tr><td>$key</td><td>$value</td></tr>";
}
say "</table>";

say "<h1>STDIN</h1>";
say "<p>$_</p>" for @in;

.say for
  "<h1>POST IT</h1>",
  "<form method='post'>",
  "  <input type='hidden' name='parameter1' value='value1' />",
  "  <input type='hidden' name='parameter2' value='value2' />",
  "  <input type='submit' />",
  "</form>";
