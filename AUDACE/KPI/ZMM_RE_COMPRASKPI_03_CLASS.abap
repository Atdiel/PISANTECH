FORM display_alv_on_screen .
  DATA: it_sort TYPE TABLE OF lvc_s_sort,
        wa_sort TYPE         lvc_s_sort.

  CLEAR: wa_sort.
  wa_sort-subtot = abap_true.
  wa_sort-fieldname = 'BANFN'.
  wa_sort-down = abap_true.
  APPEND wa_sort TO it_sort.

  CLEAR: wa_sort.
  wa_sort-fieldname = 'EBELN'.
  APPEND wa_sort TO it_sort.

  alv_container = NEW cl_gui_custom_container(
      container_name = 'REPORTE_CONTAINER' ).

  CREATE OBJECT obj_alv_grid
    EXPORTING
      i_parent = alv_container.

  obj_alv_grid->set_table_for_first_display(
    EXPORTING
      is_layout       = alv_layout
    CHANGING
      it_fieldcatalog = it_fcam
      it_outtab       = it_data
      it_sort         =  it_sort ).

ENDFORM.

FORM read_report_records .

  SELECT * FROM eban
    INTO TABLE solicitudes_de_pedido
    WHERE
*** MODIF. - 761 - 19/11/2025 - PTECHABAP01
      loekz = abap_false AND "Indicador de borrado
      badat IN s_fech AND
      ekgrp IN s_grpc.

  IF sy-subrc = 0.
    SORT solicitudes_de_pedido BY banfn bnfpo ebeln ebelp ASCENDING.
    DELETE ADJACENT DUPLICATES FROM solicitudes_de_pedido COMPARING banfn bnfpo ebeln ebelp.
    PERFORM fill_alv_table_for_solped.

*    IF sy-subrc = 0.
*      vl_flag = 'X'.
*      "Hacemos todo el proceso para la busqueda Caso Documentos de Compra.
*      PERFORM get_sale_documents_detail.
*      PERFORM fill_alv_table_for_sales_doc.
*    ENDIF.

    SORT it_data BY banfn.

* HJIMENEZ 04.07.2025 Ini:
  ELSE.
    MESSAGE 'No Existen Datos' TYPE 'I' DISPLAY LIKE 'S'.
* HJIMENEZ 04.07.2025 Fin.

  ENDIF.

ENDFORM.

FORM fill_alv_table_for_solped.

  "Buscamos documentos de compra para solicitudes con documento de compras.
  REFRESH docs.
  docs = VALUE #( FOR doc IN solicitudes_de_pedido ( banfn = doc-banfn bnfpo = doc-bnfpo ebeln = doc-ebeln ebelp = doc-ebelp werks = doc-werks ) ).
  PERFORM get_sales_documents USING docs.

  "Buscamos documento de material si es que tiene el documento de compras.
  PERFORM get_material_documents CHANGING docs.

  "Colocarlos en la tabla de ALV (Asigancion a work area de tabla de salida) .
  PERFORM append_lines_to_alv USING docs.

ENDFORM.

FORM get_sales_documents USING sales_docs TYPE sales_documents.
  REFRESH: documentos_de_compra, hora_documentos_compra.

  SELECT * FROM ekpo AS a
      INNER JOIN ekko AS b
      ON a~ebeln = b~ebeln
      INTO TABLE documentos_de_compra
      FOR ALL ENTRIES IN sales_docs
      WHERE
*        a~werks  = sales_docs-werks AND
        a~ebeln  = sales_docs-ebeln AND
*        b~lifnr IN s_prov        AND
        b~ekgrp IN s_grpc.

  IF sy-subrc = 0.
    SELECT * FROM t052u
      INTO TABLE it_052u
      FOR ALL ENTRIES IN documentos_de_compra
      WHERE spras = sy-langu
        AND zterm = documentos_de_compra-ekko-zterm.

    SELECT * FROM prcd_elements
      INTO TABLE it_prcd
      FOR ALL ENTRIES IN documentos_de_compra
      WHERE knumv = documentos_de_compra-ekko-knumv
        AND ( kschl = 'R001' OR kschl = 'R002' OR
              kschl = 'R003' OR kschl = 'PBXX' ).
  ENDIF.

*  SORT documentos_de_compra BY ekko-ebeln.
*  DELETE ADJACENT DUPLICATES FROM documentos_de_compra COMPARING ekko-ebeln.

  PERFORM get_sale_documents_detail .
