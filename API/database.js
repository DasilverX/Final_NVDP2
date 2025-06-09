// Importar el driver de Oracle
const oracledb = require('oracledb');

// Configuración de la conexión a tu base de datos Oracle XE local
const dbConfig = {
  user: 'fort', // Reemplaza si tu usuario es diferente (ej. 'FORT')
  password: 'develop', // La contraseña que definiste para tu usuario
  connectString: 'localhost/XEPDB1' // Este es el valor por defecto para Oracle XE.
                                    // Podría ser 'localhost/XE' si tienes una versión más antigua.
};

// Función reutilizable para ejecutar consultas
async function executeQuery(query, binds = []) {
  let connection;
  try {
    // Obtener una conexión de la base de datos
    connection = await oracledb.getConnection(dbConfig);
    
    // Ejecutar la consulta
    const result = await connection.execute(query, binds, { outFormat: oracledb.OUT_FORMAT_OBJECT });
    
    // Devolver las filas del resultado
    return result.rows;

  } catch (err) {
    console.error(err);
    throw err; // Re-lanzar el error para que el llamador lo maneje
  } finally {
    if (connection) {
      try {
        // Cerrar la conexión para devolverla al pool
        await connection.close();
      } catch (err) {
        console.error(err);
      }
    }
  }
}

// Exportar la función para que otros archivos puedan usarla
module.exports = { executeQuery };

// ... (código existente de executeQuery) ...

// NUEVA FUNCIÓN: Para ejecutar procedimientos o DML (INSERT, UPDATE, DELETE)
async function executeProcedure(plsql, binds = {}) {
  let connection;
  try {
    connection = await oracledb.getConnection(dbConfig);
    const result = await connection.execute(plsql, binds, { autoCommit: true }); // autoCommit guarda los cambios inmediatamente
    return result;
  } catch (err) {
    console.error(err);
    throw err;
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.error(err);
      }
    }
  }
}

// NUEVA FUNCIÓN: Específica para obtener los detalles del barco con sus cursores
async function getBarcoDetailsById(barcoId) {
  let connection;
  try {
    connection = await oracledb.getConnection(dbConfig);
    const plsql = `BEGIN GET_BARCO_DETALLES(p_barco_id => :id, c_detalles => :c_detalles, c_tripulacion => :c_tripulacion, c_historial_escalas => :c_historial_escalas); END;`;
    const binds = {
      id: barcoId,
      c_detalles: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT },
      c_tripulacion: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT },
      c_historial_escalas: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
    };

    const result = await connection.execute(plsql, binds, { outFormat: oracledb.OUT_FORMAT_OBJECT });

    const detallesCursor = result.outBinds.c_detalles;
    const tripulacionCursor = result.outBinds.c_tripulacion;
    const escalasCursor = result.outBinds.c_historial_escalas;

    const detalles = await detallesCursor.getRows();
    const tripulacion = await tripulacionCursor.getRows();
    const historial_escalas = await escalasCursor.getRows();

    // Importante: Cerramos los cursores aquí
    await detallesCursor.close();
    await tripulacionCursor.close();
    await escalasCursor.close();

    // Ensamblamos la respuesta
    return {
      detalles: detalles.length > 0 ? detalles[0] : null,
      tripulacion: tripulacion,
      historial_escalas: historial_escalas
    };

  } catch (err) {
    console.error(err);
    throw err;
  } finally {
    if (connection) {
      try {
        // Y cerramos la conexión solo al final de todo el proceso
        await connection.close();
      } catch (err) {
        console.error(err);
      }
    }
  }
}

// Actualiza la línea de module.exports al final del archivo
module.exports = { executeQuery, executeProcedure, getBarcoDetailsById };