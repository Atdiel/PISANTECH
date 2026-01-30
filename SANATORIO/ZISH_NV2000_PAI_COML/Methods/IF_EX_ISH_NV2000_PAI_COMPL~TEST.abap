METHOD if_ex_ish_nv2000_pai_compl~test.
  DATA: l_borrado TYPE c,
        l_aseg    TYPE nktr-kostr,
        w_instab  LIKE LINE OF i_instab,
        w_message TYPE bapiret2,
        w_doctab  LIKE LINE OF i_doctab,
        l_fec1    TYPE sy-datum,
        l_fec2    TYPE sy-datum.

  DATA: it_nbeww TYPE TABLE OF nbew.


*  if sy-ucomm = 'SAVE'.
*
**    SELECT ORGFA LFDNR
**      from nbew
**      INTO CORRESPONDING FIELDS OF TABLE it_nbeww
**      WHERE  falnr EQ i_falnr.
**
**      DESCRIBE TABLE it_nbeww LINES DATA(wa_nbew2).
**
**      READ TABLE it_nbeww INTO DATA(wa_nbew3) INDEX wa_nbew2.
**
**      IF wa_nbew3-orgfa is INITIAL.
**       MESSAGE 'Favor de llenar los campos obligatorios' TYPE 'W'.
**      ENDIF.
*    ENDIF.

  IF i_falnr EQ ''.
    LOOP AT i_instab INTO w_instab WHERE storn NE 'X'.

      l_aseg = w_instab-kostr.
      SELECT SINGLE loekz
        INTO l_borrado
        FROM nktr
       WHERE kostr = l_aseg.

      IF sy-subrc = 0 AND l_borrado = 'X'.
        w_message-type = 'E'.
        w_message-id   = 'ZISH'.
        w_message-number = 3.
        w_message-message = 'No se permite relacion con aseguradora porque ha sido fijada para borrado'.
        APPEND w_message TO c_messages.
        c_worst_msg_type = 'E'.
      ENDIF.
    ENDLOOP.
  ENDIF.
*  LOOP AT i_doctab INTO w_doctab WHERE storn NE 'X'.
*    SELECT SINGLE spvon spbis
*      INTO (l_fec1, l_fec2)
*      FROM ngpa
*     WHERE gpart = w_doctab-pernr.
*    IF sy-subrc = 0.
*      IF l_fec1 IS NOT INITIAL OR l_fec2 IS NOT INITIAL.
*        IF sy-datum >= l_fec1 OR sy-datum <= l_fec2.
*          w_message-type = 'E'.
*          w_message-id   = 'ZISH'.
*          w_message-number = 4.
*          w_message-message = 'No se Permite Interlocutor Bloqueado!'.
*          APPEND w_message TO c_messages.
*          c_worst_msg_type = 'E'.
*        ENDIF.
*      ENDIF.
*    ENDIF.
*  ENDLOOP.
  DATA : rc1 TYPE sy-subrc,
         rc2 TYPE sy-subrc,
         rc3 TYPE sy-subrc.
  DATA: ls_0082    TYPE zist0082,
        ls_folio   TYPE zmmmxt1005,
        ls_message TYPE string.
  DATA: it_nbew TYPE TABLE OF nbew,
        ls_nbew TYPE nbew.

  FIELD-SYMBOLS: <rndbew> TYPE rndbew,
                 <rnpat>  TYPE rnpat,
                 <rndfal> TYPE rndfal.

  ASSIGN ('(SAPLNBE2)RNDBEW') TO <rndbew>.
  rc1 = sy-subrc.
  ASSIGN ('(SAPLNPA2)RNPAT')  TO <rnpat>.
  rc2 = sy-subrc.
  ASSIGN ('(SAPLNFA2)RNDFAL') TO <rndfal>.
  rc3 = sy-subrc.


