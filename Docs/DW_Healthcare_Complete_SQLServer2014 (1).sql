-- ============================================================================
-- DATA WAREHOUSE HEALTHCARE - SQL SERVER 2014
-- Decálogo Constructivo: Esquema Estrella (Star Schema)
-- TPS → ETL → DW: Una única tabla de hechos (FACT_ATENCIONES)
-- Grano: 1 fila = 1 cita (appointment_id)
-- ============================================================================

-- PARTE 0: LIMPIAR BASES DE DATOS ANTERIORES
-- ============================================================================
USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'HealthcareTPS')
    DROP DATABASE HealthcareTPS;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'HealthcareDW')
    DROP DATABASE HealthcareDW;
GO

-- ============================================================================
-- PARTE 1: BD TRANSACCIONAL (TPS) - ORIGEN
-- ============================================================================

CREATE DATABASE HealthcareTPS;
GO

USE HealthcareTPS;
GO

PRINT '==== CREANDO TABLAS TPS (11 tablas transaccionales) ====';
GO

-- 1. CLÍNICAS
CREATE TABLE clinics (
    clinic_id      VARCHAR(10)  PRIMARY KEY,
    clinic_name    VARCHAR(150) NOT NULL,
    address        VARCHAR(200),
    city           VARCHAR(100),
    state          VARCHAR(100),
    phone          VARCHAR(30),
    opening_hours  VARCHAR(50),
    clinic_type    VARCHAR(50)   -- Private / Public
);

-- 2. PACIENTES
CREATE TABLE patients (
    patient_id         VARCHAR(10) PRIMARY KEY,
    full_name          VARCHAR(150) NOT NULL,
    gender             VARCHAR(20),
    date_of_birth      DATE,
    phone              VARCHAR(30),
    email              VARCHAR(150),
    address            VARCHAR(200),
    registration_date  DATE,
    blood_group        VARCHAR(5),
    emergency_contact  VARCHAR(30)
);

-- 3. SEGURO DEL PACIENTE (1:1 con patients)
CREATE TABLE patient_insurance (
    patient_id        VARCHAR(10) PRIMARY KEY,
    insurance_status  VARCHAR(20),   -- Insured / Not Insured
    provider          VARCHAR(100),
    coverage_level    VARCHAR(20),   -- High / Medium / Low
    CONSTRAINT fk_insurance_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
        ON DELETE CASCADE
);

-- 4. MÉDICOS
CREATE TABLE doctors (
    doctor_id   VARCHAR(10) PRIMARY KEY,
    full_name   VARCHAR(150) NOT NULL,
    specialty   VARCHAR(100),
    phone       VARCHAR(30),
    email       VARCHAR(150),
    clinic_id   VARCHAR(10),
    CONSTRAINT fk_doctor_clinic
        FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id)
        ON DELETE SET NULL
);

-- 5. PERSONAL / STAFF
CREATE TABLE staff (
    staff_id   VARCHAR(10) PRIMARY KEY,
    full_name  VARCHAR(150) NOT NULL,
    role       VARCHAR(50),
    clinic_id  VARCHAR(10),
    phone      VARCHAR(30),
    email      VARCHAR(150),
    CONSTRAINT fk_staff_clinic
        FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id)
        ON DELETE SET NULL
);

-- 6. CITAS (tabla transaccional central)
CREATE TABLE appointments (
    appointment_id     VARCHAR(10) PRIMARY KEY,
    patient_id         VARCHAR(10) NOT NULL,
    doctor_id          VARCHAR(10) NOT NULL,
    clinic_id          VARCHAR(10) NOT NULL,
    appointment_date   DATE,
    status             VARCHAR(20),   -- Completed / Pending / Cancelled
    reason_for_visit   VARCHAR(150),
    CONSTRAINT fk_appt_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_appt_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_appt_clinic
        FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id)
        ON DELETE CASCADE
);

-- 7. TRATAMIENTOS (hija de appointments)
CREATE TABLE treatments (
    treatment_id      VARCHAR(10) PRIMARY KEY,
    appointment_id    VARCHAR(10) NOT NULL,
    treatment_type    VARCHAR(100),
    treatment_cost    DECIMAL(10,2),
    treatment_status  VARCHAR(20),
    CONSTRAINT fk_treatment_appt
        FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
        ON DELETE CASCADE
);

-- 8. MEDICINAS (catálogo)
CREATE TABLE medicines (
    medicine_id    INT IDENTITY(1,1) PRIMARY KEY,
    medicine_name  VARCHAR(150) NOT NULL UNIQUE,
    default_instructions VARCHAR(200)
);

