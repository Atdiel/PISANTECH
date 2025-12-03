*&---------------------------------------------------------------------*
*& Include          ZMME_ENVIO_OC_1F01
*&---------------------------------------------------------------------*
FORM create_1ordcompl .
  "almacena la fecha actual del sistema.
  DATA: lv_current_date TYPE sy-datum,
        lt_orders       TYPE TABLE OF ekko,
        ls_orders       TYPE ekko,
        lt_cdpos        TYPE TABLE OF cdpos,
        ls_cdhdr        TYPE cdhdr,
        lv_changenr     TYPE cdhdr-changenr,
        lv_lines        TYPE i,
        val_mensaj      TYPE c,
        lv_date_low     TYPE sy-datum,
        lv_date_high    TYPE sy-datum,
        sum             TYPE i,
        lv_ebeln        TYPE ekko-ebeln,
        lt_sent_orders  TYPE TABLE OF ekko-ebeln,
        lv_order_list   TYPE string.

  DATA: lv_flag TYPE c LENGTH 1.

  " Obtener la fecha actual del sistema
  lv_current_date = sy-datum.

  " Validar Campos de Entrada
  IF s_ebeln IS INITIAL AND s_bedat-low IS INITIAL AND s_bedat-high IS INITIAL.
    MESSAGE 'Por favor, ingrese al menos un campo: número de orden o rango de fechas.' TYPE 'W'.
    EXIT.
  ENDIF.

  " Procesar basado en número de orden
  IF s_ebeln IS NOT INITIAL.
    SELECT *
      INTO TABLE lt_orders
      FROM ekko
      WHERE ebeln IN s_ebeln.

    DESCRIBE TABLE lt_orders LINES lv_lines.
    WRITE: / 'Número de órdenes encontradas:', lv_lines.

    IF lv_lines > 0.
      LOOP AT lt_orders INTO ls_orders.

        " Verificar la liberación en CDPOS
        SELECT SINGLE changenr
          INTO lv_changenr
          FROM cdpos
          WHERE objectid = ls_orders-ebeln
            AND objectclas = 'EINKBELEG'
            AND tabname = 'EKKO'
            AND fname = 'FRGKE'
            AND value_new = 'L'.

        IF sy-subrc = 0.
          SELECT SINGLE udate
            INTO ls_cdhdr-udate
            FROM cdhdr
            WHERE changenr = lv_changenr.

          IF sy-subrc = 0.
            WRITE: / 'Fecha de liberación obtenida:', ls_cdhdr-udate.
            WRITE: / 'Fecha actual del sistema:', lv_current_date.

            " Comprobar si el checkbox está marcado
            WRITE: / 'Estado del check de reenvio', p_chk.  " Mensaje de depuración

            " Permitir enviar el correo si el checkbox está marcado o si no se había enviado antes
            IF p_chk = abap_true OR val_mensaj <> 'X'.
              " Llama a la función para enviar el correo
              CALL FUNCTION 'ZMF_SEND_1MAIL'
                EXPORTING
                  is_ekko    = ls_orders
                  iv_flag    = p_chk
                IMPORTING
                  val_mensaj = val_mensaj
                EXCEPTIONS
                  OTHERS     = 1.

              IF val_mensaj = ''.
                APPEND ls_orders-ebeln TO lt_sent_orders.
                WRITE: / 'El correo enviado para la orden', ls_orders-ebeln, 'se envió exitosamente.'.
              ELSEIF val_mensaj = 'X'.
                sum = sum + 1.
              ENDIF.
            ELSE.
              WRITE: / 'El correo ya fue enviado previamente para la orden', ls_orders-ebeln.
            ENDIF.
          ELSE.
            WRITE: / 'No se pudo obtener la fecha de liberación para la orden', ls_orders-ebeln.
          ENDIF.
        ELSE.
          WRITE: / 'La orden de compra con número', ls_orders-ebeln, 'no está liberada.'.
        ENDIF.

      ENDLOOP.

      IF sum > 0.
        DATA(mess) = |El correo ya fue enviado previamente para { sum } documentos|.
        WRITE: / mess.
      ENDIF.

    ELSE.
      WRITE: / 'No se encontraron órdenes liberadas con el número especificado.'.
    ENDIF.

    " Procesar basado en rango de fechas
  ELSEIF s_bedat-low IS NOT INITIAL OR s_bedat-high IS NOT INITIAL.
    " Validar si las fechas ingresadas son válidas
    IF s_bedat-low IS NOT INITIAL AND s_bedat-low > lv_current_date.
      WRITE: / 'La fecha de entrada que ingresaste aún no ha pasado.'.
      EXIT.
    ENDIF.

    IF s_bedat-high IS NOT INITIAL AND s_bedat-high > lv_current_date.
      WRITE: / 'La fecha de salida que ingresaste aún no ha pasado.'.
      EXIT.
    ENDIF.

    " Definir el rango de fechas para la búsqueda
    IF s_bedat-low IS INITIAL.
      lv_date_low = '00000000'.
    ELSE.
      lv_date_low = s_bedat-low.
    ENDIF.

    IF s_bedat-high IS INITIAL.
      lv_date_high = lv_current_date.
    ELSE.
      lv_date_high = s_bedat-high.
    ENDIF.

    " Buscar órdenes en el rango de fechas
