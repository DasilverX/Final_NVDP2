# NVDPA - Sistema de Gestión para Agencia Naviera

Este proyecto es un sistema de gestión integral para agencias navieras, diseñado para centralizar y optimizar las operaciones logísticas, financieras y administrativas. La aplicación web ha sido desarrollada como proyecto final para la materia de Base de Datos.

Demo del app: https://youtu.be/hL4n-CU16Gg

## ✨ Características Principales

- **Dashboard Interactivo:** Vista principal con resúmenes y métricas clave, incluyendo una gráfica de estado de facturas.
- **Gestión de Roles y Permisos:** Cuatro roles de usuario (Administrador, Contador, Capitán, Logística) con vistas y acciones personalizadas.
- **Módulos CRUD Completos:**
    - Gestión de Barcos
    - Gestión de Clientes
    - Gestión de Tripulantes
    - Gestión de Usuarios
- **Módulo de Contabilidad:**
    - Listado y detalle de facturas.
    - Simulación de pagos y actualización de estados de facturas.
    - Generación de facturas en PDF y envío automático por correo.
    - Reporte de contabilidad por cliente.
- **Visualización Geográfica:** Mapa interactivo que muestra la ubicación de los puertos registrados en la base de datos.
- **Simulación de "IA":** Un módulo de análisis que ofrece recomendaciones logísticas basadas en datos simulados.
- **Exportación de Datos:** Funcionalidad para exportar el listado de facturas a formato CSV.

## 🛠️ Tecnologías Utilizadas

- **Frontend:** Flutter (Web)
- **Backend:** Node.js con Express
- **Base de Datos:** Oracle Database
- **Librerías Clave (Backend):** `oracledb`, `express`, `cors`, `bcryptjs`, `nodemailer`, `pdfkit`, `json2csv`, `dotenv`.
- **Paquetes Clave (Frontend):** `provider`, `http`, `fl_chart`, `flutter_map`, `url_launcher`.
- **Despliegue:** Firebase Hosting (Frontend) y Render (Backend - opcional).

## 🚀 Cómo Ejecutar el Proyecto

Sigue estos pasos para poner en marcha el entorno de desarrollo local.

### Prerrequisitos
- Tener instalado [Node.js](https://nodejs.org/) (versión 20 o superior).
- Tener instalado el [SDK de Flutter](https://flutter.dev/docs/get-started/install).
- Tener una instancia de Oracle Database accesible.

### 1. Configuración del Backend (API)
```bash
# 1. Clona el repositorio
git clone <URL_DEL_REPOSITORIO>
cd Final_NVDP2

# 2. Instala las dependencias
npm install

# 3. Configura las variables de entorno
#    Crea un archivo llamado .env en la raíz y añade tus credenciales:
#    DB_USER="NVDPA_USER"
#    DB_PASSWORD="ndpa1"
#    DB_CONNECT_STRING="localhost:1521/XEPDB1"
#    PORT=3000

# 4. Ejecuta los scripts de la base de datos
#    Abre tu cliente de SQL (ej. SQL Developer) y ejecuta:
#    a) nvdp_database.sql (para crear la estructura)
#    b) El script de datos masivos (para poblar las tablas)

# 5. Inicia el servidor
node index.js
# El API estará corriendo en http://localhost:3000
```

### 2. Configuración del Frontend (App Flutter)
```bash
# 1. Navega a la carpeta del proyecto Flutter
cd nvdp

# 2. Obtén las dependencias de Flutter
flutter pub get

# 3. Ejecuta la aplicación en Chrome
flutter run -d chrome
# La aplicación se abrirá y se conectará al API local.
```

## 📋 Casos de Uso y Cuentas de Prueba

Puedes iniciar sesión con los siguientes usuarios para probar los diferentes roles. **La contraseña para todos es `password123`**.

- **Administrador (`admin`):**
  - Tiene acceso a todos los módulos sin restricciones.
  - Puede ver el dashboard completo, gestionar barcos, clientes, tripulantes y usuarios.
  - Puede cambiar el estado de las facturas y acceder a todos los reportes.

- **Contador (`contador_ana`):**
  - Ve un menú enfocado en finanzas.
  - Puede acceder a la sección de Contabilidad y al Reporte por Cliente.
  - No tiene acceso a los módulos de gestión de barcos o tripulantes.

- **Capitán (`capitan_smith`):**
  - Al iniciar sesión, el sistema identifica su barco asociado.
  - Tiene acceso a una sección para ver las facturas de su barco y realizar pagos simulados.
  - Tiene una vista limitada del resto de la aplicación.

- **Logística (`logistica_juan`):**
  - Tiene acceso al Dashboard y al Mapa de Puertos.
  - Puede ver la información pero no tiene permisos de edición o creación en los módulos principales.

## 👥 Autores

- **Nayelis Gutiérrez**
- **Liseika Calderón**
- **José Dasilva**
