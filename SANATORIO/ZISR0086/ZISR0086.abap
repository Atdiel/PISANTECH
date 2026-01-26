*----------------------------------------------------------------------*
* Delivery PISANTECH  *
*----------------------------------------------------------------------*
* Proyecto  : Control de Pre-Alta                                      *
* Requerimiento : 3271                                                 *
* Programa  : ZISR0086                                                 *
* Creado por  : Ramón Atdiel Pérez Quintana DEVBT02                    *
* Fecha de creacion : 28/07/2025                                       *
*	Descripcion	: Validar Altas desde NWP1 esten                         *
*               liberadas sus pre altas                                *
* Transporte  : DEVK911759                                             *
*----------------------------------------------------------------------*
REPORT zisr0086.

DATA: lv_einri TYPE einri,
      lv_falnr TYPE falnr,
      ls_nfal  TYPE nfal,
      ls_186   TYPE zist0186,
      lv_hos_need_pre TYPE abap_bool.

CLEAR:  lv_einri, lv_falnr,
        ls_nfal, ls_186, lv_hos_need_pre.

GET PARAMETER ID 'EIN' FIELD lv_einri.
GET PARAMETER ID 'FAL' FIELD lv_falnr.

SELECT SINGLE * FROM nfal
  INTO ls_nfal
  WHERE
    einri   = lv_einri AND
    falnr   = lv_falnr.

IF sy-subrc = 0.
  "Solo episodios Hospitalarios
  IF ls_nfal-falar = '1'.

    CALL FUNCTION 'ZISMF_VALIDAR_AREAS'
      EXPORTING
        iv_einri         =  lv_einri   " IS-H: Centro sanitario
        iv_falnr         =  lv_falnr   " IS-H: Número de episodio
      IMPORTING
        ev_need_pre_alta = lv_hos_need_pre
      EXCEPTIONS
        falnr_not_found  = 1
        others           = 2
      .
    IF sy-subrc <> 0.
*     MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      EXIT.
    ENDIF.
    IF lv_hos_need_pre = abap_true.

      SELECT SINGLE * FROM zist0186
        INTO ls_186
        WHERE
          einri   = lv_einri AND
          falnr   = lv_falnr AND
          deleted = abap_false.
      "No se encuentra aun la pre alta
      IF sy-subrc <> 0.
        MESSAGE ID 'NWP_ALTA' TYPE 'S' NUMBER '001' WITH text-001 DISPLAY LIKE 'E'.
        EXIT.
      ENDIF.
      "Existe la pre alta pero no se ha liberado aun
      IF ls_186-status <> icon_green_light.
        MESSAGE ID 'NWP_ALTA' TYPE 'S' NUMBER '002' WITH text-002 DISPLAY LIKE 'E'.
        EXIT.
      ENDIF.

    ENDIF.

    CALL TRANSACTION 'NP97'.
  ENDIF.

ENDIF.