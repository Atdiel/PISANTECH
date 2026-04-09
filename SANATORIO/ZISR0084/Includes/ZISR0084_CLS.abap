*&---------------------------------------------------------------------*
*&  Include           ZISR0084_CLS
*&---------------------------------------------------------------------*


**********************************************************************
*     T I M E R   F O R   A L V   R E Q U E S T   D A T A
**********************************************************************

CLASS lcl_timer DEFINITION .
  PUBLIC SECTION.
    DATA:
      lo_timer  TYPE REF TO cl_gui_timer.
    METHODS:
      constructor,
      timer_event FOR EVENT finished OF cl_gui_timer,
      free.

  PRIVATE SECTION .

ENDCLASS .                    "cl_timer DEFINITION
CLASS lcl_timer IMPLEMENTATION .
  METHOD constructor.

    CREATE OBJECT lo_timer.
    SET HANDLER me->timer_event FOR lo_timer.
    lo_timer->interval = gc_timer_interval.
    lo_timer->run( ).

  ENDMETHOD.
  METHOD timer_event .
    DATA: lv_mens TYPE c LENGTH 30,
          ls_are  TYPE ty_areas_output.

    "Buscamos datos de ambos ALV
    PERFORM f_datos_pre_alta.
    PERFORM f_datos_area.

    "Solo para admin, actualizamos alv de areas tambien
    CLEAR ls_are.
    IF sy-tcode = 'ZISH195'.
      IF gt_are_output IS NOT INITIAL.
        READ TABLE gt_are_output INTO ls_are INDEX 1.
        REFRESH gt_are_output.
        gt_are_output = VALUE #( FOR row IN gt_are_all WHERE ( id = ls_are-id )
                                                           ( row ) ).
      ENDIF.
    ELSE. "Solo para detalles, actualizamos alv de detalles
      IF gt_are_det_out IS NOT INITIAL.
        READ TABLE gt_are_det_out INTO ls_are INDEX 1.
        REFRESH gt_are_det_out.
        gt_are_det_out = VALUE #( FOR line IN gt_are_det_all WHERE ( einri = ls_are-einri AND
                                                                      falnr = ls_are-falnr )
                                                                      ( line ) ).
      ENDIF.
    ENDIF.

    "Refrescamos ALV
    IF go_pre_alv IS NOT INITIAL.
      go_pre_alv->refresh_table_display( ).
    ENDIF.
    IF go_are_alv IS NOT INITIAL.
      go_are_alv->refresh_table_display( ).
    ENDIF.
    IF go_det_alv IS NOT INITIAL.
      go_det_alv->refresh_table_display( ).
    ENDIF.

    "Enviamos mensaje de hora ultima actualización
    lv_mens = |Actualizado a las { sy-uzeit+0(2) }:{ sy-uzeit+2(2) }:{ sy-uzeit+4(2) }|.
    MESSAGE ID 'MPA' TYPE 'S' NUMBER '001' WITH lv_mens.

    me->lo_timer->run( ) .

  ENDMETHOD .                    "timer_event
  METHOD free.

    "Free the instance of the timer
    me->lo_timer->cancel( ).
    me->lo_timer->free( ).

  ENDMETHOD.                      "free
ENDCLASS .                    "cl_timer IMPLEMENTATION

**********************************************************************
*           P A R E N T   C L A S S
**********************************************************************
CLASS lcl_alv_management DEFINITION ABSTRACT.

  PUBLIC SECTION.
    METHODS:
      show_alv
        IMPORTING
          iv_cont_name TYPE tabname
        CHANGING
          co_container TYPE REF TO cl_gui_custom_container
          co_grid      TYPE REF TO cl_gui_alv_grid
          ct_fcat      TYPE lvc_t_fcat
          cs_layout    TYPE lvc_s_layo
          ct_outtab    TYPE table,
      handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING
          e_object
          e_interactive,
      handle_user_command ABSTRACT FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING
          e_ucomm.
