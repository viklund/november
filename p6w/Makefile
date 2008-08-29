SOURCES=Impatience.pm HTML/Template.pm CGI.pm Wiki.pm Text/Escape.pm
PIRS=$(SOURCES:.pm=.pir)
PARROT_DIR=/home/johan/Perl6/parrot-svn

all: $(PIRS)

%.pir: %.pm
	$(PARROT_DIR)/parrot $(PARROT_DIR)/languages/perl6/perl6.pbc --target=pir $<  > $@

clean:
	rm $(PIRS)

