KiCad 10 AppImage, чанки kicad_aa .. kicad_ae (по 95 МиБ, последний меньше).
Суммарный размер после сборки: 486007834 байт (проверяется в bootstrap.sh).

Как сделать чанки заново:
  split -b 95m KiCad.AppImage kicad_
  # получится kicad_aa, kicad_ab, ...
Сборка:
  cat kicad_a[abcde] > KiCad.AppImage && chmod +x KiCad.AppImage
  ./KiCad.AppImage --appimage-extract   # -> squashfs-root/
Проверка: файл начинается с ELF + "AI" (AppImage type-2), kicad-cli version работает.