*** INICIO MODIF. - 900 - 02/12/2025 - PTECHABAP01
    "Hacer un select con inner join para traer datos de la oc por fecha de liberacion
    SELECT h_oc~*, h_mod~udate FROM ( cdpos AS i_mod
      INNER JOIN cdhdr AS h_mod ON h_mod~changenr = i_mod~changenr AND h_mod~udate BETWEEN @lv_date_low AND @lv_date_high )
      INNER JOIN ekko AS h_oc ON h_oc~ebeln = i_mod~objectid
      INTO TABLE @DATA(lt_purchase_orders)
      WHERE
        i_mod~changenr    = ( SELECT MAX( changenr ) FROM cdpos
                              WHERE objectclas  = 'EINKBELEG' AND
                                    fname       = 'FRGKE' AND value_new = 'L') AND
        i_mod~objectclas = 'EINKBELEG' AND
        i_mod~tabname = 'EKKO' AND
        i_mod~fname       = 'FRGKE' AND
        i_mod~value_new   = 'L'.

*    SELECT *
*      INTO TABLE lt_orders
*      FROM ekko
*      WHERE bedat BETWEEN lv_date_low AND lv_date_high.

*    DESCRIBE TABLE lt_orders LINES lv_lines.
    DESCRIBE TABLE lt_purchase_orders LINES lv_lines.
*** FIN MODIF.    - 900 - 02/12/2025 - PTECHABAP01
    WRITE: / 'Número de órdenes encontradas en el rango:', lv_lines.

    IF lv_lines > 0.
*** INICIO MODIF. - 900 - 02/12/2025 - PTECHABAP01
*      LOOP AT lt_orders INTO ls_orders.
      LOOP AT lt_purchase_orders INTO DATA(ls_po).
*** FIN MODIF.    - 900 - 02/12/2025 - PTECHABAP01
        CLEAR: val_mensaj.
*** INICIO MODIF. - 900 - 02/12/2025 - PTECHABAP01
*        " Verificar liberación en CDPOS
*        SELECT SINGLE changenr
*          INTO lv_changenr
*          FROM cdpos
*          WHERE objectclas = 'EINKBELEG'
*            AND objectid = ls_orders-ebeln
*            AND tabname = 'EKKO'
*            AND fname = 'FRGKE'
*            AND value_new = 'L'.
*
*        IF sy-subrc = 0.
*          SELECT SINGLE udate
*            INTO ls_cdhdr-udate
*            FROM cdhdr
*            WHERE changenr = lv_changenr.

*          IF sy-subrc = 0.
            WRITE: / 'Fecha de liberación obtenida:', ls_po-udate.
*** FIN MODIF.    - 900 - 02/12/2025 - PTECHABAP01
            WRITE: / 'Fecha actual del sistema:', lv_current_date.

            " Comprobar si el checkbox está marcado
            WRITE: / 'Estado de check de reenvio:', p_chk.  " Mensaje de depuración

            " Permitir enviar el correo si el checkbox está marcado o si no se había enviado antes
            IF p_chk = abap_true OR val_mensaj <> 'X'.
*** INICIO MODIF. - 900 - 02/12/2025 - PTECHABAP01
              CLEAR ls_orders.
              ls_orders = CORRESPONDING #( ls_po-h_oc ).
*** FIN MODIF.    - 900 - 02/12/2025 - PTECHABAP01
              CALL FUNCTION 'ZMF_SEND_1MAIL'
                EXPORTING
                  is_ekko    = ls_orders
                  iv_flag    = p_chk
                IMPORTING
                  val_mensaj = val_mensaj
                EXCEPTIONS
                  OTHERS     = 1.

              IF val_mensaj = ''.
*** INICIO MODIF. - 900 - 02/12/2025 - PTECHABAP01
                APPEND ls_po-h_oc-ebeln TO lt_sent_orders.
                WRITE: / 'El correo enviado para la orden', ls_po-h_oc-ebeln, 'se envió exitosamente.'.
*** FIN MODIF.    - 900 - 02/12/2025 - PTECHABAP01
              ELSEIF val_mensaj = 'X'.
                sum = sum + 1.
              ENDIF.
            ELSE.
              WRITE: / 'El correo ya fue enviado previamente para la orden', ls_orders-ebeln.
            ENDIF.
*          ELSE.
*            WRITE: / 'No se pudo obtener la fecha de liberación para la orden', ls_orders-ebeln.
*          ENDIF.
*        ELSE.
*          WRITE: / 'No se encontraron órdenes liberadas en el rango de fechas especificado.'.
*        ENDIF.

      ENDLOOP.

      IF sum > 0.
        DATA(mess2) = |El correo ya fue enviado previamente para { sum } documentos|.
        WRITE: / mess2.
      ENDIF.

    ELSE.
      WRITE: / 'No se encontraron órdenes en el rango de fechas especificado.'.
    ENDIF.

  ELSE.
    WRITE: / 'Debe ingresar al menos una fecha de entrada o salida para buscar órdenes liberadas.'.
  ENDIF.

  " Mostrar las órdenes enviadas
  CLEAR: lv_order_list.
  LOOP AT lt_sent_orders INTO lv_ebeln.
    CONCATENATE lv_order_list lv_ebeln INTO lv_order_list SEPARATED BY ', '.
  ENDLOOP.

  WRITE: / 'Órdenes enviadas:',
         / '-------------------',
         / lv_order_list.
  " Limpiar el checkbox al final del proceso
  p_chk = abap_false.

ENDFORM.
