-- =======================================================================================
-- =======================================================================================
--                  SCRIPT DE BASE DE DATOS PARA AGENCIA NAVIERA
--                                 VERSIÓN 1.0
-- =======================================================================================
-- =======================================================================================
-- Este script está organizado en las siguientes secciones:
-- 1. Creación de Tablas (DDL)
-- 2. Creación de Vistas (DDL)
-- 3. Configuración de Seguridad (Roles, Usuarios y Tablas relacionadas)
-- 4. Inserción de Datos Maestros y de Semilla (DML)
-- 5. Procedimientos Almacenados (Lógica de Negocio)
-- 6. Inserción de Datos de Prueba y Escenarios Operacionales (DML)
-- 7. Scripts de Ejecución y Pruebas
-- =======================================================================================


-- =======================================================================================
-- SECCIÓN 1: CREACIÓN DE TABLAS (Data Definition Language - DDL)
-- ---------------------------------------------------------------------------------------
-- En esta sección se definen todas las tablas principales del esquema.
-- =======================================================================================

-- TABLAS PRINCIPALES E INDEPENDIENTES
CREATE TABLE Cliente (
    ClienteID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    Nombre VARCHAR2(100) NOT NULL,
    Direccion VARCHAR2(255),
    InformacionContacto VARCHAR2(100)
);

CREATE TABLE Puerto (
    PuertoID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    Nombre VARCHAR2(100) NOT NULL,
    Ubicacion VARCHAR2(100),
    Pais VARCHAR2(50)
);

CREATE TABLE Servicio (
    ServicioID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    Tipo VARCHAR2(100) NOT NULL,
    Descripcion VARCHAR2(255)
);

-- TABLAS DEPENDIENTES
CREATE TABLE Barco (
    BarcoID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    Nombre VARCHAR2(100) NOT NULL,
    NumeroIMO VARCHAR2(7) NOT NULL UNIQUE,
    Tipo VARCHAR2(50),
    Bandera VARCHAR2(50),
    PropietarioID NUMBER,
    CONSTRAINT fk_barco_cliente FOREIGN KEY (PropietarioID) REFERENCES Cliente(ClienteID)
);

CREATE TABLE EscalaPortuaria (
    EscalaPortuariaID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    BarcoID NUMBER NOT NULL,
    PuertoID NUMBER NOT NULL,
    FechaHoraLlegada TIMESTAMP,
    FechaHoraSalida TIMESTAMP,
    Muelle VARCHAR2(20),
    CONSTRAINT fk_escala_barco FOREIGN KEY (BarcoID) REFERENCES Barco(BarcoID),
    CONSTRAINT fk_escala_puerto FOREIGN KEY (PuertoID) REFERENCES Puerto(PuertoID),
    CONSTRAINT chk_fechas_escala CHECK (FechaHoraSalida > FechaHoraLlegada)
);

CREATE TABLE Tripulacion (
    TripulacionID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    BarcoID NUMBER NOT NULL,
    Nombre VARCHAR2(150) NOT NULL,
    Rol VARCHAR2(50),
    NumeroPasaporte VARCHAR2(50) UNIQUE,
    Nacionalidad VARCHAR2(50),
    CONSTRAINT fk_tripulacion_barco FOREIGN KEY (BarcoID) REFERENCES Barco(BarcoID)
);

CREATE TABLE Carga (
    CargaID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    EscalaPortuariaID NUMBER NOT NULL,
    Tipo VARCHAR2(100),
    Cantidad NUMBER,
    Peso NUMBER(10, 3),
    Origen VARCHAR2(100),
    Destino VARCHAR2(100),
    CONSTRAINT fk_carga_escala FOREIGN KEY (EscalaPortuariaID) REFERENCES EscalaPortuaria(EscalaPortuariaID)
);

-- TABLAS INTERMEDIAS Y TRANSACCIONALES
CREATE TABLE ServicioEscala (
    ServicioEscalaID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    EscalaPortuariaID NUMBER NOT NULL,
    ServicioID NUMBER NOT NULL,
    Proveedor VARCHAR2(100),
    Costo NUMBER(10, 2) DEFAULT 0.00,
    CONSTRAINT fk_se_escala FOREIGN KEY (EscalaPortuariaID) REFERENCES EscalaPortuaria(EscalaPortuariaID),
    CONSTRAINT fk_se_servicio FOREIGN KEY (ServicioID) REFERENCES Servicio(ServicioID)
);

CREATE TABLE Transaccion (
    TransaccionID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    EscalaPortuariaID NUMBER NOT NULL,
    ClienteID NUMBER NOT NULL,
    Monto NUMBER(12, 2) NOT NULL,
    Fecha DATE DEFAULT SYSDATE,
    EstadoPago VARCHAR2(20) DEFAULT 'Pendiente',
    CONSTRAINT fk_transaccion_escala FOREIGN KEY (EscalaPortuariaID) REFERENCES EscalaPortuaria(EscalaPortuariaID),
    CONSTRAINT fk_transaccion_cliente FOREIGN KEY (ClienteID) REFERENCES Cliente(ClienteID),
    CONSTRAINT chk_estadopago CHECK (EstadoPago IN ('Pendiente', 'Pagado', 'Cancelado'))
);


-- =======================================================================================
--  [ Espacio para futuras actualizaciones de TABLAS ]
-- =======================================================================================

