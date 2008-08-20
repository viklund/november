SOURCES=Impatience.pm HTML/Template.pm CGI.pm Wiki.pm
PIRS=$(SOURCES:.pm=.pir)
PARROT_DIR=/home/johan/Perl6/parrot-svn

all: $(PIRS)

#$(PIRS): $(SOURCES)
#	$(PARROT_DIR)/parrot $(PARROT_DIR)/languages/perl6/perl6.pbc --target=pir $<  > $@

%.pir: %.pm
	$(PARROT_DIR)/parrot $(PARROT_DIR)/languages/perl6/perl6.pbc --target=pir $<  > $@
	


clean:
	rm $(PIRS)

