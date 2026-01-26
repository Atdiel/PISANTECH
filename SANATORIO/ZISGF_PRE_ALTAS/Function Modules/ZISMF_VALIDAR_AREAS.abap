FUNCTION zismf_validar_areas.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  IMPORTING
*"     REFERENCE(IV_EINRI) TYPE  EINRI
*"     REFERENCE(IV_FALNR) TYPE  FALNR
*"  EXPORTING
*"     REFERENCE(EV_NEED_PRE_ALTA) TYPE  ABAP_BOOL
*"  EXCEPTIONS
*"      FALNR_NOT_FOUND
*"----------------------------------------------------------------------
  CONSTANTS: lc_hospitalizado TYPE i VALUE '1',
             lc_ambulatorio   TYPE i VALUE '2'.

  DATA: lv_clase_epi TYPE char1.

  CLEAR: lv_clase_epi.

  "Validar si es hospitalario o ambulatorio
  SELECT SINGLE * FROM nfal
    INTO @DATA(ls_nfal_pa)
    WHERE
      einri   = @iv_einri AND
      falnr   = @iv_falnr.
  IF sy-subrc = 0.
    "Asignamos a la variable que clase de epi. es.
    lv_clase_epi = COND #( WHEN ls_nfal_pa-falar = lc_ambulatorio
                            THEN lc_ambulatorio
                            ELSE lc_hospitalizado ).

    "Leemos todas las areas que solicitan pre-alta segun su clase de epi.
    SELECT * FROM zist0190
      INTO TABLE @DATA(lt_areas)
      WHERE
        clase_epi = @lv_clase_epi.
    IF sy-subrc <> 0.
      ev_need_pre_alta = abap_false.
    ENDIF.

    "Validar todas las areas por las que paso el epi
    SELECT * FROM nbew
      INTO TABLE @DATA(lt_movements)
      WHERE
        einri     = @iv_einri AND
        falnr     = @iv_falnr.
    IF sy-subrc <> 0.
      "En caso de no haber movimientos en el epi.
    ENDIF.

    "Verificar que algun area por la que paso no este en la tabla de pre-altas
    LOOP AT lt_movements INTO DATA(ls_movements).
      READ TABLE lt_areas WITH KEY area = ls_movements-orgfa TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        "levantar flag para pedir pre-alta
        ev_need_pre_alta = abap_true.
        EXIT.
      ELSE.
        READ TABLE lt_areas WITH KEY area = ls_movements-orgpf TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          "levantar flag para pedir pre-alta
          ev_need_pre_alta = abap_true.
          EXIT.
        ENDIF.
      ENDIF.

    ENDLOOP.

  ELSE.
    RAISE falnr_not_found.
  ENDIF.



ENDFUNCTION.