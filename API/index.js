require('dotenv').config();
const express = require('express');
const bcrypt = require('bcrypt');
const oracledb = require('oracledb');
const cors = require('cors');
const { executeQuery, executeProcedure, getBarcoDetailsById } = require('./database');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.get('/', (req, res) => {
  res.send('<h1>API de NVDPA</h1><p>¡El servidor está funcionando correctamente!</p>');
});


// --- ENDPOINTS DE ESCALAS ---
app.get('/api/escalas', async (req, res) => {
  try {
    // ***** CAMBIO CLAVE: USAMOS LA CONSULTA COMPLETA EN LUGAR DE LA VISTA *****
    const query = `
        SELECT
            ep.EscalaPortuariaID,
            b.BarcoID,
            ep.FechaHoraLlegada,
            ep.FechaHoraSalida,
            b.Nombre AS NombreBarco,
            b.NumeroIMO,
            c.Nombre AS NombreCliente,
            p.Nombre AS NombrePuerto,
            p.Pais AS PaisPuerto,
            ep.Muelle
        FROM
            EscalaPortuaria ep
        JOIN 
            Barco b ON ep.BarcoID = b.BarcoID
        JOIN 
            Cliente c ON b.PropietarioID = c.ClienteID
        JOIN 
            Puerto p ON ep.PuertoID = p.PuertoID
    `;

    const escalas = await executeQuery(query);
    res.json(escalas);
  } catch (err) {
    // Añadimos un console.log para ver el error en la terminal del API
    console.error("Error en /api/escalas:", err); 
    res.status(500).send({ message: 'Error al obtener las escalas' });
  }
});
// --- ENDPOINTS DE TRIPULANTES ---

// ***** NUEVO: Endpoint para OBTENER todos los tripulantes *****
app.get('/api/tripulantes', async (req, res) => {
    try {
        // Unimos con la tabla Barco para saber en qué barco están
        const query = `
            SELECT t.TripulacionID, t.Nombre, t.Rol, t.Nacionalidad, b.Nombre AS NombreBarco
            FROM Tripulacion t
            JOIN Barco b ON t.BarcoID = b.BarcoID
            ORDER BY t.TripulacionID DESC
        `;
        const tripulantes = await executeQuery(query);
        res.json(tripulantes);
    } catch (err) {
        res.status(500).send({ message: 'Error al obtener los tripulantes' });
    }
});

// Endpoint para AÑADIR un tripulante (el que ya tenías)
// Reemplazar el endpoint de login completo
app.post('/api/login', async (req, res) => {
    try {
        const { nombre, password } = req.body;

        // 1. Buscamos al usuario solo por su nombre
        const query = `
            SELECT u.UsuarioID, u.Nombre, u.Password, u.BarcoID, r.NombreRol
            FROM Usuarios u
            JOIN Roles r ON u.RolID = r.RolID
            WHERE u.Nombre = :nombre
        `;
        // Usamos executeQuery con un array para los binds
        const result = await executeQuery(query, [nombre]);

        if (result.length === 0) {
            // Si el usuario no existe, enviamos un error genérico para no dar pistas
            return res.status(401).send({ message: 'Nombre de usuario o contraseña incorrectos.' });
        }

        const user = result[0];
        
        // 2. Comparamos la contraseña enviada con el hash de la BD de forma asíncrona
        const passwordMatch = await bcrypt.compare(password, user.PASSWORD);

        if (passwordMatch) {
            // 3. Si la contraseña coincide, enviamos los datos del usuario (PERO NUNCA EL HASH)
            const userData = {
                usuarioId: user.USUARIOID,
                nombre: user.NOMBRE,
                rol: user.NOMBREROL,
                barcoId: user.BARCOID
            };
            res.status(200).json(userData);
        } else {
            // Si la contraseña no coincide, enviamos el mismo error genérico
            res.status(401).send({ message: 'Nombre de usuario o contraseña incorrectos.' });
        }
    } catch (err) {
        console.error("Error en /api/login:", err);
        res.status(500).send({ message: 'Error en el servidor durante el login.', error: err.message });
    }
});

// ***** NUEVO: Endpoint para ELIMINAR un tripulante por su ID *****
app.delete('/api/tripulantes/:id', async (req, res) => {
    try {
        // Obtenemos el ID de los parámetros de la URL (ej. /api/tripulantes/10)
        const tripulanteId = req.params.id;

        const plsql = `BEGIN ELIMINAR_TRIPULANTE(p_tripulacion_id => :id); END;`;
        const binds = { id: tripulanteId };

        await executeProcedure(plsql, binds);

        res.status(200).send({ message: `Tripulante con ID ${tripulanteId} eliminado correctamente` });
    } catch (err) {
        // Capturamos el error personalizado si el tripulante no existe
        res.status(404).send({ message: 'Error al eliminar el tripulante', error: err.message });
    }
});

