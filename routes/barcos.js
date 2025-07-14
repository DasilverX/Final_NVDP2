const express = require('express');
const router = express.Router();
const db = require('../database');

// GET /api/barcos - Obtener todos los barcos
router.get('/', async (req, res) => {
    try {
        const barcos = await db.executeQuery('SELECT * FROM BARCO ORDER BY NOMBRE_BARCO');
        res.json(barcos);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET /api/barcos/:id/detalles - Obtener detalles, tripulación e historial de un barco
router.get('/:id/detalles', async (req, res) => {
    const plsql = `BEGIN GET_BARCO_DETALLES(:p_barco_id, :c_detalles, :c_tripulacion, :c_historial_escalas); END;`;
    try {
        const result = await db.executeProcedure(plsql, {
            p_barco_id: req.params.id,
            c_detalles: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT },
            c_tripulacion: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT },
            c_historial_escalas: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
        });

        const detallesCursor = result.outBinds.c_detalles;
        const tripulacionCursor = result.outBinds.c_tripulacion;
        const escalasCursor = result.outBinds.c_historial_escalas;

        const detalles = await detallesCursor.getRows(1);
        const tripulacion = await tripulacionCursor.getRows();
        const historial = await escalasCursor.getRows();

        await detallesCursor.close();
        await tripulacionCursor.close();
        await escalasCursor.close();

        res.json({ detalles: detalles[0], tripulacion, historial });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// POST /api/barcos - Crear un nuevo barco
router.post('/', async (req, res) => {
    const { p_nombre, p_numero_imo, p_id_tipo_barco, p_id_pais_bandera, p_id_cliente } = req.body;
    const plsql = `BEGIN CREAR_BARCO(:p_nombre, :p_numero_imo, :p_id_tipo_barco, :p_id_pais_bandera, :p_id_cliente); END;`;
    try {
        await db.executeProcedure(plsql, { p_nombre, p_numero_imo, p_id_tipo_barco, p_id_pais_bandera, p_id_cliente });
        res.status(201).json({ message: 'Barco creado exitosamente' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// PUT /api/barcos/:id - Actualizar un barco
router.put('/:id', async (req, res) => {
    const { id } = req.params;
    const { p_nombre_barco, p_id_tipo_barco, p_id_pais_bandera, p_id_cliente } = req.body;
    const plsql = `BEGIN ACTUALIZAR_BARCO(:p_id_barco, :p_nombre_barco, :p_id_tipo_barco, :p_id_pais_bandera, :p_id_cliente); END;`;
    try {
        await db.executeProcedure(plsql, { p_id_barco: id, p_nombre_barco, p_id_tipo_barco, p_id_pais_bandera, p_id_cliente });
        res.json({ message: 'Barco actualizado exitosamente' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;