ENDFORM.

*FORM fill_alv_table_for_sales_doc .
*  "Buscar solped para doc de compras
*  REFRESH docs.
*  docs = VALUE #( FOR doc IN documentos_de_compra ( ebeln = doc-ekko-ebeln banfn = doc-ekpo-banfn ebelp = doc-ekpo-ebelp ) ).
*  PERFORM get_solped_documents CHANGING docs.
*
*  "Buscar Documentos de Material para Documentos de compra
*  PERFORM get_material_documents CHANGING docs.
*
*  "Colocarlos en la tabla de ALV (Asigancion a work area de tabla de salida) .
*  PERFORM append_lines_to_alv USING docs.
*ENDFORM.

*&---------------------------------------------------------------------*
*& Form get_sale_documents_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_sale_documents_detail .

  REFRESH:  hora_documentos_compra, proveedores, grupos_de_compra.

  it_objectid =  VALUE #( FOR id IN documentos_de_compra ( objid = id-ekko-ebeln objid2 = id-ekpo-banfn ) ).

  SORT it_objectid BY objid objid2.
  DELETE ADJACENT DUPLICATES FROM it_objectid.

* HJIMENEZ 04.07.2025 Ini:
  IF NOT it_objectid IS INITIAL.
* HJIMENEZ 04.07.2025 Fin.

    SELECT * FROM cdpos
        INTO TABLE it_cdpos
        FOR ALL ENTRIES IN  it_objectid
        WHERE objectclas = 'BANF'
        AND   objectid = it_objectid-objid2
*** INICIO MODIF. - 761 - 19/11/2025 - PTECHABAP01
        AND   changenr  = ( SELECT MAX( changenr ) FROM cdpos
                              WHERE objectclas  = 'BANF' AND
                                    objectid    = it_objectid-objid2 AND
                                    fname       = 'FRGKZ' AND value_new = 'Y')
*** FIN MODIF.    - 761 - 19/11/2025 - PTECHABAP01
        AND   fname   = 'FRGKZ'
        AND   value_new = 'Y'.

    SELECT * FROM cdhdr
     INTO TABLE hora_documentos_compra
     FOR ALL ENTRIES IN it_cdpos
     WHERE
       objectid = it_cdpos-objectid AND
       changenr = it_cdpos-changenr.

* HJIMENEZ 04.07.2025 Ini.
  ENDIF.
* HJIMENEZ 04.07.2025 Fin.

  SELECT * FROM lfa1
    INTO TABLE proveedores
    FOR ALL ENTRIES IN documentos_de_compra
    WHERE
      lifnr       = documentos_de_compra-ekko-lifnr.

  SELECT * FROM t024
    INTO TABLE grupos_de_compra
    FOR ALL ENTRIES IN solicitudes_de_pedido "documentos_de_compra
    WHERE
      ekgrp       = solicitudes_de_pedido-ekgrp. "documentos_de_compra-ekko-ekgrp.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_material_documents
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- DOCS
*&---------------------------------------------------------------------*
FORM get_material_documents CHANGING  documents TYPE sales_documents .

  REFRESH documentos_de_material.
  "Busqueda a base de datos.

  SELECT * FROM ekbe
    INTO TABLE documentos_de_material
    FOR ALL ENTRIES IN documents
    WHERE ebeln = documents-ebeln
*      AND werks = documents-werks
      AND bwart = '101'.

  "Ordenamos por doc material para borrar posiciones de la entrega.
  IF sy-subrc = 0.
    SELECT * FROM mkpf
       INTO TABLE it_mkpf
       FOR ALL ENTRIES IN documentos_de_material
       WHERE mblnr = documentos_de_material-belnr.
  ENDIF.

  SELECT * FROM eket
   INTO TABLE it_eket
   FOR ALL ENTRIES IN documents "documentos_de_material
   WHERE ebeln = documents-ebeln. "documentos_de_material-ebeln.

  DATA all_material_docs TYPE sales_documents.
  DATA docs_with_material_docs TYPE sales_documents.
  LOOP AT documents INTO DATA(doc).
    "Para documentos de compra que si tienen doc de material
    IF line_exists( documentos_de_material[ ebeln = doc-ebeln ebelp = doc-ebelp ] ).
      "Un doc de compra puede tener mas de un doc de material.
      all_material_docs = VALUE #( FOR material_doc IN documentos_de_material WHERE ( ebeln = doc-ebeln AND ebelp = doc-ebelp )
                                          ( banfn = doc-banfn "Llenamos datos que ya teniamos del doc de compras
                                            bnfpo = doc-bnfpo
                                            ebeln = doc-ebeln "Como la solped
                                            belnr = material_doc-belnr
                                            ebelp = doc-ebelp
                                            werks = doc-werks ) ).

    ELSE.
      "Para documentos que no tienen doc de material.
      all_material_docs = VALUE #( ( banfn = doc-banfn bnfpo = doc-bnfpo ebeln = doc-ebeln
                                     ebelp = doc-ebelp werks = doc-werks ) ).
    ENDIF.

    APPEND LINES OF all_material_docs TO docs_with_material_docs.

  ENDLOOP.

  REFRESH: it_objectid.
  LOOP AT docs_with_material_docs INTO DATA(wa_solped).

