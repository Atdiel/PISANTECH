*&---------------------------------------------------------------------*
*& Include          ZMM_RE_COMPRASKPI_03_TOP
*&---------------------------------------------------------------------*
*** INICIO MODIF. - 761 - 24/11/2025 - PTECHABAP01
CLASS lcl_event_handler DEFINITION DEFERRED.
DATA: go_event_handler TYPE REF TO lcl_event_handler.
TYPES: BEGIN OF gtype_deliveried,
         ebeln TYPE ekko-ebeln,
         ebelp TYPE ekpo-ebelp,
         menge TYPE dmbtr,
       END OF gtype_deliveried,
       BEGIN OF gtype_hist_serv,
         ebeln TYPE ebeln,
         ebelp TYPE ebelp,
         belnr TYPE belnr_d,
         buzei TYPE eslh-ebelp,
       END OF gtype_hist_serv.


DATA: gt_deliveried TYPE TABLE OF gtype_deliveried,
      gs_deliveried TYPE gtype_deliveried,
      gt_hist_serv  TYPE TABLE OF gtype_hist_serv.
*** FIN MODIF.    - 761 - 24/11/2025 - PTECHABAP01

DATA: ok_code TYPE sy-ucomm.

DATA: it_fcam       TYPE lvc_t_fcat,
*       wa_fcam       TYPE lvc_s_fcat,
      alv_container TYPE REF TO cl_gui_custom_container,
      obj_alv_grid  TYPE REF TO cl_gui_alv_grid,
      alv_layout    TYPE lvc_s_layo.
*       rows          TYPE lvc_t_row,
*       wa_row        TYPE lvc_s_row.

TYPES: BEGIN OF ty_data,
         werks         TYPE werks_d,  "Centro
         banfn         TYPE banfn,    "solped
         badat         TYPE badat,    "fecha solped
         result        TYPE i,        "Días transcurridos
         udate(10)     TYPE c,        "Fe. liberación solped
         smf1          TYPE icon_d,   "Status1
         ebeln         TYPE ebeln,    "sale doc
*** MODIF. - 761 - 19/11/2025 - PTECHABAP01
         ernam         TYPE ernam,    "Usuario creador de po
         v_trans       TYPE i,        "Días transcurridos
         ebdat(10)     TYPE c,        "fecha_sale_doc
         smf2          TYPE icon_d,   "Status2
         days_tran     TYPE i,        "Días transcurridos
         doc_udate(10) TYPE c,        "Fecha liberación sale doc
         smf4          TYPE icon_d,   "Status4
         mblnr         TYPE mblnr,    "documento de material
         eindt         TYPE eindt,    "entg. real vs fech. prog.
         eindt1        TYPE i,        "fecha entrega posiccion
*** MODIF. - <ID_requrimiento> - <Fecha_Mod> - <User>
         ctd_pend      TYPE menge_d,  "Cantidad pendiente a entregar
         budat1(10)    TYPE c,        "fecha contabilizacion doc
         smf3          TYPE icon_d,   "Status3
         brtwr         TYPE bbwert,   "valor bruto pedido moneda pedido
         netwr         TYPE wertv8,   "Valor neto.
         moneda        TYPE waers,
         brtwr1        TYPE bbwert,
         porct(6)      TYPE c,
         matnr         TYPE matnr,
         txz01         TYPE txz01,
         elifn         TYPE elifn,    "proveedor
         name1_gp      TYPE name1_gp, "nombre de un interlocutor
         bkgrp         TYPE bkgrp,    "comprador
         eknam         TYPE eknam,    "grupo de compras
         zterm         TYPE dzterm,
         text1         TYPE text1_052,
         "------------------------------------------------------------------------
         frgdt         TYPE frgdt,
         bnfpo         TYPE bnfpo,    "Posición solped
         cduzeit       TYPE cduzeit,  "tiempo sale doc
         budat         TYPE budat,    "fecha
         cputm         TYPE cputm,    "hora de entrada
         v_trasns2     TYPE i,
         aedat         TYPE aedat,    "T. elab ord.c y liberado
         aedat1        TYPE i,        "fecha creacion documento
         udate1        TYPE i,        "fecha de modificacion solped
         status        TYPE icon_d,   "icon
         netpr1        TYPE bprei,
         dias_h        TYPE i,
         pos           TYPE ebelp,
         result2       TYPE i,
         smfr1         TYPE int1,
         smfr2         TYPE int1,
         smfr3         TYPE int1,
         smfr4         TYPE int1,
       END OF ty_data.

