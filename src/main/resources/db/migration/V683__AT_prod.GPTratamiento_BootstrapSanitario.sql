-- Bootstrap de catálogos productivos. Solo añade entradas ausentes; no modifica históricos.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF OBJECT_ID(N'prod.GPTratamiento', N'U') IS NULL
BEGIN
    THROW 51000, N'No está disponible el catálogo de tratamientos.', 1;
END;
GO

DECLARE @Tratamientos TABLE (
    nombre NVARCHAR(160) NOT NULL PRIMARY KEY,
    descripcion NVARCHAR(1000) NOT NULL
);

INSERT INTO @Tratamientos (nombre, descripcion)
VALUES
    (N'Evaluación y manejo · Pudrición radicular (Phytophthora) (PALTA)', N'Evaluar raíces y drenaje; ajustar riego y retirar material comprometido según evaluación agronómica.'),
    (N'Control y seguimiento · Pudrición radicular (Phytophthora) (PALTA)', N'Inspeccionar raíces y humedad del suelo; registrar respuesta a las correcciones aplicadas.'),
    (N'Evaluación y manejo · Antracnosis de palta (PALTA)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Antracnosis de palta (PALTA)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Tizón tardío de papa (PAPA)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Tizón tardío de papa (PAPA)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Rhizoctoniasis de papa (PAPA)', N'Verificar síntomas y condición del suelo; evaluar rotación, drenaje y manejo de residuos con asesoría agronómica.'),
    (N'Control y seguimiento · Rhizoctoniasis de papa (PAPA)', N'Revisar evolución del foco y efectividad del manejo de suelo y riego.'),
    (N'Evaluación y manejo · Roya común del maíz (MAIZ)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Roya común del maíz (MAIZ)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Tizón foliar del maíz (MAIZ)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Tizón foliar del maíz (MAIZ)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Antracnosis de alfalfa (ALFALFA)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Antracnosis de alfalfa (ALFALFA)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Mildiu de alfalfa (ALFALFA)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Mildiu de alfalfa (ALFALFA)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Oídio de arveja (ARVEJA)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Oídio de arveja (ARVEJA)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Fusariosis de arveja (ARVEJA)', N'Verificar síntomas y condición del suelo; evaluar rotación, drenaje y manejo de residuos con asesoría agronómica.'),
    (N'Control y seguimiento · Fusariosis de arveja (ARVEJA)', N'Revisar evolución del foco y efectividad del manejo de suelo y riego.'),
    (N'Evaluación y manejo · Roya del café (CAFE)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Roya del café (CAFE)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Ojo de gallo del café (CAFE)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Ojo de gallo del café (CAFE)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Roya de cebada (CEBADA)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Roya de cebada (CEBADA)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Mancha reticulada de cebada (CEBADA)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Mancha reticulada de cebada (CEBADA)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Abolladura del duraznero (DURAZNO)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Abolladura del duraznero (DURAZNO)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Podredumbre parda del durazno (DURAZNO)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Podredumbre parda del durazno (DURAZNO)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Antracnosis de frijol (FRIJOL)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Antracnosis de frijol (FRIJOL)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Roya del frijol (FRIJOL)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Roya del frijol (FRIJOL)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Mancha chocolate del haba (HABA)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Mancha chocolate del haba (HABA)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Roya del haba (HABA)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Roya del haba (HABA)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Mildiu de quinua (QUINUA)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Mildiu de quinua (QUINUA)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Mancha foliar de quinua (QUINUA)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Mancha foliar de quinua (QUINUA)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Roya amarilla del trigo (TRIGO)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Roya amarilla del trigo (TRIGO)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Septoriosis del trigo (TRIGO)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Septoriosis del trigo (TRIGO)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Oídio de la vid (UVA)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Oídio de la vid (UVA)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Mildiu de la vid (UVA)', N'Verificar diagnóstico, sanear tejidos cuando corresponda y evaluar controles autorizados con un especialista.'),
    (N'Control y seguimiento · Mildiu de la vid (UVA)', N'Monitorear avance de síntomas, condiciones de humedad y respuesta al manejo integrado.'),
    (N'Evaluación y manejo · Mastitis bovina (BOVINO)', N'Realizar evaluación veterinaria, medidas higiénicas y manejo individual según diagnóstico profesional.'),
    (N'Control y seguimiento · Mastitis bovina (BOVINO)', N'Control veterinario y registro de evolución, estado clínico y medidas adoptadas.'),
    (N'Evaluación y manejo · Parasitismo gastrointestinal bovino (BOVINO)', N'Solicitar diagnóstico veterinario y establecer control parasitario según evaluación profesional.'),
    (N'Control y seguimiento · Parasitismo gastrointestinal bovino (BOVINO)', N'Reevaluar animales, corrales y riesgo de reinfestación con orientación veterinaria.'),
    (N'Evaluación y manejo · Parasitismo gastrointestinal ovino (OVINO)', N'Solicitar diagnóstico veterinario y establecer control parasitario según evaluación profesional.'),
    (N'Control y seguimiento · Parasitismo gastrointestinal ovino (OVINO)', N'Reevaluar animales, corrales y riesgo de reinfestación con orientación veterinaria.'),
    (N'Evaluación y manejo · Pododermatitis ovina (OVINO)', N'Separar animales afectados y solicitar atención veterinaria; mejorar higiene y sequedad de superficies.'),
    (N'Control y seguimiento · Pododermatitis ovina (OVINO)', N'Supervisar recuperación de pezuñas, locomoción y condiciones del alojamiento.'),
    (N'Evaluación y manejo · Neumonía caprina (CAPRINO)', N'Aislar animales sintomáticos, mejorar ventilación y solicitar diagnóstico veterinario.'),
    (N'Control y seguimiento · Neumonía caprina (CAPRINO)', N'Registrar evolución respiratoria y revisar bioseguridad bajo supervisión veterinaria.'),
    (N'Evaluación y manejo · Parasitismo gastrointestinal caprino (CAPRINO)', N'Solicitar diagnóstico veterinario y establecer control parasitario según evaluación profesional.'),
    (N'Control y seguimiento · Parasitismo gastrointestinal caprino (CAPRINO)', N'Reevaluar animales, corrales y riesgo de reinfestación con orientación veterinaria.'),
    (N'Evaluación y manejo · Sarna porcina (PORCINO)', N'Verificar diagnóstico, separar animales afectados y evaluar control autorizado con un veterinario.'),
    (N'Control y seguimiento · Sarna porcina (PORCINO)', N'Comprobar respuesta al manejo, limpieza del ambiente y signos de reinfestación.'),
    (N'Evaluación y manejo · Diarrea posdestete porcina (PORCINO)', N'Aislar animales afectados; revisar agua y alimento y solicitar valoración veterinaria.'),
    (N'Control y seguimiento · Diarrea posdestete porcina (PORCINO)', N'Verificar hidratación, evolución y medidas sanitarias con un veterinario.'),
    (N'Evaluación y manejo · Salmonelosis del cuy (CUY)', N'Aislar de inmediato animales sospechosos; aplicar bioseguridad y solicitar evaluación veterinaria.'),
    (N'Control y seguimiento · Salmonelosis del cuy (CUY)', N'Registrar evolución del brote y revisar medidas de bioseguridad con veterinario.'),
    (N'Evaluación y manejo · Ectoparasitosis del cuy (CUY)', N'Verificar diagnóstico, separar animales afectados y evaluar control autorizado con un veterinario.'),
    (N'Control y seguimiento · Ectoparasitosis del cuy (CUY)', N'Comprobar respuesta al manejo, limpieza del ambiente y signos de reinfestación.'),
    (N'Evaluación y manejo · Sarna en alpacas (ALPACA)', N'Verificar diagnóstico, separar animales afectados y evaluar control autorizado con un veterinario.'),
    (N'Control y seguimiento · Sarna en alpacas (ALPACA)', N'Comprobar respuesta al manejo, limpieza del ambiente y signos de reinfestación.'),
    (N'Evaluación y manejo · Parasitismo gastrointestinal en alpacas (ALPACA)', N'Solicitar diagnóstico veterinario y establecer control parasitario según evaluación profesional.'),
    (N'Control y seguimiento · Parasitismo gastrointestinal en alpacas (ALPACA)', N'Reevaluar animales, corrales y riesgo de reinfestación con orientación veterinaria.'),
    (N'Evaluación y manejo · Sarna en llamas (LLAMA)', N'Verificar diagnóstico, separar animales afectados y evaluar control autorizado con un veterinario.'),
    (N'Control y seguimiento · Sarna en llamas (LLAMA)', N'Comprobar respuesta al manejo, limpieza del ambiente y signos de reinfestación.'),
    (N'Evaluación y manejo · Parasitismo gastrointestinal en llamas (LLAMA)', N'Solicitar diagnóstico veterinario y establecer control parasitario según evaluación profesional.'),
    (N'Control y seguimiento · Parasitismo gastrointestinal en llamas (LLAMA)', N'Reevaluar animales, corrales y riesgo de reinfestación con orientación veterinaria.'),
    (N'Evaluación y manejo · Coccidiosis aviar (GALLINA)', N'Aislar animales afectados; revisar agua y alimento y solicitar valoración veterinaria.'),
    (N'Control y seguimiento · Coccidiosis aviar (GALLINA)', N'Verificar hidratación, evolución y medidas sanitarias con un veterinario.'),
    (N'Evaluación y manejo · Coriza infecciosa aviar (GALLINA)', N'Aislar animales sintomáticos, mejorar ventilación y solicitar diagnóstico veterinario.'),
    (N'Control y seguimiento · Coriza infecciosa aviar (GALLINA)', N'Registrar evolución respiratoria y revisar bioseguridad bajo supervisión veterinaria.'),
    (N'Evaluación y manejo · Parasitismo gastrointestinal equino (EQUINO)', N'Solicitar diagnóstico veterinario y establecer control parasitario según evaluación profesional.'),
    (N'Control y seguimiento · Parasitismo gastrointestinal equino (EQUINO)', N'Reevaluar animales, corrales y riesgo de reinfestación con orientación veterinaria.'),
    (N'Evaluación y manejo · Dermatofitosis equina (EQUINO)', N'Verificar diagnóstico, separar animales afectados y evaluar control autorizado con un veterinario.'),
    (N'Control y seguimiento · Dermatofitosis equina (EQUINO)', N'Comprobar respuesta al manejo, limpieza del ambiente y signos de reinfestación.'),
    (N'Evaluación y manejo · Coccidiosis del conejo (CONEJO)', N'Aislar animales afectados; revisar agua y alimento y solicitar valoración veterinaria.'),
    (N'Control y seguimiento · Coccidiosis del conejo (CONEJO)', N'Verificar hidratación, evolución y medidas sanitarias con un veterinario.'),
    (N'Evaluación y manejo · Sarna del conejo (CONEJO)', N'Verificar diagnóstico, separar animales afectados y evaluar control autorizado con un veterinario.'),
    (N'Control y seguimiento · Sarna del conejo (CONEJO)', N'Comprobar respuesta al manejo, limpieza del ambiente y signos de reinfestación.');

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO prod.GPTratamiento (nombre, descripcion)
    SELECT S.nombre, S.descripcion
    FROM @Tratamientos S
    WHERE NOT EXISTS (
        SELECT 1 FROM prod.GPTratamiento T WITH (UPDLOCK, HOLDLOCK)
        WHERE T.nombre = S.nombre
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;
    THROW;
END CATCH;
GO