* HJIMENEZ 04.07.2025 Ini:
    IF wa_solped-ebeln NE space.
* HJIMENEZ 04.07.2025 Fin.

      wa_objectid-objid = wa_solped-ebeln.
      APPEND wa_objectid TO it_objectid.

* HJIMENEZ 04.07.2025 Ini:
    ENDIF.
* HJIMENEZ 04.07.2025 Fin.

  ENDLOOP.

* HJIMENEZ 04.07.2025 Ini:
  IF NOT it_objectid IS INITIAL.
* HJIMENEZ 04.07.2025 Fin.

    SELECT *  FROM cdpos
      INTO CORRESPONDING FIELDS OF TABLE it_cdpos2
      FOR ALL ENTRIES IN it_objectid
      WHERE  objectid = it_objectid-objid AND
             fname    = 'FRGKE'  AND
            value_new = 'L'.

* HJIMENEZ 04.07.2025 Ini:
  ENDIF.
* HJIMENEZ 04.07.2025 Fin.

* HJIMENEZ 04.07.2025 Ini:
  IF sy-subrc = 0.
* HJIMENEZ 04.07.2025 Fin.

    SELECT * FROM cdhdr
     INTO CORRESPONDING FIELDS OF TABLE it_cdhdr
     FOR ALL ENTRIES IN it_cdpos2
     WHERE changenr = it_cdpos2-changenr.

* HJIMENEZ 04.07.2025 Ini:
  ENDIF.
* HJIMENEZ 04.07.2025 Fin.

  REFRESH documents.
  documents[] = docs_with_material_docs[].

ENDFORM.
*&---------------------------------------------------------------------*
*& Form append_lines_to_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> DOCS
*&---------------------------------------------------------------------*
FORM append_lines_to_alv USING documents TYPE sales_documents.

  nuevas_entradas_alv = VALUE #( FOR record IN documents
        ( banfn     = record-banfn
          bnfpo     = record-bnfpo
          frgdt     = VALUE #( solicitudes_de_pedido[ banfn = record-banfn ]-frgdt OPTIONAL )
          badat     = VALUE #( solicitudes_de_pedido[ banfn = record-banfn ]-badat OPTIONAL )
          bkgrp     = VALUE #( solicitudes_de_pedido[ banfn = record-banfn ]-ekgrp OPTIONAL )

          ebeln     = COND  #( WHEN record-ebeln IS NOT INITIAL
                        THEN  VALUE #( documentos_de_compra[ ekko-ebeln = record-ebeln ]-ekpo-ebeln OPTIONAL ) )

          ebdat     = VALUE #( documentos_de_compra[ ekko-ebeln = record-ebeln ]-ekko-bedat OPTIONAL )
          cduzeit   = VALUE #( hora_documentos_compra[ objectid = record-ebeln ]-utime OPTIONAL )

          mblnr     = VALUE #( documentos_de_material[ belnr = record-belnr ]-belnr OPTIONAL ) "record-belnr ] )
          budat     = VALUE #( documentos_de_material[ belnr = record-belnr ]-budat OPTIONAL )

          v_trasns2 = COND #( WHEN line_exists( documentos_de_compra[ ekko-ebeln = record-ebeln ] ) AND
                                        line_exists( documentos_de_material[ belnr = record-belnr ] )
                                  THEN documentos_de_material[ belnr = record-belnr ]-budat -
                                        documentos_de_compra[ ekko-ebeln = record-ebeln ]-ekko-bedat )

          elifn     = VALUE #( documentos_de_compra[ ekko-ebeln = record-ebeln ]-ekko-lifnr OPTIONAL )

          name1_gp  = VALUE #( proveedores[ lifnr = VALUE #( documentos_de_compra[ ekko-ebeln = record-ebeln ]-ekko-lifnr OPTIONAL ) ]-name1 OPTIONAL ) &&
                              VALUE #( proveedores[ lifnr = VALUE #( documentos_de_compra[ ekko-ebeln = record-ebeln ]-ekko-lifnr OPTIONAL ) ]-name2 OPTIONAL )