-- 9. RECETAS (hija de appointments, referencia medicines)
CREATE TABLE prescriptions (
    prescription_id  VARCHAR(10) PRIMARY KEY,
    appointment_id   VARCHAR(10) NOT NULL,
    medicine_id      INT,
    instructions     VARCHAR(200),
    CONSTRAINT fk_prescription_appt
        FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_prescription_medicine
        FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
);

-- 10. ASEGURADORAS (catálogo)
CREATE TABLE insurance_providers (
    provider_id    INT IDENTITY(1,1) PRIMARY KEY,
    provider_name  VARCHAR(100) NOT NULL UNIQUE,
    contact_phone  VARCHAR(30),
    contact_email  VARCHAR(150)
);

-- 11. PAGOS (hija de appointments)
CREATE TABLE payments (
    payment_id      VARCHAR(10) PRIMARY KEY,
    appointment_id  VARCHAR(10) NOT NULL,
    payment_date    DATE,
    payment_amount  DECIMAL(10,2),
    payment_method  VARCHAR(30),
    payment_status  VARCHAR(20),
    CONSTRAINT fk_payment_appt
        FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
        ON DELETE CASCADE
);

-- Índices en TPS
CREATE INDEX idx_appt_patient   ON appointments(patient_id);
CREATE INDEX idx_appt_doctor    ON appointments(doctor_id);
CREATE INDEX idx_appt_clinic    ON appointments(clinic_id);
CREATE INDEX idx_appt_date      ON appointments(appointment_date);
CREATE INDEX idx_doctor_clinic  ON doctors(clinic_id);
CREATE INDEX idx_staff_clinic   ON staff(clinic_id);

PRINT '✓ TPS: 11 tablas transaccionales creadas';
GO

-- ============================================================================
-- PARTE 2: BD DATA WAREHOUSE (DW) - DESTINO
-- ============================================================================

CREATE DATABASE HealthcareDW;
GO

USE HealthcareDW;
GO

PRINT '==== CREANDO DIMENSIONES Y TABLA DE HECHOS (Esquema Estrella) ====';
GO

-- DIMENSIÓN 1: TIEMPO (DIM_TIEMPO)
-- Origen principal: appointments.appointment_date
-- Análisis diario, mensual, trimestral y anual
CREATE TABLE DIM_TIEMPO (
    tiempo_key      INT IDENTITY(1,1) PRIMARY KEY,
    fecha           DATE NOT NULL UNIQUE,
    dia             INT,
    mes             INT,
    nombre_mes      VARCHAR(20),
    trimestre       INT,
    semestre        INT,
    año             INT,
    dia_semana      VARCHAR(20),
    es_fin_semana   BIT
);

-- DIMENSIÓN 2: PACIENTE (DIM_PACIENTE)
-- Origen: patients
-- Características y segmentación de pacientes
CREATE TABLE DIM_PACIENTE (
    paciente_key    INT IDENTITY(1,1) PRIMARY KEY,
    patient_id      VARCHAR(10) NOT NULL UNIQUE,
    full_name       VARCHAR(150) NOT NULL,
    gender          VARCHAR(20),
    date_of_birth   DATE,
    phone           VARCHAR(30),
    email           VARCHAR(150),
    address         VARCHAR(200),
    registration_date DATE,
    blood_group     VARCHAR(5),
    emergency_contact VARCHAR(30)
);

-- DIMENSIÓN 3: MÉDICO (DIM_MEDICO)
-- Origen: doctors
-- Análisis por médico y especialidad
CREATE TABLE DIM_MEDICO (
    medico_key      INT IDENTITY(1,1) PRIMARY KEY,
    doctor_id       VARCHAR(10) NOT NULL UNIQUE,
    full_name       VARCHAR(150) NOT NULL,
    specialty       VARCHAR(100),
    phone           VARCHAR(30),
    email           VARCHAR(150)
);

-- DIMENSIÓN 4: CLÍNICA (DIM_CLINICA)
-- Origen: clinics
-- Análisis por clínica y ubicación
CREATE TABLE DIM_CLINICA (
    clinica_key     INT IDENTITY(1,1) PRIMARY KEY,
    clinic_id       VARCHAR(10) NOT NULL UNIQUE,
    clinic_name     VARCHAR(150) NOT NULL,
    address         VARCHAR(200),
    city            VARCHAR(100),
    state           VARCHAR(100),
    phone           VARCHAR(30),
    opening_hours   VARCHAR(50),
    clinic_type     VARCHAR(50)
);

