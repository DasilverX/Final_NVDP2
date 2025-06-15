const express = require('express');
const bcrypt = require('bcrypt');
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

// Iniciar el servidor
app.listen(port, () => {
    console.log(`Servidor NVDPA escuchando en http://localhost:${port}`);
});