*          bkgrp     = VALUE #( documentos_de_compra[ ekko-ebeln = record-ebeln ]-ekko-ekgrp OPTIONAL )

*          eknam     = VALUE #( grupos_de_compra[ ekgrp = VALUE #( documentos_de_compra[ ekko-ebeln = record-ebeln ]-ekko-ekgrp OPTIONAL ) ]-eknam OPTIONAL )
          eknam     = VALUE #( grupos_de_compra[ ekgrp = VALUE #( solicitudes_de_pedido[ banfn = record-banfn ]-ekgrp OPTIONAL ) ]-eknam OPTIONAL )

          aedat     = VALUE #( documentos_de_compra[ ekko-ebeln = record-ebeln ]-ekko-aedat OPTIONAL )

          udate     =  VALUE #( hora_documentos_compra[ objectid = record-banfn ]-udate OPTIONAL )

          aedat1    = COND #( WHEN record-banfn IS NOT INITIAL AND record-ebeln IS NOT INITIAL
                                      THEN VALUE #( documentos_de_compra[ ekko-ebeln = record-ebeln ]-ekko-aedat OPTIONAL ) -
                                            VALUE #( hora_documentos_compra[ objectid = record-banfn ]-udate OPTIONAL ) )

          udate1    = COND #( WHEN record IS NOT INITIAL AND record-ebeln IS NOT INITIAL
                           THEN VALUE #( hora_documentos_compra[ objectid = record-banfn ]-udate OPTIONAL ) -
                                VALUE #( documentos_de_compra[ ekko-ebeln = record-ebeln ]-ekko-aedat OPTIONAL )  )

          budat1    = VALUE #( it_mkpf[ mblnr = record-belnr ]-budat OPTIONAL )
          eindt     = VALUE #( it_eket[ ebeln = record-ebeln ]-eindt OPTIONAL )

          pos       = COND #( WHEN record-ebelp IS NOT INITIAL
                        THEN VALUE #( documentos_de_compra[ ekpo-ebelp = record-ebelp ]-ekpo-ebelp OPTIONAL ) )

          doc_udate = VALUE #( it_cdhdr[ objectid = record-ebeln ]-udate OPTIONAL )

          moneda    = COND #( WHEN record-ebeln IS NOT INITIAL
                         THEN  VALUE #( documentos_de_compra[ ekko-ebeln = record-ebeln ]-ekko-waers OPTIONAL ) )

          zterm     = VALUE #( documentos_de_compra[ ekko-ebeln = record-ebeln ]-ekko-zterm OPTIONAL )

          werks     = record-werks
        ) ).

  PERFORM get_fechas.

  APPEND LINES OF nuevas_entradas_alv TO it_data.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_solped_documents
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- DOCS
*&---------------------------------------------------------------------*
FORM get_solped_documents CHANGING documents TYPE sales_documents.
  REFRESH solicitudes_de_pedido.

