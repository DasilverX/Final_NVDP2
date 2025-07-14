const oracledb = require('oracledb');

// Lista de configuraciones de conexión, en orden de prioridad
const dbConfigs = [
    { // Conexión Primaria (Producción)
        poolAlias: 'default', // Usaremos el pool por defecto
        user: process.env.DB_USER_PROD,
        password: process.env.DB_PASSWORD_PROD,
        connectString: process.env.DB_CONNECT_STRING_PROD
    },
    { // Conexión Secundaria (Contingencia)
        poolAlias: 'default',
        user: process.env.DB_USER_CONT,
        password: process.env.DB_PASSWORD_CONT,
        connectString: process.env.DB_CONNECT_STRING_CONT
    }
];

// Función que se ejecuta UNA SOLA VEZ al iniciar el servidor
async function initialize() {
    console.log('Iniciando conexión a la base de datos...');
    for (const config of dbConfigs) {
        try {
            // Intenta crear el pool de conexiones. Si tiene éxito, termina el bucle.
            await oracledb.createPool(config);
            console.log(`✅ Pool de conexiones creado exitosamente para: ${config.connectString}`);
            return; // Sal del bucle y la función si la conexión fue exitosa
        } catch (err) {
            console.error(`⚠️ Fallo al conectar con [${config.connectString}]. Intentando con la siguiente opción...`);
        }
    }

    // Si el bucle termina y no se pudo crear ningún pool, la aplicación no puede continuar.
    console.error('❌ FATAL: No se pudo establecer conexión con ninguna de las bases de datos disponibles.');
    process.exit(1); // Detiene la aplicación
}

// Función para ejecutar una consulta (SELECT)
async function executeQuery(query, binds = []) {
    let connection;
    try {
        // Pide prestada una conexión del pool ya creado
        connection = await oracledb.getConnection(); 
        const result = await connection.execute(query, binds, { outFormat: oracledb.OUT_FORMAT_OBJECT });
        return result.rows;
    } catch (err) {
        console.error('Error en executeQuery:', err);
        throw err; // Relanza el error para que la ruta de la API lo maneje
    } finally {
        if (connection) {
            try {
                // Devuelve la conexión al pool
                await connection.close(); 
            } catch (e) {
                console.error('Error al devolver la conexión al pool:', e);
            }
        }
    }
}

// Función para ejecutar un procedimiento (INSERT, UPDATE, DELETE)
async function executeProcedure(plsql, binds = {}) {
    let connection;
    try {
        connection = await oracledb.getConnection();
        const result = await connection.execute(plsql, binds, { autoCommit: true });
        return result;
    } catch (err) {
        console.error('Error en executeProcedure:', err);
        throw err;
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (e) {
                console.error('Error al devolver la conexión al pool:', e);
            }
        }
    }
}

// Exportamos la función de inicialización y las de ejecución
module.exports = { initialize, executeQuery, executeProcedure };