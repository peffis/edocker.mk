edocker.mk: edocker.tmpl
	$(eval TAR_BLOB := $(shell find .ed -print0 | LC_ALL=C sort -z | tar cf - --no-recursion --null -T - | gzip -n | base64))
	$(eval ESCAPED_TAR_BLOB := $(shell printf '%s\n' "${TAR_BLOB}" | sed -e 's/[\/&]/\\&/g'))
	@sed "s/TAR_BLOB/${ESCAPED_TAR_BLOB}/g" $< > $@
