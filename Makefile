PERL6 = perl6

SOURCES = \
    lib/Digest.pm \
    lib/Digest/SHA.pm \
    lib/Dispatcher.pm \
    lib/Dispatcher/Rule.pm \
    lib/November.pm \
    lib/November/CGI.pm \
    lib/November/Cache.pm \
    lib/November/Config.pm \
    lib/November/Session.pm \
    lib/November/Storage.pm \
    lib/November/Storage/File.pm \
    lib/November/Tags.pm \
    lib/November/URI.pm \
    lib/November/URI/Grammar.pm \
    lib/November/Utils.pm \
    lib/November/Utils.pm \
    lib/Test/CGI.pm \
    lib/Test/InputOutput.pm \
    lib/Text/Markup/Wiki/MediaWiki.pm \
    lib/Text/Markup/Wiki/Minimal.pm

PIRS = $(SOURCES:.pm=.pir)

all: $(PIRS)

%.pir: %.pm
	$(PERL6) --target=pir --output=$@ $<

clean:
	rm -f $(PIRS)

tests: test

test: all
	prove -e '$(PERL6)' -r --nocolor t/
