const express = require('express');
const cors = require('cors');
const oracledb = require('oracledb');
const database = require('./database.js'); // Importamos nuestro módulo de base de datos

// Configuración de la aplicación Express
const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;

/**
 * Endpoint de Login
 * Ruta: POST /api/login
 */
app.post('/api/login', async (req, res) => {
  const { nombre, password } = req.body;

  if (!nombre || !password) {
    return res.status(400).json({ message: 'El nombre de usuario y la contraseña son obligatorios.' });
  }

  let connection;
  try {
    // Obtenemos una conexión del pool que ya fue inicializado
    connection = await oracledb.getConnection();

    const result = await connection.execute(
      `SELECT ID_USUARIO, NOMBRE_USUARIO, PASSWORD_HASH, ID_ROL 
       FROM USUARIOS 
       WHERE NOMBRE_USUARIO = :nombre`,
      { nombre: nombre }
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ message: 'Usuario o contraseña incorrectos.' });
    }
    
    const user = result.rows[0];

    // **NOTA DE SEGURIDAD IMPORTANTE**
    // Tu script SQL usa contraseñas en texto plano ('admin123'). Esto es muy inseguro.
    // En un futuro, deberías usar 'bcrypt' para comparar contraseñas hasheadas.
    // Por ahora, para que coincida con tu script, comparamos texto plano.
    if (password === 'admin123' && user.NOMBRE_USUARIO === 'admin') { 
        res.status(200).json({
          message: 'Inicio de sesión exitoso.',
          user: { id: user.ID_USUARIO, nombre: user.NOMBRE_USUARIO, rol: user.ID_ROL }
        });
    } else {
      res.status(401).json({ message: 'Usuario o contraseña incorrectos.' });
    }

  } catch (err) {
    console.error('Error en el login:', err);
    res.status(500).json({ message: 'Error interno del servidor.' });
  } finally {
    if (connection) {
      try {
        await connection.close(); // Liberar la conexión de vuelta al pool
      } catch (err) {
        console.error('Error al cerrar la conexión:', err);
      }
    }
  }
});

async function startup() {
  console.log('Iniciando servidor...');
  try {
    // 1. PRIMERO: Intenta conectar a la base de datos
    await database.initialize();

    // 2. SEGUNDO: Si la conexión es exitosa, inicia el servidor web
    app.listen(PORT, () => {
      console.log(`🚀 Servidor listo y escuchando en el puerto ${PORT}`);
    });
  } catch (err) {
    // Si la inicialización de la BD falla, el error ya se registró y el proceso se detuvo.
    console.error('Error crítico durante el arranque:', err);
    process.exit(1);
  }
}

// Llama a la función para arrancar todo
startup();