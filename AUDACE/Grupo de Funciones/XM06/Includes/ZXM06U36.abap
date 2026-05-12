*&---------------------------------------------------------------------*
*& Include          ZXM06U36
*&---------------------------------------------------------------------*
DATA: lv_trtyp TYPE c.
"-->  Export to PBO of screen 0101.
lv_trtyp = i_trtyp.
EXPORT lv_trtyp TO MEMORY ID 'LV_TRTYP'.
ekko_ci-zzclausulado  = i_ekko-zzclausulado.