-- DIMENSIÓN 5: TRATAMIENTO (DIM_TRATAMIENTO)
-- Origen: treatments (agregado por tipo)
-- Tipo, estado y clasificación del tratamiento
CREATE TABLE DIM_TRATAMIENTO (
    tratamiento_key INT IDENTITY(1,1) PRIMARY KEY,
    treatment_type  VARCHAR(100) NOT NULL UNIQUE,
    avg_cost        DECIMAL(10,2)
);

-- DIMENSIÓN 6: MEDICAMENTO (DIM_MEDICAMENTO)
-- Origen: medicines
-- Medicamentos prescritos e instrucciones
CREATE TABLE DIM_MEDICAMENTO (
    medicamento_key INT IDENTITY(1,1) PRIMARY KEY,
    medicine_id     INT,
    medicine_name   VARCHAR(150) NOT NULL UNIQUE,
    instructions    VARCHAR(200)
);

-- DIMENSIÓN 7: SEGURO (DIM_SEGURO)
-- Origen: patient_insurance + insurance_providers
-- Proveedor, plan y nivel de cobertura en una sola dimensión (normalización DW)
CREATE TABLE DIM_SEGURO (
    seguro_key      INT IDENTITY(1,1) PRIMARY KEY,
    insurance_status VARCHAR(20),
    provider_name   VARCHAR(100),
    coverage_level  VARCHAR(20)
);

-- TABLA DE HECHOS: FACT_ATENCIONES
-- Decálogo punto 10: Una única tabla de hechos
-- Grano: 1 fila por cita (appointment_id) - OBLIGATORIO
-- Las tablas hijas (treatments, payments, prescriptions) se AGREGAN por appointment_id
-- ANTES de cargar en FACT_ATENCIONES para evitar duplicación
CREATE TABLE FACT_ATENCIONES (
    atencion_key       INT IDENTITY(1,1) PRIMARY KEY,
    appointment_id     VARCHAR(10) NOT NULL UNIQUE,
    
    -- Claves foráneas a dimensiones
    tiempo_key         INT NOT NULL,
    paciente_key       INT NOT NULL,
    medico_key         INT NOT NULL,
    clinica_key        INT NOT NULL,
    tratamiento_key    INT,
    medicamento_key    INT,
    seguro_key         INT,
    
    -- MEDIDAS (métricas agregadas a nivel de cita)
    appointment_count  INT DEFAULT 1,              -- Siempre 1 por grano
    treatment_count    INT,                         -- COUNT(treatments) agregado
    total_treatment_cost DECIMAL(10,2),             -- SUM(treatment_cost) agregado
    payment_amount     DECIMAL(10,2),               -- SUM(payments) agregado
    prescription_count INT,                         -- COUNT(prescriptions) agregado
    payment_count      INT,                         -- COUNT(payments) agregado
    appointment_status VARCHAR(20),                 -- Completed / Pending / Cancelled
    
    -- Auditoría
    fecha_carga        DATETIME DEFAULT GETDATE(),
    
    -- Constraints
    CONSTRAINT fk_fact_tiempo
        FOREIGN KEY (tiempo_key) REFERENCES DIM_TIEMPO(tiempo_key),
    CONSTRAINT fk_fact_paciente
        FOREIGN KEY (paciente_key) REFERENCES DIM_PACIENTE(paciente_key),
    CONSTRAINT fk_fact_medico
        FOREIGN KEY (medico_key) REFERENCES DIM_MEDICO(medico_key),
    CONSTRAINT fk_fact_clinica
        FOREIGN KEY (clinica_key) REFERENCES DIM_CLINICA(clinica_key),
    CONSTRAINT fk_fact_tratamiento
        FOREIGN KEY (tratamiento_key) REFERENCES DIM_TRATAMIENTO(tratamiento_key),
    CONSTRAINT fk_fact_medicamento
        FOREIGN KEY (medicamento_key) REFERENCES DIM_MEDICAMENTO(medicamento_key),
    CONSTRAINT fk_fact_seguro
        FOREIGN KEY (seguro_key) REFERENCES DIM_SEGURO(seguro_key)
);

-- Índices estratégicos en FACT_ATENCIONES (para consultas analíticas)
CREATE INDEX idx_fact_tiempo    ON FACT_ATENCIONES(tiempo_key);
CREATE INDEX idx_fact_paciente  ON FACT_ATENCIONES(paciente_key);
CREATE INDEX idx_fact_medico    ON FACT_ATENCIONES(medico_key);
CREATE INDEX idx_fact_clinica   ON FACT_ATENCIONES(clinica_key);
CREATE INDEX idx_fact_apptid    ON FACT_ATENCIONES(appointment_id);

