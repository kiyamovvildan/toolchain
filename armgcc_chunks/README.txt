ARM-GCC (arm-none-eabi 13.3.rel1), два варианта архива:
- armgcc_aa + armgcc_ab = tar.xz (ОСНОВНОЙ). Сборка: cat armgcc_a[ab] > armgcc.tar.xz
- *.tar.7z.001 + .002 = 7z (запасной, из 7-Zip). Распаковка: 7z x на .7z.001

Как сделать чанки заново (Linux/Mac):
  split -b 95m arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz armgcc_
  mv armgcc_aa armgcc_aa  # split и так даёт aa, ab, ac...
Загрузка на GitHub: в эту папку (файлы < 100 МБ).
Проверка после сборки: xz -t armgcc.tar.xz && tar -tf armgcc.tar.xz | head
