class ZGLCL_ENHANCEMENT_HELPER definition
  public
  final
  create public .

public section.

  class-methods HAS_PENDING_FOLIO
    importing
      !IV_EINRI type EINRI
      !IV_FALNR type FALNR
    exporting
      !EV_FOLIO type ZISDE_FOLIOS
    returning
      value(RV_HAS_PENDING) type ABAP_BOOL .