use v6;
class Dispatcher;

has @.rules;
has $.default is rw;

method add ($rule) {
    die "Only complite rules accepteable there." unless $rule.?is_complite;
    @!rules.push($rule);
}

method dispatch (@chunks) {

    # that make clsure:
    #my @applyable =  @!rules.grep: { .is_applyable(@chunks) };    
    # so workaround:

    my @applyable;
    for @!rules -> $r {
        @applyable.push($r) if $r.is_applyable(@chunks);
    }
    #say "Applyable:" ~ @applyable;

    if @applyable {
        @applyable[-1].apply(@chunks);
    }
    elsif $.default {
        $.default();
    }
    else {
        return False;
    }
}

# vim:ft=perl6
