FUNCTION zismf_has_pend_folio.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  IMPORTING
*"     REFERENCE(IV_EINRI) TYPE  EINRI
*"     REFERENCE(IV_FALNR) TYPE  FALNR
*"  EXPORTING
*"     REFERENCE(EV_FOLIO) TYPE  ZISDE_FOLIOS
*"     REFERENCE(EV_RSNUM) TYPE  RSNUM
*"----------------------------------------------------------------------
  TYPES: ltype_rsnum TYPE RANGE OF mseg-rsnum.

  DATA: lr_rsnum  TYPE ltype_rsnum.

  DATA: lv_rsnum TYPE rsnum,
        lv_folio TYPE zisde_folios,
        lt_reservas TYPE TABLE OF resb.

  CLEAR: lv_folio, lv_rsnum, lr_rsnum.

  REFRESH: lt_reservas.

**********************************************************************
*     F O L I O S
**********************************************************************

  "Validar si existe folio con numero de reserva pendiente
  SELECT folio, rsnum FROM zish0001
    INTO TABLE @DATA(lt_folios)
      WHERE
        falnr = @iv_falnr.

  SELECT folio, rsnum FROM zmmmxt1005
     APPENDING TABLE @lt_folios
    WHERE
      einri = @iv_einri AND
      falnr = @iv_falnr.

  IF lt_folios IS NOT INITIAL.
    "Primero validar escenario donde existe folio pero no hay reserva.
    READ TABLE lt_folios WITH KEY rsnum = '' INTO DATA(ls_fol_n_res).
    IF sy-subrc = 0.
      "🚨 Salimos y marcamos flag
      ev_folio = ls_fol_n_res-folio.
      EXIT.
    ENDIF.

*    SELECT * FROM resb
*      APPENDING TABLE lt_reservas
*      FOR ALL ENTRIES IN lt_folios
*      WHERE
*        rsnum   = lt_folios-rsnum AND
*        xloek   = abap_false AND "que no este eliminado
*        kzear   = abap_false.

*    IF sy-subrc = 0.
*      ev_folio = VALUE #( lt_folios[ 1 ]-folio OPTIONAL ).
*      EXIT.
*    ENDIF.

  ENDIF.

**********************************************************************
**      R E S E R V A S
**********************************************************************

  SELECT n~mblnr, n~mbpos, n~menge, n~lfsta, r~kzear AS sfin FROM nmatp AS n LEFT OUTER JOIN resb AS r
    ON n~mblnr = r~rsnum AND n~mbpos = r~rspos AND r~xloek = @abap_false "Borrada
    INTO TABLE @DATA(lt_reserv)
    WHERE
      n~falnr     = @iv_falnr AND
      n~einri     = @iv_einri AND
      n~storn     = @abap_false AND "posicon anulada
      n~lfsta     <> '3'. "Entrega completa

  IF sy-subrc <> 0.
    EXIT.
  ENDIF.

  "Eliminar aquellas resrvas que tengan salida fin
  DELETE lt_reserv WHERE sfin = abap_true.

  "Buscar reservas que esten en status diferentes a entrega parcial.
  LOOP AT lt_reserv INTO DATA(ls_reserv) WHERE lfsta  <> '2'.
    ev_rsnum = ls_reserv-mblnr.
    EXIT.
  ENDLOOP.

  IF lt_reserv IS INITIAL.
    EXIT.
  ENDIF.

  lr_rsnum = VALUE #( FOR rs IN lt_reserv ( sign    = 'I'
                                            option  = 'EQ'
                                            low     = rs-mblnr ) ).

  "Buscar para esas reservas con entreg. parci. las cantidades en la mseg
  SELECT mblnr, zeile, menge, rsnum, rspos FROM mseg
    INTO TABLE @DATA(lt_mseg)
    WHERE
      rsnum IN @lr_rsnum.

  IF sy-subrc <> 0. "el status es posiblemente 2 pero no se encuentra en mseg, error indeterminado
    ev_rsnum = VALUE #( lt_reserv[ 1 ]-mblnr OPTIONAL ).
    MESSAGE ID 'C-LIST' TYPE 'S' NUMBER '012' WITH text-016 ev_rsnum DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  LOOP AT lt_reserv INTO ls_reserv.
    DATA(lv_dlv_real) = REDUCE mseg-menge( INIT t = 0
                                            FOR docmat IN lt_mseg
                                            WHERE ( rsnum = ls_reserv-mblnr AND
                                                    rspos = ls_reserv-mbpos )
                                            NEXT t = t + docmat-menge ).
    IF ( ls_reserv-menge - lv_dlv_real ) > 0. "comparamos entregas en mseg con lo planeado de nmatp
      ev_rsnum = ls_reserv-mblnr. "si existe una diferencia positiva falta por entregar material en reserva
      EXIT.
    ENDIF.
  ENDLOOP.



ENDFUNCTION.