*  IF ( sy-ucomm = 'STO' ).
*    SELECT SINGLE * FROM zmmmxt1005
*    INTO CORRESPONDING FIELDS OF  ls_folio
*    WHERE einri = i_institution AND
*      falnr = i_falnr AND
*      lfdnr = i_lfdnr.
*
*    IF sy-subrc EQ '0'.
*      CONCATENATE
*       'Está consulta no se puede eliminar, ya que está asociado a un folio:'
*       ls_folio-folio INTO ls_message SEPARATED BY space.
*
*      MESSAGE ls_message TYPE 'I'.
*      LEAVE PROGRAM.
*    ENDIF.
*  ENDIF.

  DATA: lt_0189  TYPE TABLE OF zist0189,
        ls_0189  TYPE zist0189,
        lv_area  TYPE xfeld,
        lv_statu TYPE nbew-statu,
        lv_kztxt TYPE nbew-kztxt.
  DATA: lt_0100 TYPE  TABLE OF zist0100,
        ls_0100 TYPE zist0100.

  IF rc1 = '0' AND rc2 = '0' AND rc3 = '0' .
    IF i_vcode EQ 'UPD' AND
      ( sy-ucomm = 'END' OR sy-ucomm = 'BACK' OR sy-ucomm = 'SAVE' )
      AND sy-tcode = 'NV2001'.

      SELECT * FROM zist0189
        INTO CORRESPONDING FIELDS OF TABLE lt_0189
        WHERE einri = <rndbew>-einri.

      READ TABLE lt_0189 INTO ls_0189 WITH KEY orgfa = <rndbew>-orgfa.
      IF sy-subrc EQ 0.
        lv_area = 'X'.
      ELSE.
        READ TABLE lt_0189 INTO ls_0189 WITH KEY orgfa = <rndbew>-orgpf.
        IF sy-subrc = 0.
          lv_area = 'X'.
        ENDIF.
      ENDIF.
      IF lv_area = 'X'.
        SELECT SINGLE statu kztxt FROM nbew
          INTO (lv_statu, lv_kztxt)
          WHERE einri = <rndbew>-einri
            AND falnr = <rndbew>-falnr
            AND lfdnr = <rndbew>-lfdnr.

        IF lv_statu = '70' OR lv_statu = '30'.
          SELECT * FROM zist0100 INTO TABLE lt_0100
            WHERE orgfa = ls_0189-orgfa.
          IF sy-subrc = 0.
            READ TABLE lt_0100 INTO ls_0100 WITH KEY uname = sy-uname.
            IF sy-subrc <> 0.
              SELECT SINGLE * FROM zist0100 INTO ls_0100
                WHERE orgfa = '*' AND uname = sy-uname.
              IF sy-subrc <> 0.
                MESSAGE 'Sin autorización para modificar una consulta concluida'
                   TYPE 'E'.
              ENDIF.
            ENDIF.
          ELSE.
            MESSAGE 'Sin autorización para modificar una consulta concluida'
               TYPE 'E'.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  IF rc1 = '0' AND rc2 = '0' AND rc3 = '0' .
    IF ( i_vcode EQ 'UPD' OR i_vcode = 'INS' ) AND
      ( sy-ucomm = 'SAVE' OR sy-ucomm = 'FURT' OR sy-ucomm = 'PRIF' ).
      IF sy-cprog <> 'SAPMNPA10'.
        IF <rndbew>-orgfa IS INITIAL AND <rndbew>-orgpf IS INITIAL.
          MESSAGE 'Requiere llenar los campos UO MEDICA y UO TRATAMIENTO para continuar.' TYPE 'E'.
          LEAVE PROGRAM.
        ENDIF.
      ENDIF.

