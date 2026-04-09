FUNCTION zismf_reserva_pend_areas.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  IMPORTING
*"     REFERENCE(IV_EINRI) TYPE  EINRI
*"     REFERENCE(IV_FALNR) TYPE  FALNR
*"     REFERENCE(IV_UMEDICA) TYPE  ANFOE
*"  EXPORTING
*"     REFERENCE(EV_HAS_RESERV_PEND) TYPE  /BA1/F4_DTE_BOOLE
*"----------------------------------------------------------------------

  TYPES: ltype_rsnum TYPE RANGE OF mseg-rsnum.

  DATA: lr_rsnum  TYPE ltype_rsnum.
  CLEAR lr_rsnum.

  ev_has_reserv_pend = abap_false.

 "Filtrar campo anfoe
  SELECT n~mblnr, n~mbpos, n~menge, n~lfsta, n~anfoe, n~anpoe, r~kzear AS sfin FROM nmatp AS n LEFT OUTER JOIN resb AS r
      ON n~mblnr = r~rsnum AND n~mbpos = r~rspos
      INTO TABLE @DATA(lt_reserv)
      WHERE
        n~falnr     = @iv_falnr AND
        n~einri     = @iv_einri AND
        r~xloek     = @abap_false AND "Borrada
        n~storn     = @abap_false AND "posicon anulada
        n~lfsta     <> '3' AND "Entrega completa
        n~anfoe     = @iv_umedica.
 "Filtrar campo anpoe
  SELECT n~mblnr, n~mbpos, n~menge, n~lfsta, n~anfoe, n~anpoe, r~kzear AS sfin FROM nmatp AS n LEFT OUTER JOIN resb AS r
     ON n~mblnr = r~rsnum AND n~mbpos = r~rspos
     APPENDING TABLE @lt_reserv
     WHERE
       n~falnr     = @iv_falnr AND
       n~einri     = @iv_einri AND
       r~xloek     = @abap_false AND "Borrada
       n~storn     = @abap_false AND "posicon anulada
       n~lfsta     <> '3' AND "Entrega completa
       n~anpoe     = @iv_umedica.

  IF lt_reserv IS INITIAL.
    EXIT.
  ENDIF.

  "Eliminar aquellas resrvas que tengan salida fin
  DELETE lt_reserv WHERE sfin = abap_true.

  IF lt_reserv IS INITIAL.
    EXIT.
  ENDIF.

  "Buscar reservas que esten en status diferentes a entrega parcial.
  LOOP AT lt_reserv INTO DATA(ls_reserv) WHERE lfsta  <> '2'.
    ev_has_reserv_pend = abap_true.
    MESSAGE ID 'C-LIST' TYPE 'S' NUMBER '013' WITH text-017 ls_reserv-mblnr DISPLAY LIKE 'E'.
    EXIT.
  ENDLOOP.

  lr_rsnum = VALUE #( FOR rs IN lt_reserv ( sign    = 'I'
                                            option  = 'EQ'
                                            low     = rs-mblnr ) ).

  "Buscar para esas reservas con entreg. parci. las cantidades en la mseg
  SELECT mblnr, zeile, menge, rsnum, rspos FROM mseg
    INTO TABLE @DATA(lt_mseg)
    WHERE
      rsnum IN @lr_rsnum.

  IF sy-subrc <> 0. "el status es posiblemente 2 pero no se encuentra en mseg, error indeterminado
    ev_has_reserv_pend = abap_true.
    MESSAGE ID 'C-LIST' TYPE 'S' NUMBER '012' WITH text-016 VALUE #( lt_reserv[ 1 ]-mblnr OPTIONAL ) DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  LOOP AT lt_reserv INTO ls_reserv.
    DATA(lv_dlv_real) = REDUCE mseg-menge( INIT t = 0
                                            FOR docmat IN lt_mseg
                                            WHERE ( rsnum = ls_reserv-mblnr AND
                                                    rspos = ls_reserv-mbpos )
                                            NEXT t = t + docmat-menge ).
    IF ( ls_reserv-menge - lv_dlv_real ) > 0. "comparamos entregas en mseg con lo planeado de nmatp
      MESSAGE ID 'C-LIST' TYPE 'S' NUMBER '014' WITH text-017 ls_reserv-mblnr DISPLAY LIKE 'E'.
      ev_has_reserv_pend = abap_true.
      EXIT.
    ENDIF.
  ENDLOOP.


ENDFUNCTION.