ENDCLASS.
CLASS lcl_alv_management IMPLEMENTATION.
  METHOD show_alv.
    DATA: ls_variant TYPE disvariant.

    CLEAR ls_variant.
*** MODIF. - 3565 - 27/01/2026 - PTECHABAP01
    ls_variant-report   = |{ sy-repid }_{ sy-tcode }|.
    ls_variant-username = sy-uname.

*** MODIF. - 3565 - 27/01/2026 - PTECHABAP01
    ls_variant-handle = iv_cont_name.
    cs_layout-sel_mode = 'D'.
    cs_layout-col_opt  = abap_true.
    cs_layout-zebra    = abap_true.

    co_container = NEW #( container_name = iv_cont_name ).

    co_grid      = NEW #( i_parent = co_container ).

    "Toolbar
    SET HANDLER me->handle_toolbar FOR co_grid.
    SET HANDLER me->handle_user_command FOR co_grid.

    co_grid->set_table_for_first_display(
      EXPORTING
        is_layout                     = cs_layout
        is_variant                    = ls_variant
        i_save                        = 'A'
      CHANGING
        it_outtab                     = ct_outtab
        it_fieldcatalog               = ct_fcat
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4
    ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    IF go_timer_management IS NOT BOUND.
*   activar timer para autorefresh
      CREATE OBJECT go_timer_management.

    ENDIF.

  ENDMETHOD.                                "show_alv
  METHOD handle_toolbar.
    DATA: ls_toolbar TYPE stb_button.
    IF sy-tcode <> 'ZISH195'.
      CLEAR ls_toolbar.
      MOVE 'LOG' TO ls_toolbar-function.
      MOVE icon_history TO ls_toolbar-icon.
      MOVE 'Historial' TO ls_toolbar-text.
      MOVE 'Liberados' TO ls_toolbar-quickinfo.
      MOVE space TO ls_toolbar-disabled.
      APPEND ls_toolbar TO e_object->mt_toolbar.
    ENDIF.

  ENDMETHOD.                                "handle_toolbar
ENDCLASS.

**********************************************************************
*             P R E - A L T A S   C L A S S
**********************************************************************

CLASS lcl_pre_management DEFINITION INHERITING FROM lcl_alv_management.
  PUBLIC SECTION.
    METHODS:
      create_fieldcat
        IMPORTING
          iv_tabname  TYPE tabname
        CHANGING
          ct_fieldcat TYPE lvc_t_fcat,
      handle_double_click FOR EVENT double_click OF cl_gui_alv_grid
        IMPORTING
          e_row,
      handle_user_command REDEFINITION.

ENDCLASS.
CLASS lcl_pre_management IMPLEMENTATION.
  METHOD create_fieldcat.

    ct_fieldcat = VALUE #(
            ( fieldname = 'STATUS' reptext = 'Status' icon = abap_true )
            ( fieldname = 'EINRI' reptext = 'CeSa' just = 'R' )
            ( fieldname = 'FALNR' reptext = 'Episodio' no_zero = abap_true just = 'R' )
            ( fieldname = 'PATNR' reptext = 'Paciente' no_zero = abap_true just = 'R' )
            ( fieldname = 'ZIMMR' reptext = 'Habitación' just = 'R' )
            ( fieldname = 'FULL_NAME' reptext = 'Nombre Completo' outputlen = 40 just = 'R' )
            ( fieldname = 'PRE_DATE' reptext = 'Fecha Check-List' just = 'R' outputlen = 12 )
            ( fieldname = 'PRE_HOUR' reptext = 'Hora Check-List' just = 'R' outputlen = 12 )
            ).

    IF sy-tcode = 'ZISH195'.
      INSERT VALUE #( fieldname = 'UNAME' reptext = 'Usuario' just = 'R' ) INTO ct_fieldcat INDEX 3.
      APPEND VALUE #( fieldname = 'ALTA_HOUR' reptext = 'Hora Alta' just = 'R' outputlen = 10 ) TO ct_fieldcat.
      APPEND VALUE #( fieldname = 'DIFF_HOUR' reptext = 'Diferencia' just = 'R' outputlen = 10 ) TO ct_fieldcat.
    ENDIF.
    LOOP AT ct_fieldcat REFERENCE INTO DATA(field_ref).
      field_ref->tabname = iv_tabname.
    ENDLOOP.

  ENDMETHOD.                            "create_fieldcat
  METHOD handle_double_click.

    READ TABLE gt_pre_output INTO DATA(ls_pre_output) INDEX e_row-index.
    IF sy-subrc <> 0.
      EXIT.
    ENDIF.

    gt_are_output = VALUE #( FOR row IN gt_are_all WHERE ( id = ls_pre_output-id )
                                                         ( row ) ).
    IF gt_are_output IS INITIAL.
      MESSAGE ID 'MPA' TYPE 'S' NUMBER '004' WITH text-005 DISPLAY LIKE 'W'.
    ENDIF.


    "Actualizamos el alv para mostrar la tabla con areas de ese episodio
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


  ENDMETHOD.                            "handle_double_click
  METHOD handle_user_command.

    "Llamar dynpro para solicitar rango de fechas.
    CALL SCREEN '999' STARTING AT 6 6.

    "Salimos si no se llena parametros de busqueda
    IF s_log IS INITIAL OR gv_ok_code = 'CANCEL'.
      EXIT.
    ENDIF.
    "llamar otra pantalla con un nuevo ALV
    DATA: ls_layout   TYPE slis_layout_alv,
          lt_fieldcat TYPE slis_t_fieldcat_alv.
    CLEAR ls_layout.
    REFRESH: lt_fieldcat.

    lt_fieldcat = VALUE #( FOR field IN gt_pre_fcat
                            ( fieldname = field-fieldname
                              seltext_m = field-reptext
                              icon      = field-icon
                              just      = field-just
                              no_zero   = field-no_zero
                              outputlen = field-outputlen ) ).

    SELECT * FROM zist0186
      INTO TABLE @DATA(lt_history_pre)
      WHERE
        uname     = @sy-uname AND
        pre_date  IN @s_log.


    LOOP AT lt_history_pre REFERENCE INTO DATA(lo_hist_pre).
      IF lo_hist_pre->deleted = abap_true.
        lo_hist_pre->status = icon_delete.
      ENDIF.
    ENDLOOP.

    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program = sy-repid
        is_layout          = ls_layout
        it_fieldcat        = lt_fieldcat
      TABLES
        t_outtab           = lt_history_pre
      EXCEPTIONS
        program_error      = 1
        OTHERS             = 2.
  ENDMETHOD.                            "handle_user_command
