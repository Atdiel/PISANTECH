  METHOD if_ex_ish_nv2000_pbo~modify_data.
    FIELD-SYMBOLS: <rndbew> TYPE rndbew.
    DATA: ls_0186 TYPE zist0186.

    ASSIGN ('(SAPLNBE2)RNDBEW') TO <rndbew>.
    IF sy-subrc = 0.
      IF <rndbew>-bewty = '2'.
        SELECT SINGLE * FROM zist0186
          INTO ls_0186
          WHERE
            einri       = <rndbew>-einri AND
            falnr       = <rndbew>-falnr.

        IF sy-subrc = 0.
          IF ls_0186-status <> icon_green_light.
            CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'
              EXPORTING
                titel     = 'PRE ALTA'
                textline1 = 'El paciente tiene unaa solicitud de Pre Alta'
                textline2 = 'áreas hospitalarias pendientes de liberar'
                textline3 = 'Imposible generar Alta'.

            c_worst_message_type = 'E'.
            c_messages = VALUE #( ( type = 'E' id = 'ZISH' number = 067 ) ).

            EXIT.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.