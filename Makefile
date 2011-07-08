PERL6=perl6

SOURCES=lib/November/URI/Grammar.pm lib/November/URI.pm \
	lib/November/CGI.pm lib/Text/Markup/Wiki/Minimal.pm \
	lib/Text/Markup/Wiki/MediaWiki.pm lib/Digest.pm \
	lib/November/Storage.pm lib/November/Utils.pm \
	lib/November/Config.pm lib/November/Storage/File.pm lib/November/Tags.pm \
	lib/Dispatcher/Rule.pm lib/Dispatcher.pm \
	lib/November/Session.pm lib/November/Utils.pm \
    lib/Test/InputOutput.pm lib/Test/CGI.pm \
    lib/November/Cache.pm lib/November.pm

PIRS=$(SOURCES:.pm=.pir)

all: $(PIRS)

%.pir: %.pm
	$(PERL6) --target=pir --output=$@ $<

clean:
	rm -f $(PIRS)

tests: test

test: all
	prove -e '$(PERL6)' -r --nocolor t/
