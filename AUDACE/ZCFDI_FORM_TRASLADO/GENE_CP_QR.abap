CHECK is_data-idccp IS NOT INITIAL.

qr_cp = |https://verificacfdi.facturaelectronica.sat.gob.mx/verificaccp/default.aspx?| &&
|IdCCP={ is_data-idccp }| &&
|&FechaOrig={ is_data-fecha_emision }| &&
|&FechaTimb={ is_data-fecha_timbrado DATE = ISO }T{ is_data-hora_timbrado TIME = ISO }|.
