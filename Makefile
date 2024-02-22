edocker.mk: edocker.tmpl .ed/src/edocker_erlexec.c .ed/bin/app .ed/bin/mkimage .ed/bin/release_name .ed/bin/release_version .ed/bin/system_version .ed/bin/version
	$(eval TAR_BLOB := $(shell find .ed -print0 | LC_ALL=C sort -z | tar cf - --no-recursion --null -T - | gzip -n | base64))
	$(eval ESCAPED_TAR_BLOB := $(shell printf '%s\n' "${TAR_BLOB}" | sed -e 's/[\/&]/\\&/g'))
	@sed "s/TAR_BLOB/${ESCAPED_TAR_BLOB}/g" $< > $@
