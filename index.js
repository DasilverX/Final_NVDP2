require('dotenv').config();
const express = require('express');
const bcrypt = require('bcrypt');
const oracledb = require('oracledb');
const cors = require('cors');
// Asegúrate de que las funciones en database.js también usen los nombres de columna correctos.
const { executeQuery, executeProcedure, getBarcoDetailsById } = require('./database');

const app = express();


app.use(cors());
app.use(express.json());
app.get('/', (req, res) => {
  res.send('<h1>API de NVDPA</h1><p>¡El servidor está funcionando correctamente!</p>');
});


// --- ENDPOINTS DE ESCALAS ---
app.get('/api/escalas', async (req, res) => {
  try {
    // ***** CONSULTA CORREGIDA CON NOMBRES DE TABLAS/COLUMNAS REALES Y ALIAS *****
    const query = `
        SELECT
            ep.id AS escala_id,
            b.id AS barco_id,
            ep.fecha_llegada,
            ep.fecha_salida,
            b.nombre AS nombre_barco,
            b.numero_imo,
            c.nombre AS nombre_cliente,
            p.nombre AS nombre_puerto,
            pa.nombre AS pais_puerto,
            ep.muelle
        FROM
            escala_portuaria ep
        JOIN 
            barco b ON ep.id_barco = b.id
        JOIN 
            cliente c ON b.id_cliente = c.id
        JOIN 
            puerto p ON ep.id_puerto = p.id
        JOIN
            pais pa ON p.id_pais = pa.id
    `;

    const escalas = await executeQuery(query);
    res.json(escalas);
  } catch (err) {
    console.error("Error en /api/escalas:", err); 
    res.status(500).send({ message: 'Error al obtener las escalas' });
  }
});
// --- ENDPOINTS DE TRIPULANTES ---

app.get('/api/tripulantes', async (req, res) => {
    try {
        // ***** CONSULTA CORREGIDA *****
        const query = `
            SELECT t.id AS tripulante_id, t.nombre, t.rol, p.nombre AS nacionalidad, b.nombre AS nombre_barco
            FROM tripulacion t
            JOIN barco b ON t.id_barco = b.id
            JOIN pais p ON t.id_pais_nacionalidad = p.id
            ORDER BY t.id DESC
        `;
        const tripulantes = await executeQuery(query);
        res.json(tripulantes);
    } catch (err) {
        res.status(500).send({ message: 'Error al obtener los tripulantes' });
    }
});

// --- ENDPOINT DE LOGIN (ÚNICO Y CORREGIDO) ---
app.post('/api/login', async (req, res) => {
    try {
        const { nombre, password } = req.body;

        // 1. Buscamos al usuario por su nombre con los nombres de columna correctos
        const query = `
            SELECT u.id, u.nombre, u.password_hash, u.id_barco, r.nombre_rol
            FROM usuario u
            JOIN rol r ON u.id_rol = r.id
            WHERE u.nombre = :nombre
        `;
        const result = await executeQuery(query, [nombre]);

        if (result.length === 0) {
            return res.status(401).send({ message: 'Nombre de usuario o contraseña incorrectos.' });
        }

        const user = result[0];
        
        // 2. Comparamos la contraseña con el hash de la BD (el nombre de columna es PASSWORD_HASH)
        const passwordMatch = await bcrypt.compare(password, user.PASSWORD_HASH);

        if (passwordMatch) {
            // 3. Si la contraseña coincide, enviamos los datos del usuario
            const userData = {
                usuarioId: user.ID,
                nombre: user.NOMBRE,
                rol: user.NOMBRE_ROL,
                barcoId: user.ID_BARCO
            };
            res.status(200).json(userData);
        } else {
            res.status(401).send({ message: 'Nombre de usuario o contraseña incorrectos.' });
        }
    } catch (err) {
        console.error("Error en /api/login:", err);
        res.status(500).send({ message: 'Error en el servidor durante el login.', error: err.message });
    }
});

// --- ENDPOINTS DE PETICIONES DE SERVICIO ---

