class Dispatcher {
    use Dispatcher::Rule;

    has @.rules;
    has $.default is rw;

    multi method add (Dispatcher::Rule $rule) {
        die "Only complete rules allowed" unless $rule.?is_complete;
        @!rules.push($rule);
    }

    multi method add (@tokens, $action) {
        my $rule = Dispatcher::Rule.new( tokens => @tokens, action => $action );
        @!rules.push($rule);
    }

# I think a Hash might be better here, but Rakudo converts all hash keys
# into string now
    method add_rules(@rules) {
        # RAKUDO: rakudo doesn't know return values in for loops yet
        my $r;
        for @rules -> Object @tokens, $action {
            $r = self.add(@tokens, $action);
        }
        return $r;
    }

    method dispatch (@chunks) {
        my @matched =  @!rules.grep: { .match(@chunks); };    

        if @matched {
            my $result = @matched[*-1].apply;
            .clear for @!rules; 
            return $result;
        }
        elsif defined $.default {
            $.default();
        }
        else {
            return Failure;
        }
    }
}

# vim:ft=perl6
