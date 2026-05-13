ENHANCEMENT 1  ZXFUNDS_CHECK_FI.    "active version
*
  IF ( sy-tcode = 'MIGO' OR sy-tcode = 'MIGO_GI' ) AND ( sy-ucomm = 'OK_POST1' OR sy-ucomm = 'OK_POST' ).
    DATA: lv_auart TYPE AUFART,
          lv_hkont TYPE HKONT.
    CLEAR:  lv_auart, lv_hkont.
    IMPORT tipo_orden TO lv_auart FROM MEMORY ID 'Z_AUART_MIGO'.
    IF sy-subrc = 0.

      READ TABLE T_FMIFIIT INDEX 1 INTO DATA(ls_fmifiit).
      IF SY-SUBRC = 0.

        "Obtenemos la cuenta de mayor guardada anteriormente antes de cambiarla por la pospre
        IMPORT cuenta_mayor TO lv_hkont FROM MEMORY ID 'Z_HKONT_MIGO'.
        IF sy-subrc = 0.
          SELECT SINGLE destino FROM zfit_cta_sust
            INTO @DATA(lv_cta_destino)
            WHERE
              hkont       = @lv_hkont AND
              kostl       = @ls_fmifiit-fistl AND
              auart       = @lv_auart.
          IF sy-subrc = 0.
            "Cambiamos el check para que no valide presupuesto.
            i_check_funds = abap_false.
          ENDIF.
       ENDIF.
      ENDIF.

    ELSE.
      "Mensaje de no se pudo recuperar la clase cuenta.
      MESSAGE 'No se pudo recuperar la clase de cuenta' TYPE 'S' DISPLAY LIKE 'W'.
    ENDIF.
  ENDIF.
ENDENHANCEMENT.