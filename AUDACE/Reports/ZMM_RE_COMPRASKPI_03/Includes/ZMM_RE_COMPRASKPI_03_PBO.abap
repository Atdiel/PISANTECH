*----------------------------------------------------------------------*
***INCLUDE ZMM_RE_COMPRASKPI_03_PBO.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'ST1000'.
ENDMODULE.

MODULE update_screen OUTPUT.

  "Si es la primera vez que carga la pantalla
  IF alv_container IS INITIAL.
    "Asignamos valores del Selection Screen a los inputs del dynpro

    PERFORM read_report_records.
    MOVE-CORRESPONDING it_data TO it_zmmkpi.
    MODIFY zmm_kpi FROM TABLE it_zmmkpi.
    PERFORM created_catalog.

    CLEAR alv_layout.
    alv_layout-zebra = 'X'.
    alv_layout-col_opt = 'X'.
    alv_layout-cwidth_opt = 'X'.

    PERFORM display_alv_on_screen.

  ELSE.
    obj_alv_grid->refresh_table_display( ).
  ENDIF.
ENDMODULE.