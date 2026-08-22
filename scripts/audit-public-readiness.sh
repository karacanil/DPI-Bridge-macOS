#!/bin/zsh

set -eu

REPO_ROOT=${0:A:h:h}
cd "$REPO_ROOT"
failed=0

report_failure() {
    print -u2 "HATA: $*"
    failed=1
}

print "[1/4] Tüm Git geçmişinde hassas/editor dosyaları aranıyor..."
history_paths=$(git rev-list --objects main --tags --remotes=origin | cut -d' ' -f2- | \
    rg '(^|/)(\.env($|\.)|settings\.txt$|\.settings\.txt\.swp$|\.vscode/|\.idea/)|\.(p12|pem|key|mobileprovision)$' || true)
[[ -z "$history_paths" ]] || report_failure "Git geçmişinde kaldırılması gereken dosyalar var."

print "[2/4] Commit e-postaları sınıflandırılıyor..."
non_noreply=$(git log main --tags --remotes=origin --format='%ae%n%ce' | sort -u | \
    rg -v '(@users\.noreply\.github\.com$|^$)' || true)
[[ -z "$non_noreply" ]] || report_failure "Git geçmişinde GitHub noreply olmayan e-posta metadata'sı var."

print "[3/4] Origin branch'leri kontrol ediliyor..."
extra_branches=$(git for-each-ref --format='%(refname:short)' refs/remotes/origin | \
    rg -v '^origin/(HEAD|main)$' || true)
[[ -z "$extra_branches" ]] || report_failure "Origin üzerinde main dışında branch var."

print "[4/4] Güncel tree kişisel yol ve credential dosyaları açısından taranıyor..."
current_user=$(id -un)
if git grep -I -i -q -F "$current_user" HEAD --; then
    report_failure "Güncel tree yerel kullanıcı adını içeriyor."
fi
if git ls-files | rg -q '(^|/)(\.env|settings\.txt)$|\.(p12|pem|key|mobileprovision)$'; then
    report_failure "Güncel tree hassas dosya türü içeriyor."
fi

(( failed == 0 )) || exit 1
print "Public-readiness geçmiş ve metadata kontrolleri başarılı."
