CHECK is_data-idccp IS NOT INITIAL.

*** INICIO MODIF. - 3503 - 08/12/2025 - PTECHABAP01
*DATA(fecha_orig) = is_data-fecha_emision.
READ TABLE gt_ubicacion INTO DATA(ls_ubicacion) WITH KEY tipo_ubicacion = 'Origen'.
IF sy-subrc = 0.
  DATA(fecha_orig) =
    |{ ls_ubicacion-fecha(4) }-{ ls_ubicacion-fecha+4(2) }-| &&
    |{ ls_ubicacion-fecha+6(2) }T| &&
    |{ ls_ubicacion-hora(2) }:{ ls_ubicacion-hora+2(2) }:| &&
    |{ ls_ubicacion-hora+4(2) }|.
ENDIF.
*** FIN MODIF.    - 3503 - 08/12/2025 - PTECHABAP01
CONDENSE fecha_orig NO-GAPS.

qr_cp = |https://verificacfdi.facturaelectronica.sat.gob.mx/verificaccp/default.aspx?| &&
|IdCCP={ is_data-idccp }| &&
|&FechaOrig={ fecha_orig }| &&
|&FechaTimb={ is_data-fecha_timbrado DATE = ISO }T{ is_data-hora_timbrado TIME = ISO }|.
