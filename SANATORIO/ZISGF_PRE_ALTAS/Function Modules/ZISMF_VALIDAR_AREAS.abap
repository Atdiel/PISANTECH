FUNCTION zismf_validar_areas.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  IMPORTING
*"     REFERENCE(IV_EINRI) TYPE  EINRI
*"     REFERENCE(IV_FALNR) TYPE  FALNR
*"     REFERENCE(IV_UMEDICA) TYPE  NZUWFA
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
*** MODIF. - 3565 - 06/03/2026 - DEVBT02 Ramón Quintana
        area      = @iv_umedica AND
        clase_epi = @lv_clase_epi.
    IF sy-subrc <> 0.
*** MODIF. - 3565 - 06/03/2026 - DEVBT02 Ramón Quintana
      "No es necesaria pre-alta
      ev_need_pre_alta = abap_false.
*** INICIO MODIF. - 3565 - 06/03/2026 - DEVBT02 Ramón Quintana
      EXIT.
    ELSE.
      "levantar flag para pedir pre-alta
      ev_need_pre_alta = abap_true.
      EXIT.
    ENDIF.
*** FIN MODIF.    - 3565 - 06/03/2026 - DEVBT02 Ramón Quintana

  ELSE.
    RAISE falnr_not_found.
  ENDIF.



ENDFUNCTION.