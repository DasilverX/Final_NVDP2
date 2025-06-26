@ECHO OFF
TITLE Prueba de Backup Manual - NVDPA

ECHO.
ECHO ==========================================================
ECHO      ASISTENTE PARA BACKUP MANUAL DE LA BASE DE DATOS
ECHO ==========================================================
ECHO.

REM --- Peticion de datos al usuario ---
ECHO Por favor, introduce la contrasena de tu usuario NVDPA_USER:
SET /p DB_PASSWORD=Contrasena: 

ECHO.
ECHO Ahora, introduce el SID de tu base de datos.
ECHO (Para Oracle XE, normalmente es 'XE' o 'XEPDB1'. Si no estas seguro, prueba con 'XE')
SET /p DB_SID=SID de la Base de Datos: 

ECHO.
ECHO Configuracion lista. Presiona cualquier tecla para iniciar el backup...
PAUSE > NUL

ECHO.
ECHO --- Ejecutando Data Pump (expdp)... ---

expdp NVDPA_USER/%DB_PASSWORD%@%DB_SID% SCHEMAS=NVDPA_USER DIRECTORY=NVDPA_BACKUP_DIR DUMPFILE=NVDPA_MANUAL_BKP.dmp LOGFILE=NVDPA_MANUAL_BKP.log

ECHO.
ECHO ----------------------------------------------------------
ECHO Proceso finalizado. Revisa la ventana en busca de errores.
ECHO ----------------------------------------------------------
ECHO.
PAUSE