**********************************************
* Modificado por: Maria Oliveira (MGOB)
* Modificado el: 06/12/2016
* Se agrega la condicion RECARGOS
**********************************************

DATA: ls_komk TYPE komk,
      wa_komvd LIKE komvd OCCURS 0 WITH HEADER LINE,
      wa_komv  LIKE komv  OCCURS 0 WITH HEADER LINE,
      it_ico_cond LIKE zmm_ico_cond OCCURS 0 WITH HEADER LINE,
      lv_tax like gv_tax.

field-symbols: <ekpo> like line of it_ekpo.

BREAK PTECHABAP01.
CLEAR gs_komk.
CLEAR gt_komvd[].
break moralesv.
break abap01.
*-- Busca Condiciones
SELECT * FROM zmm_ico_cond
  INTO TABLE it_ico_cond
  WHERE inco1 EQ is_ekko-inco1.
*     OR inco1 EQ ' '.

*  IF is_pekko-prsdr EQ space.
*    EXIT.
*  ENDIF.

ls_komk-mandt = is_ekko-mandt.
IF is_ekko-kalsm NE space.
  ls_komk-kalsm = is_ekko-kalsm.
ELSE.
  ls_komk-kalsm = 'RM0000'.
ENDIF.
ls_komk-kappl = 'M'.
ls_komk-waerk = is_ekko-waers.
ls_komk-knumv = is_ekko-knumv.
ls_komk-bukrs = is_ekko-bukrs.
ls_komk-lifnr = is_ekko-lifnr.

CALL FUNCTION 'RV_PRICE_PRINT_HEAD'
  EXPORTING
    comm_head_i = ls_komk
    language    = gv_language
  IMPORTING
    comm_head_e = gs_komk
  TABLES
    tkomv       = gt_komv
    tkomvd      = gt_komvd.

LOOP AT gt_komvd INTO wa_komvd.

  gv_kwert = wa_komvd-kwert.

ENDLOOP.

*  BREAK sofosabap03.

* Buscando Datos de POS, para verificar pos borrada - Carlos P
*23.08.2011
  DATA: wa_ekpo_aux TYPE ekpo,
        it_ekpo_aux TYPE TABLE OF ekpo
        .
  CLEAR: wa_ekpo_aux.
*  IF <fs> is ASSIGNED .
    SELECT *
    FROM ekpo
    INTO CORRESPONDING FIELDS OF TABLE it_ekpo_aux
*    INTO wa_ekpo_aux
    WHERE
      EBELN eq IS_EKKO-EBELN
      "and EBELP eq <fs>-EBELP
      .
*  ENDIF.

*break sofosabap03.
clear: lv_tax.

*loop at gt_komv into wa_komv where "kschl eq 'ZIEP'  "IEPS
*                                 kschl eq 'XIM2'. "IVA
**  if wa_komv-kschl eq 'ZIEP'.
**    gv_ieps    = gv_ieps + wa_komv-kwert.
**  else.
*    gv_tax     = gv_tax  + wa_komv-kwert.
*    gv_porc = wa_komv-KBETR / 10.
**  endif.
*endloop.
*
*gv_tot = GV_SUBT + gv_tax.
BREAK MORALESV.
LOOP AT it_ico_cond.

  LOOP AT gt_komv INTO wa_komv WHERE kposn NE '000000'
                                 AND kschl EQ it_ico_cond-kschl
                                 AND kinak eq ' '.

    TRANSLATE it_ico_cond-renglon TO UPPER CASE.

    CASE it_ico_cond-renglon.
      WHEN 'IVA'.

        gv_tax = gv_tax + wa_komv-kwert.
        gv_porc = wa_komv-kbetr / 10.

*       Verificando Pos no Borrada CFPC 23.08.2011
        LOOP AT it_ekpo assigning <ekpo>.
          IF <ekpo>-LOEKZ is not initial.
            lv_tax = lv_tax + ( <ekpo>-NETPR * ( gv_porc * 100 ) ).
          ENDIF.
        ENDLOOP.
*       Restando Pos con Peticion de borrado, si es el caso
        gv_tax = gv_tax - lv_tax.

