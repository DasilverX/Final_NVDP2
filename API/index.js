const express = require('express');
const oracledb = require('oracledb');
const cors = require('cors');
const { executeQuery, executeProcedure, getBarcoDetailsById } = require('./database');

const app = express();
const port = 3000;

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
app.post('/api/tripulantes', async (req, res) => {
    try {
        const { barcoId, nombre, rol, pasaporte, nacionalidad } = req.body;
        const plsql = `BEGIN ASIGNAR_TRIPULANTE_BARCO( p_barco_id => :barcoId, p_nombre => :nombre, p_rol => :rol, p_pasaporte => :pasaporte, p_nacionalidad => :nacionalidad); END;`;
        const binds = { barcoId, nombre, rol, pasaporte, nacionalidad };
        await executeProcedure(plsql, binds);
        res.status(201).send({ message: 'Tripulante añadido exitosamente' });
    } catch (err) {
        res.status(500).send({ message: 'Error al añadir el tripulante', error: err.message });
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

// Iniciar el servidor
app.listen(port, () => {
    console.log(`Servidor NVDPA escuchando en http://localhost:${port}`);
});