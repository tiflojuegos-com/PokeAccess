@echo off
REM Comprueba si un fangame acepta el mod (sin instalar nada). Doble clic y elige la carpeta
REM del juego, o arrastra la carpeta sobre este .bat. Informa de si hay mkxp.json y si el
REM ejecutable acepta preloadScript (la via por la que se carga el mod).
echo Comprobacion de compatibilidad del mod de accesibilidad.
echo Se abrira una ventana para elegir la carpeta del juego...
powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1" "%~1" -Check