ENDCLASS.

**********************************************************************
*             A R E A S   C L A S S
**********************************************************************

CLASS lcl_are_management DEFINITION INHERITING FROM lcl_alv_management.
  PUBLIC SECTION.
    METHODS:
      create_fieldcat
        IMPORTING
          iv_tabname  TYPE tabname
        CHANGING
          ct_fieldcat TYPE lvc_t_fcat,
      handle_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_row_id e_column_id es_row_no,

      handle_validation
        IMPORTING e_row_id  TYPE lvc_s_row
                  e_column  TYPE lvc_s_col
                  es_row_no TYPE lvc_s_roid,

      handle_user_command REDEFINITION.

ENDCLASS.
CLASS lcl_are_management IMPLEMENTATION.
  METHOD create_fieldcat.

    ct_fieldcat = VALUE #(
          ( fieldname = 'EINRI' reptext = 'CeSa' just = 'R' outputlen = 6 )
          ( fieldname = 'FALNR' reptext = 'Episodio' no_zero = abap_true just = 'R' outputlen = 9 )
          ( fieldname = 'PATNR' reptext = 'Paciente' no_zero = abap_true just = 'R' )
          ( fieldname = 'AREA' reptext = 'Um' just = 'R' outputlen = 6 )
          ( fieldname = 'ROLE_NAME' reptext = 'Rol' just = 'R' outputlen = 10 )
          ( fieldname = 'FULL_NAME' reptext = 'Nombre Completo' outputlen = 40 just = 'R' )
          ( fieldname = 'BUTTON' reptext = 'Liberar' hotspot = abap_true just = 'C' )
            ).

    IF sy-tcode = 'ZISH195'.
      INSERT VALUE #( fieldname = 'STATUS' reptext = 'Status' icon = abap_true ) INTO ct_fieldcat INDEX 1.
      APPEND VALUE #( fieldname = 'NURSING' reptext = 'Enfermería' just = 'R' outputlen = 12 ) TO ct_fieldcat.
      APPEND VALUE #( fieldname = 'PHARMACY' reptext = 'Farmacia' just = 'R' outputlen = 12 ) TO ct_fieldcat.
      APPEND VALUE #( fieldname = 'RECEPTION' reptext = 'Recepción' just = 'R' outputlen = 12 ) TO ct_fieldcat.