*  SELECT * FROM eban
*    INTO TABLE solicitudes_de_pedido
*    FOR ALL ENTRIES IN documents
*    WHERE
*      werks       = p_werks AND
*      ebeln       = documents-ebeln.

  solicitudes_de_pedido = it_eban.
  "Modificamos los documentos para dar seguimiento.
  SORT solicitudes_de_pedido BY banfn ebeln ebelp.
  DELETE ADJACENT DUPLICATES FROM solicitudes_de_pedido COMPARING banfn ebeln ebelp.

  LOOP AT documents INTO DATA(doc).
    DATA(idx) = sy-tabix.
    IF line_exists( solicitudes_de_pedido[ ebeln = doc-ebeln ebelp = doc-ebelp ] ).
      doc-banfn = solicitudes_de_pedido[ ebeln = doc-ebeln ]-banfn.
      MODIFY documents FROM doc INDEX idx.
    ELSE.
      CLEAR doc.
      doc-banfn = solicitudes_de_pedido[ ebeln = doc-ebeln ]-banfn.
      doc-bnfpo = solicitudes_de_pedido[ ebeln = doc-ebeln ]-banfn.
      APPEND doc TO documents.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM created_catalog .
  REFRESH it_fcam.

  it_fcam = VALUE #(

     ( tabname = 'IT_DATA' fieldname = 'WERKS'     scrtext_l = 'Centro' no_out = 'X')
     ( tabname = 'IT_DATA' fieldname = 'BANFN'     scrtext_l = 'Solicitud de pedido' )

     ( tabname = 'IT_DATA' fieldname = 'BADAT'     scrtext_l = 'Fecha solped.' )
     ( tabname = 'IT_DATA' fieldname = 'RESULT'    scrtext_l = 'Dias Transcurridos.' )
     ( tabname = 'IT_DATA' fieldname = 'UDATE'     scrtext_l = 'Lib. solped' )
     ( tabname = 'IT_DATA' fieldname = 'SMF1'      scrtext_l = 'Status' )

     ( tabname = 'IT_DATA' fieldname = 'EBELN'     scrtext_l = 'Doc. oc.' )
     ( tabname = 'IT_DATA' fieldname = 'V_TRANS'   scrtext_l = 'Dias Transcurridos'  )
     ( tabname = 'IT_DATA' fieldname = 'EBDAT'     scrtext_l = 'Fec. Doc. oc.' )
     ( tabname = 'IT_DATA' fieldname = 'SMF2'      scrtext_l = 'Status' )

     ( tabname = 'IT_DATA' fieldname = 'DAYS_TRAN' scrtext_l = 'Dias Transcurridos' )
     ( tabname = 'IT_DATA' fieldname = 'DOC_UDATE' scrtext_l = 'Fec. Lib. oc.' )
     ( tabname = 'IT_DATA' fieldname = 'SMF4'      scrtext_l = 'Status' )

     ( tabname = 'IT_DATA' fieldname = 'MBLNR'     scrtext_l = 'Documento de Material' )
     ( tabname = 'IT_DATA' fieldname = 'EINDT'     scrtext_l = 'Fec. ent. pln.')
     ( tabname = 'IT_DATA' fieldname = 'EINDT1'    scrtext_l = 'Dias transcurridos')
     ( tabname = 'IT_DATA' fieldname = 'BUDAT1'    scrtext_l = 'Fec. entrg. real.' )
     ( tabname = 'IT_DATA' fieldname = 'SMF3'      scrtext_l = 'Status' )

     ( tabname = 'IT_DATA' fieldname = 'BRTWR'     scrtext_l = 'Valor bruto'  )
     ( tabname = 'IT_DATA' fieldname = 'NETWR'     scrtext_l = 'Precio neto.' do_sum = 'X' )
     ( tabname = 'IT_DATA' fieldname = 'MONEDA'    scrtext_l = 'Divisa' )
     ( tabname = 'IT_DATA' fieldname = 'BRTWR1'    scrtext_l = 'Precio desc.')
     ( tabname = 'IT_DATA' fieldname = 'PORCT'     scrtext_l = 'Porcentaje desc')

     ( tabname = 'IT_DATA' fieldname = 'MATNR'     scrtext_l = 'Material' )
     ( tabname = 'IT_DATA' fieldname = 'TXZ01'     scrtext_l = 'Descripción' )

     ( tabname = 'IT_DATA' fieldname = 'ELIFN'     scrtext_l = 'Proveedor' )
     ( tabname = 'IT_DATA' fieldname = 'NAME1_GP'  scrtext_l = 'Nombre Proveedor' )
     ( tabname = 'IT_DATA' fieldname = 'BKGRP'     scrtext_l = 'Grupo Comp' )
     ( tabname = 'IT_DATA' fieldname = 'EKNAM'     scrtext_l = 'Nombre Comprador' )

     ( tabname = 'IT_DATA' fieldname = 'ZTERM'     scrtext_l = 'Condición de Pago' )
     ( tabname = 'IT_DATA' fieldname = 'TEXT1'     scrtext_l = 'Descripción' )
     ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_fechas
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_fechas.

* HJIMENEZ 04.07.2025 Ini:
  CLEAR: wa_solpeds.