-- ========= SCRIPT PARA TABLAS DE EMPLEADOS Y ASIGNACIÓN =========

-- 1. Tabla de Empleados para datos adicionales de administradores/operadores
CREATE TABLE Empleados (
    EmpleadoID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    -- Creamos una relación 1 a 1 con la tabla Usuarios
    UsuarioID NUMBER NOT NULL UNIQUE,
    Puesto VARCHAR2(100), -- Ej: 'Jefe de Operaciones', 'Soporte Logístico'
    FechaContratacion DATE,
    Telefono VARCHAR2(50),
    
    CONSTRAINT fk_empleado_usuario FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);


-- 2. Tabla Pivote para la relación Muchos-a-Muchos entre Operadores y Capitanes
CREATE TABLE OperadorCapitan (
    AsignacionID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    -- El ID del usuario Operador (debe tener rol de admin u operador)
    OperadorUsuarioID NUMBER NOT NULL,
    -- El ID del usuario Capitán (debe tener rol de capitán)
    CapitanUsuarioID NUMBER NOT NULL,
    FechaAsignacion DATE DEFAULT SYSDATE,
    Estatus VARCHAR2(50) DEFAULT 'Activo', -- Ej: 'Activo', 'Inactivo'
    
    CONSTRAINT fk_opcap_operador FOREIGN KEY (OperadorUsuarioID) REFERENCES Usuarios(UsuarioID),
    CONSTRAINT fk_opcap_capitan FOREIGN KEY (CapitanUsuarioID) REFERENCES Usuarios(UsuarioID),
    -- Restricción para evitar asignaciones duplicadas
    CONSTRAINT uq_operador_capitan UNIQUE (OperadorUsuarioID, CapitanUsuarioID)
);


COMMIT;


-- =======================================================================================
-- SECCIÓN 2: CREACIÓN DE VISTAS (Data Definition Language - DDL)
-- ---------------------------------------------------------------------------------------
-- Vistas para simplificar consultas complejas y generar reportes.
-- =======================================================================================

CREATE OR REPLACE VIEW V_ESCALA_DETALLE AS
SELECT
    ep.EscalaPortuariaID,
    b.BarcoID,
    ep.FechaHoraLlegada,
    ep.FechaHoraSalida,
    b.Nombre AS NombreBarco,
    b.NumeroIMO,
    c.Nombre AS NombreCliente,
    p.Nombre AS NombrePuerto,
    p.Pais AS PaisPuerto,
    ep.Muelle
FROM
    EscalaPortuaria ep
JOIN 
    Barco b ON ep.BarcoID = b.BarcoID
JOIN 
    Cliente c ON b.PropietarioID = c.ClienteID
JOIN 
    Puerto p ON ep.PuertoID = p.PuertoID
/

CREATE OR REPLACE VIEW V_FINANZAS_ESCALA AS
SELECT
    ep.EscalaPortuariaID,
    b.Nombre AS NombreBarco,
    c.Nombre AS NombreCliente,
    (SELECT SUM(se.Costo) FROM ServicioEscala se WHERE se.EscalaPortuariaID = ep.EscalaPortuariaID) AS CostoTotalServicios,
    t.Monto AS MontoFacturado,
    t.EstadoPago,
    t.TransaccionID
FROM
    EscalaPortuaria ep
JOIN Barco b ON ep.BarcoID = b.BarcoID
JOIN Cliente c ON b.PropietarioID = c.ClienteID
LEFT JOIN Transaccion t ON ep.EscalaPortuariaID = t.EscalaPortuariaID
/

CREATE OR REPLACE VIEW V_MANIFIESTO_ESCALA AS
SELECT
    ep.EscalaPortuariaID,
    b.Nombre AS NombreBarco,
    'Tripulante' AS TipoRegistro,
    tr.Nombre AS Detalle,
    tr.Rol
FROM
    EscalaPortuaria ep
JOIN Barco b ON ep.BarcoID = b.BarcoID
JOIN Tripulacion tr ON b.BarcoID = tr.BarcoID
UNION ALL
SELECT
    ep.EscalaPortuariaID,
    b.Nombre AS NombreBarco,
    'Carga' AS TipoRegistro,
    ca.Tipo AS Detalle,
    'Origen: ' || ca.Origen || ' - Destino: ' || ca.Destino AS Rol
FROM
    EscalaPortuaria ep
JOIN Barco b ON ep.BarcoID = b.BarcoID
JOIN Carga ca ON ep.EscalaPortuariaID = ca.EscalaPortuariaID
/


-- =======================================================================================
--  [ Espacio para futuras actualizaciones de VISTAS ]
-- =======================================================================================

CREATE OR REPLACE PROCEDURE REGISTRAR_BARCO_Y_ASIGNAR_CAPITAN (
    p_nombre            IN VARCHAR2,
    p_numero_imo        IN VARCHAR2,
    p_tipo              IN VARCHAR2,
    p_bandera           IN VARCHAR2,
    p_propietario_id    IN NUMBER,
    p_capitan_usuario_id IN NUMBER
)
AS
    v_nuevo_barco_id NUMBER;