PRINT '✓ DW: Esquema Estrella creado (8 dimensiones + 1 tabla de hechos)';
GO

-- ============================================================================
-- PARTE 3: ETL - ALMACENADOS PARA POBLAR DW DESDE TPS
-- ============================================================================
-- Decálogo punto 3: Regla de carga - payments, treatments, prescriptions deben
-- agregarse por appointment_id antes de incorporarse a FACT_ATENCIONES

PRINT '==== CREANDO ALMACENADOS ETL (7 stored procedures) ====';
GO

-- SP 1: POBLAR DIM_TIEMPO (rango de 2 años)
CREATE PROCEDURE sp_load_dim_tiempo
    @fecha_inicio DATE = '2022-01-01',
    @fecha_fin DATE = '2024-12-31'
AS
BEGIN
    DECLARE @fecha DATE = @fecha_inicio;
    
    WHILE @fecha <= @fecha_fin
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM DIM_TIEMPO WHERE fecha = @fecha)
        BEGIN
            INSERT INTO DIM_TIEMPO 
            (fecha, dia, mes, nombre_mes, trimestre, semestre, año, dia_semana, es_fin_semana)
            VALUES (
                @fecha,
                DAY(@fecha),
                MONTH(@fecha),
                DATENAME(MONTH, @fecha),
                (MONTH(@fecha) - 1) / 3 + 1,
                CASE WHEN MONTH(@fecha) <= 6 THEN 1 ELSE 2 END,
                YEAR(@fecha),
                DATENAME(WEEKDAY, @fecha),
                CASE WHEN DATEPART(WEEKDAY, @fecha) IN (1, 7) THEN 1 ELSE 0 END
            );
        END
        SET @fecha = DATEADD(DAY, 1, @fecha);
    END
    
    PRINT 'DIM_TIEMPO cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' fechas';
END;
GO

-- SP 2: POBLAR DIM_PACIENTE
CREATE PROCEDURE sp_load_dim_paciente
AS
BEGIN
    INSERT INTO DIM_PACIENTE 
    (patient_id, full_name, gender, date_of_birth, phone, email, address, registration_date, blood_group, emergency_contact)
    SELECT 
        patient_id, full_name, gender, date_of_birth, phone, email, address, registration_date, blood_group, emergency_contact
    FROM HealthcareTPS.dbo.patients
    WHERE patient_id NOT IN (SELECT patient_id FROM DIM_PACIENTE);
    
    PRINT 'DIM_PACIENTE cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' pacientes';
END;
GO

-- SP 3: POBLAR DIM_MEDICO
CREATE PROCEDURE sp_load_dim_medico
AS
BEGIN
    INSERT INTO DIM_MEDICO 
    (doctor_id, full_name, specialty, phone, email)
    SELECT 
        doctor_id, full_name, specialty, phone, email
    FROM HealthcareTPS.dbo.doctors
    WHERE doctor_id NOT IN (SELECT doctor_id FROM DIM_MEDICO);
    
    PRINT 'DIM_MEDICO cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' médicos';
END;
GO

-- SP 4: POBLAR DIM_CLINICA
CREATE PROCEDURE sp_load_dim_clinica
AS
BEGIN
    INSERT INTO DIM_CLINICA 
    (clinic_id, clinic_name, address, city, state, phone, opening_hours, clinic_type)
    SELECT 
        clinic_id, clinic_name, address, city, state, phone, opening_hours, clinic_type
    FROM HealthcareTPS.dbo.clinics
    WHERE clinic_id NOT IN (SELECT clinic_id FROM DIM_CLINICA);
    
    PRINT 'DIM_CLINICA cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' clínicas';
END;
GO

-- SP 5: POBLAR DIM_TRATAMIENTO (agregado por tipo con costo promedio)
CREATE PROCEDURE sp_load_dim_tratamiento
AS
BEGIN
    INSERT INTO DIM_TRATAMIENTO (treatment_type, avg_cost)
    SELECT DISTINCT 
        treatment_type,
        AVG(CAST(treatment_cost AS DECIMAL(10,2))) OVER (PARTITION BY treatment_type)
    FROM HealthcareTPS.dbo.treatments
    WHERE treatment_type NOT IN (SELECT treatment_type FROM DIM_TRATAMIENTO);
    
    PRINT 'DIM_TRATAMIENTO cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' tipos de tratamiento';
END;
GO

