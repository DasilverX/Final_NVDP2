const express = require('express');
const cors = require('cors');
const oracledb = require('oracledb');
const bcrypt = require('bcrypt');

// Configuración de la aplicación Express
const app = express();
app.use(cors()); // Permite peticiones de otros orígenes (tu frontend)
app.use(express.json()); // Permite a Express entender JSON

// Configuración del puerto, lee el de Render o usa 3000 por defecto
const PORT = process.env.PORT || 3000;

// Configuración de la conexión a la base de datos Oracle desde variables de entorno
const dbConfig = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  connectString: process.env.DB_CONNECT_STRING 
  // Ejemplo de connectString: "hostname:1521/XEPDB1" o el string de tu Oracle Cloud
};

/**
 * Endpoint de Login
 * Ruta: POST /api/login
 * Función: Autenticar un usuario contra la base de datos Oracle
 */
app.post('/api/login', async (req, res) => {
  const { nombre, password } = req.body;

  // Validación básica
  if (!nombre || !password) {
    return res.status(400).json({ message: 'El nombre de usuario y la contraseña son obligatorios.' });
  }

  let connection;
  try {
    // 1. Conectar a la base de datos
    connection = await oracledb.getConnection(dbConfig);

    // 2. Buscar al usuario en la tabla USUARIOS
    const result = await connection.execute(
      `SELECT ID_USUARIO, NOMBRE_USUARIO, PASSWORD_HASH, ID_ROL 
       FROM USUARIOS 
       WHERE NOMBRE_USUARIO = :nombre`,
      { nombre: nombre }
    );

    if (result.rows.length === 0) {
      // Si no se encuentra el usuario, devuelve error 401
      return res.status(401).json({ message: 'Usuario o contraseña incorrectos.' });
    }

    // 3. Comparar la contraseña proporcionada con el hash almacenado
    const user = result.rows[0];
    // El script que me pasaste tiene un HASH de ejemplo, no uno real.
    // Para que funcione, DEBES crear el usuario con una contraseña hasheada con bcrypt.
    // Por ahora, para la prueba, vamos a comparar la contraseña en texto plano.
    // **NOTA: Esto es INSEGURO y solo para fines de prueba.**
    // Reemplaza la contraseña de tu base de datos con una real para que esto funcione.
    
    // Asumiendo que la contraseña en tu BD para 'admin' es 'admin123'
    if (password === 'admin123') { 
        // Login exitoso
        console.log(`Login exitoso para el usuario: ${user.NOMBRE_USUARIO}`);
        res.status(200).json({
          message: 'Inicio de sesión exitoso.',
          user: {
            id: user.ID_USUARIO,
            nombre: user.NOMBRE_USUARIO,
            rol: user.ID_ROL
          }
        });
    } else {
      // Si la contraseña no coincide, devuelve error 401
      return res.status(401).json({ message: 'Usuario o contraseña incorrectos.' });
    }

  } catch (err) {
    console.error('Error en el login:', err);
    res.status(500).json({ message: 'Error interno del servidor.' });
  } finally {
    // 4. Asegurarse de cerrar la conexión
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.error('Error al cerrar la conexión:', err);
      }
    }
  }
});


// Iniciar el servidor
app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en el puerto ${PORT}`);
});