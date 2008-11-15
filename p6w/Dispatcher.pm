use v6;
class Dispatcher;

has @!rules;
has $.default is rw;

method add ($rule) {
    die "Only complite rules accepteable there." unless $rule.?is_complite;
    @!rules.push($rule);
}

method dispatch (@chunks) {
    my @applyable =  @!rules.grep: { .is_applyable(@chunks) };    
    if @applyable {
        @applyable[0].apply(@chunks);
    }
    elsif $.default {
        $.default();
    }
    else {
        return False;
    }
}

# vim:ft=perl6
