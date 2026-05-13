ENHANCEMENT 1  ZENHFI_SUSTITUCION_ACC.    "active version
*
IF sy-tcode = 'KO88' OR sy-tcode = 'KO8G'.
    DATA lt_copy_acdoc TYPE finst_acdoc_item.

    APPEND LINES OF ct_acdoc_items TO lt_copy_acdoc.
    DELETE lt_copy_acdoc WHERE aufnr IS INITIAL.
    READ TABLE lt_copy_acdoc INDEX 1 INTO DATA(ls_acdoc).

    SELECT SINGLE auart, objnr FROM aufk
      INTO @DATA(ls_aufk)
      WHERE
        aufnr   = @ls_acdoc-aufnr.

    SELECT SINGLE kostl FROM cobrb
      INTO @DATA(lv_kostl)
      WHERE
        objnr   = @ls_aufk-objnr AND
        konty   = 'KS'.

    LOOP AT ct_acdoc_items REFERENCE INTO DATA(lo_ct_acdoc). "WHERE aufnr = ls_acdoc-aufnr.
      SELECT SINGLE destino FROM zfit_cta_sust
        INTO @DATA(lv_cta_destino)
        WHERE
          hkont       = @lo_ct_acdoc->hkont AND
          kostl       = @lv_kostl AND
          auart       = @ls_aufk-auart.
      IF sy-subrc = 0.
        lo_ct_acdoc->hkont = lv_cta_destino.
        lo_ct_acdoc->gkont = lv_cta_destino.
      ENDIF.
    ENDLOOP.

  ENDIF.
  ENDENHANCEMENT.