// ***** NUEVO: Endpoint para ACTUALIZAR un tripulante por su ID *****
app.put('/api/tripulantes/:id', async (req, res) => {
    try {
        // Obtenemos el ID de los parámetros de la URL
        const tripulanteId = req.params.id;
        // Obtenemos los nuevos datos del cuerpo de la petición
        const { nombre, rol, nacionalidad } = req.body;

        const plsql = `BEGIN ACTUALIZAR_TRIPULANTE(p_tripulacion_id => :id, p_nombre => :nombre, p_rol => :rol, p_nacionalidad => :nacionalidad); END;`;
        const binds = {
            id: tripulanteId,
            nombre: nombre,
            rol: rol,
            nacionalidad: nacionalidad
        };

        await executeProcedure(plsql, binds);

        res.status(200).send({ message: `Tripulante con ID ${tripulanteId} actualizado correctamente` });
    } catch (err) {
        res.status(500).send({ message: 'Error al actualizar el tripulante', error: err.message });
    }
});

// --- ENDPOINT DE LOGIN ---
app.post('/api/login', async (req, res) => {
    try {
        const { nombre, password } = req.body;
        // ***** CONSULTA MODIFICADA para incluir BarcoID *****
        const query = `
            SELECT u.UsuarioID, u.Nombre, u.BarcoID, r.NombreRol
            FROM Usuarios u
            JOIN Roles r ON u.RolID = r.RolID
            WHERE u.Nombre = :nombre AND u.Password = :password
        `;
        const binds = { nombre, password };
        const result = await executeQuery(query, binds);

        if (result.length > 0) {
            const user = {
                usuarioId: result[0].USUARIOID,
                nombre: result[0].NOMBRE,
                rol: result[0].NOMBREROL,
                // ***** AÑADIMOS BarcoID a la respuesta si existe *****
                barcoId: result[0].BARCOID // Será null para admin y visitante
            };
            res.status(200).json(user);
        } else {
            res.status(401).send({ message: 'Nombre de usuario o contraseña incorrectos.' });
        }
    } catch (err) {
        res.status(500).send({ message: 'Error en el servidor durante el login.', error: err.message });
    }
});

// --- ENDPOINTS DE PETICIONES DE SERVICIO ---

// Endpoint para que un capitán vea todas las peticiones de sus escalas
app.get('/api/peticiones/barco/:barcoId', async (req, res) => {
    try {
        const { barcoId } = req.params;
        const query = `
            SELECT 
                p.PeticionID,
                p.Estado,
                p.FechaPeticion,
                p.Notas,
                s.Tipo AS ServicioTipo,
                ep.FechaHoraLlegada,
                pu.Nombre AS NombrePuerto
            FROM PeticionesServicio p
            JOIN Servicio s ON p.ServicioID = s.ServicioID
            JOIN EscalaPortuaria ep ON p.EscalaPortuariaID = ep.EscalaPortuariaID
            JOIN Puerto pu ON ep.PuertoID = pu.PuertoID
            WHERE ep.BarcoID = :barcoId
            ORDER BY p.FechaPeticion DESC
        `;
        const binds = { barcoId };
        const peticiones = await executeQuery(query, binds);
        res.json(peticiones);
    } catch (err) {
        console.error("Error en /api/peticiones/barco:", err);
        res.status(500).send({ message: 'Error al obtener las peticiones de servicio' });
    }
});

// Endpoint para que un capitán cree una nueva petición de servicio
app.post('/api/peticiones', async (req, res) => {
    try {
        const { escalaId, servicioId, usuarioId, notas } = req.body;
        const query = `
            INSERT INTO PeticionesServicio (EscalaPortuariaID, ServicioID, UsuarioID, Notas)
            VALUES (:escalaId, :servicioId, :usuarioId, :notas)
        `;
        const binds = { escalaId, servicioId, usuarioId, notas };
        
        // Usamos executeProcedure porque no necesitamos que devuelva filas, solo que se ejecute.
        await executeProcedure(query, binds);
        
        res.status(201).send({ message: 'Petición de servicio creada exitosamente' });
    } catch (err) {
        console.error("Error en POST /api/peticiones:", err);
        res.status(500).send({ message: 'Error al crear la petición de servicio', error: err.message });
    }
});

// ***** NUEVO: Endpoint para OBTENER todos los detalles de un barco específico *****
app.get('/api/barcos/:id', async (req, res) => {
    try {
        const barcoId = req.params.id;
        // Simplemente llamamos a nuestra nueva función
        const data = await getBarcoDetailsById(barcoId);
        res.json(data);
    } catch (err) {
        res.status(500).send({ message: 'Error al obtener los detalles del barco', error: err.message });
    }
});

