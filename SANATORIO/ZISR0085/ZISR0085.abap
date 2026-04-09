*&---------------------------------------------------------------------*
*& Report  ZISR0085
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT zisr0085.

DATA: lv_einri     TYPE nfal-einri,
      lv_falnr     TYPE nfal-falnr,
      lv_orgfa     TYPE nbew-orgfa,
      lv_answer(1) TYPE c,
      lv_room      TYPE ish_zimmid,
      lv_pat_name TYPE char60_cp.

CLEAR: lv_einri, lv_falnr, lv_orgfa, lv_room, lv_pat_name.

GET PARAMETER ID 'EIN' FIELD lv_einri.
GET PARAMETER ID 'FAL' FIELD lv_falnr.
GET PARAMETER ID 'OGE' FIELD lv_orgfa. "OEF->MMINT OGE->EMINT

**********************************************************************
"Obtener datos de paciente para mostrar en ventana de confirmación
SELECT SINGLE epi~patnr, epi~falar, but~name_first, but~name_last
    FROM nfal AS epi INNER JOIN npnt AS pat
    ON epi~patnr = pat~patnr
    INNER JOIN but000 AS but
    ON pat~partner = but~partner
    INTO @DATA(ls_epi_pat)
    WHERE
      epi~einri     = @lv_einri AND
      epi~falnr     = @lv_falnr.


  SELECT * FROM nbew
    INTO TABLE @DATA(lt_nbew)
    WHERE
      einri   = @lv_einri AND
      falnr   = @lv_falnr.

  IF ls_epi_pat-falar = '1'. "Para Hospitalizados
    "Admisión
    READ TABLE lt_nbew WITH KEY bewty = '1' INTO DATA(ls_bew1).
    IF sy-subrc = 0.
      lv_room = ls_bew1-zimmr.
    ELSE.
      "Traslados
      READ TABLE lt_nbew WITH KEY bewty = '3' INTO DATA(ls_bew3).
      IF sy-subrc = 0.
        lv_room = ls_bew3-zimmr.
      ENDIF.
    ENDIF.
  ELSEIF ls_epi_pat-falar = '2'.
    "Para ambulatorios el primer movimiento
    READ TABLE lt_nbew WITH KEY lfdnr = 1 INTO DATA(ls_first_mov).
    IF sy-subrc = 0.
      lv_room = ls_first_mov-zimmr.
    ENDIF.
  ENDIF.

  lv_pat_name = |{ ls_epi_pat-name_first } { ls_epi_pat-name_last }|.
**********************************************************************

CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
  EXPORTING
    defaultoption  = 'Y'
*** MODIF. - 3565 - 03/03/2026 - Ramón Quintana DEVBT02
    textline1      = '¿Generar Check-List para Paciente?'
    textline2      = |{ lv_room }, { lv_pat_name }|
*** MODIF. - 3565 - 03/03/2026 - Ramón Quintana DEVBT02
    titel          = 'CONFIRMACIÓN CHECK-LIST'
    cancel_display = 'X'
  IMPORTING
    answer         = lv_answer.

IF lv_answer = 'J'.

  CALL FUNCTION 'ZISMF_CREAR_PRE_ALTA'
    EXPORTING
      iv_einri         = lv_einri
      iv_falnr         = lv_falnr
      iv_orgfa         = lv_orgfa
    EXCEPTIONS
      falnr_not_found  = 1
      save_user_failed = 2
      creation_failed  = 3
      OTHERS           = 4.
  IF sy-subrc = 0.
    CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'
      EXPORTING
*** INICIO MODIF. - 3565 - 03/03/2026 - Ramón Quintana DEVBT02
        titel     = 'CHECK-LIST'
        textline1 = 'Se ha generado la solicitud de Check-List'
*** FIN MODIF.    - 3565 - 03/03/2026 - Ramón Quintana DEVBT02
        textline2 = 'a las áreas hospitalarias del episodio'.
  ENDIF.
ENDIF.