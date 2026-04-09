FUNCTION z_fct_mm_check_stock.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  IMPORTING
*"     REFERENCE(SS_TCODE) LIKE  SY-TCODE
*"     REFERENCE(SS_EINRI) TYPE  EINRI
*"  TABLES
*"      SS_REQUISITIONS_TAB STRUCTURE  /ISHMX/STR_REQUISITION
*"----------------------------------------------------------------------
  DATA: it_0047 TYPE TABLE OF zmmt0047,
        ls_0047 TYPE zmmt0047,
        it_0080 TYPE TABLE OF zmmt0080,
        ls_0080 TYPE zmmt0080,
        it_0083 TYPE TABLE OF zmmt0083,
        ls_0083 TYPE zmmt0083,
        it_mara TYPE TABLE OF mara,
        ls_mara TYPE mara,
        it_nbew TYPE TABLE OF nbew,
        ls_nbew TYPE nbew,
        lv_bett TYPE nbew-bett.
  DATA: ls_0145 TYPE zist0145,
        it_mchb TYPE TABLE OF mchb,
        ls_mchb TYPE mchb.

  DATA: uoctr   TYPE norg.

* Check if localization is active

  CALL FUNCTION '/ISHMX/FCT_CHECK_LOC'
    EXPORTING
      ss_einri                = ss_einri
    EXCEPTIONS
      localization_not_active = 1
      OTHERS                  = 2.


  CHECK sy-subrc EQ 0.

* Only executed for NMM7 or NMM8 Report o Job de fondo

  CHECK ss_tcode = mantain_goods_issue OR
        ss_tcode = display_goods_issue OR
        ss_tcode = 'SE38' OR sy-batch = 'X'.

  DESCRIBE TABLE ss_requisitions_tab LINES lines.

  SELECT * FROM zmmt0047
    INTO CORRESPONDING FIELDS OF TABLE it_0047.

  SELECT * FROM zmmt0080
    INTO CORRESPONDING FIELDS OF TABLE it_0080
    FOR ALL ENTRIES IN ss_requisitions_tab
    WHERE matnr = ss_requisitions_tab-matnr.

  SELECT * FROM zmmt0083
    INTO CORRESPONDING FIELDS OF TABLE it_0083.

  SELECT matnr mtart
    FROM mara
    INTO CORRESPONDING FIELDS OF TABLE it_mara
    FOR ALL ENTRIES IN ss_requisitions_tab
    WHERE matnr = ss_requisitions_tab-matnr
      AND mtart = 'ZROP'.

  LOOP AT ss_requisitions_tab WHERE mblnr IS INITIAL.
    tabix = sy-tabix.
    CHECK tabix LE lines.

    CLEAR v_sllgo. CLEAR avail_stock.
    CLEAR t_stock. CLEAR: ls_mara, lv_bett.
    IMPORT lv_bett FROM MEMORY ID 'BETT'.
** OSS
    IF lv_bett IS INITIAL.
      SELECT einri falnr lfdnr orgfa orgpf zimmr bett
        FROM nbew
        INTO CORRESPONDING FIELDS OF TABLE it_nbew
        WHERE einri = ss_requisitions_tab-einri
          AND falnr = ss_requisitions_tab-falnr
          AND orgfa = ss_requisitions_tab-anfoe
          AND orgpf = ss_requisitions_tab-anpoe
          AND storn NE 'X'.
      IF it_nbew[] IS NOT INITIAL. "sy-subrc = 0.
        SORT it_nbew BY lfdnr DESCENDING.
        READ TABLE it_nbew INTO ls_nbew INDEX 1.
        IF sy-subrc = 0.
          IF ls_nbew-bett IS NOT INITIAL.
            lv_bett = ls_nbew-bett.
          ELSE.
            IF ls_nbew-zimmr IS NOT INITIAL.
              lv_bett = ls_nbew-zimmr.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
** OSS

