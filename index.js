// --- 1. Importaciones y Configuración Inicial ---
const express = require('express');
const oracledb = require('oracledb');
const cors = require('cors');
const bcrypt = require('bcryptjs'); 
const nodemailer = require('nodemailer');
const PDFDocument = require('pdfkit'); 
const { Parser } = require('json2csv'); // Para generar CSV si es necesario

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

async function generarFacturaPDF(facturaInfo, detalles) {
  return new Promise((resolve) => {
    const doc = new PDFDocument({ margin: 50 });
    const buffers = [];
    doc.on('data', buffers.push.bind(buffers));
    doc.on('end', () => {
      resolve(Buffer.concat(buffers));
    });

    // Cabecera del PDF
    doc.fontSize(20).text('Factura NVDPA', { align: 'center' });
    doc.moveDown();
    doc.fontSize(12).text(`Factura N°: ${facturaInfo.NUMERO_FACTURA}`);
    doc.text(`Fecha: ${new Date(facturaInfo.FECHA_EMISION).toLocaleDateString()}`);
    doc.text(`Cliente: ${facturaInfo.NOMBRE_CLIENTE}`);
    doc.moveDown();

    // Tabla de Detalles
    doc.font('Helvetica-Bold').text('Descripción');
    doc.moveUp().text('Subtotal', { align: 'right' });
    doc.font('Helvetica');
    detalles.forEach(item => {
        doc.text(item.DESCRIPCION);
        doc.moveUp().text(`$${(item.SUBTOTAL || 0).toFixed(2)}`, { align: 'right' });
    });
    
    // Total
    doc.moveDown();
    doc.font('Helvetica-Bold').fontSize(14).text('Total:', { align: 'left' });
    doc.moveUp().text(`$${(facturaInfo.MONTO_TOTAL || 0).toFixed(2)}`, { align: 'right' });

    doc.end();
  });
}

async function setupEmailTransporter() {
    // Genera una cuenta de prueba en Ethereal
    let testAccount = await nodemailer.createTestAccount();
    console.log(`
    *************************************************
    Para ver los correos de prueba, usa estas credenciales en Ethereal:
    Usuario: ${testAccount.user}
    Contraseña: ${testAccount.pass}
    *************************************************
    `);

    // Crea el objeto transportador usando el SMTP de Ethereal
    return nodemailer.createTransport({
        host: 'smtp.ethereal.email',
        port: 587,
        secure: false, 
        auth: {
            user: testAccount.user,
            pass: testAccount.pass,
        },
    });
}
let transporter;
setupEmailTransporter().then(t => transporter = t);

// =======================================================================
// SECCIÓN DE ENDPOINTS
// =======================================================================


app.get('/api/test-db', async (req, res) => {
    let connection;
    try {
        console.log('Intentando conectar a la base de datos...');
        connection = await oracledb.getConnection(dbConfig);
        console.log('¡Conexión exitosa!');
        await connection.close();
        res.status(200).json({ status: "success", message: "Conexión a la base de datos exitosa." });
    } catch (err) {
        // Si hay un error, lo enviamos en la respuesta para poder verlo
        console.error('FALLO LA CONEXIÓN:', err);
        res.status(500).json({ status: "error", message: "Fallo la conexión", error: err.message });
    }
});


// --- Endpoint de Autenticación (Login) ---
app.post('/api/login', async (req, res) => {
    let connection;
    const { nombre_usuario, password } = req.body;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const userSql = `SELECT ID_USUARIO, NOMBRE_USUARIO, PASSWORD_HASH, ID_ROL FROM USUARIOS WHERE NOMBRE_USUARIO = :nombre_usuario`;
        const userResult = await connection.execute(userSql, { nombre_usuario }, { outFormat: oracledb.OUT_FORMAT_OBJECT });
        if (userResult.rows.length === 0) return res.status(401).json({ error: "Credenciales inválidas." });
        
        const user = userResult.rows[0];
        const isPasswordValid = await bcrypt.compare(password, user.PASSWORD_HASH);
        if (!isPasswordValid) return res.status(401).json({ error: "Credenciales inválidas." });
        
        let responseData = { id_usuario: user.ID_USUARIO, nombre_usuario: user.NOMBRE_USUARIO, id_rol: user.ID_ROL };
        
        // Si el rol es 'capitan' (ID=2), buscamos su barco
        if (user.ID_ROL === 2) {
             const barcoSql = `SELECT ID_BARCO FROM TRIPULACION WHERE ID_USUARIO_CAPITAN = :id_usuario`; // Asumiendo esta columna de relación
             const barcoResult = await connection.execute(barcoSql, { id_usuario: user.ID_USUARIO }, { outFormat: oracledb.OUT_FORMAT_OBJECT });
             if (barcoResult.rows.length > 0) {
                 responseData.id_barco = barcoResult.rows[0].ID_BARCO;
             }
        }
        res.json(responseData);
    } catch (err) {
        console.error("Error en /api/login:", err);
        res.status(500).json({ error: "Error interno del servidor." });
    } finally { await closeConnection(connection); }
});