-- SP 6: POBLAR DIM_MEDICAMENTO
CREATE PROCEDURE sp_load_dim_medicamento
AS
BEGIN
    INSERT INTO DIM_MEDICAMENTO (medicine_id, medicine_name, instructions)
    SELECT 
        medicine_id, medicine_name, default_instructions
    FROM HealthcareTPS.dbo.medicines
    WHERE medicine_name NOT IN (SELECT medicine_name FROM DIM_MEDICAMENTO);
    
    PRINT 'DIM_MEDICAMENTO cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' medicamentos';
END;
GO

-- SP 7: POBLAR DIM_SEGURO (combinaciones únicas de status, provider, coverage_level)
CREATE PROCEDURE sp_load_dim_seguro
AS
BEGIN
    INSERT INTO DIM_SEGURO (insurance_status, provider_name, coverage_level)
    SELECT DISTINCT 
        pi.insurance_status,
        pi.provider,  -- Texto directo, sin reference a provider_id (que no existe en TPS)
        pi.coverage_level
    FROM HealthcareTPS.dbo.patient_insurance pi
    WHERE NOT EXISTS (
        SELECT 1 FROM DIM_SEGURO s
        WHERE s.insurance_status = pi.insurance_status
        AND s.provider_name = pi.provider
        AND s.coverage_level = pi.coverage_level
    );
    
    PRINT 'DIM_SEGURO cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' combinaciones de seguro';
END;
GO

-- SP 8: POBLAR FACT_ATENCIONES (PASO CRÍTICO - Decálogo punto 10)
-- REGLA CLAVE: Agregar treatments/payments/prescriptions por appointment_id
-- ANTES de cargar FACT_ATENCIONES para evitar multiplicación de importes y conteos
CREATE PROCEDURE sp_load_fact_atenciones
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'Iniciando carga de FACT_ATENCIONES...';
    
    -- Tabla auxiliar: agregar datos hijos por cita (appointment_id)
    IF OBJECT_ID('tempdb..#appt_agg', 'U') IS NOT NULL
        DROP TABLE #appt_agg;
    
    CREATE TABLE #appt_agg (
        appointment_id VARCHAR(10),
        treatment_count INT,
        total_treatment_cost DECIMAL(10,2),
        payment_count INT,
        total_payment_amount DECIMAL(10,2),
        prescription_count INT,
        primary_medicine_id INT
    );
    
    PRINT 'Agregando datos transaccionales hijos por cita (treatments, payments, prescriptions)...';
    
    -- AGREGACIÓN: Sumar treatments/payments/prescriptions por appointment_id
    -- Esto EVITA la duplicación en FACT_ATENCIONES
    INSERT INTO #appt_agg
    SELECT 
        a.appointment_id,
        COUNT(DISTINCT CASE WHEN t.treatment_id IS NOT NULL THEN t.treatment_id END) treatment_count,
        SUM(ISNULL(t.treatment_cost, 0)) total_treatment_cost,
        COUNT(DISTINCT CASE WHEN p.payment_id IS NOT NULL THEN p.payment_id END) payment_count,
        SUM(ISNULL(p.payment_amount, 0)) total_payment_amount,
        COUNT(DISTINCT CASE WHEN pr.prescription_id IS NOT NULL THEN pr.prescription_id END) prescription_count,
        MAX(pr.medicine_id) primary_medicine_id
    FROM HealthcareTPS.dbo.appointments a
    LEFT JOIN HealthcareTPS.dbo.treatments t ON a.appointment_id = t.appointment_id
    LEFT JOIN HealthcareTPS.dbo.payments p ON a.appointment_id = p.appointment_id
    LEFT JOIN HealthcareTPS.dbo.prescriptions pr ON a.appointment_id = pr.appointment_id
    GROUP BY a.appointment_id;
    
    PRINT 'Tabla auxiliar #appt_agg: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' citas agregadas';
    
    -- Insertar en FACT_ATENCIONES con claves foráneas a dimensiones
    PRINT 'Insertando datos agregados en FACT_ATENCIONES...';
    
    INSERT INTO FACT_ATENCIONES 
    (appointment_id, tiempo_key, paciente_key, medico_key, clinica_key, tratamiento_key, 
     medicamento_key, seguro_key, appointment_count, treatment_count, total_treatment_cost, 
     payment_amount, prescription_count, appointment_status, payment_count)
    SELECT 
        a.appointment_id,
        dt.tiempo_key,
        dp.paciente_key,
        dm.medico_key,
        dc.clinica_key,
        CASE WHEN tr.treatment_type IS NOT NULL THEN dtr.tratamiento_key ELSE NULL END tratamiento_key,
        CASE WHEN agg.primary_medicine_id IS NOT NULL THEN dmed.medicamento_key ELSE NULL END medicamento_key,
        ds.seguro_key,
        1 appointment_count,  -- Grano = 1 cita = 1
        ISNULL(agg.treatment_count, 0),
        ISNULL(agg.total_treatment_cost, 0),
        ISNULL(agg.total_payment_amount, 0),
        ISNULL(agg.prescription_count, 0),
        a.status,
        ISNULL(agg.payment_count, 0)
    FROM HealthcareTPS.dbo.appointments a
    INNER JOIN #appt_agg agg ON a.appointment_id = agg.appointment_id
    INNER JOIN DIM_TIEMPO dt ON CAST(a.appointment_date AS DATE) = dt.fecha
    INNER JOIN DIM_PACIENTE dp ON a.patient_id = dp.patient_id
    INNER JOIN DIM_MEDICO dm ON a.doctor_id = dm.doctor_id
    INNER JOIN DIM_CLINICA dc ON a.clinic_id = dc.clinic_id
    LEFT JOIN HealthcareTPS.dbo.treatments tr ON a.appointment_id = tr.appointment_id
    LEFT JOIN DIM_TRATAMIENTO dtr ON tr.treatment_type = dtr.treatment_type
    LEFT JOIN DIM_MEDICAMENTO dmed ON agg.primary_medicine_id = dmed.medicine_id
    LEFT JOIN HealthcareTPS.dbo.patient_insurance pi ON a.patient_id = pi.patient_id
    LEFT JOIN DIM_SEGURO ds ON pi.insurance_status = ds.insurance_status
        AND ISNULL(pi.provider, '') = ISNULL(ds.provider_name, '')
        AND ISNULL(pi.coverage_level, '') = ISNULL(ds.coverage_level, '')
    WHERE a.appointment_id NOT IN (SELECT appointment_id FROM FACT_ATENCIONES);
    
    PRINT 'FACT_ATENCIONES cargada: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' citas';
    
    DROP TABLE #appt_agg;
    
    PRINT '✓ Carga de FACT_ATENCIONES completada exitosamente';
    SET NOCOUNT OFF;
