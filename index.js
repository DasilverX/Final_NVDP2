// --- 1. Importaciones y Configuración Inicial ---
const express = require('express');
const oracledb = require('oracledb');
const cors = require('cors');
const bcrypt = require('bcryptjs'); 

const app = express();
const port = process.env.PORT || 3000;

// --- 2. Middlewares ---
app.use(cors());
app.use(express.json());

// --- 3. Configuración de la Conexión a Oracle ---
const dbConfig = {
    user: "NVDPA_USER",
    password: "nvdpa1",
    connectString: "2.tcp.ngrok.io:10267/XEPDB1" 
};

// Función auxiliar para cerrar la conexión de forma segura
async function closeConnection(connection) {
    if (connection) {
        try {
            await connection.close();
        } catch (err) {
            console.error("Error al cerrar la conexión:", err);
        }
    }
}

// =======================================================================
// SECCIÓN DE ENDPOINTS
// =======================================================================

// --- Endpoint de Autenticación (Login) ---
app.post('/api/login', async (req, res) => {
    let connection;
    const { nombre_usuario, password } = req.body;

    if (!nombre_usuario || !password) {
        return res.status(400).json({ error: "Nombre de usuario y contraseña son requeridos." });
    }

    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `SELECT ID_USUARIO, NOMBRE_USUARIO, PASSWORD_HASH, ID_ROL FROM USUARIOS WHERE NOMBRE_USUARIO = :nombre_usuario`;
        const result = await connection.execute(sql, { nombre_usuario });

        if (result.rows.length === 0) {
            return res.status(401).json({ error: "Credenciales inválidas." });
        }

        const user = result.rows[0];
        // Comparamos la contraseña enviada con el hash de la BD
        const isPasswordValid = await bcrypt.compare(password, user.PASSWORD_HASH);

        if (!isPasswordValid) {
            return res.status(401).json({ error: "Credenciales inválidas." });
        }

        // Si es válido, enviamos los datos del usuario sin el hash
        res.json({
            id_usuario: user.ID_USUARIO,
            nombre_usuario: user.NOMBRE_USUARIO,
            id_rol: user.ID_ROL
        });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Error interno del servidor." });
    } finally {
        await closeConnection(connection);
    }
});


// --- Endpoints para BARCOS ---

// GET: Obtener todos los barcos
app.get('/api/barcos', async (req, res) => {
    let connection;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const result = await connection.execute(`SELECT ID_BARCO, NOMBRE_BARCO, NUMERO_IMO, ID_TIPO_BARCO, ID_PAIS_BANDERA, ID_CLIENTE FROM BARCO ORDER BY NOMBRE_BARCO`);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// GET: Obtener un barco por su ID
app.get('/api/barcos/:id', async (req, res) => {
    let connection;
    const { id } = req.params;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const result = await connection.execute(`SELECT * FROM BARCO WHERE ID_BARCO = :id`, { id });
        if (result.rows.length === 0) {
            return res.status(404).json({ error: "Barco no encontrado." });
        }
        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// POST: Crear un nuevo barco
app.post('/api/barcos', async (req, res) => {
    let connection;
    const { nombre_barco, numero_imo, id_tipo_barco, id_pais_bandera, id_cliente } = req.body;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `INSERT INTO BARCO (NOMBRE_BARCO, NUMERO_IMO, ID_TIPO_BARCO, ID_PAIS_BANDERA, ID_CLIENTE) VALUES (:nombre_barco, :numero_imo, :id_tipo_barco, :id_pais_bandera, :id_cliente)`;
        await connection.execute(sql, { nombre_barco, numero_imo, id_tipo_barco, id_pais_bandera, id_cliente }, { autoCommit: true });
        res.status(201).json({ message: "Barco creado exitosamente." });
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// PUT: Actualizar un barco existente por su ID
app.put('/api/barcos/:id', async (req, res) => {
    let connection;
    const { id } = req.params;
    const { nombre_barco, numero_imo, id_tipo_barco, id_pais_bandera, id_cliente } = req.body;

    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `UPDATE BARCO 
                     SET NOMBRE_BARCO = :nombre_barco, 
                         NUMERO_IMO = :numero_imo, 
                         ID_TIPO_BARCO = :id_tipo_barco, 
                         ID_PAIS_BANDERA = :id_pais_bandera, 
                         ID_CLIENTE = :id_cliente
                     WHERE ID_BARCO = :id`;

        const result = await connection.execute(
            sql,
            { nombre_barco, numero_imo, id_tipo_barco, id_pais_bandera, id_cliente, id },
            { autoCommit: true }
        );

        if (result.rowsAffected === 0) {
            return res.status(404).json({ message: "Barco no encontrado para actualizar." });
        }

        res.status(200).json({ message: "Barco actualizado exitosamente." });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: err.message });
    } finally {
        if (connection) {
            try { await connection.close(); } 
            catch (err) { console.error(err); }
        }
    }
});

// --- Endpoints para ESCALAS PORTUARIAS ---

// GET: Obtener todas las escalas con información adicional (JOIN)
app.get('/api/escalas', async (req, res) => {
    let connection;
    try {
        connection = await oracledb.getConnection(dbConfig);
        // Hacemos un JOIN para obtener los nombres en lugar de solo los IDs
        const sql = `
            SELECT 
                e.ID_ESCALA, e.ID_BARCO,
                b.NOMBRE_BARCO,
                c.NOMBRE_CLIENTE,
                p.NOMBRE_PUERTO
            FROM ESCALA_PORTUARIA e
            JOIN BARCO b ON e.ID_BARCO = b.ID_BARCO
            JOIN CLIENTE c ON b.ID_CLIENTE = c.ID_CLIENTE
            JOIN PUERTO p ON e.ID_PUERTO = p.ID_PUERTO
            ORDER BY e.FECHA_LLEGADA DESC
        `;
        const result = await connection.execute(sql);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        if (connection) {
            try { await connection.close(); }
            catch (err) { console.error(err); }
        }
    }
});


// --- Endpoints para SERVICIOS ---

// GET: Obtener todos los servicios disponibles
app.get('/api/servicios', async (req, res) => {
    let connection;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const result = await connection.execute(`SELECT ID_SERVICIO, NOMBRE_SERVICIO, DESCRIPCION FROM SERVICIO ORDER BY NOMBRE_SERVICIO`);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});


// --- Endpoints para FACTURAS ---

// GET: Obtener todas las facturas de una escala específica
app.get('/api/escalas/:id_escala/facturas', async (req, res) => {
    let connection;
    const { id_escala } = req.params;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `SELECT ID_FACTURA, NUMERO_FACTURA, FECHA_EMISION, FECHA_VENCIMIENTO, MONTO_TOTAL, ESTADO_FACTURA FROM FACTURA WHERE ID_ESCALA = :id_escala ORDER BY FECHA_EMISION DESC`;
        const result = await connection.execute(sql, { id_escala });
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});


// Iniciar el Servidor
app.listen(port, () => {
    console.log(`🚀 Servidor del API Naviera corriendo en http://localhost:${port}`);
});