// Función para validar la fortaleza de la contraseña
function validarPassword(password) {
    if (!password || password.length < 8) {
        return { isValid: false, message: 'La contraseña debe tener al menos 8 caracteres.' };
    }
    const tieneMayuscula = /[A-Z]/.test(password);
    const tieneNumero = /[0-9]/.test(password);

    if (!tieneMayuscula || !tieneNumero) {
        return { isValid: false, message: 'La contraseña debe contener al menos una mayúscula y un número.' };
    }
    return { isValid: true };
}


// ***** NUEVO: Endpoint para CREAR un nuevo usuario con contraseña segura *****
app.post('/api/usuarios', async (req, res) => {
    try {
        const { nombre, password, rolId, barcoId } = req.body;

        // 1. Validar la contraseña
        const validacion = validarPassword(password);
        if (!validacion.isValid) {
            return res.status(400).send({ message: validacion.message });
        }

        // 2. Encriptar la contraseña
        const saltRounds = 10;
        const passwordHash = await bcrypt.hash(password, saltRounds);

        // 3. Insertar el nuevo usuario en la base de datos
        const query = `
            INSERT INTO Usuarios (Nombre, Password, RolID, BarcoID)
            VALUES (:nombre, :passwordHash, :rolId, :barcoId)
        `;
        const binds = { nombre, passwordHash, rolId, barcoId: barcoId || null };

        await executeProcedure(query, binds);

        res.status(201).send({ message: 'Usuario creado exitosamente.' });

    } catch (err) {
        // Manejar error de usuario duplicado (ORA-00001) u otros
        if (err.errorNum === 1) {
            return res.status(409).send({ message: 'El nombre de usuario ya existe.' });
        }
        console.error("Error en POST /api/usuarios:", err);
        res.status(500).send({ message: 'Error al crear el usuario.', error: err.message });
    }
});

// --- ENDPOINTS PARA CRUD DE BARCOS ---

// GET para listar todos los barcos
app.get('/api/barcos', async (req, res) => {
    try {
        // 1. Obtenemos los parámetros de la URL (o usamos valores por defecto)
        const searchTerm = req.query.search || ''; // Término de búsqueda
        const page = parseInt(req.query.page, 10) || 1; // Página actual
        const limit = parseInt(req.query.limit, 10) || 10; // Resultados por página
        const offset = (page - 1) * limit; // Calculamos el desfase

        // Preparamos los binds para la consulta
        const binds = {};
        let whereClauses = [];

        // 2. Construimos la cláusula WHERE si hay un término de búsqueda
        if (searchTerm) {
            whereClauses.push(`
                (LOWER(b.Nombre) LIKE :searchTerm 
                OR LOWER(b.NumeroIMO) LIKE :searchTerm 
                OR LOWER(b.Tipo) LIKE :searchTerm
                OR LOWER(b.Bandera) LIKE :searchTerm)
            `);
            binds.searchTerm = `%${searchTerm.toLowerCase()}%`;
        }
        
        const whereSql = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';
        
        // 3. Primera consulta: Contar el total de registros que coinciden con la búsqueda
        const countQuery = `SELECT COUNT(*) AS total FROM Barco b ${whereSql}`;
        const countResult = await executeQuery(countQuery, binds);
        const totalItems = countResult[0].TOTAL;
        const totalPages = Math.ceil(totalItems / limit);

        // 4. Segunda consulta: Obtener los datos de la página actual
        const dataQuery = `
            SELECT b.BarcoID, b.Nombre, b.NumeroIMO, b.Tipo, b.Bandera, c.Nombre AS NombrePropietario, b.PropietarioID
            FROM Barco b
            JOIN Cliente c ON b.PropietarioID = c.ClienteID
            ${whereSql}
            ORDER BY b.Nombre
            OFFSET :offset ROWS FETCH NEXT :limit ROWS ONLY
        `;
        binds.offset = offset;
        binds.limit = limit;
        
        const barcos = await executeQuery(dataQuery, binds);

        // 5. Devolvemos una respuesta estructurada con los datos y la información de paginación
        res.json({
            totalItems,
            totalPages,
            currentPage: page,
            barcos
        });

    } catch (err) {
        console.error("Error en GET /api/barcos:", err);
        res.status(500).send({ message: 'Error al obtener los barcos' });
    }
});

// POST para crear un nuevo barco
app.post('/api/barcos', async (req, res) => {
    try {
        const { nombre, numeroImo, tipo, bandera, propietarioId } = req.body;
        const plsql = `BEGIN CREAR_BARCO(:nombre, :numeroImo, :tipo, :bandera, :propietarioId); END;`;
        const binds = { nombre, numeroImo, tipo, bandera, propietarioId };
        await executeProcedure(plsql, binds);
        res.status(201).send({ message: 'Barco creado exitosamente.' });
    } catch (err) {
        // El error personalizado de la BD (ej. IMO duplicado) viene en err.message
        res.status(500).send({ message: 'Error al crear el barco', error: err.message });
    }
});

