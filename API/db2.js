// =======================================================================================
// =======================================================================================
//                      MÓDULO DE ACCESO A DATOS (database.js)
// =======================================================================================
// =======================================================================================
// Responsabilidad: Centralizar toda la comunicación con la base de datos Oracle.
//                  Exporta funciones reutilizables para ejecutar consultas y procedimientos.
// =======================================================================================


// =======================================================================================
// SECCIÓN 1: DEPENDENCIAS Y CONFIGURACIÓN DE CONEXIÓN
// ---------------------------------------------------------------------------------------
// Importación del driver y definición de los parámetros de conexión.
// =======================================================================================

const oracledb = require('oracledb');

// NOTA: En un entorno de producción, estos datos sensibles deberían gestionarse
// a través de variables de entorno (process.env) en lugar de estar hardcodeados.
const dbConfig = {
  user: 'fort',
  password: 'develop',
  connectString: 'localhost/XEPDB1'
};


// =======================================================================================
--  [ Espacio para futuras actualizaciones de CONFIGURACIÓN ]
-- =======================================================================================


// =======================================================================================
// SECCIÓN 2: FUNCIONES REUTILIZABLES DE ACCESO A DATOS
// ---------------------------------------------------------------------------------------
// Funciones genéricas para interactuar con la base de datos.
// =======================================================================================

/**
 * Función genérica para ejecutar consultas SELECT.
 * @param {string} query - La sentencia SQL a ejecutar.
 * @param {Array | Object} binds - Los parámetros para la consulta.
 * @returns {Promise<Array>} - Una promesa que resuelve a un array de objetos.
 */
async function executeQuery(query, binds = []) {
  let connection;
  try {
    connection = await oracledb.getConnection(dbConfig);
    const result = await connection.execute(query, binds, { outFormat: oracledb.OUT_FORMAT_OBJECT });
    return result.rows;
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

/**
 * Función genérica para ejecutar DML (INSERT, UPDATE, DELETE) o procedimientos almacenados.
 * @param {string} plsql - La sentencia PL/SQL o DML a ejecutar.
 * @param {Object} binds - Los parámetros para la ejecución.
 * @returns {Promise<Object>} - El resultado de la ejecución.
 */
async function executeProcedure(plsql, binds = {}) {
  let connection;
  try {
    connection = await oracledb.getConnection(dbConfig);
    // autoCommit=true asegura que los cambios se guarden en la BD inmediatamente.
    const result = await connection.execute(plsql, binds, { autoCommit: true });
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


// =======================================================================================
// SECCIÓN 3: FUNCIONES ESPECIALIZADAS
// ---------------------------------------------------------------------------------------
// Funciones específicas para lógica de negocio compleja, como el manejo de cursores.
// =======================================================================================

/**
 * Obtiene los detalles completos de un barco, incluyendo tripulación e historial,
 * llamando a un procedimiento almacenado que devuelve múltiples cursores (SYS_REFCURSOR).
 * @param {number} barcoId - El ID del barco a consultar.
 * @returns {Promise<Object>} - Un objeto con los detalles, tripulación e historial.
 */
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

    // Extraer los cursores de la respuesta
    const detallesCursor = result.outBinds.c_detalles;
    const tripulacionCursor = result.outBinds.c_tripulacion;
    const escalasCursor = result.outBinds.c_historial_escalas;

    // Leer los datos de cada cursor
    const detalles = await detallesCursor.getRows();
    const tripulacion = await tripulacionCursor.getRows();
    const historial_escalas = await escalasCursor.getRows();

    // Importante: Cerrar los cursores para liberar recursos en la base de datos
    await detallesCursor.close();
    await tripulacionCursor.close();
    await escalasCursor.close();

    // Ensamblar y devolver la respuesta final en un único objeto
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
        await connection.close();
      } catch (err) {
        console.error(err);
      }
    }
  }
}


// =======================================================================================
--  [ Espacio para futuras FUNCIONES de base de datos ]
-- =======================================================================================


// =======================================================================================
// SECCIÓN 4: EXPORTACIÓN DEL MÓDULO
// ---------------------------------------------------------------------------------------
// Hacemos las funciones accesibles para otros archivos (como index.js).
// =======================================================================================

module.exports = {
  executeQuery,
  executeProcedure,
  getBarcoDetailsById
};