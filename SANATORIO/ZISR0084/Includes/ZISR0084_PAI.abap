*----------------------------------------------------------------------*
***INCLUDE ZISR0084_PAI.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  HANDLE_EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE handle_exit INPUT.

  IF go_timer_management IS NOT INITIAL.
    go_timer_management->free( ).
    CLEAR go_timer_management.
  ENDIF.
  IF go_are_alv IS NOT INITIAL.
    go_are_alv->free( ).
    go_are_contain->free( ).
    CLEAR:  go_are_alv, go_are_contain.
  ENDIF.
  IF go_pre_alv IS NOT INITIAL.
    go_pre_alv->free( ).
    go_pre_contain->free( ).
    CLEAR:  go_are_alv, go_are_contain.
  ENDIF.
  IF go_det_alv IS NOT INITIAL.
    go_det_alv->free( ).
    go_det_contain->free( ).
    CLEAR:  go_det_alv, go_det_contain.
  ENDIF.

  LEAVE TO SCREEN 0.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0666  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0666 INPUT.
  DATA: lv_answer TYPE c.

  CASE sy-ucomm.
    WHEN 'DETAIL'.
      IF go_timer_management IS BOUND.
        go_timer_management->free( ).
        CLEAR go_timer_management.
      ENDIF.
      CALL SCREEN '777' STARTING AT 6 1.
    WHEN 'DELETE'. "Eliminar
      CLEAR:  lv_answer.
      "Mostrar Popup de confirmación
      CALL FUNCTION 'POPUP_CONTINUE_YES_NO'
        EXPORTING
          textline1 = 'Desea eliminar el(los) registro(s) ?'
          titel     = 'Eliminación de Pre-Altas'
        IMPORTING
          answer    = lv_answer.
      "Usuario say yes
      IF lv_answer = 'J'.
        PERFORM f_delete_pre_alta.
      ENDIF.
    WHEN 'REFRESH'.
      go_timer_management->timer_event( ).
  ENDCASE.

  IF go_timer_management IS NOT BOUND.
*   activar timer para autorefresh
      CREATE OBJECT go_timer_management.

  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  HANDLE_EXIT_777  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE handle_exit_777 INPUT.

  "Limpiar instancia, timer no soporta pantallas switch
  IF go_timer_management IS BOUND.
    go_timer_management->free( ).
    CLEAR go_timer_management.
  ENDIF.
  LEAVE TO SCREEN 0.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0999  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0999 INPUT.
  gv_ok_code = sy-ucomm.
  CLEAR sy-ucomm.
  CASE gv_ok_code.
    WHEN 'OK'.
      IF s_log IS INITIAL.
        MESSAGE ID 'MPA' TYPE 'S' NUMBER '008' WITH text-015 DISPLAY LIKE 'E'.
      ELSE.
        LEAVE TO SCREEN 0.
      ENDIF.

  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  HANDLE_EXIT_999  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE handle_exit_999 INPUT.
  gv_ok_code = sy-ucomm.
  LEAVE TO SCREEN 0.

ENDMODULE.