// =======================================================================================
// =======================================================================================
//                  SERVIDOR PRINCIPAL Y RUTAS DE LA API (index.js)
// =======================================================================================
// =======================================================================================
// Responsabilidad: Crear el servidor Express, configurar middleware y definir todos
//                  los endpoints de la API REST que serán consumidos por el frontend.
// =======================================================================================


// =======================================================================================
// SECCIÓN 1: DEPENDENCIAS Y CONFIGURACIÓN INICIAL DE EXPRESS
// ---------------------------------------------------------------------------------------
const express = require('express');
const cors = require('cors');
// Importamos las funciones de nuestro módulo de base de datos
const { executeQuery, executeProcedure, getBarcoDetailsById } = require('./database');

const app = express();
const port = 3000;

// MIDDLEWARE
// Habilita CORS para permitir peticiones desde otros dominios (nuestra app de Flutter)
app.use(cors());
// Permite al servidor entender y procesar cuerpos de petición en formato JSON
app.use(express.json());


// =======================================================================================
--  [ Espacio para futuras configuraciones de MIDDLEWARE ]
-- =======================================================================================


// =======================================================================================
// SECCIÓN 2: ENDPOINTS DE LA API
// ---------------------------------------------------------------------------------------
// Definición de todas las rutas de la API, agrupadas por entidad de negocio.
// =======================================================================================

// Endpoint raíz para verificar que el servidor está funcionando
app.get('/', (req, res) => {
  res.send('<h1>API de NVDPA</h1><p>¡El servidor está funcionando correctamente!</p>');
});


// --- ENDPOINTS DE ESCALAS ---
app.get('/api/escalas', async (req, res) => {
  try {
    const query = `
        SELECT ep.EscalaPortuariaID, b.BarcoID, ep.FechaHoraLlegada, ep.FechaHoraSalida, b.Nombre AS NombreBarco,
               b.NumeroIMO, c.Nombre AS NombreCliente, p.Nombre AS NombrePuerto, p.Pais AS PaisPuerto, ep.Muelle
        FROM EscalaPortuaria ep
        JOIN Barco b ON ep.BarcoID = b.BarcoID
        JOIN Cliente c ON b.PropietarioID = c.ClienteID
        JOIN Puerto p ON ep.PuertoID = p.PuertoID
    `;
    const escalas = await executeQuery(query);
    res.json(escalas);
  } catch (err) {
    console.error("Error en /api/escalas:", err); 
    res.status(500).send({ message: 'Error al obtener las escalas' });
  }
});


// --- ENDPOINTS DE TRIPULANTES (CRUD COMPLETO) ---
// OBTENER todos los tripulantes
app.get('/api/tripulantes', async (req, res) => {
    try {
        const query = `
            SELECT t.TripulacionID, t.Nombre, t.Rol, t.Nacionalidad, b.Nombre AS NombreBarco
            FROM Tripulacion t JOIN Barco b ON t.BarcoID = b.BarcoID
            ORDER BY t.TripulacionID DESC
        `;
        const tripulantes = await executeQuery(query);
        res.json(tripulantes);
    } catch (err) {
        res.status(500).send({ message: 'Error al obtener los tripulantes' });
    }
});

// AÑADIR un nuevo tripulante
app.post('/api/tripulantes', async (req, res) => {
    try {
        const { barcoId, nombre, rol, pasaporte, nacionalidad } = req.body;
        const plsql = `BEGIN ASIGNAR_TRIPULANTE_BARCO(:barcoId, :nombre, :rol, :pasaporte, :nacionalidad); END;`;
        await executeProcedure(plsql, { barcoId, nombre, rol, pasaporte, nacionalidad });
        res.status(201).send({ message: 'Tripulante añadido exitosamente' });
    } catch (err) {
        res.status(500).send({ message: 'Error al añadir el tripulante', error: err.message });
    }
});

// ACTUALIZAR un tripulante existente
app.put('/api/tripulantes/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { nombre, rol, nacionalidad } = req.body;
        const plsql = `BEGIN ACTUALIZAR_TRIPULANTE(:id, :nombre, :rol, :nacionalidad); END;`;
        await executeProcedure(plsql, { id, nombre, rol, nacionalidad });
        res.status(200).send({ message: `Tripulante con ID ${id} actualizado correctamente` });
    } catch (err) {
        res.status(500).send({ message: 'Error al actualizar el tripulante', error: err.message });
    }
});

