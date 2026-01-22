*&---------------------------------------------------------------------*
*& Report ZMMR_VENCIMIENTO_OC
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zmmr_vencimiento_oc.

INCLUDE zmmr_vencimiento_oc_top.
INCLUDE zmmr_vencimiento_oc_f01.

START-OF-SELECTION.
  PERFORM delete_old_registers.
  PERFORM check_upcomming_delivery.
