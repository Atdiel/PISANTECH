 DATA: lt_reserva TYPE STANDARD TABLE OF resb,
       ls_reserva TYPE resb,
       ls_folio   TYPE zmmmxt1005, "Estructura para folio
       ls_mesfec  TYPE string." Estructura para fecha de mensaje.

 DATA: lv_kzear TYPE char1,
       lv_title  TYPE string,
       lv_text1  TYPE string,
       lv_text2  TYPE string.


     IF alv_ucomm = 'NP97'."

        SELECT SINGLE * FROM zmmmxt1005
        INTO CORRESPONDING FIELDS OF ls_folio
        WHERE einri = rnpa1-einri
        AND falnr = nfal-falnr.
*        AND ( asig = '' OR pick = '' ).

          IF sy-subrc = '0'.
            SELECT * FROM resb
              INTO TABLE lt_reserva
              WHERE rsnum = ls_folio-rsnum.

              LOOP AT lt_reserva INTO ls_reserva.
                IF ls_reserva-kzear IS NOT INITIAL.
                  lv_kzear = 'X'.
                  EXIT.
                ENDIF.
              ENDLOOP.

              IF lv_kzear IS INITIAL.

                CONCATENATE 'El episodio tiene el folio pendiente: ' ls_folio-folio
                'Imposible asignar fecha final' INTO ls_mesfec SEPARATED BY space.
                CALL FUNCTION 'POPUP_TO_INFORM'
                EXPORTING
                  titel         = 'Advertencia'
                  txt1          = ls_mesfec
                  txt2          = ''.

                LEAVE TO SCREEN 0.
        ENDIF.
      ENDIF.
    ENDIF.