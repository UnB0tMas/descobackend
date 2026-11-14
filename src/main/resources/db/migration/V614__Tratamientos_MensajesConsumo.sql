-- DESCO / 2026-11-06 / AL-03: rechazos de consumo comprensibles para el usuario.
-- Ejemplo: utilizar más de lo entregado responde 400 sin guardar tratamiento ni consumo.
INSERT config.MensajeUsuario(texto_origen,mensaje,codigo_error,http_error)
SELECT X.texto,X.texto,'CONSUMO_TECNICO_NO_VALIDO',400
FROM (VALUES
 (N'Indique una cantidad utilizada válida.'),
 (N'El producto entregado no corresponde al responsable o a la UOT seleccionada.'),
 (N'La solicitud ya tiene otro consumo registrado.'),
 (N'La cantidad supera el producto entregado pendiente de uso.'),
 (N'Seleccione el producto entregado y su cantidad utilizada.'),
 (N'El caso no pertenece a la UOT de trabajo.'),
 (N'Seleccione el producto entregado registrado en la solicitud.')
) X(texto)
WHERE NOT EXISTS(SELECT 1 FROM config.MensajeUsuario M WHERE M.texto_origen=X.texto);
GO