BEGIN
    -- 1. Insertamos el nuevo barco y obtenemos su ID recién creado
    INSERT INTO Barco (Nombre, NumeroIMO, Tipo, Bandera, PropietarioID)
    VALUES (p_nombre, p_numero_imo, p_tipo, p_bandera, p_propietario_id)
    RETURNING BarcoID INTO v_nuevo_barco_id;

    -- 2. Actualizamos la tabla Usuarios para asignar el nuevo BarcoID al capitán
    UPDATE Usuarios
    SET BarcoID = v_nuevo_barco_id
    WHERE UsuarioID = p_capitan_usuario_id;
    
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20010, 'El número IMO ' || p_numero_imo || ' ya existe.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- =======================================================================================
-- SECCIÓN 3: CONFIGURACIÓN DE SEGURIDAD (Roles, Usuarios y Funcionalidad de Capitanes)
-- ---------------------------------------------------------------------------------------
-- Creación de tablas y modificaciones para el manejo de la seguridad.
-- =======================================================================================

-- Tabla para definir los roles
CREATE TABLE Roles (
    RolID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    NombreRol VARCHAR2(50) NOT NULL UNIQUE
);

-- Tabla para almacenar los usuarios
CREATE TABLE Usuarios (
    UsuarioID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    Nombre VARCHAR2(100) NOT NULL UNIQUE,
    Password VARCHAR2(100) NOT NULL,
    RolID NUMBER,
    CONSTRAINT fk_usuario_rol FOREIGN KEY (RolID) REFERENCES Roles(RolID)
);

-- Modificar la tabla Usuarios para vincular un capitán a un barco
ALTER TABLE Usuarios
ADD (BarcoID NUMBER,
     CONSTRAINT fk_usuario_barco FOREIGN KEY (BarcoID) REFERENCES Barco(BarcoID)
);

-- Crear la nueva tabla para las peticiones de servicio de los capitanes
CREATE TABLE PeticionesServicio (
    PeticionID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    EscalaPortuariaID NUMBER NOT NULL,
    ServicioID NUMBER NOT NULL,
    UsuarioID NUMBER NOT NULL,
    Estado VARCHAR2(50) DEFAULT 'Pendiente', -- Pendiente, Aprobado, Completado, Rechazado
    FechaPeticion DATE DEFAULT SYSDATE,
    Notas VARCHAR2(500),
    CONSTRAINT fk_peticion_escala FOREIGN KEY (EscalaPortuariaID) REFERENCES EscalaPortuaria(EscalaPortuariaID),
    CONSTRAINT fk_peticion_servicio FOREIGN KEY (ServicioID) REFERENCES Servicio(ServicioID),
    CONSTRAINT fk_peticion_usuario FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);


-- =======================================================================================
--  [ Espacio para futuras actualizaciones de SEGURIDAD ]
-- =======================================================================================


-- =======================================================================================
-- SECCIÓN 4: INSERCIÓN DE DATOS MAESTROS Y DE SEMILLA (Data Manipulation Language - DML)
-- ---------------------------------------------------------------------------------------
-- Datos iniciales necesarios para el funcionamiento básico del sistema.
-- =======================================================================================

-- Insertar los roles disponibles
INSERT INTO Roles (NombreRol) VALUES ('administrador');
INSERT INTO Roles (NombreRol) VALUES ('visitante');
INSERT INTO Roles (NombreRol) VALUES ('capitan');

-- Insertar usuarios de ejemplo
INSERT INTO Usuarios (Nombre, Password, RolID, BarcoID) VALUES ('admin', '$2a$12$30ZWJDDUrmEDtR2a1leexe.YC6W54Z9.butFsna5Mm57tLhYc3s5.', 1, NULL);
INSERT INTO Usuarios (Nombre, Password, RolID, BarcoID) VALUES ('user', 'user', 2, NULL);
INSERT INTO Usuarios (Nombre, Password, RolID, BarcoID) VALUES ('cpt.jones', 'password123', 3, 1); -- Capitán del BarcoID 1

-- Insertar datos maestros de negocio
INSERT INTO Cliente (Nombre, Direccion, InformacionContacto) VALUES ('Naviera Global', 'Calle Falsa 123, Panama', 'contacto@navieraglobal.com');
INSERT INTO Puerto (Nombre, Ubicacion, Pais) VALUES ('Puerto de Valencia', 'Valencia', 'España');
INSERT INTO Servicio (Tipo, Descripcion) VALUES ('Atraque', 'Servicio de amarre en muelle');
INSERT INTO Servicio (Tipo, Descripcion) VALUES ('Pilotaje', 'Servicio de piloto para entrada al puerto');
INSERT INTO Servicio (Tipo, Descripcion) VALUES ('Suministro', 'Abastecimiento de combustible y víveres');

COMMIT;


-- =======================================================================================
--  [ Espacio para futuras actualizaciones de DATOS MAESTROS ]
-- =======================================================================================

-- 1. Añadir las columnas de latitud y longitud a la tabla Puerto
ALTER TABLE Puerto
ADD (
    Latitud NUMBER,
    Longitud NUMBER
);

-- 2. Actualizar los puertos existentes con sus coordenadas
UPDATE Puerto SET Latitud = 39.45, Longitud = -0.33 WHERE Nombre = 'Puerto de Valencia';
UPDATE Puerto SET Latitud = 9.35, Longitud = -79.9 WHERE Nombre = 'Puerto de Manzanillo';
UPDATE Puerto SET Latitud = 51.95, Longitud = 4.48 WHERE Nombre = 'Puerto de Róterdam';
UPDATE Puerto SET Latitud = 1.28, Longitud = 103.85 WHERE Nombre = 'Puerto de Singapur';

