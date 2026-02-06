*&---------------------------------------------------------------------*
*&  Include           /ISHLA/INCL_MNAF1I40_01                          *
*&---------------------------------------------------------------------*
*-----------------------------------------------------------------------
* OBJECT NAME  : /ISHLA/INCL_MNAF1I40_01
* AUTHOR       : Federico Ricotta (BYTE TECH Argentina)
* DATE         : 21/04/2005
* DESCRIPTION  :
*-----------------------------------------------------------------------
*----------------------------------------------------------------------------------*
*	                        Log de modificaciones	                                   *
*----------------------------------------------------------------------------------*
* Modified by       : Bryan Bautista Prado                                         *
* Requerimiento     : 3164                                                         *
* Modificado por    : Bryan Bautista Prado         20                              *
* Fecha             : 17/07/2025                                                   *
* Descripción       : Permitir continuar el proceso si se elige "Fact. modo test"  *
* Transporte        : DEVK911785                                                   *
*----------------------------------------------------------------------------------*

* Check Localization Active Flag
CALL FUNCTION '/ISHLA/FCT_CHECK_LOC'
  EXPORTING
    ss_einri                = nfal-einri
  IMPORTING
    ss_cvers                = v_cvers
  EXCEPTIONS
    localization_not_active = 1
    OTHERS                  = 2.
IF sy-subrc = 0.

* Billing Limit by Insurance Provider
* Límite en La Facturación X Aseguradora
* POP UP para cargar los límites...
*
  IF v_cvers = 'MX'.