*** MODIF. - 3565 - 27/01/2026 - PTECHABAP01
      APPEND VALUE #( fieldname = 'INSURANCE' reptext = 'Aseguradora' just = 'R' outputlen = 12 ) TO ct_fieldcat.
      APPEND VALUE #( fieldname = 'RESP_HOUR' reptext = 'Hora Respuesta' just = 'R' outputlen = 12 ) TO ct_fieldcat.
      APPEND VALUE #( fieldname = 'RESP_DATE' reptext = 'Día Respuesta' just = 'R' outputlen = 12 ) TO ct_fieldcat.
      APPEND VALUE #( fieldname = 'RESP_USER' reptext = 'Usuario Liberó' just = 'R' outputlen = 12 ) TO ct_fieldcat.
      APPEND VALUE #( fieldname = 'DIFF_RES_REQ' reptext = 'Dif. Tiempo' just = 'R' outputlen = 12 ) TO ct_fieldcat.
      DELETE ct_fieldcat WHERE fieldname = 'BUTTON'.
    ENDIF.
    LOOP AT ct_fieldcat REFERENCE INTO DATA(field_ref).
      field_ref->tabname = iv_tabname.
    ENDLOOP.

  ENDMETHOD.                              "create_fieldcat
  METHOD handle_hotspot_click.

    me->handle_validation( e_row_id = e_row_id e_column = e_column_id es_row_no = es_row_no ).
    "Refrescamos ALV
    IF go_pre_alv IS NOT INITIAL.
      go_pre_alv->refresh_table_display( ).
    ENDIF.
    IF go_are_alv IS NOT INITIAL.
      go_are_alv->refresh_table_display( ).
    ENDIF.
    IF go_det_alv IS NOT INITIAL.
      go_det_alv->refresh_table_display( ).
    ENDIF.


  ENDMETHOD.                              "handle_hotspot_click
  METHOD handle_validation.

    DATA: ls_area_updated TYPE zist0187,
          lv_answer(1)    TYPE c,
*** INICIO MODIF. - 3565 - 05/03/2026 - Ramón Quintana DEVBT02
          lv_reserv_pend(1) TYPE c.
    CLEAR:  ls_area_updated, lv_reserv_pend.
*** FIN MODIF.    - 3565 - 05/03/2026 - Ramón Quintana DEVBT02

*    buscamos linea en alv con parametro OPTIONAL para evitar error en caso de no existir linea
    ls_area_updated = CORRESPONDING #( VALUE #( gt_are_output[ es_row_no-row_id ] OPTIONAL ) ).
    IF ls_area_updated IS INITIAL.
      MESSAGE ID 'MPA' TYPE 'S' NUMBER '002' WITH text-002 DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

*** INICIO MODIF. - 3565 - 03/03/2026 - Ramón Quintana DEVBT02
    "Inicia validacion de cargos pendientes en NMATP
    CALL FUNCTION 'ZISMF_RESERVA_PEND_AREAS'
      EXPORTING
        iv_einri           =    ls_area_updated-einri " IS-H: Centro sanitario
        iv_falnr           =    ls_area_updated-falnr " IS-H: Número de episodio
        iv_umedica         =    ls_area_updated-area " IS-H: Unidad org.médica que solicita la prestación
      IMPORTING
        ev_has_reserv_pend =    lv_reserv_pend. " Valores booleanos TRUE (= 'X') y FALSE (= ' ')
    IF lv_reserv_pend = abap_true.
      RETURN.
    ENDIF.