app.get('/api/peticiones/barco/:barcoId', async (req, res) => {
    try {
        const { barcoId } = req.params;
        // ***** CONSULTA CORREGIDA *****
        const query = `
            SELECT 
                p.id AS peticion_id,
                p.estado,
                p.fecha_peticion,
                p.notas,
                s.nombre AS servicio_nombre,
                ep.fecha_llegada,
                pu.nombre AS nombre_puerto
            FROM peticion_servicio p
            JOIN servicio s ON p.id_servicio = s.id
            JOIN escala_portuaria ep ON p.id_escala_portuaria = ep.id
            JOIN puerto pu ON ep.id_puerto = pu.id
            WHERE ep.id_barco = :barcoId
            ORDER BY p.fecha_peticion DESC
        `;
        const binds = { barcoId };
        const peticiones = await executeQuery(query, binds);
        res.json(peticiones);
    } catch (err) {
        console.error("Error en /api/peticiones/barco:", err);
        res.status(500).send({ message: 'Error al obtener las peticiones de servicio' });
    }
});

app.post('/api/peticiones', async (req, res) => {
    try {
        const { escalaId, servicioId, usuarioId, notas } = req.body;
        // ***** CONSULTA CORREGIDA *****
        const query = `
            INSERT INTO peticion_servicio (id_escala_portuaria, id_servicio, id_usuario, notas)
            VALUES (:escalaId, :servicioId, :usuarioId, :notas)
        `;
        const binds = { escalaId, servicioId, usuarioId, notas };
        
        await executeQuery(query, binds, { autoCommit: true }); // Usamos executeQuery para simplicidad
        
        res.status(201).send({ message: 'Petición de servicio creada exitosamente' });
    } catch (err) {
        console.error("Error en POST /api/peticiones:", err);
        res.status(500).send({ message: 'Error al crear la petición de servicio', error: err.message });
    }
});

// --- ENDPOINTS PARA USUARIOS Y ROLES ---

app.get('/api/usuarios', async (req, res) => {
    try {
        // ***** CONSULTA CORREGIDA *****
        const query = `
            SELECT u.id, u.nombre, r.nombre_rol
            FROM usuario u
            JOIN rol r ON u.id_rol = r.id
            ORDER BY u.id
        `;
        const usuarios = await executeQuery(query);
        res.json(usuarios);
    } catch (err) {
        res.status(500).send({ message: 'Error al obtener los usuarios' });
    }
});

app.get('/api/roles', async (req, res) => {
    try {
        // ***** CONSULTA CORREGIDA *****
        const query = 'SELECT id, nombre_rol FROM rol ORDER BY id';
        const roles = await executeQuery(query);
        res.json(roles);
    } catch (err) {
        res.status(500).send({ message: 'Error al obtener los roles' });
    }
});

// --- ENDPOINTS PARA CRUD DE BARCOS ---

app.get('/api/barcos', async (req, res) => {
    try {
        const searchTerm = req.query.search || '';
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 10;
        const offset = (page - 1) * limit;

        const binds = {};
        let whereClause = '';

        if (searchTerm) {
            // ***** BÚSQUEDA CORREGIDA (solo por nombre y IMO) *****
            whereClause = `WHERE LOWER(b.nombre) LIKE :searchTerm OR LOWER(b.numero_imo) LIKE :searchTerm`;
            binds.searchTerm = `%${searchTerm.toLowerCase()}%`;
        }
        
        const countQuery = `SELECT COUNT(*) AS total FROM barco b ${whereClause}`;
        const countResult = await executeQuery(countQuery, binds);
        const totalItems = countResult[0].TOTAL;
        const totalPages = Math.ceil(totalItems / limit);

        // ***** CONSULTA CORREGIDA *****
        const dataQuery = `
            SELECT b.id, b.nombre, b.numero_imo, tb.nombre AS tipo_barco, p.nombre AS pais_bandera, c.nombre AS nombre_propietario, b.id_cliente
            FROM barco b
            JOIN cliente c ON b.id_cliente = c.id
            JOIN tipo_barco tb ON b.id_tipo_barco = tb.id
            JOIN pais p ON b.id_pais_bandera = p.id
            ${whereClause}
            ORDER BY b.nombre
            OFFSET :offset ROWS FETCH NEXT :limit ROWS ONLY
        `;
        binds.offset = offset;
        binds.limit = limit;
        
        const barcos = await executeQuery(dataQuery, binds);

        res.json({ totalItems, totalPages, currentPage: page, barcos });

    } catch (err) {
        console.error("Error en GET /api/barcos:", err);
        res.status(500).send({ message: 'Error al obtener los barcos' });
    }
});

