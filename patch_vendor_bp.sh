#!/bin/bash
# Makes the Lineage-era blob repos and AOSPA's QTI components coexist. Run from the source root, after sync.
python3 - <<'EOF'
import os,re,glob
DROP_IMPORTS=("hardware/qcom-caf/","vendor/qcom/opensource/display","vendor/qcom/opensource/dataservices")
DROP_MODULES={
  "vendor/motorola/devon":{"libthermalclient","libofflinelog"},
  "vendor/motorola/sm6225-common":{"vendor.qti.hardware.fm@1.0"},
}
RENAME={'"libqti_vndfwk_detect"':'"libqti_vndfwk_detect_vendor"'}
def patch_bp(bp,drop):
    lines=open(bp).read().split("\n")
    kept=[l for l in lines if not any(('"'+x) in l for x in DROP_IMPORTS)]
    di=len(lines)-len(kept)
    out=[];blk=None;removed=[]
    for l in kept:
        if blk is not None:
            blk.append(l)
            if l=="}":
                t="\n".join(blk); m=re.search(r'\n\s*name:\s*"([^"]+)"',t)
                if m and m.group(1) in drop: removed.append(m.group(1))
                else: out.extend(blk)
                blk=None
            continue
        if re.match(r'^[a-z_0-9]+ \{$',l): blk=[l]; continue
        out.append(l)
    s="\n".join(out); n=0
    for a,b in RENAME.items(): n+=s.count(a); s=s.replace(a,b)
    open(bp,"w").write(s)
    print(f"{bp}: imports dropped {di}, modules removed {removed}, renamed refs {n}")
for d,drop in DROP_MODULES.items():
    bp=d+"/Android.bp"
    if os.path.isfile(bp): patch_bp(bp,drop)
    else: print("MISSING",bp)
g="device/motorola/sm6225-common/gps/android/2.1/Android.bp"
if os.path.isfile(g):
    s=open(g).read(); n=0
    for a,b in RENAME.items(): n+=s.count(a); s=s.replace(a,b)
    open(g,"w").write(s); print(g,"renamed refs",n)
c=0
for f in glob.glob("vendor/qcom/common/**/*-vendor.mk",recursive=True):
    open(f,"w").write("# neutralized: this device ships its own vendor blobs\n"); c+=1
print("neutralized vendor/qcom/common makefiles:",c)
os.makedirs("device/motorola/kernel-headers",exist_ok=True)
open("device/motorola/kernel-headers/Android.bp","w").write("".join(
 'cc_library_headers {\n    name: "%s",\n    vendor_available: true,\n    host_supported: true,\n}\n\n'%n
 for n in ("qti_kernel_headers","device_kernel_headers","generated_kernel_headers")))
print("kernel header stubs written")
EOF
