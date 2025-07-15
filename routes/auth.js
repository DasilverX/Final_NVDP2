const express = require('express');
// const bcrypt = require('bcrypt'); // Ya no necesitamos bcrypt
const db = require('../database');
const router = express.Router();

router.post('/login', async (req, res) => {
    const { nombre, password } = req.body;
    if (!nombre || !password) {
        return res.status(400).json({ message: 'Usuario y contraseña requeridos.' });
    }

    try {
        const users = await db.executeQuery(
            `SELECT ID_USUARIO, NOMBRE_USUARIO, PASSWORD_HASH, ID_ROL FROM USUARIOS WHERE NOMBRE_USUARIO = :nombre`,
            [nombre]
        );

        if (users.length === 0) {
            return res.status(401).json({ message: 'Credenciales inválidas.' });
        }

        const user = users[0];
        
        // ===================================================================
        // ADVERTENCIA: LÓGICA DE LOGIN INSEGURA - SOLO PARA DEPURACIÓN
        // Comparamos directamente la contraseña enviada con la guardada en la BD
        if (password !== user.PASSWORD_HASH) { // <-- Cambio clave aquí
            return res.status(401).json({ message: 'Credenciales inválidas.' });
        }
        // ===================================================================
        
        // Si el login es exitoso...
        res.json({
            message: 'Login exitoso (Modo Inseguro)',
            user: {
                id: user.ID_USUARIO,
                nombre: user.NOMBRE_USUARIO,
                rol: user.ID_ROL
            }
        });

    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Error interno del servidor' });
    }
});

module.exports = router;