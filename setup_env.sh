#!/usr/bin/env bash
# setup_env.sh — развёртывание окружения сборки TITAN-HYBRID firmware в чистой песочнице
# ВЕРСИИ ЗАПИНЕНЫ (2026-09-13, проверено BUILD_OK arm-gcc 13.2.1). Апгрейд — только осознанно:
# обновить SHA ниже и прогнать build.sh. Плавающие master НЕ использовать.
# КЛЮЧЕВОЕ ПРАВИЛО: STM32CubeG4 — МЕТА-репозиторий (сабмодули в tarball пустые!). Качать сабмодули напрямую.
# Тактика: ВЕСЬ цикл в ОДНОМ вызове shell (песочница чистит /tmp между вызовами), артефакты сразу в /mnt/agents.
set -e
cd /tmp

# --- пины (коммит-SHA, дата фиксации) ---
SHA_HAL=a6001282dfac   # stm32g4xx_hal_driver master @2026-06-03
SHA_DEV=626ee412334a   # cmsis_device_g4     master @2026-06-11
SHA_CORE=afc5ca6af0a4  # cmsis_core          master @2026-06-15
SHA_RTOS=8be86d4a24fd  # FreeRTOS-Kernel     main   @2026-08-26
SHA_MW=d8c632a9478f    # stm32-mw-freertos   master @2026-06-11

echo "[1/6] ARM-GCC 13.2 Rel1 (CDN, ~170MB)..."
curl -sL --retry 3 -o armgcc.tar.xz "https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-arm-none-eabi.tar.xz"
mkdir -p armgcc_x && tar -xf armgcc.tar.xz -C armgcc_x
echo "[2/6] HAL G4...";           curl -sL --retry 3 -o hal.tar.gz  "https://codeload.github.com/STMicroelectronics/stm32g4xx_hal_driver/tar.gz/$SHA_HAL"
echo "[3/6] CMSIS Device G4...";  curl -sL --retry 3 -o dev4.tar.gz "https://codeload.github.com/STMicroelectronics/cmsis_device_g4/tar.gz/$SHA_DEV"
echo "[4/6] CMSIS Core...";       curl -sL --retry 3 -o core.tar.gz "https://codeload.github.com/STMicroelectronics/cmsis_core/tar.gz/$SHA_CORE"
echo "[5/6] FreeRTOS Kernel...";  curl -sL --retry 3 -o rtos.tar.gz "https://codeload.github.com/FreeRTOS/FreeRTOS-Kernel/tar.gz/$SHA_RTOS"
echo "[6/6] ST CMSIS_RTOS_V2..."; curl -sL --retry 3 -o mw.tar.gz   "https://codeload.github.com/STMicroelectronics/stm32-mw-freertos/tar.gz/$SHA_MW"
mkdir -p hal devg4 cmsis_core frtk mwrtos
tar -xzf hal.tar.gz -C hal --strip-components=1
tar -xzf dev4.tar.gz -C devg4 --strip-components=1
tar -xzf core.tar.gz -C cmsis_core --strip-components=1
tar -xzf rtos.tar.gz -C frtk --strip-components=1
tar -xzf mw.tar.gz -C mwrtos --strip-components=1
mkdir -p libs && cd libs
ln -sfn /tmp/cmsis_core/CMSIS/Core/Include cmsis_core
ln -sfn /tmp/hal halg4
ln -sfn /tmp/devg4 devg4
ln -sfn /tmp/frtk frtk
ln -sfn /tmp/mwrtos mwrtos
ls /tmp/armgcc_x/arm-gnu-toolchain-13.2.Rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-gcc \
   cmsis_core/core_cm4.h halg4/Inc/stm32g4xx_hal.h devg4/Include/stm32g474xx.h \
   devg4/Source/Templates/gcc/startup_stm32g474xx.s frtk/tasks.c mwrtos/Source/CMSIS_RTOS_V2/cmsis_os2.c
echo "ENV READY. Далее одним вызовом: клон source, sed -i 's|^L=.*|L=/tmp/libs|' firmware/titan-legacy/build.sh, ./build.sh, cp titan.elf titan.bin /mnt/agents/work/"
