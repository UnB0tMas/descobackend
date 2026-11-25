@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0.."
if errorlevel 1 exit /b 1

echo [1/4] Limpieza y compilacion Java (incluye actualizacion de Flyway en target/classes)
call mvnw.cmd -DskipTests clean package
if errorlevel 1 (
  echo ERROR: no se pudo compilar el backend. Revise el primer error del comando.
  exit /b 1
)
echo [2/4] Comparacion de migracion original y recurso compilado
fc /b "src\main\resources\db\migration\V642__AP_doc.PA_Correspondencia_Ejecutar.sql" "target\classes\db\migration\V642__AP_doc.PA_Correspondencia_Ejecutar.sql" >nul
if errorlevel 1 (
  echo ERROR: target/classes conserva una migracion desactualizada.
  exit /b 1
)
echo [3/4] Pruebas Java
call mvnw.cmd test
if errorlevel 1 exit /b 1

echo [4/4] Compilacion Angular
if not exist "..\desco_frontend\package.json" (
  echo ADVERTENCIA: no se encontro el frontend hermano desco_frontend.
  exit /b 0
)
pushd "..\desco_frontend"
call npm run build
set "resultado=!errorlevel!"
popd
if not "!resultado!"=="0" exit /b !resultado!
echo VALIDACION DE COMPILACION FINALIZADA
exit /b 0
