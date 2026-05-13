*&---------------------------------------------------------------------*
*& Report ZFIR_TEST_LEER_EXCEL
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zfir_test_leer_excel.

*---------------------------------------------------------------------*
* Tipos
*---------------------------------------------------------------------*
DATA: BEGIN OF li_excel OCCURS 0.
        INCLUDE STRUCTURE alsmex_tabline.
DATA: END OF li_excel.

*---------------------------------------------------------------------*
* Datos
*---------------------------------------------------------------------*
DATA: gt_excel TYPE TABLE OF zfit_cta_sust,
      gs_excel TYPE zfit_cta_sust.

DATA: gt_raw TYPE STANDARD TABLE OF REF TO data.

DATA: gt_solix TYPE solix_tab,
      gv_xstr  TYPE xstring,
      gv_file  TYPE string.

*---------------------------------------------------------------------*
* Selección de archivo
*---------------------------------------------------------------------*
PARAMETERS p_file TYPE rlgrap-filename OBLIGATORY.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  CALL FUNCTION 'F4_FILENAME'
    IMPORTING
      file_name = p_file.

*---------------------------------------------------------------------*
* Start
*---------------------------------------------------------------------*
START-OF-SELECTION.

  gv_file = p_file.

  PERFORM read_excel.
  PERFORM save_data.

*---------------------------------------------------------------------*
* Leer Excel
*---------------------------------------------------------------------*
FORM read_excel.

  CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      filename                = p_file
      i_begin_col             = 1
      i_begin_row             = 1
      i_end_col               = 100
      i_end_row               = 30000
    TABLES
      intern                  = li_excel
    EXCEPTIONS
      inconsistent_parameters = 1
      upload_ole              = 2
      OTHERS                  = 3.

ENDFORM.

*---------------------------------------------------------------------*
* Guardar en tabla Z
*---------------------------------------------------------------------*
FORM save_data.

  LOOP AT li_excel WHERE row <> 00001.

    CASE li_excel-col.
      WHEN 1. "cta origen
        gs_excel-hkont = li_excel-value.
      WHEN 3. "TP orden
        gs_excel-auart = li_excel-value.
      WHEN 4. "POSPRE
        gs_excel-pospre = li_excel-value.
      WHEN 5. "CECO
        gs_excel-kostl = li_excel-value.
      WHEN 8. "destino
        gs_excel-destino = li_excel-value.
        " Insertar en tabla Z
        INSERT zfit_cta_sust FROM gs_excel.
    ENDCASE.

  ENDLOOP.

  COMMIT WORK.
  WRITE: / 'Carga finalizada correctamente'.

ENDFORM.