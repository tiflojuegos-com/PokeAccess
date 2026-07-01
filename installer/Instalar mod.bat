@echo off
REM Ejecuta este archivo (doble clic) y se abrira un selector de carpetas para elegir el
REM juego. Tambien puedes arrastrar la carpeta del juego sobre este .bat.
echo Instalador del mod de accesibilidad.
echo Se abrira una ventana para elegir la carpeta del juego...
powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1" "%~1"
