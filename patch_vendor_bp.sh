#!/bin/bash
# Patches the Lineage-generated blob repos (TheMuppets) so they build on AOSPA/PenguinOS.
# Run from the source root, after sync.
python3 - <<'EOF'
import os,re
DROP_IMPORTS=("hardware/qcom-caf/","vendor/qcom/opensource/display","vendor/qcom/opensource/dataservices")
# blob modules that AOSPA's QTI components already provide (found in multiple namespaces)
DROP_MODULES={"system_ext_priv-app_ims_lib_arm64_libimsmedia_jni_so","init.qti.chg_policy"}
for d in ("vendor/motorola/devon","vendor/motorola/sm6225-common"):
    bp=os.path.join(d,"Android.bp")
    if not os.path.isfile(bp):
        print("MISSING",bp); continue
    lines=open(bp).read().split("\n")
    kept=[l for l in lines if not any(('"'+x) in l for x in DROP_IMPORTS)]
    dropped_imports=len(lines)-len(kept)
    lines=kept
    out=[];blk=None;removed=[]
    for l in lines:
        if blk is not None:
            blk.append(l)
            if l=="}":
                text="\n".join(blk)
                m=re.search(r'\n\s*name:\s*"([^"]+)"',text)
                if m and m.group(1) in DROP_MODULES: removed.append(m.group(1))
                else: out.extend(blk)
                blk=None
            continue
        if re.match(r'^[a-z_0-9]+ \{$',l):
            blk=[l]; continue
        out.append(l)
    open(bp,"w").write("\n".join(out))
    print(f"{bp}: dropped {dropped_imports} import(s), removed modules: {removed}")
EOF