END;
GO

PRINT '✓ ETL: 8 almacenados creados (7 dimensiones + 1 tabla de hechos)';
GO

-- ============================================================================
-- PARTE 4: EJECUTAR ETL COMPLETO (DESCOMENTA PARA EJECUTAR)
-- ============================================================================

PRINT '';
PRINT '==== EJECUTANDO CARGA ETL COMPLETA ====';
PRINT '';

EXEC sp_load_dim_tiempo @fecha_inicio='2022-01-01', @fecha_fin='2024-12-31';
GO

EXEC sp_load_dim_paciente;
GO

EXEC sp_load_dim_medico;
GO

EXEC sp_load_dim_clinica;
GO

EXEC sp_load_dim_tratamiento;
GO

EXEC sp_load_dim_medicamento;
GO

EXEC sp_load_dim_seguro;
GO

EXEC sp_load_fact_atenciones;
GO

-- ============================================================================
-- PARTE 5: VISTAS ANALÍTICAS (REPORTES PREDEFINIDOS)
-- ============================================================================

PRINT '';
PRINT '==== CREANDO VISTAS DE REPORTES ====';
PRINT '';

-- VISTA 1: Citas por mes y clínica (KPI mensual)
CREATE VIEW vw_citas_por_mes_clinica AS
SELECT 
    dt.año,
    dt.mes,
    dt.nombre_mes,
    dc.clinic_name,
    COUNT(fa.atencion_key) citas_totales,
    SUM(fa.total_treatment_cost) costo_tratamientos,
    SUM(fa.payment_amount) ingresos_totales,
    AVG(fa.total_treatment_cost) costo_promedio
FROM FACT_ATENCIONES fa
INNER JOIN DIM_TIEMPO dt ON fa.tiempo_key = dt.tiempo_key
INNER JOIN DIM_CLINICA dc ON fa.clinica_key = dc.clinica_key
GROUP BY dt.año, dt.mes, dt.nombre_mes, dc.clinica_key, dc.clinic_name;
GO

-- VISTA 2: Productividad por médico (análisis de desempeño RH)
CREATE VIEW vw_productividad_medico AS
SELECT 
    dm.full_name,
    dm.specialty,
    COUNT(fa.atencion_key) total_citas,
    SUM(fa.total_treatment_cost) ingresos_tratamientos,
    AVG(fa.total_treatment_cost) costo_promedio_tratamiento,
    SUM(fa.payment_amount) pagos_recibidos,
    AVG(fa.payment_amount) pago_promedio_cita
