#!/bin/bash
# ============================================================
# EMELYA bootstrap v3 — восстановление окружения в новом чате
# ============================================================
# ВАЖНО (прочитать перед запуском):
#  1. Всё собирается в /tmp — ЭФЕМЕРНО, между чатами исчезает.
#     Все правки пушить обратно в github.com/kiyamovvildan/source
#     В ТОМ ЖЕ ЧАТЕ, где делались.
#  2. /mnt/agents (fuse-портал облака) НЕ подходит для git-клонов:
#     запись pack-файла падает с I/O error, лимит 100 МБ на файл.
#  3. Перед запуском: export GITHUB_TOKEN=ghp_xxxxxxxx
#     (нужен для приватного репо kiyamovvildan/source)
#
# Форматы чанков (проверено по магическим байтам 25.09):
#  armgcc_chunks/armgcc_aa+ab = tar.xz (arm-none-eabi 13.3.rel1)
#  armgcc_chunks/*.7z.001/002 = то же железо, но архив 7z (запасной)
#  kicad_chunks/kicad_aa..ae  = KiCad 10 AppImage (ELF/AppImage type-2)
# ============================================================
set -e

ENV="/tmp/emelya_env"
TOOLCHAIN="$ENV/toolchain"
SRC="$ENV/source"

echo "=== EMELYA bootstrap v3 ==="
mkdir -p "$ENV"

# === 1. toolchain (public) ===
if [ ! -d "$TOOLCHAIN/.git" ]; then
    echo "Клонирую toolchain..."
    git clone --depth=1 https://github.com/kiyamovvildan/toolchain.git "$TOOLCHAIN"
fi

# === 2. source (private, нужен токен) ===
if [ ! -d "$SRC/.git" ]; then
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "ОШИБКА: export GITHUB_TOKEN=ghp_xxxxxxxx и запусти снова."
        exit 1
    fi
    echo "Клонирую source..."
    git clone --depth=1 "https://${GITHUB_TOKEN}@github.com/kiyamovvildan/source.git" "$SRC"
fi

# === 3. ARM-GCC из чанков (armgcc_aa + armgcc_ab -> tar.xz) ===
if [ ! -x "$ENV/armgcc/bin/arm-none-eabi-gcc" ]; then
    echo "Собираю ARM-GCC из чанков (tar.xz)..."
    cat "$TOOLCHAIN"/armgcc_chunks/armgcc_a[ab] > "$ENV/armgcc.tar.xz"
    xz -t "$ENV/armgcc.tar.xz" || { echo "ОШИБКА: чанки битые (xz -t не прошёл)"; exit 1; }
    mkdir -p "$ENV/armgcc"
    tar -xf "$ENV/armgcc.tar.xz" -C "$ENV/armgcc" --strip-components=1
    rm "$ENV/armgcc.tar.xz"
    echo "ARM-GCC готов."
    # Запасной вариант (7z): 7z x на .7z.001, внутри тот же tar.xz
fi
export PATH="$ENV/armgcc/bin:$PATH"

# === 4. KiCad AppImage из чанков (kicad_aa..ae, ~486 МБ) ===
# Сборка плат — ТОЛЬКО через AppImage (pcbnew CLI).
# Текстовый kicad_headless_toolkit.py — запасной вариант.
KICAD_BYTES=486007834
if [ ! -x "$ENV/squashfs-root/usr/bin/kicad" ]; then
    if ls "$TOOLCHAIN"/kicad_chunks/kicad_* >/dev/null 2>&1; then
        echo "Собираю KiCad AppImage из чанков..."
        cat "$TOOLCHAIN"/kicad_chunks/kicad_a[abcde] > "$ENV/KiCad.AppImage"
        SZ=$(stat -c%s "$ENV/KiCad.AppImage")
        if [ "$SZ" != "$KICAD_BYTES" ]; then
            echo "ОШИБКА: размер $SZ, ожидалось $KICAD_BYTES — чанки неполные."
            exit 1
        fi
        chmod +x "$ENV/KiCad.AppImage"
        cd "$ENV" && ./KiCad.AppImage --appimage-extract   # -> squashfs-root/
        rm "$ENV/KiCad.AppImage"
        echo "KiCad готов (squashfs-root)."
    else
        echo "ВНИМАНИЕ: kicad_chunks/ пуст — KiCad НЕ собран."
        echo "Платы не трогать до загрузки чанков в репо!"
    fi
fi
export PATH="$ENV/squashfs-root/usr/bin:$PATH"

# === 5. Python-зависимости (wheels из репо, без сети) ===
if [ -d "$TOOLCHAIN/py/wheels" ] && [ "$(ls -A "$TOOLCHAIN/py/wheels")" ]; then
    pip install --user --no-index --find-links="$TOOLCHAIN/py/wheels" \
        -r "$TOOLCHAIN/py/requirements.txt" 2>/dev/null || true
fi

# === 6. Состояние проекта (читать первым!) ===
if [ -f "$SRC/PROJECT_STATE.md" ]; then
    echo "--- PROJECT_STATE.md (первые 40 строк) ---"
    head -40 "$SRC/PROJECT_STATE.md"
fi

# === 7. Проверка ===
echo "=== Проверка ==="
arm-none-eabi-gcc --version | head -1
kicad-cli version 2>/dev/null || echo "KiCad CLI недоступен (нет чанков?)"
echo "ENV=$SRC (source) | $TOOLCHAIN (toolchain)"
echo "=== Готово ==="
