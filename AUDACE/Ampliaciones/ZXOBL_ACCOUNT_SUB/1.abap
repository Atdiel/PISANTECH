ENHANCEMENT 1  ZXOBL_ACCOUNT_SUB.    "active version
*
*** inicio MODIF. - <ID_requrimiento> - <Fecha_Mod> - <User>
    "Filtramos que solo sea por la MIGO o MIGO_GI y despues de presionar uno de estos botones
    IF ( sy-tcode = 'MIGO' OR sy-tcode = 'MIGO_GI' ) AND ( sy-ucomm = 'OK_POST1' OR sy-ucomm = 'OK_POST' ).
      LOOP AT T_ACCIT REFERENCE INTO DATA(lo_accit) WHERE ktosl = 'GBB' AND shkzg = 'S'.

        IF lo_accit->bwart = '261' AND lo_accit->aufnr IS NOT INITIAL.
          SELECT SINGLE auart, objnr FROM aufk
            INTO @DATA(ls_aufk)
            WHERE
              aufnr   = @lo_accit->aufnr.
          IF sy-subrc <> 0. CONTINUE. ENDIF.

          EXPORT tipo_orden = ls_aufk-auart TO MEMORY ID 'Z_AUART_MIGO'.

          SELECT SINGLE kostl FROM cobrb
            INTO @DATA(lv_kostl)
            WHERE
              objnr   = @ls_aufk-objnr AND
              konty   = 'KS'.
          IF sy-subrc <> 0. CONTINUE. ENDIF.

          SELECT SINGLE pospre FROM zfit_cta_sust
            INTO @DATA(lv_pospre)
            WHERE
              hkont       = @lo_accit->hkont AND
              kostl       = @lv_kostl AND
              auart       = @ls_aufk-auart.
          IF sy-subrc = 0.
            "Se guarda en memoria para un uso posterior
            EXPORT cuenta_mayor = lo_accit->hkont TO MEMORY ID 'Z_HKONT_MIGO'.
            "Se sustituye por la posicion presupuestari def. por el usuario
            lo_accit->hkont = lv_pospre.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.
*** FIN MODIF.    - <ID_requrimiento> - <Fecha_Mod> - <User>
ENDENHANCEMENT.