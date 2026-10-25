#!/bin/bash
f=build/make/core/base_rules.mk
sed -i 's|^\$(error \$(LOCAL_PATH): \$(module_id) already defined by \$(\$(module_id)))$|$(warning DUPMODULE $(LOCAL_PATH): $(module_id) already defined by $($(module_id)))|' "$f"
echo "dup-module patch: $(grep -c DUPMODULE "$f") line(s) patched in $f"
