python3 - <<'EOF'
import os
p = "build/soong/ui/build/soong.go"
s = open(p).read() if os.path.isfile(p) else ""
a = "invocationEnv := make(map[string]string)"
if "GOMEMLIMIT" not in s and a in s:
    s = s.replace(a, a + '\n\tfor _, v := range []string{"GOMEMLIMIT", "GOGC"} { if val := os.Getenv(v); val != "" { invocationEnv[v] = val } }', 1)
    open(p, "w").write(s)
    print("PATCHED")
else:
    print("NOT PATCHED: already patched, or file or line missing")
EOF