*   Check material stock
    READ TABLE it_0047 INTO ls_0047
      WITH KEY einri = ss_requisitions_tab-einri
               anpoe = ss_requisitions_tab-anpoe
               anfoe = ss_requisitions_tab-anfoe
               bett  = lv_bett.
    IF sy-subrc = 0.
      READ TABLE it_mara INTO ls_mara
        WITH KEY matnr = ss_requisitions_tab-matnr.
      IF sy-subrc = 0.
        v_sllgo = ls_0047-lgort.
      ELSE.
        SELECT SINGLE sllgo FROM norg INTO v_sllgo
                            WHERE orgid = ss_requisitions_tab-anpoe.
      ENDIF.
    ELSE.
      SELECT SINGLE * FROM zist0145
        INTO CORRESPONDING FIELDS OF ls_0145
        WHERE einri = ss_requisitions_tab-einri
          AND orgfa = ss_requisitions_tab-anfoe
          AND reser = 'X'.
      IF sy-subrc EQ 0.
        v_sllgo = ls_0145-lgort.
        ss_requisitions_tab-werks = ls_0145-werks.
      ELSE.
        SELECT SINGLE * FROM zist0145
          INTO CORRESPONDING FIELDS OF ls_0145
          WHERE einri = ss_requisitions_tab-einri
            AND orgfa = ss_requisitions_tab-anpoe
            AND reser = 'X'.
        IF sy-subrc EQ 0.
          v_sllgo = ls_0145-lgort.
          ss_requisitions_tab-werks = ls_0145-werks.
        ELSE.
          SELECT SINGLE sllgo FROM norg INTO v_sllgo
                              WHERE orgid = ss_requisitions_tab-anpoe.
        ENDIF.
      ENDIF.
      READ TABLE it_0080 INTO ls_0080 WITH KEY matnr = ss_requisitions_tab-matnr.
*                                               orgpf = ss_requisitions_tab-anpoe.
      IF sy-subrc = 0.
        CALL FUNCTION 'ISH_READ_NORG'
          EXPORTING
               orgid  = ss_requisitions_tab-anpoe
          IMPORTING
               norg_e = uoctr
          EXCEPTIONS
               OTHERS = 2.

        READ TABLE it_0083 INTO ls_0083
          WITH KEY einri = ss_requisitions_tab-einri
                   werks = uoctr-slwrk
                   orgpf = ss_requisitions_tab-anpoe
                   zimmr = lv_bett.
        IF sy-subrc = 0.
          v_sllgo = ls_0083-lgort.
        ELSE.
          READ TABLE it_0083 INTO ls_0083
          WITH KEY einri = ss_requisitions_tab-einri
                   orgpf = ss_requisitions_tab-anpoe
                   zimmr = lv_bett.
          IF sy-subrc = 0.
            v_sllgo = ls_0083-lgort.
          ELSE.
            READ TABLE it_0083 INTO ls_0083
              WITH KEY einri = ss_requisitions_tab-einri
                       orgpf = ss_requisitions_tab-anpoe.
            IF sy-subrc = 0.
              v_sllgo = ls_0083-lgort.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    IF v_sllgo IS NOT INITIAL.
*    if sy-subrc eq 0.

      SELECT SINGLE labst FROM mard INTO avail_stock
                          WHERE matnr = ss_requisitions_tab-matnr
                            AND werks = ss_requisitions_tab-werks
                            AND lgort = v_sllgo.


      IF sy-subrc EQ 0 AND avail_stock EQ 0.


*       If no stock left ----> Reservation
        ss_requisitions_tab-lfsta = item_requested.
        ss_requisitions_tab-mbart = reservation.
        MODIFY ss_requisitions_tab INDEX tabix.
      ELSE.
*       If material does not exist in plant -----> Purchase Requeriment
        IF sy-subrc > 0.
          ss_requisitions_tab-lfsta = item_requested.
          ss_requisitions_tab-mbart = purchase_req.
          MODIFY ss_requisitions_tab INDEX tabix.
        ELSE.

