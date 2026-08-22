# Üçüncü taraf bileşenleri

## ByeDPI / ciadpi

- Kaynak: https://github.com/hufrea/byedpi
- Sabitlenen commit: `ba532298de7b28cfe854aea83d061369d13ca290`
- Commit tarihi: 27 Mart 2026
- Lisans: `byedpi/LICENSE`

`ciadpi` binary'si repoda hazır binary olarak tutulmaz. `build.sh`, vendored
kaynakları `scripts/build-ciadpi.sh` üzerinden hedef macOS mimarisi için yeniden
derler. Böylece release içindeki yardımcının kaynağı ve üretim adımı denetlenebilir.

Upstream güncellenirken commit değeri, `byedpi/` içeriği, lisans ve her iki mimari
derleme birlikte doğrulanmalıdır.

## macOS derleme notları

Clang, upstream kaynakta iki taşınabilirlik uyarısı gösterir: GCC'ye özgü
`nonstring` attribute'u macOS Clang tarafından yok sayılır ve uygulamanın
kullanmadığı daemon modu deprecated `daemon(3)` çağrısını içerir.

Clang Static Analyzer ayrıca `mpool.c` içindeki `dump_cache` iterator erişimini
olası null dereference olarak raporlar. Kod, iterator kurulmadan önce
`hdr->root` değerinin null olmadığını kontrol eder; `kavl_itr_first` bu durumda
stack'e en az bir düğüm ekler. Bu nedenle mevcut uyarı macro/iterator akışını
çözemeyen analiz kaynaklı false-positive olarak değerlendirilmiştir. Upstream
commit değiştirilirken bu değerlendirme yeniden yapılmalıdır.
