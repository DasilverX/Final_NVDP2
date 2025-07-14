const oracledb = require('oracledb');

// Lista de configuraciones de conexión, en orden de prioridad
const dbConfigs = [
    { // Conexión Primaria (Producción)
        poolAlias: 'prod',
        user: process.env.DB_USER_PROD,
        password: process.env.DB_PASSWORD_PROD,
        connectString: process.env.DB_CONNECT_STRING_PROD
    },
    { // Conexión Secundaria (Contingencia)
        poolAlias: 'cont',
        user: process.env.DB_USER_CONT,
        password: process.env.DB_PASSWORD_CONT,
        connectString: process.env.DB_CONNECT_STRING_CONT
    }
];


// Nueva función "inteligente" para obtener una conexión
async function getConnection() {
    for (const config of dbConfigs) {
        try {
            // Intenta obtener una conexión del pool. Si no existe, lo crea.
            // Si la conexión falla, saltará al bloque CATCH.
            const connection = await oracledb.getConnection(config.poolAlias);
            console.log(`>>> Conexión exitosa con la base de datos: ${config.poolAlias}`);
            return connection;
        } catch (err) {
            // Si la conexión falla, lo registra y prueba con la siguiente de la lista.
            console.error(`!!! Fallo al conectar con la DB [${config.poolAlias}]. Intentando con la siguiente...`);
            // Intenta crear el pool si no existe, para la primera conexión.
            try {
                await oracledb.createPool(config);
                const connection = await oracledb.getConnection(config.poolAlias);
                console.log(`>>> Pool creado y conexión exitosa con la base de datos: ${config.poolAlias}`);
                return connection;
            } catch (poolErr) {
                 console.error(`!!! Fallo al crear pool para [${config.poolAlias}]: ${poolErr.message}`);
            }
        }
    }
    // Si ninguna conexión de la lista funciona, lanza un error final.
    throw new Error('No se pudo establecer conexión con ninguna de las bases de datos disponibles.');
}

// Adaptamos nuestras funciones para usar la nueva lógica de conexión
async function executeQuery(query, binds = []) {
    let connection;
    try {
        connection = await getConnection(); // Usa la nueva función inteligente
        const result = await connection.execute(query, binds, { outFormat: oracledb.OUT_FORMAT_OBJECT });
        return result.rows;
    } finally {
        if (connection) {
            try { await connection.close(); } catch (e) { console.error(e); }
        }
    }
}

async function executeProcedure(plsql, binds = {}) {
    let connection;
    try {
        connection = await getConnection(); // Usa la nueva función inteligente
        const result = await connection.execute(plsql, binds, { autoCommit: true });
        return result;
    } finally {
        if (connection) {
            try { await connection.close(); } catch (e) { console.error(e); }
        }
    }
}

// No olvides exportar las funciones
module.exports = { executeQuery, executeProcedure };