FUNCTION EXIT_SAPMM06E_008.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_UCOMM) TYPE  SY-UCOMM
*"  EXPORTING
*"     VALUE(E_CI_UPDATE) LIKE  SY-CALLD
*"     VALUE(E_UCOMM) LIKE  SY-UCOMM
*"  CHANGING
*"     VALUE(E_CI_EKKO) LIKE  EKKO_CI STRUCTURE  EKKO_CI OPTIONAL
*"----------------------------------------------------------------------


INCLUDE ZXM06U37 .


ENDFUNCTION.