* HJIMENEZ 04.07.2025 Fin.

  SELECT * FROM zmm_val_dias
    INTO CORRESPONDING FIELDS OF TABLE it_val_d.

  LOOP AT nuevas_entradas_alv INTO wa_nuevas_alv.

    PERFORM read_fec_it.
    PERFORM get_desc_material.
    PERFORM get_desc_conpag.
    PERFORM get_val_day_status.
* porcentaje
    wa_nuevas_alv-porct = ( ( wa_nuevas_alv-brtwr1 * 100 ) / wa_nuevas_alv-brtwr ) * -1 .

    PERFORM get_fechas_h.

* HJIMENEZ 04.07.2025 Ini:
    READ TABLE solicitudes_de_pedido INTO wa_solpeds WITH KEY banfn = wa_nuevas_alv-banfn
                                                              bnfpo = wa_nuevas_alv-bnfpo.

* Existen datos?
    IF sy-subrc = 0.
*** INICIO MODIF. - 761 - 20/11/2025 - PTECHABAP01
      IF wa_solpeds-frgst IS INITIAL.
        wa_nuevas_alv-udate = text-001.
      ENDIF.
*** FIN MODIF.    - 761 - 20/11/2025 - PTECHABAP01
      wa_nuevas_alv-bkgrp = wa_solpeds-ekgrp.
    ENDIF.

* Limpia area de trabajo.
    CLEAR: wa_solpeds.
* HJIMENEZ 04.07.2025 Fin.

    MODIFY nuevas_entradas_alv FROM wa_nuevas_alv.

    CLEAR: wa_nuevas_alv.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_fechas_h
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_fechas_h .

*  Calcular los dias habiles
  REFRESH it_fecha.

  CLEAR: wa_fecha.
  wa_fecha-date1 = wa_nuevas_alv-badat.
  wa_fecha-date2 = wa_nuevas_alv-udate.
  APPEND wa_fecha TO it_fecha.

  CLEAR: wa_fecha.
  wa_fecha-date1 = wa_nuevas_alv-udate.
  wa_fecha-date2 = wa_nuevas_alv-ebdat.
  APPEND wa_fecha TO it_fecha.

  CLEAR: wa_fecha.
  wa_fecha-date1 = wa_nuevas_alv-ebdat.
  wa_fecha-date2 = wa_nuevas_alv-budat1.
  APPEND wa_fecha TO it_fecha.
  CLEAR: wa_fecha.

  LOOP AT it_fecha INTO wa_fecha.

    CALL FUNCTION 'ZMM_COND_DIA'
      EXPORTING
        date_at = wa_fecha-date1
        date_to = wa_fecha-date2
      IMPORTING
        conta   = wa_nuevas_alv-dias_h.
    CLEAR: wa_fecha.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_val_day_status
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_val_day_status .
  REFRESH: it_rg_day.

*  validacion directa entre fecha planeada y real
  IF gv_auxe = 'X'.
    wa_nuevas_alv-smf3  = '@0A@'.
    wa_nuevas_alv-smfr3 = 0.
  ELSEIF wa_nuevas_alv-eindt1 >= 1.
    wa_nuevas_alv-smf3  = '@0A@'.
    wa_nuevas_alv-smfr3 = 0.
  ELSEIF wa_nuevas_alv-eindt1 <= 0.
    wa_nuevas_alv-smf3  = '@08@'.
    wa_nuevas_alv-smfr3 = 1.
  ENDIF.

* creacion de tabla, para valir en la tabla z
  IF gv_auxr = 'X'.
    wa_nuevas_alv-smf1  = '@0A@'.
    wa_nuevas_alv-smfr1 = 0.
  ELSE.
    CLEAR: wa_rg_day.
    wa_rg_day-dias = wa_nuevas_alv-result.
    wa_rg_day-desc = 'DÍAS DE LIBERACIÓN SOLPED'.
    APPEND wa_rg_day TO it_rg_day.
  ENDIF.

  IF gv_auxv = 'X'.
    wa_nuevas_alv-smf2  = '@0A@'.
    wa_nuevas_alv-smfr2 = 0.
  ELSE.
    CLEAR wa_rg_day.
    wa_rg_day-dias = wa_nuevas_alv-v_trans.
    wa_rg_day-desc = 'DÍAS DE CREACIÓN ORD. COMPRAS'.
    APPEND wa_rg_day TO it_rg_day.
  ENDIF.

  IF gv_auxd = 'X'.
    wa_nuevas_alv-smf4  = '@0A@'.
    wa_nuevas_alv-smfr4 = 0.
  ELSE.
    CLEAR wa_rg_day.
    wa_rg_day-dias = wa_nuevas_alv-days_tran.
    wa_rg_day-desc = 'DÍAS DOCUMENTOS DE COMPRAS'.
    APPEND wa_rg_day TO it_rg_day.
  ENDIF.