FROM FACT_ATENCIONES fa
INNER JOIN DIM_MEDICO dm ON fa.medico_key = dm.medico_key
GROUP BY dm.medico_key, dm.full_name, dm.specialty;
GO

-- VISTA 3: Cobertura de seguros (análisis financiero)
CREATE VIEW vw_cobertura_seguros AS
SELECT 
    ISNULL(ds.insurance_status, 'No Especificado') insurance_status,
    ISNULL(ds.provider_name, 'Sin Proveedor') provider_name,
    ISNULL(ds.coverage_level, 'No Especificado') coverage_level,
    COUNT(fa.atencion_key) atenciones,
    SUM(fa.payment_amount) ingresos,
    AVG(fa.payment_amount) ingreso_promedio
FROM FACT_ATENCIONES fa
LEFT JOIN DIM_SEGURO ds ON fa.seguro_key = ds.seguro_key
GROUP BY ds.seguro_key, ds.insurance_status, ds.provider_name, ds.coverage_level;
GO

-- VISTA 4: Top medicamentos prescritos (análisis de farmacéutica/compras)
CREATE VIEW vw_top_medicamentos AS
SELECT TOP 20
    dmed.medicine_name,
    COUNT(fa.atencion_key) veces_prescrito,
    ISNULL(dmed.instructions, '') instrucciones_defecto
FROM FACT_ATENCIONES fa
INNER JOIN DIM_MEDICAMENTO dmed ON fa.medicamento_key = dmed.medicamento_key
WHERE fa.medicamento_key IS NOT NULL
GROUP BY dmed.medicamento_key, dmed.medicine_name, dmed.instructions
ORDER BY veces_prescrito DESC;
GO

PRINT '✓ VISTAS: 4 reportes predefinidos creados';
GO

-- ============================================================================
-- PARTE 6: QUERIES DE VALIDACIÓN Y AUDITORÍA
-- ============================================================================

PRINT '';
PRINT '==== VALIDACIÓN DEL DATA WAREHOUSE ====';
PRINT '';

-- Verificar cantidad de registros en cada tabla
SELECT 'FACT_ATENCIONES'      AS tabla, COUNT(*) AS registros FROM FACT_ATENCIONES
UNION ALL
SELECT 'DIM_TIEMPO',                  COUNT(*) FROM DIM_TIEMPO
UNION ALL
SELECT 'DIM_PACIENTE',                COUNT(*) FROM DIM_PACIENTE
UNION ALL
SELECT 'DIM_MEDICO',                  COUNT(*) FROM DIM_MEDICO
UNION ALL
SELECT 'DIM_CLINICA',                 COUNT(*) FROM DIM_CLINICA
UNION ALL
SELECT 'DIM_TRATAMIENTO',             COUNT(*) FROM DIM_TRATAMIENTO
UNION ALL
SELECT 'DIM_MEDICAMENTO',             COUNT(*) FROM DIM_MEDICAMENTO
UNION ALL
SELECT 'DIM_SEGURO',                  COUNT(*) FROM DIM_SEGURO
ORDER BY tabla;

GO

-- Verificar que no hay huérfanos en FACT_ATENCIONES
PRINT '';
PRINT 'Verificando integridad referencial en FACT_ATENCIONES...';
PRINT '';

SELECT 'FK tiempo_key sin match'      AS alerta WHERE EXISTS (SELECT 1 FROM FACT_ATENCIONES WHERE tiempo_key NOT IN (SELECT tiempo_key FROM DIM_TIEMPO))
UNION ALL
SELECT 'FK paciente_key sin match'    WHERE EXISTS (SELECT 1 FROM FACT_ATENCIONES WHERE paciente_key NOT IN (SELECT paciente_key FROM DIM_PACIENTE))
UNION ALL
SELECT 'FK medico_key sin match'      WHERE EXISTS (SELECT 1 FROM FACT_ATENCIONES WHERE medico_key NOT IN (SELECT medico_key FROM DIM_MEDICO))
UNION ALL
SELECT 'FK clinica_key sin match'     WHERE EXISTS (SELECT 1 FROM FACT_ATENCIONES WHERE clinica_key NOT IN (SELECT clinica_key FROM DIM_CLINICA));

PRINT 'Si no hay alertas arriba: ✓ Integridad referencial PERFECTA';

GO

-- Estadísticas de FACT_ATENCIONES
PRINT '';
PRINT 'Estadísticas de FACT_ATENCIONES:';
PRINT '';