*         If available stock lower than requested ---> Reservation.
          SELECT SINGLE umrez FROM  marm INTO v_numerator
                              WHERE matnr = ss_requisitions_tab-matnr
                                AND meinh = ss_requisitions_tab-meins.

          IF sy-subrc EQ 0.

            avail_stock = avail_stock / v_numerator.

          ENDIF.

          READ TABLE t_stock WITH KEY matnr = ss_requisitions_tab-matnr
                                      werks = ss_requisitions_tab-werks
                                      lgort = v_sllgo.
          IF sy-subrc NE 0.

            MOVE: ss_requisitions_tab-matnr TO t_stock-matnr,
                  ss_requisitions_tab-werks TO t_stock-werks,
                  v_sllgo                   TO t_stock-lgort,
                  avail_stock               TO t_stock-stock.

            APPEND t_stock.

          ENDIF.

          IF t_stock-stock LT ss_requisitions_tab-menge.
* Begin 28/08/2003
* Keep in v_need requested quantity.
            v_need = ss_requisitions_tab-menge.
* End 28/08/2003
*           If available stock lower than requested ---> Reservation
            SUBTRACT t_stock-stock FROM ss_requisitions_tab-menge.
* Begin 28/08/2003
* No decimal quantity for issues/reservations
* Ex: 10,5 available and 11 needed => Issue 10 and reserve 1(NOT 0,5!!!)
            COMPUTE t_stock-stock     = trunc( t_stock-stock ).
            ss_requisitions_tab-menge = v_need - t_stock-stock.
* End 28/08/2003
            ss_requisitions_tab-lfsta = item_requested.
            ss_requisitions_tab-mbart = reservation.
            MODIFY ss_requisitions_tab INDEX tabix.
            ss_requisitions_tab-lfsta = item_completely_delivered.
            ss_requisitions_tab-mbart = goods_issue.
            ss_requisitions_tab-menge = t_stock-stock.
            PERFORM nmatp_get_number CHANGING ss_requisitions_tab-lnrlm.
            APPEND ss_requisitions_tab.
          ELSE.
            ss_requisitions_tab-lfsta = item_completely_delivered.
            ss_requisitions_tab-mbart = goods_issue.
            MODIFY ss_requisitions_tab INDEX tabix.
          ENDIF.
          SUBTRACT ss_requisitions_tab-menge FROM t_stock-stock.
          MODIFY t_stock TRANSPORTING stock
                                 WHERE matnr = ss_requisitions_tab-matnr
                                   AND werks = ss_requisitions_tab-werks
                                   AND lgort = v_sllgo.

        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.
* Modif. OSS27112020 - Ajustes a Roperia
  IF ss_requisitions_tab[] IS NOT INITIAL AND sy-tcode NE '/ISHMX/TRN_MM_PICK'.
    CALL FUNCTION 'ZMFISH_SALIDA_ROPERIA'
      EXPORTING
        bett         = lv_bett
      TABLES
        requisitions = ss_requisitions_tab[].
  ENDIF.
* F. Modif. OSS27112020

*** INICIO MODIF. - 3565 - 05/03/2026 - Ramón Quintana DEVBT02

  CALL FUNCTION 'ZISMF_CHECK_NEW_RESERVATION'
    EXPORTING
      iv_einri =  ss_einri   " IS-H: Centro sanitario
      iv_falnr =  ss_requisitions_tab-falnr   " IS-H: Número de episodio
      iv_anfoe =  ss_requisitions_tab-anfoe   " IS-H: Unidad organizativa médica que solicita un material
      iv_anpoe =  ss_requisitions_tab-anpoe   " IS-H: Unidad organizativa enfermería que solicita material
    .
*** FIN MODIF.    - 3565 - 05/03/2026 - Ramón Quintana DEVBT02
ENDFUNCTION.