// PUT para actualizar un barco
app.put('/api/barcos/:id', async (req, res) => {
    try {
        const barcoId = req.params.id;
        const { nombre, tipo, bandera, propietarioId } = req.body;
        const plsql = `BEGIN ACTUALIZAR_BARCO(:id, :nombre, :tipo, :bandera, :propietarioId); END;`;
        const binds = { id: barcoId, nombre, tipo, bandera, propietarioId };
        await executeProcedure(plsql, binds);
        res.status(200).send({ message: `Barco con ID ${barcoId} actualizado.` });
    } catch (err) {
        res.status(500).send({ message: 'Error al actualizar el barco', error: err.message });
    }
});

// DELETE para eliminar un barco
app.delete('/api/barcos/:id', async (req, res) => {
    try {
        const barcoId = req.params.id;
        const plsql = `BEGIN ELIMINAR_BARCO(:id); END;`;
        const binds = { id: barcoId };
        await executeProcedure(plsql, binds);
        res.status(200).send({ message: `Barco con ID ${barcoId} eliminado.` });
    } catch (err) {
        res.status(400).send({ message: 'Error al eliminar el barco', error: err.message });
    }
});

// --- ENDPOINT PARA CLIENTES ---
app.get('/api/clientes', async (req, res) => {
    try {
        const query = 'SELECT ClienteID, Nombre FROM Cliente ORDER BY Nombre';
        const clientes = await executeQuery(query);
        res.json(clientes);
    } catch (err) {
        res.status(500).send({ message: 'Error al obtener los clientes' });
    }
});

// --- ENDPOINT PARA MAPA ---
app.get('/api/puertos', async (req, res) => {
    try {
        // Obtenemos solo los puertos que tengan coordenadas definidas
        const query = 'SELECT PuertoID, Nombre, Latitud, Longitud FROM Puerto WHERE Latitud IS NOT NULL AND Longitud IS NOT NULL';
        const puertos = await executeQuery(query);
        res.json(puertos);
    } catch (err) {
        res.status(500).send({ message: 'Error al obtener los puertos' });
    }
});

// Endpoint específico para que un capitán registre su barco
app.post('/api/capitan/registrar-barco', async (req, res) => {
    try {
        const { nombre, numeroImo, tipo, bandera, propietarioId, capitanUsuarioId } = req.body;

        const plsql = `BEGIN REGISTRAR_BARCO_Y_ASIGNAR_CAPITAN(:nombre, :numeroImo, :tipo, :bandera, :propietarioId, :capitanUsuarioId, :nuevoBarcoId); END;`;
        
        const binds = {
            nombre, numeroImo, tipo, bandera, propietarioId, capitanUsuarioId,
            // Definimos el parámetro de salida
            nuevoBarcoId: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
        };
        
        const result = await executeProcedure(plsql, binds);

        // Devolvemos el ID del nuevo barco en la respuesta
        res.status(201).send({ 
            message: 'Barco registrado y asignado exitosamente.',
            nuevoBarcoId: result.outBinds.nuevoBarcoId[0] 
        });
    } catch (err) {
        res.status(500).send({ message: 'Error al registrar el barco', error: err.message });
    }
});

// Importar la librería de IA de Google (al principio del archivo con los otros 'require')
const { GoogleGenerativeAI } = require("@google/generative-ai");

// Inicializar el cliente de la IA con tu clave
//const genAI = new GoogleGenerativeAI(process.env.AIzaSyDWyclTKvAJ2tUrsZ8U4t6XyduFNj7iJuY);
const genAI = new GoogleGenerativeAI("AIzaSyDWyclTKvAJ2tUrsZ8U4t6XyduFNj7iJuY"); // <-- Pega tu clave aquí

// --- ENDPOINT PARA ANÁLISIS CON IA ---
app.post('/api/analisis-logistico', async (req, res) => {
    try {
        // 1. Obtenemos los datos de la simulación desde Flutter
        const { tipoBarco, tipoCarga, servicios } = req.body;

        // 2. Creamos el "Prompt": la pregunta detallada para la IA
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

        // 3. Llamamos al modelo de IA de Google
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash-latest" });
        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        // 4. Devolvemos la respuesta de la IA a la aplicación Flutter
        res.status(200).json({ analisis: text });

    } catch (err) {
        console.error("Error en /api/analisis-logistico:", err);
        res.status(500).send({ message: 'Error al generar el análisis de IA' });
    }
});

// Iniciar el servidor
app.listen(port, () => {
  console.log(`Servidor NVDPA escuchando en el puerto ${port}`);
});