* lectura para dias habiles
  LOOP AT it_rg_day INTO wa_rg_day.

    CASE wa_rg_day-desc.

      WHEN 'DÍAS DE LIBERACIÓN SOLPED'.
        READ TABLE it_val_d INTO wa_val_d WITH KEY descripcion = wa_rg_day-desc.
        IF sy-subrc = 0.
          IF wa_rg_day-dias < wa_val_d-dias AND wa_rg_day-dias < 0.
            wa_nuevas_alv-smf1  = '@0A@'.
            wa_nuevas_alv-smfr1 = 0.
          ELSEIF wa_rg_day-dias = 0 OR wa_rg_day-dias >= wa_val_d-dias.
            wa_nuevas_alv-smf1  = '@08@'.
            wa_nuevas_alv-smfr1 = 1.
          ENDIF.
        ENDIF.
      WHEN 'DÍAS DE CREACIÓN ORD. COMPRAS'.
        READ TABLE it_val_d INTO wa_val_d WITH KEY descripcion = wa_rg_day-desc.
        IF sy-subrc = 0.
          IF wa_rg_day-dias < wa_val_d-dias AND wa_rg_day-dias < 0.
            wa_nuevas_alv-smf2  = '@0A@'.
            wa_nuevas_alv-smfr2 = 0.
          ELSEIF wa_rg_day-dias = 0 OR wa_rg_day-dias >= wa_val_d-dias.
            wa_nuevas_alv-smf2  = '@08@'.
            wa_nuevas_alv-smfr2 = 1.
          ENDIF.
        ENDIF.

      WHEN 'DÍAS DOCUMENTOS DE COMPRAS'.
        READ TABLE it_val_d INTO wa_val_d WITH KEY descripcion = wa_rg_day-desc.
        IF sy-subrc = 0.
          IF wa_rg_day-dias < wa_val_d-dias AND wa_rg_day-dias < 0.
            wa_nuevas_alv-smf4  = '@0A@'.
            wa_nuevas_alv-smfr4 = 0.
          ELSEIF wa_rg_day-dias = 0 OR wa_rg_day-dias >= wa_val_d-dias.
            wa_nuevas_alv-smf4  = '@08@'.
            wa_nuevas_alv-smfr4 = 1.
          ENDIF.
        ENDIF.

    ENDCASE.
    CLEAR: wa_rg_day.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form read_fec_it
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM read_fec_it .
  DATA: udate     TYPE udate,
        ebdat     TYPE ebdat,
        budat     TYPE budat,
        doc_udate TYPE udate.

  CLEAR: gv_auxr, gv_auxv, gv_auxd, gv_auxe,
         udate, ebdat, budat, doc_udate.

* si vienen vacios las fechas se le asigna la fecha actual
  IF wa_nuevas_alv-udate IS INITIAL.
*    wa_nuevas_alv-udate = sy-datum.
    wa_nuevas_alv-udate = 'Pendiente'.
    gv_auxr = 'X'.
    gv_auxv = 'X'.
  ELSE.
    udate = wa_nuevas_alv-udate.

    CONCATENATE wa_nuevas_alv-udate+6(2) '.' wa_nuevas_alv-udate+4(2) '.'
      wa_nuevas_alv-udate(4) INTO wa_nuevas_alv-udate.
  ENDIF.

  IF wa_nuevas_alv-ebdat IS INITIAL.
*    wa_nuevas_alv-ebdat = sy-datum.
    wa_nuevas_alv-ebdat = 'Pendiente'.
    gv_auxv = 'X'.
    gv_auxd = 'X'.
  ELSE.
    ebdat = wa_nuevas_alv-ebdat.

    CONCATENATE wa_nuevas_alv-ebdat+6(2) '.' wa_nuevas_alv-ebdat+4(2) '.'
      wa_nuevas_alv-ebdat(4) INTO wa_nuevas_alv-ebdat.
  ENDIF.

  IF wa_nuevas_alv-budat1 IS INITIAL.