// --- ENDPOINT PARA CLIENTES ---
app.get('/api/clientes', async (req, res) => {
    try {
        // ***** CONSULTA CORREGIDA *****
        const query = 'SELECT id, nombre FROM cliente ORDER BY nombre';
        const clientes = await executeQuery(query);
        res.json(clientes);
    } catch (err) {
        res.status(500).send({ message: 'Error al obtener los clientes' });
    }
});

// --- ENDPOINT PARA MAPA ---
app.get('/api/puertos', async (req, res) => {
    try {
        // ***** CONSULTA CORREGIDA *****
        const query = 'SELECT id, nombre, latitud, longitud FROM puerto WHERE latitud IS NOT NULL AND longitud IS NOT NULL';
        const puertos = await executeQuery(query);
        res.json(puertos);
    } catch (err) {
        res.status(500).send({ message: 'Error al obtener los puertos' });
    }
});

// --- ENDPOINTS QUE USAN PROCEDIMIENTOS ---
// NOTA: Revisa que los procedimientos almacenados en la BD usen también los nombres de columna correctos.
app.delete('/api/tripulantes/:id', async (req, res) => {
    try {
        const tripulanteId = req.params.id;
        const plsql = `BEGIN ELIMINAR_TRIPULANTE(p_tripulacion_id => :id); END;`;
        await executeProcedure(plsql, { id: tripulanteId });
        res.status(200).send({ message: `Tripulante con ID ${tripulanteId} eliminado` });
    } catch (err) {
        res.status(404).send({ message: 'Error al eliminar el tripulante', error: err.message });
    }
});

app.put('/api/tripulantes/:id', async (req, res) => {
    try {
        const tripulanteId = req.params.id;
        const { nombre, rol, nacionalidad } = req.body;
        const plsql = `BEGIN ACTUALIZAR_TRIPULANTE(p_tripulacion_id => :id, p_nombre => :nombre, p_rol => :rol, p_nacionalidad => :nacionalidad); END;`;
        await executeProcedure(plsql, { id: tripulanteId, nombre, rol, nacionalidad });
        res.status(200).send({ message: `Tripulante con ID ${tripulanteId} actualizado` });
    } catch (err) {
        res.status(500).send({ message: 'Error al actualizar el tripulante', error: err.message });
    }
});

// ... (El resto de endpoints que llaman a procedimientos también deben ser revisados) ...


// --- ENDPOINT PARA ANÁLISIS CON IA ---
const { GoogleGenerativeAI } = require("@google/generative-ai");
const genAI = new GoogleGenerativeAI(process.env.GEMINIS_API);

app.post('/api/analisis-logistico', async (req, res) => {
    try {
        const { tipoBarco, tipoCarga, servicios } = req.body;
        const prompt = `
            Actúa como un experto en logística del Canal de Panamá. 
            Basado en los siguientes datos, proporciona un análisis breve y estimado del tiempo en el canal.
            Datos del Barco:
            - Tipo de Barco: ${tipoBarco}
            - Tipo de Carga: ${tipoCarga}
            - Servicios Requeridos en el puerto: ${servicios}
            Análisis Requerido:
            1. Un tiempo estimado (en horas) que podría tomar el tránsito y la recepción de los servicios.
            2. Una breve descripción de 2 o 3 posibles desafíos o cuellos de botella para este tipo de operación.
            3. Una recomendación logística clave.
            Formatea tu respuesta de forma clara y profesional usando texto simple.
        `;
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash-latest" });
        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();
        res.status(200).json({ analisis: text });
    } catch (err) {
        console.error("Error en /api/analisis-logistico:", err);
        res.status(500).send({ message: 'Error al generar el análisis de IA' });
    }
});


const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Servidor NVDPA escuchando en el puerto ${port}`);
});
