const express = require('express');
const cors = require('cors');
const database = require('./database.js');

// Importar las rutas que creamos
const authRoutes = require('./routes/auth.js');
const barcoRoutes = require('./routes/barcos.js');
const tripulanteRoutes = require('./routes/tripulantes.js');

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors());
app.use(express.json());

// Montar las rutas en la API
app.use('/api/auth', authRoutes);
app.use('/api/barcos', barcoRoutes);
app.use('/api/tripulantes', tripulanteRoutes);

// Ruta principal para verificar que la API está viva
app.get('/', (req, res) => {
    res.send('API de NVDPA está funcionando.');
});

async function startup() {
    console.log('Iniciando servidor...');
    try {
        await database.initialize();
        app.listen(PORT, () => {
            console.log(`🚀 Servidor listo y escuchando en el puerto ${PORT}`);
        });
    } catch (err) {
        console.error('Error crítico durante el arranque:', err);
        process.exit(1);
    }
}

startup();