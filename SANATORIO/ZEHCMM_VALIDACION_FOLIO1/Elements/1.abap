*** INICIO MODIF. - 3164 - 30/01/2026 - PTECHABAP01
 DATA: ls_mesfec  TYPE string." Estructura para fecha de mensaje.
 DATA: lv_folio TYPE zisde_folios.
 CLEAR: lv_folio.
*** FIN MODIF.    - 3164 - 30/01/2026 - PTECHABAP01
  IF alv_ucomm = 'NP97'."
*** INICIO MODIF. - 3164 - 03/02/2026 - PTECHABAP01
    DATA(lv_pending) = ZGLCL_ENHANCEMENT_HELPER=>has_pending_folio( EXPORTING iv_einri = rnpa1-einri
                                                                              iv_falnr = nfal-falnr
                                                                    IMPORTING ev_folio = lv_folio ).
    IF lv_pending = abap_true.

        CONCATENATE 'El episodio tiene el folio pendiente: ' lv_folio
*** FIN MODIF.    - 3164 - 03/02/2026 - PTECHABAP01
          'Imposible asignar fecha final' INTO ls_mesfec SEPARATED BY space.
        CALL FUNCTION 'POPUP_TO_INFORM'
          EXPORTING
            titel         = 'Advertencia'
            txt1          = ls_mesfec
            txt2          = ''.

         LEAVE TO SCREEN 0.
    ENDIF.
  ENDIF.
