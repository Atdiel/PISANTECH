*----------------------------------------------------------------------*
***INCLUDE ZISR0084_PBO.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0666  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0666 OUTPUT.
  DATA: lv_title     TYPE char30,
        lv_message,
        lt_hidden_bt TYPE syucomm_t.
  CLEAR:  lv_title,
          lv_message.
  REFRESH:  lt_hidden_bt.

  "Asignar el area con el que se trabajara
  IF gt_areas_roles IS INITIAL.
    SELECT area, role FROM zist0185
      INTO TABLE @gt_areas_roles
      WHERE
        uname     = @sy-uname.

  ENDIF.

  IF sy-tcode = 'ZISH195'.
    MOVE '( Administrador )' TO lv_title.
  ELSE.

  ENDIF.


  "Configurar botones para cada monitor
  IF sy-tcode = 'ZISH195'.
    lt_hidden_bt = VALUE #( ( 'DETAIL' ) ).
    GET PARAMETER ID 'ZBORRAR_PREALTA' FIELD DATA(lv_has_auth).
    IF lv_has_auth = abap_false.
      lt_hidden_bt = VALUE #( BASE lt_hidden_bt ( 'DELETE' ) ).
    ENDIF.
  ELSE.
    lt_hidden_bt = VALUE #( ( 'DELETE' ) ).
  ENDIF.

  SET PF-STATUS 'MN_PRE_ALTA_MANAGE' EXCLUDING lt_hidden_bt.
  SET TITLEBAR 'TI_PRE_ALTA' WITH lv_title.


*  DELETE FROM ZIST0186 WHERE einri = '1000'.
*  DELETE FROM ZIST0187 WHERE einri = '1000'.
*  COMMIT WORK.


ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  SHOW_UPDATE_ALV  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE show_update_alv OUTPUT.