// ELIMINAR un tripulante por su ID
app.delete('/api/tripulantes/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const plsql = `BEGIN ELIMINAR_TRIPULANTE(:id); END;`;
        await executeProcedure(plsql, { id });
        res.status(200).send({ message: `Tripulante con ID ${id} eliminado correctamente` });
    } catch (err) {
        res.status(404).send({ message: 'Error al eliminar el tripulante', error: err.message });
    }
});


// --- ENDPOINT DE AUTENTICACIÓN ---
app.post('/api/login', async (req, res) => {
    try {
        const { nombre, password } = req.body;
        const query = `
            SELECT u.UsuarioID, u.Nombre, u.BarcoID, r.NombreRol
            FROM Usuarios u JOIN Roles r ON u.RolID = r.RolID
            WHERE u.Nombre = :nombre AND u.Password = :password
        `;
        const result = await executeQuery(query, { nombre, password });

        if (result.length > 0) {
            const user = {
                usuarioId: result[0].USUARIOID,
                nombre: result[0].NOMBRE,
                rol: result[0].NOMBREROL,
                barcoId: result[0].BARCOID
            };
            res.status(200).json(user);
        } else {
            res.status(401).send({ message: 'Nombre de usuario o contraseña incorrectos.' });
        }
    } catch (err) {
        res.status(500).send({ message: 'Error en el servidor durante el login.', error: err.message });
    }
});


// --- ENDPOINTS DE PETICIONES DE SERVICIO (CAPITANES) ---
// OBTENER peticiones para un barco específico
app.get('/api/peticiones/barco/:barcoId', async (req, res) => {
    try {
        const { barcoId } = req.params;
        const query = `
            SELECT p.PeticionID, p.Estado, p.FechaPeticion, p.Notas, s.Tipo AS ServicioTipo, ep.FechaHoraLlegada, pu.Nombre AS NombrePuerto
            FROM PeticionesServicio p
            JOIN Servicio s ON p.ServicioID = s.ServicioID
            JOIN EscalaPortuaria ep ON p.EscalaPortuariaID = ep.EscalaPortuariaID
            JOIN Puerto pu ON ep.PuertoID = pu.PuertoID
            WHERE ep.BarcoID = :barcoId
            ORDER BY p.FechaPeticion DESC
        `;
        const peticiones = await executeQuery(query, { barcoId });
        res.json(peticiones);
    } catch (err) {
        console.error("Error en /api/peticiones/barco:", err);
        res.status(500).send({ message: 'Error al obtener las peticiones de servicio' });
    }
});

// CREAR una nueva petición de servicio
app.post('/api/peticiones', async (req, res) => {
    try {
        const { escalaId, servicioId, usuarioId, notas } = req.body;
        const query = `INSERT INTO PeticionesServicio (EscalaPortuariaID, ServicioID, UsuarioID, Notas) VALUES (:escalaId, :servicioId, :usuarioId, :notas)`;
        await executeProcedure(query, { escalaId, servicioId, usuarioId, notas });
        res.status(201).send({ message: 'Petición de servicio creada exitosamente' });
    } catch (err) {
        console.error("Error en POST /api/peticiones:", err);
        res.status(500).send({ message: 'Error al crear la petición de servicio', error: err.message });
    }
});


// --- ENDPOINTS DE BARCOS (AVANZADO) ---
// OBTENER los detalles completos de un barco
app.get('/api/barcos/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const data = await getBarcoDetailsById(id);
        res.json(data);
    } catch (err) {
        res.status(500).send({ message: 'Error al obtener los detalles del barco', error: err.message });
    }
});


// =======================================================================================
--  [ Espacio para futuros ENDPOINTS de la API ]
-- =======================================================================================


// =======================================================================================
// SECCIÓN 3: INICIALIZACIÓN DEL SERVIDOR
// ---------------------------------------------------------------------------------------
// Inicia el servidor Express para que comience a escuchar peticiones HTTP.
// =======================================================================================

app.listen(port, () => {
    console.log(`Servidor NVDPA escuchando en http://localhost:${port}`);
});