*        CLEAR: wa_ekpo_aux.
*        READ TABLE it_ekpo_aux INTO wa_ekpo_aux
*                               WITH  KEY
*                               EBELN = IS_EKKO-EBELN
*                               EBELP = wa_komv-kposn.
*        CHECK sy-subrc eq 0.
*        CHECK wa_ekpo_aux-LOEKZ IS INITIAL.
*        CHECK wa_ekpo_aux-LOEKZ IS INITIAL and
*              wa_ekpo_aux-EBELP eq  wa_komv-kposn.
      WHEN 'IEPS'.
********** AJUSTE ZIEP MCZ 22.10.2019
********** Se agrego una condición para
* poder identificar cuando el impuesto es ZIEP
        IF wa_komv-kschl = 'XIEP'.
         gv_ieps = gv_ieps + wa_komv-kwert.
         gv_porc2 = wa_komv-kbetr / 10.

        ELSEIF WA_KOMV-KSCHL = 'ZIEP'.

          gv_ieps = gv_ieps + wa_komv-kbetr.
          "gv_porc2 = wa_komv-kbetr / 10.

        endif.
***************************************

      WHEN 'DESCUENTO'.
        gv_desc = gv_desc + wa_komv-kwert.
      WHEN 'SEGURO'.
        gv_otca = gv_otca + wa_komv-kwert.
*        gv_otca_nac = gv_otca_nac + wa_komv-kwert.
      WHEN 'FLETE'.
        gv_flet = gv_flet + wa_komv-kwert.
*        gv_otca_nac = gv_otca_nac + wa_komv-kwert.
      "BOM: MGOB {
      WHEN 'RECARGOS'.
        gv_otca_nac = gv_otca_nac + wa_komv-kwert.
      "EOM: MGOB }
    ENDCASE.

  ENDLOOP.
ENDLOOP.

* Total
* BOM: MGOB {
*gv_tot = gv_subt + gv_desc + gv_flet + gv_otca + gv_tax.
gv_tot = gv_subt + gv_desc + gv_ieps + gv_flet + gv_otca + gv_tax +
gv_otca_nac.
* EOM: MGOB {

*  DATA: zcondcl LIKE zmm_cond_clases OCCURS 0 WITH HEADER LINE.
*
*  break abap01.
*  SELECT *
*  INTO TABLE zcondcl
*  FROM zmm_cond_clases
*  CLIENT SPECIFIED
*  WHERE mandt EQ sy-mandt.

*  LOOP AT gt_komv INTO wa_komv WHERE kposn NE '000000'.
*    LOOP AT zcondcl WHERE condicion = wa_komv-kschl.
**  READ TABLE zcondcl WITH KEY condicion = wa_komv-kschl.
*
**    IF sy-subrc EQ 0.
*
*      IF ( zcondcl-ekorg EQ is_ekko-ekorg OR zcondcl-ekorg EQ ' ' ) AND
*      ( zcondcl-inco1 EQ is_ekko-inco1 OR zcondcl-inco1 EQ ' ' ).
*
*        CASE zcondcl-tipo.
*
*          WHEN '01'.
*
*            gv_desc = gv_desc + wa_komv-kwert.
*
*          WHEN '02'.
*
*            gv_flet = gv_flet + wa_komv-kwert.
*
*          WHEN '03'.
*
*            gv_otca = gv_otca + wa_komv-kwert.
*
*        ENDCASE.
*
*      ELSEIF zcondcl-ekorg IS INITIAL.
*
*        CASE zcondcl-tipo.
*
*          WHEN '01'.
*
*            gv_desc = gv_desc + wa_komv-kwert.
*
*          WHEN '02'.
*
*            gv_flet = gv_flet + wa_komv-kwert.
*
*          WHEN '03'.
*
*            gv_otca = gv_otca + wa_komv-kwert.
*
*        ENDCASE.
*
*      ENDIF.
*
**    ENDIF.
*    ENDLOOP.
*ENDLOOP.

** Total
*  gv_tot = gv_subt + gv_desc + gv_flet + gv_otca.