COMMIT;

-- ========= SCRIPT PARA REINICIAR AL USUARIO 'cpt.smith' =========

-- Parte 1: Borrado Seguro del Usuario y sus dependencias
DECLARE
    v_usuario_id NUMBER;
BEGIN
    -- Buscamos el ID del usuario. Si no existe, la excepción se encargará.
    SELECT UsuarioID INTO v_usuario_id FROM Usuarios WHERE Nombre = 'cpt.smith';

    -- Borramos registros en tablas hijas que puedan hacer referencia al usuario.
    -- Esto previene errores de llaves foráneas.
    DELETE FROM OperadorCapitan WHERE OperadorUsuarioID = v_usuario_id OR CapitanUsuarioID = v_usuario_id;
    DELETE FROM Empleados WHERE UsuarioID = v_usuario_id;
    DELETE FROM PeticionesServicio WHERE UsuarioID = v_usuario_id;
    
    -- Finalmente, borramos el usuario principal de la tabla Usuarios
    DELETE FROM Usuarios WHERE UsuarioID = v_usuario_id;
    
    DBMS_OUTPUT.PUT_LINE('Usuario ''cpt.smith'' y sus dependencias han sido eliminados.');
    
EXCEPTION
    -- Si el usuario no se encuentra, simplemente lo informamos y continuamos.
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('El usuario ''cpt.smith'' no existía. No se borró nada.');
END;
/


-- Parte 2: Creación (o Re-creación) del Usuario con el comando MERGE
MERGE INTO Usuarios u
USING (SELECT 'cpt.smith' AS Nombre FROM dual) src
ON (u.Nombre = src.Nombre)
WHEN MATCHED THEN
  UPDATE SET
    u.Password = '$2a$12$yPcgg2rt52A.h9a0AMJypu3KVr7SWaApWSBMCDe6C5xelfpqXjcJG',
    u.RolID = 3, -- Rol de Capitán
    u.BarcoID = NULL -- Sin barco asignado
WHEN NOT MATCHED THEN
  INSERT (Nombre, Password, RolID, BarcoID)
  VALUES ('cpt.smith', '$2a$12$yPcgg2rt52A.h9a0AMJypu3KVr7SWaApWSBMCDe6C5xelfpqXjcJG', 3, NULL);
/

COMMIT;

-- Mensaje final de confirmación
SELECT 'Usuario cpt.smith reiniciado correctamente. Listo para las pruebas.' AS ESTATUS FROM DUAL;


-- ========= SCRIPT ALTERNATIVO PARA CREAR/ACTUALIZAR AL CAPITÁN DE PRUEBA =========

BEGIN
  -- Primero, intentamos actualizar el usuario por si ya existe
  UPDATE Usuarios
  SET
    Password = '$2a$12$yPcgg2rt52A.h9a0AMJypu3KVr7SWaApWSBMCDe6C5xelfpqXjcJG',
    RolID = 3,
    BarcoID = NULL
  WHERE
    Nombre = 'cpt.smith';

  -- Si la actualización no afectó a ninguna fila (SQL%NOTFOUND), significa que el usuario no existía
  IF SQL%NOTFOUND THEN
    -- Entonces, lo insertamos como un nuevo registro
    INSERT INTO Usuarios (Nombre, Password, RolID, BarcoID)
    VALUES ('cpt.smith', '$2a$12$yPcgg2rt52A.h9a0AMJypu3KVr7SWaApWSBMCDe6C5xelfpqXjcJG', 3, NULL);
    
    DBMS_OUTPUT.PUT_LINE('Usuario ''cpt.smith'' creado exitosamente.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Usuario ''cpt.smith'' ya existía y ha sido actualizado.');
  END IF;

END;
/

COMMIT;

-- Mensaje final de confirmación
SELECT 'Usuario cpt.smith reiniciado correctamente. Listo para las pruebas.' AS ESTATUS FROM DUAL;

-- =======================================================================================
-- SECCIÓN 5: PROCEDIMIENTOS ALMACENADOS (Lógica de Negocio)
-- ---------------------------------------------------------------------------------------
-- Automatización de procesos de negocio mediante procedimientos en PL/SQL.
-- =======================================================================================

CREATE OR REPLACE PROCEDURE GENERAR_TRANSACCION_ESCALA (p_escala_id IN NUMBER)
AS
    v_total_costo NUMBER;
    v_cliente_id NUMBER;
    v_transaccion_existente NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_transaccion_existente FROM Transaccion WHERE EscalaPortuariaID = p_escala_id;
    IF v_transaccion_existente > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Error: Ya existe una transacción para la Escala ID ' || p_escala_id);
        RETURN;
    END IF;
    SELECT SUM(Costo) INTO v_total_costo FROM ServicioEscala WHERE EscalaPortuariaID = p_escala_id;
    IF v_total_costo IS NULL OR v_total_costo = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No hay servicios con costo para la Escala ID ' || p_escala_id || '. No se generó transacción.');
        RETURN;
    END IF;
    SELECT b.PropietarioID INTO v_cliente_id FROM EscalaPortuaria ep JOIN Barco b ON ep.BarcoID = b.BarcoID WHERE ep.EscalaPortuariaID = p_escala_id;
    INSERT INTO Transaccion (EscalaPortuariaID, ClienteID, Monto, Fecha, EstadoPago) VALUES (p_escala_id, v_cliente_id, v_total_costo, SYSDATE, 'Pendiente');
    DBMS_OUTPUT.PUT_LINE('Transacción generada exitosamente para la Escala ID ' || p_escala_id || ' por un monto de ' || v_total_costo);
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: No se encontró la Escala ID ' || p_escala_id || ' o el cliente asociado.');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ha ocurrido un error inesperado: ' || SQLERRM);
        ROLLBACK;