*{   INSERT         DEVK903774                                        1
***********************************************************************
*Obtenemos las relaciones de la verificación de seguro
*Oscar Santiago Sánchez - Deloitte - 13-10-2010
***********************************************************************
* Obtenemos las relaciones de verificación de seguro
    DATA: lv_cont     TYPE i,
          lv_mess(80) TYPE c.
    DATA: ls_0010 TYPE zist0010,
          ls_bkpf TYPE bkpf.
    DATA: it_nksk TYPE STANDARD TABLE OF nksk,
          ls_nksk TYPE nksk.
    DATA: lv_answer(1),
          it_nfal TYPE TABLE OF nfal WITH HEADER LINE.
    DATA: ls_0117 TYPE zist0117,
          it_0117 TYPE TABLE OF zist0117.
    DATA: it_folio   TYPE TABLE OF zmmmxt1005,
          ls_folio   TYPE zmmmxt1005,
          lt_reserva TYPE STANDARD TABLE OF resb,
          ls_reserva TYPE resb,
          lv_kzear   TYPE char1.

*** INICIO MODIF. - 3164 - 30/01/2026 - PTECHABAP01
    DATA: lv_folio TYPE zisde_folios.

    CLEAR: lv_folio.

    DATA(lv_pending) = zglcl_enhancement_helper=>has_pending_folio( EXPORTING iv_einri = rnpa1-einri
                                                                              iv_falnr = nfal-falnr
                                                                    IMPORTING ev_folio = lv_folio ).
    IF lv_pending = abap_true.
*** INICIO MODIF. - 3164  - 17/07/2025   - Bryan Bautista Prado
      IF rnaf0-tabkz = 'X'.
*** MODIF. - 3164 - 30/01/2026 - PTECHABAP01
        MESSAGE i083(zish) WITH lv_folio.
      ELSEIF rnaf0-echtkz = 'X'.
*** INICIO MODIF. - 3164 - 28/01/2026 - DEVBT02
        MESSAGE i083(zish) WITH lv_folio DISPLAY LIKE 'E'.
        EXIT.
*** FIN MODIF.    - 3164 - 28/01/2026 - DEVBT02
      ENDIF.
*** FIN MODIF.    - 3164  - 17/07/2025   - Bryan Bautista Prado
*   El episodio aún tiene el folio & pendiente de asignar en quirófano
    ENDIF.
*** FIN MODIF.    - 3164 - 30/01/2026 - PTECHABAP01

* Se valida si no se tiene restricciones para la aseguradora o el
* particular
    IF r_kostr[] IS INITIAL AND p_sekz IS INITIAL AND rnab0-bsper NE 'X'.

      IF rnab0-tabkz EQ 'X'.

      ELSE.

* Obtenemos la verificación de seguro para identificar deudores
        SELECT belnr einri falnr kostr FROM nksk
          INTO CORRESPONDING FIELDS OF TABLE it_nksk
          WHERE einri EQ nfal-einri
            AND falnr EQ nfal-falnr
            AND storn NE 'X'
            AND uebab NE 'X'
            AND ktext NE 'X'.

* En caso de que ya se haya hecho la verificación de factura
        IF sy-subrc EQ 0.
* Se valida si hay más de un deudor en la verificación de seguro
          DESCRIBE TABLE it_nksk LINES lv_cont.
* En caso de que exista más de un deudor, se valida si se ha marcado
* el flag de factura final, en caso afirmativo, se marca como factura
* intermedia
          IF lv_cont GT 1.
            IF rnaf0-eabkz = 'X'.
              rnaf0-kzzwa = 'X'.
              rnab0-kzzwa = 'X'.
              rnaf0-eabkz = ''.
              rnab0-eabkz = ''.
            ENDIF.
          ENDIF.
        ELSE.
          IF nfal-abrkz EQ '1' AND rnaf0-eabkz EQ 'X' AND rnaf0-echtkz = 'X'.
            CALL FUNCTION 'ZISH_VALIDAR_PRESTACIONES'
              EXPORTING
                einri                     = nfal-einri
                falnr                     = nfal-falnr
              EXCEPTIONS
                prestaciones_sin_facturar = 1
                OTHERS                    = 2.

            IF sy-subrc = 0.
              CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
                EXPORTING
                  defaultoption  = 'Y'
                  textline1      = '¿Desea cambiar status a'
                  textline2      = 'Facturación Final?'
                  titel          = 'CONFIRMACIÓN'
                  start_column   = 25
                  start_row      = 6
                  cancel_display = 'X'
                IMPORTING
                  answer         = lv_answer.

              CASE lv_answer.
                WHEN 'J'.
                  it_nfal-falnr = nfal-falnr.
                  it_nfal-einri = nfal-einri.
                  it_nfal-abrkz = '2'.
                  APPEND it_nfal.

                  CALL FUNCTION 'ISH_UPDATE_NFAL_ABRKZ_1'
                    EXPORTING
                      einri   = '1000'
                      sammel  = 'X'
                      tcode_i = 'ST01'
                    TABLES
                      ynfal   = it_nfal.

              ENDCASE.
            ENDIF.
          ENDIF.
        ENDIF.

* Se lee la primera relación de aseguradora
        READ TABLE it_nksk INTO ls_nksk INDEX 1.
        IF sy-subrc = 0.
* Si es para el particular
          IF ls_nksk-kostr IS INITIAL.
            lv_mess = 'el cliente PARTICULAR'.
            IF lv_cont GT 1.
              p_sekz = 'X'.
            ENDIF.
* O es para la aseguradora
          ELSE.
            CONCATENATE 'el cliente' ls_nksk-kostr INTO lv_mess
              SEPARATED BY space.

            IF lv_cont GT 1.
              CLEAR: r_kostr.
              REFRESH: r_kostr.
              r_kostr-sign = 'I'.
              r_kostr-option = 'EQ'.
              r_kostr-low = ls_nksk-kostr.
              APPEND r_kostr.
            ENDIF.

            SELECT SINGLE * INTO ls_0010
              FROM zist0010
              WHERE einri EQ nfal-einri
                AND kostr EQ ls_nksk-kostr.

            IF sy-subrc = 0.
              rnab0-bsper = 'X'.
            ENDIF.
          ENDIF.

* Se envía mensaje del tipo de factura generada
          CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'
            EXPORTING
              titel     = 'FACTURACIÓN'
              textline1 = 'Se generará la Factura para'
              textline2 = lv_mess.

        ENDIF.
      ENDIF.
*endif.
    ELSE.

      SELECT SINGLE * INTO ls_0010
        FROM zist0010
        WHERE einri EQ nfal-einri
          AND kostr IN r_kostr.

      IF sy-subrc = 0.
        rnab0-bsper = 'X'.
      ENDIF.
    ENDIF.

    CLEAR ls_0117.
    REFRESH: it_0117.
    IF rnab0-bsper = 'X'.
      SELECT SINGLE * FROM zist0117
        INTO CORRESPONDING FIELDS OF ls_0117
        WHERE einri = nfal-einri
          AND falnr = nfal-falnr.
      IF sy-subrc = 0." AND ls_0117-texto03 IS NOT INITIAL.
        IF ls_0117-texto03 IS INITIAL.
          ls_0117-texto03 = sy-uzeit.
        ELSE.
          ls_0117-texto30 = sy-uzeit.
          ls_0117-fualt = sy-datum.
        ENDIF.
        APPEND ls_0117 TO it_0117.
      ELSE.
        ls_0117-einri = nfal-einri.
        ls_0117-falnr = nfal-falnr.
        ls_0117-patnr = nfal-patnr.
        ls_0117-statu = 'EN PROCESO'.
        ls_0117-texto03 = sy-uzeit.
        APPEND ls_0117 TO it_0117.
      ENDIF.
      IF it_0117[] IS NOT INITIAL.
        MODIFY zist0117 FROM TABLE it_0117.
      ENDIF.
    ENDIF.
*}   INSERT

    IF r_bwart[] IS NOT INITIAL.
      DATA: it_nbew TYPE TABLE OF nbew,
            ls_nbew TYPE nbew.

      REFRESH: it_nbew.
      SELECT einri falnr lfdnr bewty bwart
        FROM nbew
        INTO CORRESPONDING FIELDS OF TABLE it_nbew
        WHERE einri = nfal-einri
          AND falnr = nfal-falnr
          AND bwart IN r_bwart
          AND storn NE 'X'.
      IF it_nbew[] IS NOT INITIAL.
        LOOP AT it_nbew INTO ls_nbew.
          CLEAR ms_besnr.
          ms_besnr-sign = 'I'.
          ms_besnr-option = 'EQ'.
          ms_besnr-low = ls_nbew-lfdnr.
          APPEND ms_besnr.
        ENDLOOP.
        cvers = 'XV1'.
      ENDIF.
    ENDIF.

    CONCATENATE '/ISH' v_cvers '/FCT_CHECK_INSUR_BLIMIT'
           INTO v_function_name.
*       call function '/ISHMX/FCT_CHECK_INSUR_BLIMIT'
    CALL FUNCTION v_function_name
      EXPORTING
        ss_nfal  = nfal
        ss_einri = nfal-einri
        ss_rnab0 = rnab0.
  ENDIF.

ENDIF.