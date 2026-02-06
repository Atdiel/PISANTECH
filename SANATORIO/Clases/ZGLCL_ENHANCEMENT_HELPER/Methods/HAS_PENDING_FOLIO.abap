  METHOD HAS_PENDING_FOLIO.

    DATA: lv_rsnum TYPE rsnum,
          lv_folio TYPE zisde_folios.

    CLEAR: lv_folio, lv_rsnum.

    "Validar si existe folio con numero de reserva pendiente
    SELECT folio, rsnum FROM zish0001
      INTO TABLE @DATA(lt_folios)
        WHERE
          falnr = @iv_falnr.

    "Manejar la validacion y luego mandar un error message
    SELECT folio, rsnum FROM zmmmxt1005
       APPENDING TABLE @lt_folios
      WHERE
        einri = @iv_einri AND
        falnr = @iv_falnr.

    IF lt_folios IS NOT INITIAL.
      "Primero validar escenario donde existe folio pero no hay reserva.
      READ TABLE lt_folios WITH KEY rsnum = '' INTO DATA(ls_fol_n_res).
      IF sy-subrc = 0.
        "Salimos y marcamos flag
        ev_folio = ls_fol_n_res-folio.
        rv_has_pending = abap_true.
        EXIT.
      ENDIF.

      SELECT * FROM resb
        INTO TABLE @DATA(lt_reserva)
        FOR ALL ENTRIES IN @lt_folios
        WHERE
          rsnum   = @lt_folios-rsnum AND
          kzear   = @abap_false.

      IF sy-subrc = 0.
        ev_folio = VALUE #( lt_folios[ 1 ]-folio OPTIONAL ).
        rv_has_pending = abap_true.
        EXIT.
      ENDIF.

    ENDIF.

  ENDMETHOD.