END;
/

CREATE OR REPLACE PROCEDURE ASIGNAR_TRIPULANTE_BARCO (p_barco_id IN NUMBER, p_nombre IN VARCHAR2, p_rol IN VARCHAR2, p_pasaporte IN VARCHAR2, p_nacionalidad IN VARCHAR2)
AS
    v_pasaporte_existente NUMBER;
    v_barco_existente     NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_pasaporte_existente FROM Tripulacion WHERE NumeroPasaporte = p_pasaporte;
    IF v_pasaporte_existente > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Error: El número de pasaporte ' || p_pasaporte || ' ya está registrado.');
        RETURN;
    END IF;
    SELECT COUNT(*) INTO v_barco_existente FROM Barco WHERE BarcoID = p_barco_id;
    IF v_barco_existente = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Error: El Barco con ID ' || p_barco_id || ' no existe.');
        RETURN;
    END IF;
    INSERT INTO Tripulacion (BarcoID, Nombre, Rol, NumeroPasaporte, Nacionalidad) VALUES (p_barco_id, p_nombre, p_rol, p_pasaporte, p_nacionalidad);
    DBMS_OUTPUT.PUT_LINE('Tripulante ' || p_nombre || ' asignado exitosamente al barco ID ' || p_barco_id || '.');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ha ocurrido un error inesperado al asignar el tripulante: ' || SQLERRM);
        ROLLBACK;
END;
/

CREATE OR REPLACE PROCEDURE ELIMINAR_TRIPULANTE (p_tripulacion_id IN NUMBER)
AS
    v_tripulante_existente NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_tripulante_existente FROM Tripulacion WHERE TripulacionID = p_tripulacion_id;
    IF v_tripulante_existente = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'El tripulante con ID ' || p_tripulacion_id || ' no existe.');
    END IF;
    DELETE FROM Tripulacion WHERE TripulacionID = p_tripulacion_id;
    DBMS_OUTPUT.PUT_LINE('Tripulante con ID ' || p_tripulacion_id || ' ha sido eliminado.');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al eliminar el tripulante: ' || SQLERRM);
        ROLLBACK;
END;
/

CREATE OR REPLACE PROCEDURE ACTUALIZAR_TRIPULANTE (p_tripulacion_id IN NUMBER, p_nombre IN VARCHAR2, p_rol IN VARCHAR2, p_nacionalidad IN VARCHAR2)
AS
BEGIN
    UPDATE Tripulacion SET Nombre = p_nombre, Rol = p_rol, Nacionalidad = p_nacionalidad WHERE TripulacionID = p_tripulacion_id;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'El tripulante con ID ' || p_tripulacion_id || ' no existe y no puede ser actualizado.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('Tripulante con ID ' || p_tripulacion_id || ' ha sido actualizado.');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al actualizar el tripulante: ' || SQLERRM);
        ROLLBACK;
END;
/

CREATE OR REPLACE PROCEDURE GET_BARCO_DETALLES (p_barco_id IN NUMBER, c_detalles OUT SYS_REFCURSOR, c_tripulacion OUT SYS_REFCURSOR, c_historial_escalas OUT SYS_REFCURSOR)
AS
BEGIN
    OPEN c_detalles FOR SELECT BarcoID, Nombre, NumeroIMO, Tipo, Bandera, PropietarioID FROM Barco WHERE BarcoID = p_barco_id;
    OPEN c_tripulacion FOR SELECT TripulacionID, Nombre, Rol, Nacionalidad FROM Tripulacion WHERE BarcoID = p_barco_id;
    OPEN c_historial_escalas FOR SELECT ep.EscalaPortuariaID, p.Nombre AS NombrePuerto, p.Pais AS PaisPuerto, ep.FechaHoraLlegada, ep.FechaHoraSalida FROM EscalaPortuaria ep JOIN Barco b ON ep.BarcoID = b.BarcoID JOIN Puerto p ON ep.PuertoID = p.PuertoID WHERE ep.BarcoID = p_barco_id ORDER BY ep.FechaHoraLlegada DESC;
END;
/


-- =======================================================================================
--  [ Espacio para futuros PROCEDIMIENTOS ALMACENADOS ]
-- =======================================================================================

-- ========= PROCEDIMIENTOS PARA CRUD DE BARCOS =========

-- 1. Procedimiento para CREAR un nuevo barco
CREATE OR REPLACE PROCEDURE CREAR_BARCO (
    p_nombre         IN VARCHAR2,
    p_numero_imo     IN VARCHAR2,
    p_tipo           IN VARCHAR2,
    p_bandera        IN VARCHAR2,
    p_propietario_id IN NUMBER
)
AS
BEGIN
    INSERT INTO Barco (Nombre, NumeroIMO, Tipo, Bandera, PropietarioID)
    VALUES (p_nombre, p_numero_imo, p_tipo, p_bandera, p_propietario_id);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20010, 'El número IMO ' || p_numero_imo || ' ya existe.');
    WHEN OTHERS THEN
        RAISE;