// GET: Obtener barcos con paginación y búsqueda
app.get('/api/barcos', async (req, res) => {
    let connection;
    const page = parseInt(req.query.page, 10) || 1;
    const limit = 15; // O el número de items por página que prefieras
    const offset = (page - 1) * limit;
    const searchTerm = req.query.search || '';

    try {
        connection = await oracledb.getConnection(dbConfig);
        
        // Base de la consulta con JOINs para obtener nombres en lugar de solo IDs
        let sql = `
            SELECT 
                b.ID_BARCO, b.NOMBRE_BARCO, b.NUMERO_IMO,
                t.TIPO_BARCO,
                p.PAIS as PAIS_BANDERA,
                c.NOMBRE_CLIENTE
            FROM BARCO b
            LEFT JOIN TIPO_BARCO t ON b.ID_TIPO_BARCO = t.ID_TIPO_BARCO
            LEFT JOIN PAIS p ON b.ID_PAIS_BANDERA = p.ID_PAIS
            LEFT JOIN CLIENTE c ON b.ID_CLIENTE = c.ID_CLIENTE
        `;
        
        const countSql = `SELECT COUNT(*) as total FROM (${sql}) `;
        
        // Añadir cláusula WHERE para la búsqueda
        if (searchTerm) {
            sql += ` WHERE LOWER(b.NOMBRE_BARCO) LIKE :searchTerm OR LOWER(b.NUMERO_IMO) LIKE :searchTerm`;
        }
        
        sql += ` ORDER BY b.NOMBRE_BARCO OFFSET :offset ROWS FETCH NEXT :limit ROWS ONLY`;

        const bindParams = { 
            offset: offset, 
            limit: limit,
            ...(searchTerm && { searchTerm: `%${searchTerm.toLowerCase()}%` })
        };
        
        const [result, countResult] = await Promise.all([
            connection.execute(sql, bindParams, { outFormat: oracledb.OUT_FORMAT_OBJECT }),
            connection.execute(countSql, (searchTerm ? { searchTerm: `%${searchTerm.toLowerCase()}%` } : {}), { outFormat: oracledb.OUT_FORMAT_OBJECT })
        ]);

        const totalItems = countResult.rows[0].TOTAL;
        const totalPages = Math.ceil(totalItems / limit);

        // Devolvemos un objeto Mapa, que es lo que Flutter espera
        res.json({
            barcos: result.rows,
            totalPages: totalPages,
            currentPage: page
        });

    } catch (err) {
        console.error(err);
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
        const sql = `SELECT * FROM BARCO WHERE ID_BARCO = :id`;
        const result = await connection.execute(sql, { id }, { outFormat: oracledb.OUT_FORMAT_OBJECT });
        
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

// POST: Crear un nuevo barco y devolver su ID
app.post('/api/barcos', async (req, res) => {
    let connection;
    const { nombre_barco, numero_imo, id_tipo_barco, id_pais_bandera, id_cliente } = req.body;
    const binds = {
        nombre_barco, numero_imo, id_tipo_barco, id_pais_bandera, id_cliente,
        out_id: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT }
    };
    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `INSERT INTO BARCO (NOMBRE_BARCO, NUMERO_IMO, ID_TIPO_BARCO, ID_PAIS_BANDERA, ID_CLIENTE) 
                     VALUES (:nombre_barco, :numero_imo, :id_tipo_barco, :id_pais_bandera, :id_cliente)
                     RETURNING ID_BARCO INTO :out_id`;
        const result = await connection.execute(sql, binds, { autoCommit: true });
        const nuevoBarcoId = result.outBinds.out_id[0];
        res.status(201).json({ message: "Barco creado exitosamente.", nuevoBarcoId: nuevoBarcoId });
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// PUT: Actualizar un barco existente
app.put('/api/barcos/:id', async (req, res) => {
    let connection;
    const { id } = req.params;
    const { nombre_barco, numero_imo, id_tipo_barco, id_pais_bandera, id_cliente } = req.body;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `UPDATE BARCO SET NOMBRE_BARCO = :nombre_barco, NUMERO_IMO = :numero_imo, ID_TIPO_BARCO = :id_tipo_barco, ID_PAIS_BANDERA = :id_pais_bandera, ID_CLIENTE = :id_cliente WHERE ID_BARCO = :id`;
        const result = await connection.execute(sql, { nombre_barco, numero_imo, id_tipo_barco, id_pais_bandera, id_cliente, id }, { autoCommit: true });
        if (result.rowsAffected === 0) {
            return res.status(404).json({ message: "Barco no encontrado para actualizar." });
        }
        res.status(200).json({ message: "Barco actualizado exitosamente." });
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// DELETE: Eliminar un barco
app.delete('/api/barcos/:id', async (req, res) => {
    let connection;
    const { id } = req.params;
    try {
        connection = await oracledb.getConnection(dbConfig);
        await connection.execute(`DELETE FROM BARCO WHERE ID_BARCO = :id`, { id }, { autoCommit: true });
        res.status(200).json({ message: "Barco eliminado." });
    } catch (err) {
        // Capturamos el error de Oracle para la restricción de integridad (si tiene escalas)
        if (err.errorNum && err.errorNum === 2292) {
            return res.status(400).json({ error: "No se puede eliminar el barco porque tiene escalas portuarias registradas." });
        }
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
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


// GET: Obtener todas las peticiones de un barco específico
app.get('/api/peticiones/barco/:barcoId', async (req, res) => {
    let connection;
    const { barcoId } = req.params;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `
            SELECT 
                p.ID_PETICION, p.FECHA_PETICION,
                s.NOMBRE_SERVICIO,
                e.ESTADO,
                pu.NOMBRE_PUERTO
            FROM PETICION_SERVICIO p
            JOIN SERVICIO s ON p.ID_SERVICIO = s.ID_SERVICIO
            JOIN ESTADO_PETICION e ON p.ID_ESTADO = e.ID_ESTADO
            JOIN ESCALA_PORTUARIA es ON p.ID_ESCALA = es.ID_ESCALA
            JOIN PUERTO pu ON es.ID_PUERTO = pu.ID_PUERTO
            WHERE es.ID_BARCO = :barcoId
            ORDER BY p.FECHA_PETICION DESC
        `;
        const result = await connection.execute(sql, { barcoId }, { outFormat: oracledb.OUT_FORMAT_OBJECT });
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// POST: Crear una nueva petición de servicio
app.post('/api/peticiones', async (req, res) => {
    let connection;
    const { escalaId, servicioId, usuarioId, notas } = req.body;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `INSERT INTO PETICION_SERVICIO (ID_ESCALA, ID_SERVICIO, ID_USUARIO_CAPITAN, ID_ESTADO, NOTAS_CAPITAN) 
                     VALUES (:escalaId, :servicioId, :usuarioId, 1, :notas)`; // ID_ESTADO = 1 para 'Pendiente'
        await connection.execute(sql, { escalaId, servicioId, usuarioId, notas }, { autoCommit: true });
        res.status(201).json({ message: "Petición creada con éxito." });
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});


// --- Endpoints para FACTURAS ---


// PATCH: Actualizar solo el estado de una factura y enviar correo
app.patch('/api/facturas/:id/status', async (req, res) => {
    let connection;
    const { id } = req.params;
    const { nuevoStatus } = req.body;
    try {
        connection = await oracledb.getConnection(dbConfig);
        await connection.beginTransaction();

        await connection.execute(`UPDATE FACTURA SET ESTADO_FACTURA = :nuevoStatus WHERE ID_FACTURA = :id`, { nuevoStatus, id });

        if (nuevoStatus === 'Pagado') {
            const facturaSql = `SELECT f.*, c.NOMBRE_CLIENTE FROM FACTURA f JOIN CLIENTE c ON f.ID_CLIENTE = c.ID_CLIENTE WHERE f.ID_FACTURA = :id`;
            const detallesSql = `SELECT * FROM DETALLE_FACTURA WHERE ID_FACTURA = :id`;
            
            const [facturaResult, detallesResult] = await Promise.all([
                connection.execute(facturaSql, {id}, {outFormat: oracledb.OUT_FORMAT_OBJECT}),
                connection.execute(detallesSql, {id}, {outFormat: oracledb.OUT_FORMAT_OBJECT})
            ]);

            const facturaInfo = facturaResult.rows[0];
            const detalles = detallesResult.rows;

            const pdfBuffer = await generarFacturaPDF(facturaInfo, detalles);

            const mailOptions = {
                from: '"NVDPA Sistema" <no-reply@nvdpa.com>',
                to: "cliente@ejemplo.com",
                subject: `Factura Pagada - N° ${facturaInfo.NUMERO_FACTURA}`,
                text: `Estimado ${facturaInfo.NOMBRE_CLIENTE},\n\nAdjuntamos la factura N° ${facturaInfo.NUMERO_FACTURA} que ha sido marcada como pagada.\n\nGracias.`,
                attachments: [{
                    filename: `Factura-${facturaInfo.NUMERO_FACTURA}.pdf`,
                    content: pdfBuffer,
                    contentType: 'application/pdf'
                }]
            };
            let info = await transporter.sendMail(mailOptions);
            console.log("Correo con PDF enviado. Preview URL: %s", nodemailer.getTestMessageUrl(info));
        }
        
        await connection.commit();
        res.status(200).json({ message: `Estado de la factura actualizado a ${nuevoStatus}.` });
    } catch (err) {
        if (connection) await connection.rollback();
        console.error("Error en PATCH /api/facturas/:id/status:", err);
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

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


// GET: Obtener todos los puertos para el mapa
app.get('/api/puertos', async (req, res) => {
    let connection;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `SELECT ID_PUERTO, NOMBRE_PUERTO, CIUDAD, LATITUD, LONGITUD FROM PUERTO WHERE LATITUD IS NOT NULL AND LONGITUD IS NOT NULL`;
        const options = { outFormat: oracledb.OUT_FORMAT_OBJECT };
        const result = await connection.execute(sql, {}, options);
        res.json(result.rows);
    } catch (err) {
        console.error("Error en /api/puertos:", err);
        res.status(500).json({ error: err.message });
    } finally {
        if (connection) {
            try { await connection.close(); }
            catch (err) { console.error(err); }
        }
    }
});

// GET: Obtener toda la tripulación con el nombre del barco
app.get('/api/tripulantes', async (req, res) => {
    let connection;
    try {
        connection = await oracledb.getConnection(dbConfig);
        // AJUSTE: Hacemos un LEFT JOIN para obtener b.NOMBRE_BARCO
        const sql = `
            SELECT 
                t.ID_TRIPULACION, 
                t.NOMBRE_COMPLETO, 
                t.ROL_ABORDO, 
                t.PASAPORTE, 
                t.ID_BARCO,
                b.NOMBRE_BARCO 
            FROM TRIPULACION t
            LEFT JOIN BARCO b ON t.ID_BARCO = b.ID_BARCO
            ORDER BY t.NOMBRE_COMPLETO
        `;
        const options = { outFormat: oracledb.OUT_FORMAT_OBJECT };
        const result = await connection.execute(sql, {}, options);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// DELETE: Eliminar un tripulante por ID
app.delete('/api/tripulantes/:id', async (req, res) => {
    let connection;
    const { id } = req.params;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `DELETE FROM TRIPULACION WHERE ID_TRIPULACION = :id`;
        await connection.execute(sql, { id }, { autoCommit: true });
        res.status(200).json({ message: "Tripulante eliminado exitosamente." });
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// PUT: Actualizar un tripulante
app.put('/api/tripulantes/:id', async (req, res) => {
    let connection;
    const { id } = req.params;
    const { nombre_completo, rol_abordo, pasaporte, id_barco } = req.body;

    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `UPDATE TRIPULACION 
                     SET NOMBRE_COMPLETO = :nombre_completo, 
                         ROL_ABORDO = :rol_abordo, 
                         PASAPORTE = :pasaporte, 
                         ID_BARCO = :id_barco
                     WHERE ID_TRIPULACION = :id`;
        
        const result = await connection.execute(
            sql,
            { nombre_completo, rol_abordo, pasaporte, id_barco, id },
            { autoCommit: true }
        );

        if (result.rowsAffected === 0) {
            return res.status(404).json({ message: "Tripulante no encontrado." });
        }
        res.status(200).json({ message: "Tripulante actualizado exitosamente." });
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// POST: Crear un nuevo tripulante
app.post('/api/tripulantes', async (req, res) => {
    let connection;
    // Extraemos los datos del cuerpo de la petición
    const { nombre_completo, rol_abordo, pasaporte, id_barco } = req.body;
    
    // Validamos que los datos necesarios estén presentes
    if (!nombre_completo || !rol_abordo || !pasaporte) {
        return res.status(400).json({ error: "Nombre, rol y pasaporte son requeridos." });
    }

    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `INSERT INTO TRIPULACION (NOMBRE_COMPLETO, ROL_ABORDO, PASAPORTE, ID_BARCO) 
                     VALUES (:nombre_completo, :rol_abordo, :pasaporte, :id_barco)`;
        
        await connection.execute(sql, 
            { nombre_completo, rol_abordo, pasaporte, id_barco }, 
            { autoCommit: true }
        );
        
        res.status(201).json({ message: "Tripulante añadido con éxito." });

    } catch (err) {
        console.error("Error en POST /api/tripulantes:", err);
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// GET: Obtener todos los usuarios (sin el hash de la contraseña)
app.get('/api/usuarios', async (req, res) => {
    let connection;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `SELECT ID_USUARIO, NOMBRE_USUARIO, ID_ROL FROM USUARIOS ORDER BY NOMBRE_USUARIO`;
        const result = await connection.execute(sql, {}, { outFormat: oracledb.OUT_FORMAT_OBJECT });
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// POST: Crear un nuevo usuario con contraseña encriptada
app.post('/api/usuarios', async (req, res) => {
    let connection;
    const { nombre_usuario, password, id_rol } = req.body;
    if (!nombre_usuario || !password || !id_rol) {
        return res.status(400).json({ error: "Nombre, contraseña y rol son requeridos." });
    }

    try {
        // Encriptamos la contraseña antes de guardarla
        const salt = await bcrypt.genSalt(12);
        const password_hash = await bcrypt.hash(password, salt);

        connection = await oracledb.getConnection(dbConfig);
        const sql = `INSERT INTO USUARIOS (NOMBRE_USUARIO, PASSWORD_HASH, ID_ROL) VALUES (:nombre_usuario, :password_hash, :id_rol)`;
        await connection.execute(sql, { nombre_usuario, password_hash, id_rol }, { autoCommit: true });
        
        res.status(201).json({ message: "Usuario creado exitosamente." });
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// DELETE: Eliminar un usuario
app.delete('/api/usuarios/:id', async (req, res) => {
    let connection;
    const { id } = req.params;
    try {
        connection = await oracledb.getConnection(dbConfig);
        await connection.execute(`DELETE FROM USUARIOS WHERE ID_USUARIO = :id`, { id }, { autoCommit: true });
        res.status(200).json({ message: "Usuario eliminado." });
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});


// GET: Obtener todas las facturas con el nombre del cliente
app.get('/api/facturas', async (req, res) => {
    let connection;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `
            SELECT 
                f.ID_FACTURA, f.NUMERO_FACTURA, f.FECHA_EMISION, 
                f.MONTO_TOTAL, f.ESTADO_FACTURA,
                c.NOMBRE_CLIENTE
            FROM FACTURA f
            JOIN CLIENTE c ON f.ID_CLIENTE = c.ID_CLIENTE
            ORDER BY f.FECHA_EMISION DESC
        `;
        const result = await connection.execute(sql, {}, { outFormat: oracledb.OUT_FORMAT_OBJECT });
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// GET: Obtener todos los detalles de una factura específica
app.get('/api/facturas/:id/detalles', async (req, res) => {
    let connection;
    const { id } = req.params;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `SELECT ID_DETALLE_FACTURA, DESCRIPCION, PRECIO_UNITARIO, CANTIDAD, SUBTOTAL 
                     FROM DETALLE_FACTURA 
                     WHERE ID_FACTURA = :id`;
        const result = await connection.execute(sql, { id }, { outFormat: oracledb.OUT_FORMAT_OBJECT });
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// POST: Crear una nueva factura y su primer detalle (TRANSACCIONAL)
app.post('/api/facturas', async (req, res) => {
    let connection;
    // Recibimos los datos de la factura y del primer detalle
    const { id_escala, id_cliente, numero_factura, id_moneda, detalle } = req.body;

    if (!id_escala || !id_cliente || !numero_factura || !detalle) {
        return res.status(400).json({ error: "Faltan datos para crear la factura." });
    }

    try {
        connection = await oracledb.getConnection(dbConfig);
        await connection.beginTransaction(); // <-- Iniciamos la transacción

        // 1. Insertamos la factura principal con monto total 0 inicialmente
        const facturaSql = `INSERT INTO FACTURA (ID_ESCALA, ID_CLIENTE, NUMERO_FACTURA, ID_MONEDA, ESTADO_FACTURA, MONTO_TOTAL)
                            VALUES (:id_escala, :id_cliente, :numero_factura, :id_moneda, 'Borrador', 0)
                            RETURNING ID_FACTURA INTO :out_id`;
        
        const facturaResult = await connection.execute(facturaSql, 
            { id_escala, id_cliente, numero_factura, id_moneda, out_id: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT } }
        );
        const nuevaFacturaId = facturaResult.outBinds.out_id[0];

        // 2. Insertamos la línea de detalle
        const subtotal = detalle.precio_unitario * detalle.cantidad;
        const detalleSql = `INSERT INTO DETALLE_FACTURA (ID_FACTURA, DESCRIPCION, PRECIO_UNITARIO, CANTIDAD, SUBTOTAL)
                            VALUES (:id_factura, :descripcion, :precio_unitario, :cantidad, :subtotal)`;
        await connection.execute(detalleSql, {
            id_factura: nuevaFacturaId,
            descripcion: detalle.descripcion,
            precio_unitario: detalle.precio_unitario,
            cantidad: detalle.cantidad,
            subtotal: subtotal
        });

        // 3. Actualizamos el monto total de la factura
        const updateSql = `UPDATE FACTURA SET MONTO_TOTAL = :subtotal WHERE ID_FACTURA = :id_factura`;
        await connection.execute(updateSql, { subtotal, id_factura: nuevaFacturaId });

        await connection.commit(); // <-- Confirmamos todos los cambios
        res.status(201).json({ message: "Factura creada exitosamente.", facturaId: nuevaFacturaId });

    } catch (err) {
        if (connection) {
            await connection.rollback(); // <-- Si algo falla, revertimos todo
        }
        console.error("Error en POST /api/facturas:", err);
        res.status(500).json({ error: "Error al crear la factura: " + err.message });
    } finally {
        await closeConnection(connection);
    }
});

// PATCH: Actualizar solo el estado de una factura
app.patch('/api/facturas/:id/status', async (req, res) => {
    let connection;
    const { id } = req.params;
    const { nuevoStatus } = req.body; // Recibimos el nuevo estado desde el body

    if (!nuevoStatus) {
        return res.status(400).json({ error: "El nuevo estado es requerido." });
    }

    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `UPDATE FACTURA SET ESTADO_FACTURA = :nuevoStatus WHERE ID_FACTURA = :id`;
        const result = await connection.execute(sql, { nuevoStatus, id }, { autoCommit: true });

        if (result.rowsAffected === 0) {
            return res.status(404).json({ message: "Factura no encontrada." });
        }
        res.status(200).json({ message: `Estado de la factura actualizado a ${nuevoStatus}.` });
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// GET: Obtener todos los roles
app.get('/api/roles', async (req, res) => {
    let connection;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `SELECT ID_ROL, NOMBRE_ROL FROM ROLES ORDER BY NOMBRE_ROL`;
        const result = await connection.execute(sql, {}, { outFormat: oracledb.OUT_FORMAT_OBJECT });
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// --- Endpoint para el DASHBOARD ---

// GET: Obtener datos de resumen para el dashboard principal
app.get('/api/dashboard/summary', async (req, res) => {
    let connection;
    try {
        connection = await oracledb.getConnection(dbConfig);
        
        // Ejecutamos varias consultas de conteo en paralelo
        const [barcosResult, tripulantesResult, facturasResult] = await Promise.all([
            connection.execute(`SELECT COUNT(*) AS TOTAL FROM BARCO`, {}, { outFormat: oracledb.OUT_FORMAT_OBJECT }),
            connection.execute(`SELECT COUNT(*) AS TOTAL FROM TRIPULACION`, {}, { outFormat: oracledb.OUT_FORMAT_OBJECT }),
            connection.execute(`SELECT COUNT(*) AS TOTAL FROM FACTURA WHERE ESTADO_FACTURA = 'Pendiente'`, {}, { outFormat: oracledb.OUT_FORMAT_OBJECT })
        ]);

        // Construimos el objeto de respuesta
        const summary = {
            totalBarcos: barcosResult.rows[0].TOTAL,
            totalTripulantes: tripulantesResult.rows[0].TOTAL,
            facturasPendientes: facturasResult.rows[0].TOTAL
        };

        res.json(summary);

    } catch (err) {
        console.error("Error en /api/dashboard/summary:", err);
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});


// --- Endpoint para ANALÍTICAS ---
app.get('/api/analytics/facturas', async (req, res) => {
    let connection;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `
            SELECT ESTADO_FACTURA, COUNT(*) AS TOTAL
            FROM FACTURA
            GROUP BY ESTADO_FACTURA
        `;
        const result = await connection.execute(sql, {}, { outFormat: oracledb.OUT_FORMAT_OBJECT });
        res.json(result.rows);
    } catch (err) {
        console.error("Error en /api/analytics/facturas:", err);
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});


// POST: Crear un nuevo registro de documento
app.post('/api/documentos', async (req, res) => {
    let connection;
    // Ahora recibimos id_pago
    const { id_escala, id_tipo_documento, nombre_archivo, id_pago } = req.body;

    // El id_pago es ahora el campo importante, aunque podríamos requerir ambos
    if (!id_tipo_documento || !nombre_archivo || !id_pago) {
        return res.status(400).json({ error: "Tipo, nombre de archivo y ID del pago son requeridos." });
    }

    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `INSERT INTO DOCUMENTO (ID_ESCALA, ID_TIPO_DOCUMENTO, NOMBRE_ARCHIVO, RUTA_ARCHIVO, FECHA_SUBIDA, ID_PAGO) 
                     VALUES (:id_escala, :id_tipo_documento, :nombre_archivo, :ruta_archivo, SYSDATE, :id_pago)`;
        
        const binds = { 
            id_escala, // Puede ser nulo si el documento solo se relaciona al pago
            id_tipo_documento, 
            nombre_archivo, 
            ruta_archivo: `/docs/pagos/${nombre_archivo}`,
            id_pago 
        };
        
        await connection.execute(sql, binds, { autoCommit: true });
        res.status(201).json({ message: "Documento registrado exitosamente." });

    } catch (err) {
        console.error("Error en POST /api/documentos:", err);
        if (err.errorNum === 2291) {
             return res.status(400).json({ error: "El ID del pago, escala o tipo de documento no existe." });
        }
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});


// --- Endpoints para CLIENTES ---

// GET: Obtener todos los clientes
app.get('/api/clientes', async (req, res) => {
    let connection;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const result = await connection.execute(`SELECT * FROM CLIENTE ORDER BY NOMBRE_CLIENTE`, {}, { outFormat: oracledb.OUT_FORMAT_OBJECT });
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// POST: Crear un nuevo cliente
app.post('/api/clientes', async (req, res) => {
    let connection;
    const { nombre_cliente, ruc_cliente, direccion, contacto_principal } = req.body;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `INSERT INTO CLIENTE (NOMBRE_CLIENTE, RUC_CLIENTE, DIRECCION, CONTACTO_PRINCIPAL) VALUES (:nombre_cliente, :ruc_cliente, :direccion, :contacto_principal)`;
        await connection.execute(sql, { nombre_cliente, ruc_cliente, direccion, contacto_principal }, { autoCommit: true });
        res.status(201).json({ message: "Cliente creado exitosamente." });
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// PUT: Actualizar un cliente existente
app.put('/api/clientes/:id', async (req, res) => {
    let connection;
    const { id } = req.params;
    const { nombre_cliente, ruc_cliente, direccion, contacto_principal } = req.body;
    try {
        connection = await oracledb.getConnection(dbConfig);
        const sql = `UPDATE CLIENTE SET NOMBRE_CLIENTE = :nombre_cliente, RUC_CLIENTE = :ruc_cliente, DIRECCION = :direccion, CONTACTO_PRINCIPAL = :contacto_principal WHERE ID_CLIENTE = :id`;
        const result = await connection.execute(sql, { nombre_cliente, ruc_cliente, direccion, contacto_principal, id }, { autoCommit: true });

        if (result.rowsAffected === 0) {
            return res.status(404).json({ message: "Cliente no encontrado." });
        }
        res.status(200).json({ message: "Cliente actualizado exitosamente." });
    } catch (err) {
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// DELETE: Eliminar un cliente
app.delete('/api/clientes/:id', async (req, res) => {
    let connection;
    const { id } = req.params;
    try {
        connection = await oracledb.getConnection(dbConfig);
        await connection.execute(`DELETE FROM CLIENTE WHERE ID_CLIENTE = :id`, { id }, { autoCommit: true });
        res.status(200).json({ message: "Cliente eliminado." });
    } catch (err) {
        if (err.errorNum === 2292) {
            return res.status(400).json({ error: "No se puede eliminar el cliente porque tiene barcos asociados." });
        }
        res.status(500).json({ error: err.message });
    } finally {
        await closeConnection(connection);
    }
});

// --- Endpoints para RECOMENDACIONES IA ---
app.get('/api/analytics/ia-recomendacion', async (req, res) => {
    const recomendaciones = [
        "Alta demanda de portacontenedores prevista para la próxima semana en el Puerto de Balboa.",
        "Posible congestión en el Puerto de Róterdam debido a condiciones climáticas. Considere rutas alternativas.",
        "Oportunidad de ahorro de combustible en la ruta del Pacífico por corrientes favorables."
    ];
    const recomendacion = recomendaciones[Math.floor(Math.random() * recomendaciones.length)];
    res.json({ recomendacion: recomendacion });
});

// Añade este endpoint en una nueva sección de EXPORTACIÓN
// --- Endpoints para EXPORTACIÓN ---
app.get('/api/export/facturas', async (req, res) => {
    let connection;
    try {
        connection = await oracledb.getConnection(dbConfig);
        // Usamos la misma consulta que para listar las facturas
        const sql = `
            SELECT 
                f.ID_FACTURA, f.NUMERO_FACTURA, c.NOMBRE_CLIENTE, 
                f.FECHA_EMISION, f.MONTO_TOTAL, f.ESTADO_FACTURA
            FROM FACTURA f
            JOIN CLIENTE c ON f.ID_CLIENTE = c.ID_CLIENTE
            ORDER BY f.FECHA_EMISION DESC
        `;
        const result = await connection.execute(sql, {}, { outFormat: oracledb.OUT_FORMAT_OBJECT });
        
        // Convertimos el resultado JSON a CSV
        const json2csvParser = new Parser();
        const csv = json2csvParser.parse(result.rows);

        // Preparamos la respuesta para que sea una descarga de archivo
        res.header('Content-Type', 'text/csv');
        res.attachment('reporte-facturas.csv');
        res.send(csv);

    } catch (err) {
        res.status(500).json({ error: "Error al exportar los datos: " + err.message });
    } finally {
        await closeConnection(connection);
    }
});



// Iniciar el Servidor
app.listen(port, () => {
    console.log(`🚀 Servidor del API Naviera corriendo en http://localhost:${port}`);
});