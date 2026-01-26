*----------------------------------------------------------------------*
***INCLUDE ZISR0084_F01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  F_DATOS_PRE_ALTA
*&---------------------------------------------------------------------*
*   Se realizo esta subrutina para poder traer los datos de Pre-altas
*   contenidas en la tabla ZIST0186 buscando por nombre de usuario
*   en la variable de sistema SY-UNAME y donde hora alta no este asignada
*----------------------------------------------------------------------*
FORM f_datos_pre_alta .

  IF sy-tcode = 'ZISH195'.
    SELECT * FROM zist0186
      INTO TABLE gt_pre_output
      WHERE
        pre_date    IN s_datum.

    LOOP AT gt_pre_output REFERENCE INTO DATA(lo_pre_out).
      IF lo_pre_out->deleted = abap_true.
        lo_pre_out->status = icon_delete.
      ENDIF.
    ENDLOOP.
  ELSE.

    SELECT * FROM zist0186
      INTO TABLE gt_pre_output
      WHERE
        uname     = sy-uname AND
        alta_hour = '000000' AND
        deleted   = abap_false. "No traer registros eliminados por ADMIN
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F_DATOS_AREA
*&---------------------------------------------------------------------*
*   Se realizo esta subrutina para poder traer los datos de unidades
*   medicas contenidas en la tabla ZIST0187 buscando por area asignada
*   al usuario actual en GV_AREA_MONITOR
*----------------------------------------------------------------------*
FORM f_datos_area .

  IF sy-tcode = 'ZISH195'.
    DATA: lv_verif     TYPE abap_bool,
          lv_least_one TYPE abap_bool,
          ls_are_all   TYPE ty_areas_output.

    SELECT b~* FROM zist0186 AS a RIGHT OUTER JOIN zist0187 AS b
      ON a~id = b~id "Solo enlazarlos por su ID
      INTO TABLE @gt_are_all
      WHERE
        a~pre_date    IN @s_datum.
    "Modificara para el alv el icono de status de area
    LOOP AT gt_are_all REFERENCE INTO DATA(lo_are_all).
      "Validar si esta area para este episodio ya se agrupo
      IF lo_are_all->einri = ls_are_all-einri AND
         lo_are_all->falnr = ls_are_all-falnr AND
         lo_are_all->area  = ls_are_all-area.
        lo_are_all->einri = space.
        CONTINUE.

      ENDIF.

      CLEAR:  lv_verif, ls_are_all, lv_least_one.

      "Comenzaremos con flag en true, si en algun momento se encuentra
      "con un area sin validar, la cambiamos, solo en ese caso.
      lv_verif = abap_true.
      "Agrupar por areas de episodio
      LOOP AT gt_are_all INTO ls_are_all
                         WHERE einri = lo_are_all->einri AND
                               falnr = lo_are_all->falnr AND
                               area  = lo_are_all->area.

        "Segun el role, colocamos la hora en su debido campo (para monitor)
        CASE ls_are_all-role.
          WHEN 1.
            lo_are_all->nursing = ls_are_all-resp_hour.
          WHEN 2.
            lo_are_all->pharmacy = ls_are_all-resp_hour.
          WHEN 3.
            lo_are_all->reception = ls_are_all-resp_hour.
        ENDCASE.

        "Si hay un caso donde alguno no se haya verificado levantamos flag
        IF ls_are_all-verif <> abap_true.
          lv_verif = ls_are_all-verif.
        ELSE.
          lv_least_one = ls_are_all-verif.
        ENDIF.

      ENDLOOP.

      IF lv_verif = abap_true.
        lo_are_all->status = icon_green_light.
      ELSE.
        IF lv_least_one = abap_true.
          lo_are_all->status = icon_yellow_light.
        ELSE.
          lo_are_all->status = icon_red_light.
        ENDIF.
      ENDIF.
      "Marcar los eliminados
      IF lo_are_all->deleted = abap_true.
        lo_are_all->status = icon_delete.
      ENDIF.
    ENDLOOP.

    "Eliminar aquellos duplicados que ya fueron agrupados
    DELETE gt_are_all WHERE einri = space.

  ELSE.
    "Buscar informacion para areas del usuario pendientes
    SELECT a~*, ( @icon_okay ) AS button FROM zist0187 AS a
      INNER JOIN zist0185 AS b ON a~area = b~area AND a~role = b~role
      INTO TABLE @gt_are_output
      WHERE
        b~uname    = @sy-uname AND
        a~verif    = @abap_false AND
        a~deleted  = @abap_false. "No traer pendientes eliminados por ADMIN

    "Asignar al output alv el rol con nombre
    LOOP AT gt_are_output REFERENCE INTO DATA(lo_are_output).
      CASE lo_are_output->role.
        WHEN 1.
          lo_are_output->role_name = text-009.
        WHEN 2.
          lo_are_output->role_name = text-010.
        WHEN 3.
          lo_are_output->role_name = text-011.
        WHEN 4.
          lo_are_output->role_name = text-017.
        WHEN OTHERS.
          lo_are_output->role_name = lo_are_output->role.
      ENDCASE.
    ENDLOOP.

    "Buscar detalles de areas para episodios del usuario
    SELECT b~* FROM zist0186 AS a RIGHT OUTER JOIN zist0187 AS b
      ON a~id = b~id
      INTO TABLE @gt_are_det_all
      WHERE
        a~uname     = @sy-uname AND
        a~alta_hour = '000000' AND
        a~deleted   = @abap_false.

    LOOP AT gt_are_det_all REFERENCE INTO DATA(lo_are_det_all).
      IF lo_are_det_all->verif = abap_true.
        lo_are_det_all->status = icon_green_light.
      ELSE.
        lo_are_det_all->status = icon_red_light.
      ENDIF.
      CASE lo_are_det_all->role.
        WHEN 1.
          lo_are_det_all->role_name = text-009.
        WHEN 2.
          lo_are_det_all->role_name = text-010.
        WHEN 3.
          lo_are_det_all->role_name = text-011.
        WHEN 4.
          lo_are_output->role_name = text-017.
      ENDCASE.
    ENDLOOP.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F_DELETE_PRE_ALTA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_delete_pre_alta .
  DATA: lt_rows_sel TYPE lvc_t_roid.

  REFRESH:  lt_rows_sel.
  go_pre_alv->get_selected_rows(
    IMPORTING
      et_row_no     = lt_rows_sel
  ).

  IF lt_rows_sel IS INITIAL.
    MESSAGE ID 'MPA' TYPE 'S' NUMBER '005' WITH text-007 DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  LOOP AT lt_rows_sel INTO DATA(ls_row).
    "Obtener datos de episodio
    READ TABLE gt_pre_output INDEX ls_row-row_id INTO DATA(ls_pre_out).
    IF sy-subrc <> 0.
      "En caso de error
      CONTINUE.
    ENDIF.

    IF ls_pre_out-deleted = abap_true.
      MESSAGE ID 'MPA' TYPE 'S' NUMBER '009' WITH text-016 DISPLAY LIKE 'W'..
      CONTINUE.
    ENDIF.
    "Borrado logico en registros de ambas tablas
    UPDATE zist0186 SET deleted = abap_true WHERE id = ls_pre_out-id.
    UPDATE zist0187 SET deleted = abap_true WHERE id = ls_pre_out-id.

    CALL FUNCTION 'ZISMF_EMAIL_CANC_PREALTA'
      EXPORTING
        iv_id_prealta = ls_pre_out-id.


    COMMIT WORK.

    DELETE gt_pre_output INDEX ls_row-row_id.
  ENDLOOP.

ENDFORM.