END;
/

-- 2. Procedimiento para ACTUALIZAR un barco existente
CREATE OR REPLACE PROCEDURE ACTUALIZAR_BARCO (
    p_barco_id       IN NUMBER,
    p_nombre         IN VARCHAR2,
    p_tipo           IN VARCHAR2,
    p_bandera        IN VARCHAR2,
    p_propietario_id IN NUMBER
)
AS
BEGIN
    UPDATE Barco
    SET 
        Nombre = p_nombre,
        Tipo = p_tipo,
        Bandera = p_bandera,
        PropietarioID = p_propietario_id
    WHERE BarcoID = p_barco_id;
    
    IF SQL%NOTFOUND THEN
        RAISE_APPLICATION_ERROR(-20011, 'El barco con ID ' || p_barco_id || ' no existe.');
    END IF;
    COMMIT;
END;
/

-- 3. Procedimiento para ELIMINAR un barco
CREATE OR REPLACE PROCEDURE ELIMINAR_BARCO (
    p_barco_id IN NUMBER
)
AS
    v_count_escalas NUMBER;
BEGIN
    -- Verificación de seguridad: no se puede borrar un barco si tiene escalas asociadas.
    SELECT COUNT(*) INTO v_count_escalas FROM EscalaPortuaria WHERE BarcoID = p_barco_id;
    
    IF v_count_escalas > 0 THEN
        RAISE_APPLICATION_ERROR(-20012, 'No se puede eliminar el barco porque tiene escalas portuarias registradas. Elimine primero las escalas.');
    END IF;
    
    DELETE FROM Barco WHERE BarcoID = p_barco_id;
    
    IF SQL%NOTFOUND THEN
        RAISE_APPLICATION_ERROR(-20011, 'El barco con ID ' || p_barco_id || ' no existe.');
    END IF;
    COMMIT;
END;
/



CREATE OR REPLACE PROCEDURE REGISTRAR_BARCO_Y_ASIGNAR_CAPITAN (
    p_nombre            IN VARCHAR2,
    p_numero_imo        IN VARCHAR2,
    p_tipo              IN VARCHAR2,
    p_bandera           IN VARCHAR2,
    p_propietario_id    IN NUMBER,
    p_capitan_usuario_id IN NUMBER,
    p_nuevo_barco_id    OUT NUMBER -- ***** PARÁMETRO DE SALIDA AÑADIDO *****
)
AS
BEGIN
    INSERT INTO Barco (Nombre, NumeroIMO, Tipo, Bandera, PropietarioID)
    VALUES (p_nombre, p_numero_imo, p_tipo, p_bandera, p_propietario_id)
    RETURNING BarcoID INTO p_nuevo_barco_id; -- Guardamos el ID en el parámetro de salida

    UPDATE Usuarios
    SET BarcoID = p_nuevo_barco_id
    WHERE UsuarioID = p_capitan_usuario_id;
    
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20010, 'El número IMO ' || p_numero_imo || ' ya existe.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- =======================================================================================
-- SECCIÓN 6: INSERCIÓN DE DATOS DE PRUEBA Y ESCENARIOS (DML)
-- ---------------------------------------------------------------------------------------
-- Inserción de datos operacionales para simular el uso real del sistema.
-- =======================================================================================

-- Escenario 1: Barco "Estrella del Mar" en Valencia (Inserción simple)
INSERT INTO Barco (Nombre, NumeroIMO, Tipo, Bandera, PropietarioID) VALUES ('Estrella del Mar', '1234567', 'Portacontenedores', 'Panamá', 1);
INSERT INTO EscalaPortuaria (BarcoID, PuertoID, FechaHoraLlegada, FechaHoraSalida, Muelle) VALUES (1, 1, TO_TIMESTAMP('2025-05-10 08:00', 'YYYY-MM-DD HH24:MI'), TO_TIMESTAMP('2025-05-12 18:00', 'YYYY-MM-DD HH24:MI'), '3');
INSERT INTO Carga (EscalaPortuariaID, Tipo, Cantidad, Peso, Origen, Destino) VALUES (1, 'Contenedores', 100, 1000, 'Shanghai', 'Valencia');
INSERT INTO ServicioEscala (EscalaPortuariaID, ServicioID, Proveedor, Costo) VALUES (1, 1, 'Servicios Portuarios S.A.', 1000);
INSERT INTO ServicioEscala (EscalaPortuariaID, ServicioID, Proveedor, Costo) VALUES (1, 2, 'Pilotos del Puerto', 500);
INSERT INTO ServicioEscala (EscalaPortuariaID, ServicioID, Proveedor, Costo) VALUES (1, 3, 'Repsol Marine', 2000);
INSERT INTO Transaccion (EscalaPortuariaID, ClienteID, Monto, Fecha, EstadoPago) VALUES (1, 1, 3500.00, TO_DATE('2025-05-12', 'YYYY-MM-DD'), 'Pendiente');
COMMIT;

-- Escenarios 2, 3 y 4 (Inserción robusta con bloque PL/SQL)
DECLARE
    v_cliente_id_sur NUMBER;
    v_cliente_id_atl NUMBER;
    v_barco_id_luna NUMBER;
    v_barco_id_gigante NUMBER;
    v_barco_id_express NUMBER;
    v_puerto_id_manzanillo NUMBER;
    v_puerto_id_rotterdam NUMBER;
    v_puerto_id_singapur NUMBER;
    v_escala_id_1 NUMBER;
    v_escala_id_2 NUMBER;
    v_escala_id_3 NUMBER;
