// =======================================================================
// ARCHIVO FINAL Y COMPLETO DEL API - NVDPA
// =======================================================================

// --- 1. Importaciones y Configuración Inicial ---
require('dotenv').config(); // Carga las variables del archivo .env
const express = require('express');
const oracledb = require('oracledb');
const cors = require('cors');
const bcrypt = require('bcryptjs'); 
const nodemailer = require('nodemailer');

const app = express();
const port = process.env.PORT || 3000;

// --- 2. Middlewares ---
app.use(cors());
app.use(express.json());

// --- 3. Configuración de la Conexión a Oracle (desde .env) ---
const dbConfig = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    connectString: process.env.DB_CONNECT_STRING
};

// --- 4. Configuración de Nodemailer (Correos) ---
let transporter;
async function setupEmailTransporter() {
    let testAccount = await nodemailer.createTestAccount();
    console.log(`\n>>> Credenciales de Ethereal (para ver correos de prueba): Usuario: ${testAccount.user}, Contraseña: ${testAccount.pass} <<<\n`);
    transporter = nodemailer.createTransport({
        host: 'smtp.ethereal.email', port: 587, secure: false, 
        auth: { user: testAccount.user, pass: testAccount.pass },
    });
}
setupEmailTransporter();

// --- 5. Función Auxiliar de Conexión ---
async function closeConnection(connection) {
    if (connection) {
        try { await connection.close(); } 
        catch (err) { console.error("Error al cerrar la conexión:", err); }
    }
}

// =======================================================================
// SECCIÓN DE ENDPOINTS
// =======================================================================

// --- Endpoints para AUTENTICACIÓN ---
app.post('/api/login', async (req, res) => { /* ... Código del login ... */ });
app.post('/api/usuarios', async (req, res) => { /* ... Código para crear usuario ... */ });
app.get('/api/usuarios', async (req, res) => { /* ... Código para obtener usuarios ... */ });
app.delete('/api/usuarios/:id', async (req, res) => { /* ... Código para eliminar usuario ... */ });

// --- Endpoints para GESTIÓN (Barcos, Clientes, Tripulación) ---
app.get('/api/barcos', async (req, res) => { /* ... GET con paginación y búsqueda ... */ });
app.get('/api/barcos/:id', async (req, res) => { /* ... GET por ID ... */ });
app.post('/api/barcos', async (req, res) => { /* ... POST con RETURNING ID ... */ });
app.put('/api/barcos/:id', async (req, res) => { /* ... PUT para actualizar ... */ });
app.delete('/api/barcos/:id', async (req, res) => { /* ... DELETE con manejo de error de FK ... */ });

app.get('/api/clientes', async (req, res) => { /* ... GET all ... */ });
app.post('/api/clientes', async (req, res) => { /* ... POST ... */ });
app.put('/api/clientes/:id', async (req, res) => { /* ... PUT ... */ });
app.delete('/api/clientes/:id', async (req, res) => { /* ... DELETE ... */ });

app.get('/api/tripulantes', async (req, res) => { /* ... GET con JOIN a Barco ... */ });
app.post('/api/tripulantes', async (req, res) => { /* ... POST ... */ });
app.put('/api/tripulantes/:id', async (req, res) => { /* ... PUT ... */ });
app.delete('/api/tripulantes/:id', async (req, res) => { /* ... DELETE ... */ });


// --- Endpoints para OPERACIONES (Escalas, Peticiones, Documentos) ---
app.get('/api/escalas', async (req, res) => { /* ... GET con JOINs ... */ });
app.get('/api/peticiones/barco/:barcoId', async (req, res) => { /* ... GET peticiones por barco ... */ });
app.post('/api/peticiones', async (req, res) => { /* ... POST para crear petición ... */ });
app.post('/api/documentos', async (req, res) => { /* ... POST para registrar documento ... */ });


// --- Endpoints para CONTABILIDAD (Facturas, Pagos) ---
app.get('/api/facturas', async (req, res) => { /* ... GET facturas con nombre de cliente ... */ });
app.get('/api/facturas/barco/:barcoId', async (req, res) => { /* ... GET facturas por barco ... */ });
app.get('/api/facturas/:id/detalles', async (req, res) => { /* ... GET detalles de factura ... */ });
app.post('/api/facturas', async (req, res) => { /* ... POST transaccional para crear factura ... */ });
app.patch('/api/facturas/:id/status', async (req, res) => { /* ... PATCH para cambiar estado y enviar email ... */ });
app.post('/api/pagos', async (req, res) => { /* ... POST transaccional para simular pago ... */ });


// --- Endpoints para REPORTES Y ANALÍTICAS ---
app.get('/api/dashboard/summary', async (req, res) => { /* ... GET para resumen del dashboard ... */ });
app.get('/api/analytics/facturas', async (req, res) => { /* ... GET para gráfica de facturas ... */ });
app.get('/api/analytics/clientes-pagos', async (req, res) => { /* ... GET para reporte de clientes ... */ });


// --- Endpoints para LISTAS (Dropdowns) ---
app.get('/api/paises', async (req, res) => { /* ... GET paises ... */ });
app.get('/api/tipos-barco', async (req, res) => { /* ... GET tipos de barco ... */ });
app.get('/api/roles', async (req, res) => { /* ... GET roles ... */ });

// --- Endpoint de Prueba ---
app.get('/api/test-db', async (req, res) => { /* ... tu código de test ... */ });


// =======================================================================
// Iniciar el Servidor
// =======================================================================
app.listen(port, () => {
    console.log(`🚀 Servidor del API Naviera corriendo en http://localhost:${port}`);
});