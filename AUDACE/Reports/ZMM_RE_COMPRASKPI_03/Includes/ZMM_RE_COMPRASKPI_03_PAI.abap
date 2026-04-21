*----------------------------------------------------------------------*
***INCLUDE ZMM_RE_COMPRASKPI_03_PAI.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE cancel_report INPUT.

  IF obj_alv_grid IS NOT INITIAL.
    obj_alv_grid->free( ).
    alv_container->free( ).
    CLEAR: obj_alv_grid, alv_container.
  ENDIF.

  LEAVE TO SCREEN 0.
ENDMODULE.