BEGIN
    INSERT INTO Cliente (Nombre, Direccion, InformacionContacto) VALUES ('Marítima del Sur', 'Av. Balboa, Panama', 'operaciones@maritimasur.com') RETURNING ClienteID INTO v_cliente_id_sur;
    INSERT INTO Cliente (Nombre, Direccion, InformacionContacto) VALUES ('Carriers Atlántico', 'Zona Libre, Colón', 'trafico@catlantico.com') RETURNING ClienteID INTO v_cliente_id_atl;
    INSERT INTO Puerto (Nombre, Ubicacion, Pais) VALUES ('Puerto de Manzanillo', 'Colón', 'Panamá') RETURNING PuertoID INTO v_puerto_id_manzanillo;
    INSERT INTO Puerto (Nombre, Ubicacion, Pais) VALUES ('Puerto de Róterdam', 'Róterdam', 'Países Bajos') RETURNING PuertoID INTO v_puerto_id_rotterdam;
    INSERT INTO Puerto (Nombre, Ubicacion, Pais) VALUES ('Puerto de Singapur', 'Singapur', 'Singapur') RETURNING PuertoID INTO v_puerto_id_singapur;
    INSERT INTO Barco (Nombre, NumeroIMO, Tipo, Bandera, PropietarioID) VALUES ('Luna del Caribe', '9876543', 'Buque Tanque', 'Liberia', v_cliente_id_sur) RETURNING BarcoID INTO v_barco_id_luna;
    INSERT INTO Barco (Nombre, NumeroIMO, Tipo, Bandera, PropietarioID) VALUES ('Gigante del Pacífico', '1122334', 'Portacontenedores', 'Singapur', v_cliente_id_atl) RETURNING BarcoID INTO v_barco_id_gigante;
    INSERT INTO Barco (Nombre, NumeroIMO, Tipo, Bandera, PropietarioID) VALUES ('Carga Express', '5566778', 'Carga General', 'Panamá', v_cliente_id_atl) RETURNING BarcoID INTO v_barco_id_express;
    INSERT INTO Tripulacion (BarcoID, Nombre, Rol, NumeroPasaporte, Nacionalidad) VALUES (v_barco_id_luna, 'Juan Pérez', 'Capitán', 'PA12345', 'Panameño');
    INSERT INTO Tripulacion (BarcoID, Nombre, Rol, NumeroPasaporte, Nacionalidad) VALUES (v_barco_id_gigante, 'Lee Yong', 'Primer Oficial', 'SG98765', 'Singapurense');
    INSERT INTO Tripulacion (BarcoID, Nombre, Rol, NumeroPasaporte, Nacionalidad) VALUES (v_barco_id_express, 'Carlos Gómez', 'Jefe de Máquinas', 'CO54321', 'Colombiano');
    INSERT INTO EscalaPortuaria (BarcoID, PuertoID, FechaHoraLlegada, FechaHoraSalida, Muelle) VALUES (v_barco_id_luna, v_puerto_id_manzanillo, TO_TIMESTAMP('2025-06-10 10:00', 'YYYY-MM-DD HH24:MI'), TO_TIMESTAMP('2025-06-12 05:00', 'YYYY-MM-DD HH24:MI'), 'M-5') RETURNING EscalaPortuariaID INTO v_escala_id_1;
    INSERT INTO Carga (EscalaPortuariaID, Tipo, Cantidad, Peso, Origen, Destino) VALUES (v_escala_id_1, 'Petróleo Crudo', 50000, 45000, 'Venezuela', 'EE.UU.');
    INSERT INTO ServicioEscala (EscalaPortuariaID, ServicioID, Proveedor, Costo) VALUES (v_escala_id_1, 1, 'Servicios Portuarios S.A.', 1200);
    INSERT INTO ServicioEscala (EscalaPortuariaID, ServicioID, Proveedor, Costo) VALUES (v_escala_id_1, 2, 'Pilotos del Puerto', 650);
    INSERT INTO Transaccion (EscalaPortuariaID, ClienteID, Monto, Fecha, EstadoPago) VALUES (v_escala_id_1, v_cliente_id_sur, 1850.00, TO_DATE('2025-06-12', 'YYYY-MM-DD'), 'Pagado');
    INSERT INTO EscalaPortuaria (BarcoID, PuertoID, FechaHoraLlegada, FechaHoraSalida, Muelle) VALUES (v_barco_id_gigante, v_puerto_id_rotterdam, TO_TIMESTAMP('2025-07-01 14:00', 'YYYY-MM-DD HH24:MI'), TO_TIMESTAMP('2025-07-03 20:00', 'YYYY-MM-DD HH24:MI'), 'E-12') RETURNING EscalaPortuariaID INTO v_escala_id_2;
    INSERT INTO Carga (EscalaPortuariaID, Tipo, Cantidad, Peso, Origen, Destino) VALUES (v_escala_id_2, 'Electrónicos', 300, 450.5, 'Singapur', 'Hamburgo');
    INSERT INTO ServicioEscala (EscalaPortuariaID, ServicioID, Proveedor, Costo) VALUES (v_escala_id_2, 1, 'Port of Rotterdam Auth.', 2500);
    INSERT INTO ServicioEscala (EscalaPortuariaID, ServicioID, Proveedor, Costo) VALUES (v_escala_id_2, 3, 'Shell Marine', 8500);
    INSERT INTO EscalaPortuaria (BarcoID, PuertoID, FechaHoraLlegada, FechaHoraSalida, Muelle) VALUES (1, v_puerto_id_singapur, TO_TIMESTAMP('2025-08-15 09:00', 'YYYY-MM-DD HH24:MI'), TO_TIMESTAMP('2025-08-17 12:00', 'YYYY-MM-DD HH24:MI'), 'T-A1') RETURNING EscalaPortuariaID INTO v_escala_id_3;
    INSERT INTO ServicioEscala (EscalaPortuariaID, ServicioID, Proveedor, Costo) VALUES (v_escala_id_3, 1, 'PSA Singapore', 1800);
    INSERT INTO Transaccion (EscalaPortuariaID, ClienteID, Monto, Fecha, EstadoPago) VALUES (v_escala_id_3, 1, 1800.00, TO_DATE('2025-08-17', 'YYYY-MM-DD'), 'Pendiente');
    DBMS_OUTPUT.PUT_LINE('Script de inserción robusta completado exitosamente.');
    COMMIT;