**********************************************************************
*     P R E - A L T A S   A L V
**********************************************************************
  IF go_pre_alv IS INITIAL.

    IF go_pre_alv_man IS INITIAL.
      go_pre_alv_man = NEW #( ).
    ENDIF.

    "Fill alv with data
    PERFORM f_datos_pre_alta.

    "Create fieldcat
    go_pre_alv_man->create_fieldcat(
          EXPORTING iv_tabname = 'GT_PRE_OUTPUT'
          CHANGING ct_fieldcat = gt_pre_fcat ).


    "Display alv
    go_pre_alv_man->show_alv(
          EXPORTING
            iv_cont_name = gc_pre_cname
          CHANGING
            co_container = go_pre_contain
            co_grid      = go_pre_alv
            ct_fcat      = gt_pre_fcat
            cs_layout    = gs_pre_layout
            ct_outtab    = gt_pre_output ).
    IF sy-tcode = 'ZISH195'.
      SET HANDLER go_pre_alv_man->handle_double_click FOR go_pre_alv.
    ENDIF.


  ELSE.
    go_pre_alv->refresh_table_display(
*      EXPORTING
*        is_stable      =
*        i_soft_refresh =
      EXCEPTIONS
        finished       = 1
        OTHERS         = 2
    ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.

**********************************************************************
*       A R E A S   A L V
**********************************************************************
  IF go_are_alv IS INITIAL.

    IF go_are_alv_man IS INITIAL.
      go_are_alv_man = NEW #( ).
    ENDIF.

    "Fill alv with data
    PERFORM f_datos_area.

    "Create fieldcat
    go_are_alv_man->create_fieldcat(
          EXPORTING iv_tabname = 'GT_ARE_OUTPUT'
          CHANGING ct_fieldcat = gt_are_fcat ).

    "Display alv
    go_are_alv_man->show_alv(
          EXPORTING
            iv_cont_name = gc_are_cname
          CHANGING
            co_container = go_are_contain
            co_grid      = go_are_alv
            ct_fcat      = gt_are_fcat
            cs_layout    = gs_are_layout
            ct_outtab    = gt_are_output ).
    SET HANDLER go_are_alv_man->handle_hotspot_click FOR go_are_alv.


  ELSE.
    go_are_alv->refresh_table_display(
*      EXPORTING
*        is_stable      =
*        i_soft_refresh =
      EXCEPTIONS
        finished       = 1
        OTHERS         = 2
    ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.




ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0777  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0777 OUTPUT.
  SET PF-STATUS 'MN_DETAIL'.
*  SET TITLEBAR 'xxx'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  SHOW_UPDATE_ALV_777  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE show_update_alv_777 OUTPUT.
  DATA: lt_row_sel TYPE lvc_t_roid,
        ls_row_sel TYPE lvc_s_roid,
        ls_pre_out TYPE zist0186.

  CLEAR:  ls_row_sel,
          ls_pre_out.
  REFRESH lt_row_sel.

  "Leer lineas seleccionadas
  go_pre_alv->get_selected_rows(
    IMPORTING
*      et_index_rows =
      et_row_no     = lt_row_sel
  ).


  READ TABLE lt_row_sel INDEX 1 INTO ls_row_sel.
  IF sy-subrc <> 0.
    "Salir si no se selecciono linea
    MESSAGE ID 'MPA' TYPE 'S' NUMBER '005' WITH text-007 DISPLAY LIKE 'E'.
    LEAVE TO SCREEN 0.
  ENDIF.

  "Leer datos del episodio seleccionado
  READ TABLE gt_pre_output INDEX ls_row_sel-row_id INTO ls_pre_out.
  IF sy-subrc <> 0.
    "manejamos el error en caso de que suceda poder trazar
    MESSAGE ID 'MPA' TYPE 'S' NUMBER '006' WITH text-008 DISPLAY LIKE 'E'.
    LEAVE TO SCREEN 0.
  ENDIF.

  "Leemos la tabla en caso de que ya este seleccionado ese episodio
  READ TABLE gt_are_det_out INDEX 1 INTO DATA(ls_are_det_out).
  IF sy-subrc = 0.
    "Es el mismo entonces no actualizamos
    IF ls_pre_out-einri = ls_are_det_out-einri AND ls_pre_out-falnr = ls_are_det_out-falnr.
      EXIT.
    ENDIF.
  ENDIF.

  gt_are_det_out = VALUE #( FOR det IN gt_are_det_all WHERE ( einri = ls_pre_out-einri AND
                                                              falnr = ls_pre_out-falnr )
                                                              ( det ) ).

**********************************************************************
*       D E T A L L E S   A L V
**********************************************************************
  IF go_det_alv IS INITIAL.

    IF go_det_alv_man IS INITIAL.
      go_det_alv_man = NEW #( ).
    ENDIF.


    "Create fieldcat
    go_det_alv_man->create_fieldcat(
          EXPORTING iv_tabname = 'GT_ARE_DET_OUT'
          CHANGING ct_fieldcat = gt_det_fcat ).

    "Display alv
    go_det_alv_man->show_alv(
          EXPORTING
            iv_cont_name = gc_det_cname
          CHANGING
            co_container = go_det_contain
            co_grid      = go_det_alv
            ct_fcat      = gt_det_fcat
            cs_layout    = gs_det_layout
            ct_outtab    = gt_are_det_out ).

  ELSE.
    go_det_alv->refresh_table_display(
*      EXPORTING
*        is_stable      =
*        i_soft_refresh =
      EXCEPTIONS
        finished       = 1
        OTHERS         = 2
    ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.

  IF go_timer_management IS NOT BOUND.
*   activar timer para autorefresh
    CREATE OBJECT go_timer_management.

  ENDIF.


ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0999  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0999 OUTPUT.
  SET PF-STATUS 'MN_FECHAS'.
  SET TITLEBAR 'TI_FECHAS'.
ENDMODULE.