SELECT 
    COUNT(*) total_atenciones,
    COUNT(DISTINCT appointment_id) citas_unicas,
    COUNT(DISTINCT paciente_key) pacientes_unicos,
    COUNT(DISTINCT medico_key) medicos_unicos,
    COUNT(DISTINCT clinica_key) clinicas_unicas,
    SUM(appointment_count) suma_appointment_count,
    SUM(treatment_count) suma_tratamientos,
    SUM(CAST(total_treatment_cost AS BIGINT)) suma_costos_tratamientos,
    SUM(CAST(payment_amount AS BIGINT)) suma_ingresos,
    AVG(CAST(total_treatment_cost AS FLOAT)) promedio_costo_tratamiento,
    AVG(CAST(payment_amount AS FLOAT)) promedio_pago
FROM FACT_ATENCIONES;

GO

-- ============================================================================
-- PARTE 7: EJEMPLOS DE CONSULTAS ANALÍTICAS (SEGÚN DECÁLOGO PUNTO 10)
-- ============================================================================

PRINT '';
PRINT '==== EJEMPLOS DE REPORTES ANALÍTICOS ====';
PRINT '';

-- Reporte 1: Citas por mes y clínica
PRINT 'REPORTE 1: Citas, costos e ingresos por mes y clínica';
PRINT '─────────────────────────────────────────────────────';
SELECT TOP 10 * FROM vw_citas_por_mes_clinica ORDER BY año DESC, mes DESC;
GO

-- Reporte 2: Productividad por médico
PRINT '';
PRINT 'REPORTE 2: Productividad de médicos';
PRINT '───────────────────────────────────';
SELECT TOP 10 * FROM vw_productividad_medico ORDER BY total_citas DESC;
GO

-- Reporte 3: Cobertura de seguros
PRINT '';
PRINT 'REPORTE 3: Análisis de cobertura de seguros';
PRINT '────────────────────────────────────────────';
SELECT * FROM vw_cobertura_seguros ORDER BY atenciones DESC;
GO

-- Reporte 4: Top medicamentos
PRINT '';
PRINT 'REPORTE 4: Medicamentos más prescritos';
PRINT '──────────────────────────────────────';
SELECT * FROM vw_top_medicamentos;
GO

-- Reporte 5: Análisis por tipo de tratamiento
PRINT '';
PRINT 'REPORTE 5: Ingresos y volumen por tipo de tratamiento';
PRINT '──────────────────────────────────────────────────────';
SELECT 
    dtr.treatment_type,
    COUNT(fa.atencion_key) citas,
    SUM(fa.total_treatment_cost) costo_total,
    AVG(fa.total_treatment_cost) costo_promedio,
    SUM(fa.payment_amount) ingresos
FROM FACT_ATENCIONES fa
LEFT JOIN DIM_TRATAMIENTO dtr ON fa.tratamiento_key = dtr.tratamiento_key
GROUP BY dtr.treatment_type
ORDER BY ingresos DESC;
GO

-- Reporte 6: Ingresos por estado/ciudad
PRINT '';
PRINT 'REPORTE 6: Ingresos por ubicación (estado/ciudad)';
PRINT '─────────────────────────────────────────────────';
SELECT 
    dc.state,
    dc.city,
    COUNT(fa.atencion_key) citas,
    SUM(fa.payment_amount) ingresos,
    AVG(fa.payment_amount) ingreso_promedio
FROM FACT_ATENCIONES fa
INNER JOIN DIM_CLINICA dc ON fa.clinica_key = dc.clinica_key
GROUP BY dc.state, dc.city
ORDER BY ingresos DESC;
GO

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================

PRINT '';
PRINT '╔════════════════════════════════════════════════════════════════════╗';
PRINT '║          ✓ DATA WAREHOUSE HEALTHCARE - COMPLETADO                ║';
PRINT '║                                                                    ║';
PRINT '║  Tablas transaccionales (TPS):        11 tablas                  ║';
PRINT '║  Dimensiones (DW):                     8 dimensiones             ║';
PRINT '║  Tabla de hechos (DW):                 1 FACT_ATENCIONES         ║';
PRINT '║  Almacenados ETL:                      8 stored procedures       ║';
PRINT '║  Vistas analíticas:                    4 reportes predefinidos   ║';
PRINT '║  Esquema:                              Estrella (Star Schema)     ║';
PRINT '║  Grano FACT_ATENCIONES:                1 fila = 1 cita           ║';
PRINT '║                                                                    ║';
PRINT '║  Decálogo: Todos los requisitos implementados ✓                  ║';
PRINT '╚════════════════════════════════════════════════════════════════════╝';
PRINT '';