END;
/


-- =======================================================================================
--  [ Espacio para futuros DATOS DE PRUEBA ]
-- =======================================================================================


-- =======================================================================================
-- SECCIÓN 7: SCRIPTS DE EJECUCIÓN Y PRUEBAS
-- ---------------------------------------------------------------------------------------
-- Comandos para ejecutar y verificar la lógica implementada.
-- =======================================================================================

SET SERVEROUTPUT ON;

-- Prueba de consulta simple
SELECT
    t.TransaccionID, c.Nombre AS Cliente, b.Nombre AS Barco, p.Nombre AS Puerto, t.Monto, t.EstadoPago
FROM Transaccion t
JOIN Cliente c ON t.ClienteID = c.ClienteID
JOIN EscalaPortuaria ep ON t.EscalaPortuariaID = ep.EscalaPortuariaID
JOIN Barco b ON ep.BarcoID = b.BarcoID
JOIN Puerto p ON ep.PuertoID = p.PuertoID;

-- Prueba 1: Generar una transacción para una escala
-- Paso A: Identificar la escala a procesar
SELECT EscalaPortuariaID, NombreBarco, NombrePuerto FROM V_ESCALAS_DETALLE WHERE NombreBarco = 'Gigante del Pacífico';
-- Paso B: Ejecutar el procedimiento (usar el ID de la consulta anterior)
EXEC GENERAR_TRANSACCION_ESCALA(p_escala_id => 25);
-- Paso C: Verificar el resultado
SELECT * FROM Transaccion WHERE EscalaPortuariaID = 25;


-- Prueba 2: Asignar un nuevo tripulante
-- Paso A: Identificar el barco
SELECT BarcoID, Nombre FROM Barco WHERE Nombre = 'Carga Express';
-- Paso B: Ejecutar el procedimiento
BEGIN
  ASIGNAR_TRIPULANTE_BARCO(
      p_barco_id      => 26, -- Usar el ID de la consulta anterior
      p_nombre        => 'Ana Rodríguez',
      p_rol           => 'Cocinera',
      p_pasaporte     => 'VE654321',
      p_nacionalidad  => 'Venezolana'
  );
END;
/
-- Paso C: Verificar el resultado
SELECT * FROM Tripulacion WHERE BarcoID = 26;


-- =======================================================================================
--  [ Espacio para futuros SCRIPTS DE PRUEBA ]
-- =======================================================================================


SELECT EscalaPortuariaID, NombrePuerto FROM V_ESCALA_DETALLE WHERE BarcoID = 1;

SELECT ServicioID, Tipo FROM Servicio;



-- Tabla de Roles
CREATE TABLE Roles (
    RolID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    NombreRol VARCHAR2(50) NOT NULL UNIQUE
);

-- Tabla de Usuarios con Roles y Barco Asignado
CREATE TABLE Usuarios (
    UsuarioID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    Nombre VARCHAR2(100) NOT NULL UNIQUE,
    Password VARCHAR2(60) NOT NULL, -- Tamaño para almacenar hash de bcrypt
    RolID NUMBER,
    BarcoID NUMBER,
    CONSTRAINT fk_usuario_rol FOREIGN KEY (RolID) REFERENCES Roles(RolID),
    CONSTRAINT fk_usuario_barco FOREIGN KEY (BarcoID) REFERENCES Barco(BarcoID)
);

-- Tabla de Peticiones de Servicio
CREATE TABLE PeticionesServicio (
    PeticionID NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    EscalaPortuariaID NUMBER NOT NULL,
    ServicioID NUMBER NOT NULL,
    UsuarioID NUMBER NOT NULL, -- Capitán que hace la petición
    Estado VARCHAR2(50) DEFAULT 'Pendiente',
    FechaPeticion DATE DEFAULT SYSDATE,
    Notas VARCHAR2(500),
    CONSTRAINT fk_peticion_escala FOREIGN KEY (EscalaPortuariaID) REFERENCES EscalaPortuaria(EscalaPortuariaID),
    CONSTRAINT fk_peticion_servicio FOREIGN KEY (ServicioID) REFERENCES Servicio(ServicioID),
    CONSTRAINT fk_peticion_usuario FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);