*   Validación de Imagenología
      IF sy-ucomm = 'PRIF'.
        IF <rndfal>-falar = '2'.
          IF ( <rndbew>-orgfa IS NOT INITIAL OR <rndbew>-orgpf IS NOT INITIAL )
            AND <rndbew>-falnr IS NOT INITIAL AND <rndbew>-bwart = 'Z8'.
            SELECT SINGLE * FROM zist0082 INTO ls_0082
                                         WHERE einri = <rndbew>-einri
                                           AND orgfa = <rndbew>-orgfa.
            IF sy-subrc EQ '0'.
              CALL FUNCTION 'ZBCMF_ALV_IMAGEN'
                EXPORTING
                  i_einri = <rndbew>-einri
                  i_falnr = <rndbew>-falnr
                  i_lfdnr = i_lfdnr
                  i_kztxt = <rndbew>-kztxt
                  i_vcode = i_vcode.
            ELSE.
              SELECT SINGLE * FROM zist0082 INTO ls_0082
                                           WHERE einri = <rndbew>-einri
                                             AND orgfa = <rndbew>-orgpf.
              IF sy-subrc EQ '0'.
                CALL FUNCTION 'ZBCMF_ALV_IMAGEN'
                  EXPORTING
                    i_einri = <rndbew>-einri
                    i_falnr = <rndbew>-falnr
                    i_lfdnr = i_lfdnr
                    i_kztxt = <rndbew>-kztxt
                    i_vcode = i_vcode.
              ENDIF.
            ENDIF.
          ENDIF.
        ELSE.
          SELECT * FROM nbew
            INTO CORRESPONDING FIELDS OF TABLE it_nbew
            WHERE einri = <rndfal>-einri
              AND falnr = <rndfal>-falnr
              AND ( bewty = '1' OR bewty = '3' ).

          IF it_nbew[] IS NOT INITIAL.
            SORT it_nbew BY lfdnr DESCENDING.
            READ TABLE it_nbew INTO ls_nbew INDEX 1.
            SELECT SINGLE * FROM zist0082 INTO ls_0082
                                         WHERE einri = ls_nbew-einri
                                           AND orgfa = ls_nbew-orgfa.
            IF sy-subrc EQ '0'.
              CALL FUNCTION 'ZBCMF_ALV_IMAGEN'
                EXPORTING
                  i_einri = ls_nbew-einri
                  i_falnr = ls_nbew-falnr
                  i_lfdnr = i_lfdnr
                  i_kztxt = ls_nbew-kztxt
                  i_vcode = i_vcode.
            ELSE.
              SELECT SINGLE * FROM zist0082 INTO ls_0082
                                           WHERE einri = ls_nbew-einri
                                             AND orgfa = ls_nbew-orgpf.
              IF sy-subrc EQ '0'.
                CALL FUNCTION 'ZBCMF_ALV_IMAGEN'
                  EXPORTING
                    i_einri = ls_nbew-einri
                    i_falnr = ls_nbew-falnr
                    i_lfdnr = i_lfdnr
                    i_kztxt = ls_nbew-kztxt
                    i_vcode = i_vcode.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

*se declaro la variable ls_0081, que es de la tabla zist0081
*  DATA: ls_0081 TYPE zist0081.

*Primer paso iniciamos en modo debug para identicar sy-ucomm del boton imprimir
*Ya que se identifico,vamos a tomar la estructura del boton guardar
*En la sentencia, ponemos que si el valor de las variables que es cuando se modifica, crea etc. esten en valor a 0
*entonces entrara a la siguiente sentencia que si se preciona el boton imprimir (sy-ucomm = PRIF) entrara a la siguiente sentencia
*Dependiendo de los campos de la tabla, que no estan inicializados o que no contengan datos se realizara otra sentencia
*En caso que este inserte datos, este hara una busqueda de la base de datos, con ciertos campos, que es de la tabla 0082 y que lo almacenara ls_0082
*EN caso de lo contrario, que este inicializado, este realizara una busqueda de la base de datos, con dichos campos y los llamara.

*Sentencia Imprimir
*si este sea igual con el valor 0, este hara una busqueda en la base de datos, donde los guardara en la cabecera ls_0081, de algunos campos.
*En caso que este le de al boton imprimir, sin llenar los campos o que los campos esten vacios y sin el boton guardar .
**Este va a mostrar un mensaje con la leyenda de Verificar que llene todos los campos, este mensaje va ser de tipo 'E', ya que se va detener el proceso
**del sistema.
*  IF rc1 = '0' AND rc2 = '0' AND rc3 = '0' .
*    IF ( sy-ucomm = 'PRIS'  ) or ( sy-ucomm = 'PRIF'  ) .
*
*      IF ( <rndbew>-orgfa IS NOT INITIAL OR <rndbew>-orgpf IS NOT INITIAL )
*         AND <rndbew>-falnr IS NOT INITIAL AND <rndbew>-bwart = 'Z8'.
*
*        SELECT SINGLE * FROM zist0082 INTO ls_0082
*            WHERE einri = <rndbew>-einri
*            AND orgfa = <rndbew>-orgfa.
*
*
*        IF sy-subrc NE '0'.
*          SELECT SINGLE * FROM zist0082 INTO ls_0082
*            WHERE einri = <rndbew>-einri
*            AND orgfa = <rndbew>-orgpf.
*         endif.
*
*        IF sy-subrc  NE '0'.
*          SELECT SINGLE * FROM zist0081 INTO ls_0081
*                                 WHERE einri = <rndbew>-einri
*                                   AND falnr = <rndbew>-falnr
*                                   AND lfdnr = <rndbew>-lfdnr.
*
*        ELSE.
*          MESSAGE: 'Favor de dar click en boton guardar' TYPE 'E'.
*     ENDIF.
*     endif.
*      ENDIF.
*     ENDIF.




ENDMETHOD.