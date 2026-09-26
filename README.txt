# Toolchain — сборка окружения (песочница Kimi)

## Состав
- armgcc_chunks/ + reassemble.sh — ARM GCC (сборка прошивок TITAN/emelya)
- kicad_chunks/ kicad_aa..ae — KiCad 10.0.6 AppImage, разбитый на чанки по ~100MB
- kicad_headless_toolkit.py — s-expr правки .kicad_sch/.kicad_pcb
- probe/, bootstrap.sh — восстановление окружения

## KiCad из чанков (ОБЯЗАТЕЛЬНО для каждого нового чата)
cat kicad_chunks/kicad_a* > /tmp/KiCad.AppImage && chmod +x /tmp/KiCad.AppImage
cd /tmp && ./KiCad.AppImage --appimage-extract   # FUSE нет, только распаковка
/tmp/squashfs-root/AppRun sch erc <проект>/titan-core.kicad_sch   # валидация ДО пуша

Скачивание чанков: https://raw.githubusercontent.com/kiyamovvildan/toolchain/main/kicad_chunks/kicad_aX
(каждый чанк < 100MB, fuse-лимит /mnt/agents не касается при скачивании в /tmp)

## Правило проекта (TITAN)
Любые правки схем/плат — только после локального прогона ERC/DRC через kicad-cli.
Баланс скобок НЕ гарантирует валидность файла (уроки v2.2.37/v2.2.41).

## kicad-jobs (стабильная песочница, 26.09)
Workflow `.github/workflows/kicad-jobs.yml`: тяжёлые KiCad-задачи гоняются здесь
(публичный репо => безлимитные минуты Actions, стабильная VM, без обрывов).
Задание = ci/jobs/<job>.sh в ПРИВАТНОМ source (ветка по выбору). Все расчёты и
результаты пушатся только в source. Требуется секрет SOURCE_PUSH_TOKEN
(Settings → Secrets and variables → Actions). Триггер: workflow_dispatch.

## СТАТУС: kicad-jobs работает (26.09, дымовой тест SUCCESS)
KiCad 10.0.6 собирается из чанков на раннере, задания ci/jobs/*.sh исполняются,
результаты пушатся в приватный source. Минуты Actions НЕ расходуются (публичный репо).
ПРАВИЛО БЕЗОПАСНОСТИ: логи прогонов ПУБЛИЧНЫ. Скрипты печатают только статусы/счётчики/
имена файлов. Запрещено echo содержимого файлов source (нетлисты, значения, результаты
расчётов) — данные только в файлы, которые пушатся в source. Артефакты не загружать.

## ПРАВИЛО ИМЁН (26.09): задания только нейтральные (job-a, job-b...)
Вход workflow_dispatch публично виден в списке прогонов. Значение input job —
только нейтральное имя. Что за заданием стоит — реестр ci/jobs/README.md
в ПРИВАТНОМ source. Запрещено диспатчить с содержательными именами
(gerber-*, drc-*, sim-*).
    