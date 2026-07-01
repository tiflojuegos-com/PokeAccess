@echo off
REM Ejecuta este archivo (doble clic) y se abrira un selector de carpetas para elegir el
REM juego del que quitar el mod. Tambien puedes arrastrar la carpeta encima.
echo Desinstalador del mod de accesibilidad.
echo Se abrira una ventana para elegir la carpeta del juego...
powershell -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" "%~1"