DATA: it_data TYPE STANDARD TABLE OF ty_data.

DATA: "s_lifnr TYPE ekko-lifnr, "Proveedor
  s_ekgrp TYPE ekko-ekgrp, "Grupo de compras
  s_badat TYPE eban-badat. "Fecha de doc. compras
DATA: vl_flag TYPE c.

* Rangos y alv
TYPES: BEGIN OF gtype_ekko_ekpo,
         ekpo TYPE ekpo,
         ekko TYPE ekko,
       END OF gtype_ekko_ekpo,
       BEGIN OF gtype_sale_documents,
         banfn TYPE banfn,
         bnfpo TYPE bnfpo,
         ebeln TYPE ebeln,
         belnr TYPE mblnr,
         ebelp TYPE ebelp,
         werks TYPE werks_d,
       END OF gtype_sale_documents,
       sales_documents TYPE TABLE OF gtype_sale_documents.

DATA: solicitudes_de_pedido  TYPE TABLE OF eban,
      documentos_de_compra   TYPE TABLE OF gtype_ekko_ekpo,
      documentos_de_material TYPE TABLE OF ekbe,
      hora_documentos_compra TYPE TABLE OF cdhdr,
      proveedores            TYPE TABLE OF lfa1,
      grupos_de_compra       TYPE TABLE OF t024,
      docs                   TYPE TABLE OF gtype_sale_documents.

DATA: it_mkpf   TYPE TABLE OF mkpf,
      it_eket   TYPE TABLE OF eket,
      it_cdpos  TYPE TABLE OF cdpos,
      it_cdpos2 TYPE TABLE OF cdpos,
      it_cdhdr  TYPE TABLE OF cdhdr,
      it_eban   TYPE TABLE OF eban,
      it_val_d  TYPE TABLE OF zmm_val_dias,
      wa_val_d  TYPE          zmm_val_dias,
      it_zmmkpi TYPE TABLE OF zmm_kpi,
      wa_001w   TYPE t001w,
      it_052u   TYPE TABLE OF t052u,
      wa_052u   TYPE t052u,
      it_prcd   TYPE TABLE OF prcd_elements,
      wa_prcd   TYPE prcd_elements.

* HJIMENEZ 04.07.2025 Ini:
DATA: wa_solpeds LIKE LINE OF solicitudes_de_pedido.
* HJIMENEZ 04.07.2025 Fin.

TYPES: BEGIN OF ty_obj,
         objid  TYPE cdpos-objectid,
         objid2 TYPE cdpos-objectid,
       END OF ty_obj.

TYPES: BEGIN OF ty_fechas,
         date1 TYPE datum,
         date2 TYPE datum,
       END OF ty_fechas.

TYPES: BEGIN OF ty_rg_day,
         dias     TYPE i,
         desc(30) TYPE c,
       END OF ty_rg_day.

DATA: it_objectid TYPE TABLE OF ty_obj,
      wa_objectid TYPE          ty_obj,
      it_fecha    TYPE TABLE OF ty_fechas,
      wa_fecha    TYPE          ty_fechas,
      it_rg_day   TYPE TABLE OF ty_rg_day,
      wa_rg_day   TYPE          ty_rg_day.

DATA: nuevas_entradas_alv TYPE TABLE OF ty_data,
      wa_nuevas_alv       TYPE ty_data.

DATA: gv_auxr TYPE c,
      gv_auxv TYPE c,
      gv_auxd TYPE c,
      gv_auxe TYPE c.

*  Pantalla de seleccion
SELECTION-SCREEN: BEGIN OF BLOCK b1.
*   PARAMETERS: p_werks  TYPE eban-werks OBLIGATORY.

  SELECT-OPTIONS:
*   s_prov FOR s_lifnr,
  s_grpc FOR s_ekgrp,
  s_fech FOR s_badat OBLIGATORY.
SELECTION-SCREEN: END OF BLOCK b1.