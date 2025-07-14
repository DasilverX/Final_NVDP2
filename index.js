// =======================================================================
// API de NVDPA v2.0 - Sincronizado con el Nuevo Esquema de Base de Datos
// =======================================================================

require('dotenv').config();
const express = require('express');
const bcrypt = require('bcrypt');
const oracledb = require('oracledb');
const cors = require('cors');
const { executeQuery, executeProcedure } = require('./database');

const app = express();
app.use(cors());
app.use(express.json());

// --- ENDPOINT RAÍZ ---
app.get('/', (req, res) => {
  res.send('<h1>API de NVDPA v2.0</h1><p>¡El servidor está funcionando correctamente!</p>');
});

// =======================================================================
// SECCIÓN DE AUTENTICACIÓN Y USUARIOS
// =======================================================================

// Endpoint de Login
app.post('/api/login', async (req, res) => {
    try {
        const { nombre, password } = req.body;
        const query = `
            SELECT u.id_usuario, u.nombre_usuario, u.password_hash, r.nombre_rol
            FROM usuarios u
            JOIN roles r ON u.id_rol = r.id_rol
            WHERE u.nombre_usuario = :nombre
        `;
        const result = await executeQuery(query, [nombre]);

        if (result.length === 0) {
            return res.status(401).send({ message: 'Nombre de usuario o contraseña incorrectos.' });
        }
        const user = result[0];
        const passwordMatch = await bcrypt.compare(password, user.PASSWORD_HASH);

        if (passwordMatch) {
            // Se debe obtener el barcoId del capitán por separado si es necesario
            const userData = {
                usuarioId: user.ID_USUARIO,
                nombre: user.NOMBRE_USUARIO,
                rol: user.NOMBRE_ROL,
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

// Endpoint para listar todos los usuarios
app.get('/api/usuarios', async (req, res) => {
    try {
        const query = `
            SELECT u.id_usuario, u.nombre_usuario, r.nombre_rol
            FROM usuarios u
            JOIN roles r ON u.id_rol = r.id_rol
            ORDER BY u.id_usuario
        `;
        const usuarios = await executeQuery(query);
        res.json(usuarios);
    } catch (err) {
        res.status(500).send({ message: 'Error al obtener los usuarios' });
    }
});

// Endpoint para crear un nuevo usuario
app.post('/api/usuarios', async (req, res) => {
    try {
        const { nombre, password, rolId } = req.body;
        const saltRounds = 10;
        const passwordHash = await bcrypt.hash(password, saltRounds);

        const query = `
            INSERT INTO usuarios (nombre_usuario, password_hash, id_rol)
            VALUES (:nombre, :passwordHash, :rolId)
        `;
        await executeProcedure(query, { nombre, passwordHash, rolId });
        res.status(201).send({ message: 'Usuario creado exitosamente.' });
    } catch (err) {
        if (err.errorNum === 1) {
            return res.status(409).send({ message: 'El nombre de usuario ya existe.' });
        }
        res.status(500).send({ message: 'Error al crear el usuario.', error: err.message });
    }
});


// =======================================================================
// SECCIÓN DE GESTIÓN DE FLOTA (CRUD DE BARCOS)
// =======================================================================

// Endpoint para listar, buscar y paginar barcos
app.get('/api/barcos', async (req, res) => {
    try {
        const searchTerm = req.query.search || '';
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 10;
        const offset = (page - 1) * limit;

        let whereClause = 'WHERE 1=1';
        const binds = {};

        if (searchTerm) {
            whereClause += ` AND (LOWER(b.nombre_barco) LIKE :searchTerm OR LOWER(b.numero_imo) LIKE :searchTerm)`;
            binds.searchTerm = `%${searchTerm.toLowerCase()}%`;
        }

        const countQuery = `SELECT COUNT(*) AS total FROM barco b ${whereClause}`;
        const countResult = await executeQuery(countQuery, binds);
        const totalItems = countResult[0].TOTAL;

        const dataQuery = `
            SELECT b.id_barco, b.nombre_barco, b.numero_imo, tb.tipo_barco, p.pais AS pais_bandera, c.nombre_cliente
            FROM barco b
            LEFT JOIN cliente c ON b.id_cliente = c.id_cliente
            LEFT JOIN tipo_barco tb ON b.id_tipo_barco = tb.id_tipo_barco
            LEFT JOIN pais p ON b.id_pais_bandera = p.id_pais
            ${whereClause}
            ORDER BY b.nombre_barco
            OFFSET :offset ROWS FETCH NEXT :limit ROWS ONLY
        `;
        binds.offset = offset;
        binds.limit = limit;
        
        const barcos = await executeQuery(dataQuery, binds);
        res.json({
            totalItems,
            totalPages: Math.ceil(totalItems / limit),
            currentPage: page,
            barcos
        });
    } catch (err) {
        console.error("Error en GET /api/barcos:", err);
        res.status(500).send({ message: 'Error al obtener los barcos', error: err.message });
    }
});

// Endpoint para obtener los detalles completos de un solo barco
app.get('/api/barcos/:id', async (req, res) => {
    // Este endpoint requiere que exista el procedimiento GET_BARCO_DETALLES en la BD
    // y que la función getBarcoDetailsById en database.js esté actualizada
    try {
        const barcoId = req.params.id;
        const data = await getBarcoDetailsById(barcoId); // Asume que esta función está actualizada
        res.json(data);
    } catch (err) {
        res.status(500).send({ message: 'Error al obtener los detalles del barco', error: err.message });
    }
});

// POST para crear un nuevo barco
app.post('/api/barcos', async (req, res) => {
    // Requiere un procedimiento CREAR_BARCO(p_nombre, p_imo, p_id_tipo, p_id_pais, p_id_cliente)
    try {
        const { nombre_barco, numero_imo, id_tipo_barco, id_pais_bandera, id_cliente } = req.body;
        const plsql = `BEGIN CREAR_BARCO(:nombre, :imo, :id_tipo, :id_pais, :id_cliente); END;`;
        const binds = { nombre: nombre_barco, imo: numero_imo, id_tipo: id_tipo_barco, id_pais: id_pais_bandera, id_cliente: id_cliente };
        await executeProcedure(plsql, binds);
        res.status(201).send({ message: 'Barco creado exitosamente.' });
    } catch (err) {
        res.status(500).send({ message: 'Error al crear el barco', error: err.message });
    }
});

// (Aquí irían los endpoints PUT y DELETE para barcos, que llamarían a sus respectivos procedimientos)


// =======================================================================
// SECCIÓN DE CATÁLOGOS (para menús desplegables)
// =======================================================================

app.get('/api/clientes', async (req, res) => {
    try {
        const query = 'SELECT id_cliente, nombre_cliente FROM cliente ORDER BY nombre_cliente';
        const clientes = await executeQuery(query);
        res.json(clientes);
    } catch (err) {
        res.status(500).send({ message: 'Error al obtener los clientes' });
    }
});

app.get('/api/roles', async (req, res) => {
    try {
        const query = 'SELECT id_rol, nombre_rol FROM roles ORDER BY id_rol';
        const roles = await executeQuery(query);
        res.json(roles);
    } catch (err) {
        res.status(500).send({ message: 'Error al obtener los roles' });
    }
});

// =======================================================================
// SECCIÓN DE ANÁLISIS CON IA
// =======================================================================
const { GoogleGenerativeAI } = require("@google/generative-ai");
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

app.post('/api/analisis-logistico', async (req, res) => {
    try {
        const { tipoBarco, tipoCarga, servicios } = req.body;
        const prompt = `Actúa como un experto en logística del Canal de Panamá... (etc.)`; // Prompt completo
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash-latest" });
        const result = await model.generateContent(prompt);
        const response = await result.response;
        res.status(200).json({ analisis: response.text() });
    } catch (err) {
        console.error("Error en /api/analisis-logistico:", err);
        res.status(500).send({ message: 'Error al generar el análisis de IA' });
    }
});

/*
 * ------------------------------------------------------------------
 * 👇 AQUÍ LA PARTE DE POST PARA EL USER
 * ------------------------------------------------------------------
 * Endpoint: POST /users
 * Función: Crear un nuevo usuario en la base de datos.
 */
app.post('/users', async (req, res) => {
  try {
    // 1. Obtenemos los datos del nuevo usuario desde el cuerpo (body) de la petición.
    // Asegúrate de que el cliente (frontend, Postman, etc.) envíe un JSON con estos campos.
    const { name, email, password } = req.body;

    // Validación simple (puedes añadir más validaciones)
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Faltan campos obligatorios (name, email, password).' });
    }

    // 2. Creamos la consulta SQL para insertar el nuevo usuario.
    // ¡IMPORTANTE! Usamos placeholders ($1, $2, $3) para evitar inyección SQL.
    const sqlQuery = `
      INSERT INTO users (name, email, password) 
      VALUES ($1, $2, $3) 
      RETURNING id, name, email, created_at;
    `;
    
    // Los valores que reemplazarán a $1, $2, $3
    const values = [name, email, password]; // Nota: En un proyecto real, la contraseña debería ser "hasheada" antes de guardarla.

    // 3. Ejecutamos la consulta en la base de datos usando el pool.
    const result = await pool.query(sqlQuery, values);

    // 4. Enviamos una respuesta exitosa (código 201: Created) con los datos del usuario creado.
    res.status(201).json({
      message: 'Usuario creado exitosamente.',
      user: result.rows[0]
    });

  } catch (error) {
    // Si algo sale mal (ej: el email ya existe, error de conexión), capturamos el error.
    console.error('Error al crear el usuario:', error);
    res.status(500).json({ error: 'Ocurrió un error en el servidor.' });
  }
});

// =======================================================================
// INICIAR SERVIDOR
// =======================================================================
const port = process.env.PORT || 3000;

app.listen(port, () => {
  console.log(`Servidor NVDPA v2.1 escuchando en el puerto ${port}`);
});