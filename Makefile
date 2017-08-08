# Copyright (C) The IETF Trust (2014)
#

YEAR=`date +%Y`
MONTH=`date +%B`
DAY=`date +%d`
PREVVERS=00
VERS=00

XML2RFC=xml2rfc

BASEDOC=draft-haynes-nfsv4-flex-filesv2
DOC_PREFIX=flexfilesv2

autogen/%.xml : %.x
	@mkdir -p autogen
	@rm -f $@.tmp $@
	@cat $@.tmp | sed 's/^\%//' | sed 's/</\&lt;/g'| \
	awk ' \
		BEGIN	{ print "<figure>"; print" <artwork>"; } \
			{ print $0 ; } \
		END	{ print " </artwork>"; print"</figure>" ; } ' \
	| expand > $@
	@rm -f $@.tmp

all: html txt flex_files_prot.x

#
# Build the stuff needed to ensure integrity of document.
common: testx html

txt: $(BASEDOC)-$(VERS).txt

html: $(BASEDOC)-$(VERS).html

nr: $(BASEDOC)-$(VERS).nr

xml: $(BASEDOC)-$(VERS).xml

clean:
	rm -f $(AUTOGEN)
	rm -rf autogen
	rm -f $(BASEDOC)-$(VERS).xml
	rm -rf draft-$(VERS)
	rm -f draft-$(VERS).tar.gz
	rm -rf testx.d
	rm -rf draft-tmp.xml

# Parallel All
pall: 
	$(MAKE) xml
	( $(MAKE) txt ; echo .txt done ) & \
	( $(MAKE) html ; echo .html done ) & \
	wait

$(BASEDOC)-$(VERS).txt: $(BASEDOC)-$(VERS).xml
	${XML2RFC} --text  $(BASEDOC)-$(VERS).xml -o $@

flex_files_prot.x: $(BASEDOC)-$(VERS).txt
	./extract.sh < $(BASEDOC)-$(VERS).txt > $@

$(BASEDOC)-$(VERS).html: $(BASEDOC)-$(VERS).xml
	${XML2RFC}  --html $(BASEDOC)-$(VERS).xml -o $@

$(BASEDOC)-$(VERS).nr: $(BASEDOC)-$(VERS).xml
	${XML2RFC} --nroff $(BASEDOC)-$(VERS).xml -o $@

${DOC_PREFIX}_front_autogen.xml: ${DOC_PREFIX}_front.xml Makefile
	sed -e s/DAYVAR/${DAY}/g -e s/MONTHVAR/${MONTH}/g -e s/YEARVAR/${YEAR}/g < ${DOC_PREFIX}_front.xml > ${DOC_PREFIX}_front_autogen.xml

${DOC_PREFIX}_rfc_start_autogen.xml: ${DOC_PREFIX}_rfc_start.xml Makefile
	sed -e s/VERSIONVAR/${VERS}/g < ${DOC_PREFIX}_rfc_start.xml > ${DOC_PREFIX}_rfc_start_autogen.xml

AUTOGEN =	\
		${DOC_PREFIX}_front_autogen.xml \
		${DOC_PREFIX}_rfc_start_autogen.xml

START_PREGEN = ${DOC_PREFIX}_rfc_start.xml
START=	${DOC_PREFIX}_rfc_start_autogen.xml
END=	${DOC_PREFIX}_rfc_end.xml

FRONT_PREGEN = ${DOC_PREFIX}_front.xml

IDXMLSRC_BASE = \
	${DOC_PREFIX}_middle_start.xml \
	${DOC_PREFIX}_middle_introduction.xml \
	${DOC_PREFIX}_middle_xdr_desc.xml \
	${DOC_PREFIX}_middle_layout.xml \
	${DOC_PREFIX}_middle_security.xml \
	${DOC_PREFIX}_middle_iana.xml \
	${DOC_PREFIX}_middle_end.xml \
	${DOC_PREFIX}_back_front.xml \
	${DOC_PREFIX}_back_references.xml \
	${DOC_PREFIX}_back_acks.xml \
	${DOC_PREFIX}_back_back.xml

IDCONTENTS = ${DOC_PREFIX}_front_autogen.xml $(IDXMLSRC_BASE)

IDXMLSRC = ${DOC_PREFIX}_front.xml $(IDXMLSRC_BASE)

draft-tmp.xml: $(START) Makefile $(END) $(IDCONTENTS)
		rm -f $@ $@.tmp
		cp $(START) $@.tmp
		chmod +w $@.tmp
		for i in $(IDCONTENTS) ; do cat $$i >> $@.tmp ; done
		cat $(END) >> $@.tmp
		mv $@.tmp $@

$(BASEDOC)-$(VERS).xml: draft-tmp.xml $(IDCONTENTS) $(AUTOGEN)
		rm -f $@
		cp draft-tmp.xml $@

genhtml: Makefile gendraft html txt draft-$(VERS).tar
	./gendraft draft-$(PREVVERS) \
		$(BASEDOC)-$(PREVVERS).txt \
		draft-$(VERS) \
		$(BASEDOC)-$(VERS).txt \
		$(BASEDOC)-$(VERS).html \
		$(BASEDOC)-dot-x-04.txt \
		$(BASEDOC)-dot-x-05.txt \
		draft-$(VERS).tar.gz

testx: flex_files_prot.x
	rm -rf testx.d
	mkdir testx.d
	( \
		echo "%#include <rpc/auth.h>" > auth.x ; \
		echo "%typedef struct opaque_auth opaque_auth;" >> auth.x ; \
		cat auth.x ~/Documents/ietf/NFSv4.2/dotx.d/nfsv42.x flex_files_prot.x > ff.x ; \
		if [ -f /usr/include/rpc/auth_sys.h ]; then \
			cp ff.x testx.d ; \
		else \
			sed s/authsys/authunix/g < ff.x | \
			sed s/auth_sys/auth_unix/g | \
			sed s/AUTH_SYS/AUTH_UNIX/g | \
			sed s/gss_svc/Gss_Svc/g > testx.d/ff.x ; \
		fi ; \
	)
	( cd testx.d ; \
		rpcgen -a ff.x ; )
	( cd testx.d ; \
		rpcgen -a ff.x ; \
		if [ ! -f /usr/include/rpc/auth_sys.h ]; then \
			ln Make* make ; \
			CFLAGS="-I /usr/include/gssglue -I /usr/include/tirpc" ; export CFLAGS ; \
		fi ; \
		$(MAKE) -f make* )

spellcheck: $(IDXMLSRC)
	for f in $(IDXMLSRC); do echo "Spell Check of $$f"; aspell check -p dictionary.pws $$f; done
AUXFILES = \
	dictionary.txt \
	gendraft \
	Makefile \
	errortbl \
	rfcdiff \
	xml2rfc_wrapper.sh \
	xml2rfc

DRAFTFILES = \
	$(BASEDOC)-$(VERS).txt \
	$(BASEDOC)-$(VERS).html \
	$(BASEDOC)-$(VERS).xml

draft-$(VERS).tar: $(IDCONTENTS) $(START_PREGEN) $(FRONT_PREGEN) $(AUXFILES) $(DRAFTFILES)
	rm -f draft-$(VERS).tar.gz
	tar -cvf draft-$(VERS).tar \
		$(START_PREGEN) \
		$(END) \
		$(FRONT_PREGEN) \
		$(IDCONTENTS) \
		$(AUXFILES) \
		$(DRAFTFILES) \
		gzip draft-$(VERS).tar
