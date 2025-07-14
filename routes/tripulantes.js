const express = require('express');
const router = express.Router();
const db = require('../database');

// GET /api/tripulantes - Obtener toda la tripulación
router.get('/', async (req, res) => {
    try {
        const tripulantes = await db.executeQuery('SELECT * FROM TRIPULACION');
        res.json(tripulantes);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// POST /api/tripulantes - Añadir un nuevo tripulante
router.post('/', async (req, res) => {
    const { nombre_completo, rol_abordo, pasaporte, id_pais_nacionalidad, id_barco } = req.body;
    const sql = `INSERT INTO TRIPULACION (NOMBRE_COMPLETO, ROL_ABORDO, PASAPORTE, ID_PAIS_NACIONALIDAD, ID_BARCO) VALUES (:1, :2, :3, :4, :5)`;
    try {
        await db.executeQuery(sql, [nombre_completo, rol_abordo, pasaporte, id_pais_nacionalidad, id_barco]);
        res.status(201).json({ message: 'Tripulante creado exitosamente' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Puedes añadir aquí las rutas PUT y DELETE de forma similar

module.exports = router;