*** FIN MODIF.    - 3565 - 03/03/2026 - Ramón Quintana DEVBT02

    CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
      EXPORTING
        defaultoption  = 'N'
        textline1      = '¿Liberar episodio?'
        titel          = 'CONFIRMACIÓN EPISODIO'
        cancel_display = 'X'
      IMPORTING
        answer         = lv_answer.

    IF lv_answer <> 'J'.
      "salir del programa
      MESSAGE ID 'MPA' TYPE 'S' NUMBER '006' WITH text-012.
      RETURN.
    ENDIF.

    "Buscamos la Pre-Alta registrada para calcular diferencia de respuesta
    " y en caso de estar todas las areas completas cambiar el status de la Pre-Alta
    SELECT SINGLE * FROM zist0186
      INTO @DATA(ls_pa_rec)
      WHERE
        id        = @ls_area_updated-id.

    ls_area_updated-verif         = abap_true.
    ls_area_updated-resp_hour     = sy-uzeit.
    ls_area_updated-resp_user     = sy-uname.
    ls_area_updated-resp_date     = sy-datum.
    ls_area_updated-diff_res_req  = ls_area_updated-resp_hour - ls_pa_rec-pre_hour.
    UPDATE zist0187 FROM ls_area_updated.
    IF sy-subrc <> 0.
      MESSAGE ID 'MPA' TYPE 'S' NUMBER '003' WITH text-003 DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    "Validamos si hay areas pendientes para ese episodio y asi
    " actualizar la tabla de pre-altas
    SELECT * FROM zist0187
      INTO TABLE @DATA(lt_pending_areas)
      WHERE
        id        = @ls_area_updated-id AND
        verif     = @abap_false.

    DELETE lt_pending_areas WHERE area = ls_area_updated-area AND role = ls_area_updated-role.

    IF lt_pending_areas IS NOT INITIAL.
      "Actualizamos semaforo amarillo si almenos una ya libero
      IF ls_pa_rec-status = icon_red_light.
        ls_pa_rec-status = icon_yellow_light.
        UPDATE zist0186 FROM ls_pa_rec.
        IF sy-subrc <> 0.
          MESSAGE ID 'MPA' TYPE 'S' NUMBER '003' WITH text-003 DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.
      ENDIF.
      COMMIT WORK.
      DELETE gt_are_output INDEX es_row_no-row_id.
      "Creado correctamente
      MESSAGE ID 'MPA' TYPE 'S' NUMBER '007' WITH text-013.
      RETURN.
    ENDIF.

    ls_pa_rec-status = icon_green_light.
    UPDATE zist0186 FROM ls_pa_rec.
    IF sy-subrc <> 0.
      MESSAGE ID 'MPA' TYPE 'S' NUMBER '003' WITH text-003 DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    COMMIT WORK.
    "Creado correctamente
    MESSAGE ID 'MPA' TYPE 'S' NUMBER '007' WITH text-013.
    DELETE gt_are_output INDEX es_row_no-row_id.
    "Actualizamos el alv para mostrar la tabla con areas de ese episodio
    go_are_alv->refresh_table_display(
      EXCEPTIONS
        finished       = 1
        OTHERS         = 2
    ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ENDMETHOD.                              "handle_validation
  METHOD handle_user_command.

    "Llamar dynpro para solicitar rango de fechas.
    CALL SCREEN '999' STARTING AT 6 6.

    "Salimos si no se llena parametros de busqueda
    IF s_log IS INITIAL OR gv_ok_code = 'CANCEL'.
      EXIT.
    ENDIF.

    "llamar otra pantalla con un nuevo ALV
    DATA: ls_layout          TYPE slis_layout_alv,
          lt_fieldcat        TYPE slis_t_fieldcat_alv,
          lt_history_are_out TYPE TABLE OF ty_areas_output.
    CLEAR ls_layout.
    REFRESH: lt_fieldcat, lt_history_are_out.

    lt_fieldcat = VALUE #( FOR field IN gt_are_fcat
                            ( fieldname = field-fieldname
                              seltext_m = field-reptext
                              icon      = field-icon
                              just      = field-just
                              no_zero   = field-no_zero
                              outputlen = field-outputlen ) ).

    "Modificamos el fieldcat para dar otra vista de campos en historico
    DELETE lt_fieldcat WHERE fieldname = 'BUTTON'.
    APPEND VALUE #( fieldname = 'RESP_HOUR' seltext_m = 'Hora Respuesta' just = 'R' outputlen = 12 ) TO lt_fieldcat.
    APPEND VALUE #( fieldname = 'RESP_DATE' seltext_m = 'Día Respuesta' just = 'R' outputlen = 12 ) TO lt_fieldcat.
    INSERT VALUE #( fieldname = 'STATUS' seltext_m = 'Status' icon = abap_true ) INTO lt_fieldcat INDEX 1.

    SELECT * FROM zist0187
      INTO TABLE lt_history_are_out
      WHERE
        resp_user     = sy-uname AND
        resp_date     IN s_log.

    LOOP AT lt_history_are_out REFERENCE INTO DATA(lo_history_are).
      IF lo_history_are->verif = abap_true.
        "Verde si ya fue liberado
        lo_history_are->status = icon_green_light.
      ENDIF.
      "Si fue eliminado mostrar icono
      IF lo_history_are->deleted = abap_true.
        lo_history_are->status = icon_delete.
      ENDIF.
      CASE lo_history_are->role.
        WHEN 1.
          lo_history_are->role_name = text-009.
        WHEN 2.
          lo_history_are->role_name = text-010.
        WHEN 3.
          lo_history_are->role_name = text-011.
