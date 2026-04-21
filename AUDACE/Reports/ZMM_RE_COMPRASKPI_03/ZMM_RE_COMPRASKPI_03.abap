*&---------------------------------------------------------------------*
*& Report ZMM_RE_COMPRASKPI_03
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zmm_re_compraskpi_03.

INCLUDE ZMM_RE_COMPRASKPI_03_top.
*INCLUDE ZMM_RE_COMPRASKPI_03_f01.
INCLUDE ZMM_RE_COMPRASKPI_03_class.

INCLUDE zmm_re_compraskpi_03_pbo.

INCLUDE zmm_re_compraskpi_03_pai.

START-OF-SELECTION.

  IF sy-batch = 'X'.
    s_fech-sign   = 'I'.
    s_fech-option = 'EQ'.
    s_fech-low    = sy-datum.
    APPEND s_fech.
  ENDIF.

  CALL SCREEN 0100.

END-OF-SELECTION.