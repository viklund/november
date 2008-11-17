use v6;
class Dispatcher;

has @.rules;
has %.index;
has $.default is rw;

method add ($rule) {
    die "Only complite rules accepteable there." unless $rule.?is_complite;
    my $n = @!rules.push($rule);
    %!index{$rule.name} = @!rules[($n - 1)];
}

method dispatch (@chunks) {

    # that make clsure:
    #my @applyable =  @!rules.grep: { .is_applyable(@chunks) };    
    # so workaround:

    my @applyable;
    for @!rules -> $r {
        @applyable.push($r) if $r.match(@chunks);
    }
    #say "Applyable:" ~ @applyable;

    if @applyable {
        @applyable[-1].apply;
    }
    elsif $.default {
        $.default();
    }
    else {
        return False;
    }
}

method forward ($name) {
    if %.index.exists($name) {
        my $w = %.index{$name}.way;
        $w();
    }
    else {
        return False;
    }
}

# vim:ft=perl6