*    wa_nuevas_alv-budat1 = sy-datum.
    wa_nuevas_alv-budat1 = 'Pendiente'.
    gv_auxe = 'X'.
  ELSE.
    budat = wa_nuevas_alv-budat1.

    CONCATENATE wa_nuevas_alv-budat1+6(2) '.' wa_nuevas_alv-budat1+4(2) '.'
      wa_nuevas_alv-budat1(4) INTO wa_nuevas_alv-budat1.
  ENDIF.

  IF wa_nuevas_alv-doc_udate IS NOT INITIAL.
    doc_udate = wa_nuevas_alv-doc_udate.
    wa_nuevas_alv-days_tran = ebdat - doc_udate.

    CONCATENATE wa_nuevas_alv-doc_udate+6(2) '.' wa_nuevas_alv-doc_udate+4(2) '.'
      wa_nuevas_alv-doc_udate(4) INTO wa_nuevas_alv-doc_udate.
  ELSE.
*    wa_nuevas_alv-doc_udate = sy-datum.
    wa_nuevas_alv-doc_udate = 'Pendiente'.
    wa_nuevas_alv-days_tran = ebdat - doc_udate.
    gv_auxd = 'X'.
  ENDIF.

*asignacion de fecha a it_data
  wa_nuevas_alv-eindt1 = budat - wa_nuevas_alv-eindt.
  wa_nuevas_alv-v_trans = udate - ebdat.

  IF wa_nuevas_alv-badat IS NOT INITIAL AND udate IS NOT INITIAL.
    wa_nuevas_alv-result = wa_nuevas_alv-badat - udate.
  ELSE.
    wa_nuevas_alv-result = 0.
  ENDIF.

  IF gv_auxr = 'X'.
    CLEAR wa_nuevas_alv-result.
  ENDIF.

  IF gv_auxv = 'X'.
    CLEAR wa_nuevas_alv-v_trans.
  ENDIF.

  IF gv_auxd = 'X'.
    CLEAR wa_nuevas_alv-days_tran.
  ENDIF.

  IF gv_auxe = 'X'.
    CLEAR wa_nuevas_alv-eindt1.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_desc_material
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_desc_material .

  READ TABLE documentos_de_compra INTO DATA(compra) WITH KEY ekpo-ebelp = wa_nuevas_alv-pos
                                                             ekpo-ebeln = wa_nuevas_alv-ebeln.
  IF sy-subrc = 0.
*** MODIF. - 761 - 19/11/2025 - PTECHABAP01
    wa_nuevas_alv-ernam   = compra-ekko-ernam.
    wa_nuevas_alv-matnr  = compra-ekpo-matnr.
    wa_nuevas_alv-txz01  = compra-ekpo-txz01.

    CLEAR wa_prcd.
    READ TABLE it_prcd INTO wa_prcd WITH KEY knumv = compra-ekko-knumv
                                             kposn = compra-ekpo-ebelp
                                             kschl = 'PBXX'.
    IF sy-subrc = 0.
      wa_nuevas_alv-brtwr  = wa_prcd-kwert.  "valor bruto
    ENDIF.

    CLEAR wa_prcd.
    LOOP AT it_prcd INTO wa_prcd WHERE knumv = compra-ekko-knumv
                                   AND kposn = compra-ekpo-ebelp
                                   AND kschl <> 'PBXX'.
      wa_nuevas_alv-netwr  = wa_nuevas_alv-brtwr + wa_prcd-kwert. "valor neto
      wa_nuevas_alv-brtwr1 = wa_prcd-kwert.
    ENDLOOP.
  ELSE.
    READ TABLE solicitudes_de_pedido INTO DATA(solped) WITH KEY banfn = wa_nuevas_alv-banfn
                                                                bnfpo = wa_nuevas_alv-bnfpo.
    IF sy-subrc = 0.
      wa_nuevas_alv-matnr  = solped-matnr.
      wa_nuevas_alv-txz01  = solped-txz01.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_desc_conpag
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_desc_conpag .
  CLEAR wa_052u.
  READ TABLE it_052u INTO wa_052u WITH KEY zterm = wa_nuevas_alv-zterm.
  IF sy-subrc = 0.
    wa_nuevas_alv-text1 = wa_052u-text1.
  ENDIF.
ENDFORM.