*** INICIO MODIF. - 3565 - 27/01/2026 - PTECHABAP01
        WHEN 4.
          lo_history_are->role_name = text-017.
*** FIN MODIF.    - 3565 - 27/01/2026 - PTECHABAP01
      ENDCASE.
    ENDLOOP.

    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program = sy-repid
        is_layout          = ls_layout
        it_fieldcat        = lt_fieldcat
      TABLES
        t_outtab           = lt_history_are_out
      EXCEPTIONS
        program_error      = 1
        OTHERS             = 2.
  ENDMETHOD.                              "handle_user_command
ENDCLASS.

**********************************************************************
*             D E T A L L E S   C L A S S
**********************************************************************

CLASS lcl_det_management DEFINITION INHERITING FROM lcl_alv_management.
  PUBLIC SECTION.
    METHODS:
      create_fieldcat
        IMPORTING
          iv_tabname  TYPE tabname
        CHANGING
          ct_fieldcat TYPE lvc_t_fcat,
      handle_user_command REDEFINITION.

ENDCLASS.
CLASS lcl_det_management IMPLEMENTATION.
  METHOD create_fieldcat.

    ct_fieldcat = VALUE #(
          ( fieldname = 'STATUS' reptext = 'Status' icon = abap_true )
          ( fieldname = 'AREA' reptext = 'Um' just = 'R' outputlen = 6 )
          ( fieldname = 'ROLE_NAME' reptext = 'Rol' just = 'R' outputlen = 10 )
          ( fieldname = 'RESP_HOUR' reptext = 'Hora Respuesta' just = 'R' outputlen = 12 )
          ( fieldname = 'DIFF_RES_REQ' reptext = 'Dif. Tiempo' just = 'R' outputlen = 12 )
          ).


    LOOP AT ct_fieldcat REFERENCE INTO DATA(field_ref).
      field_ref->tabname = iv_tabname.
    ENDLOOP.

  ENDMETHOD.                              "create_fieldcat
  METHOD handle_user_command.
  ENDMETHOD.                              "handle_user_command
ENDCLASS.