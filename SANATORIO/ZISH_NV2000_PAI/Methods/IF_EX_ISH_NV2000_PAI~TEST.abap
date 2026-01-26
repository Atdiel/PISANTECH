*----------------------------------------------------------------------*
*                                                                      *
* Método - IF_EX_ISH_NV2000_PAI~TEST                                   *
*----------------------------------------------------------------------*
METHOD if_ex_ish_nv2000_pai~test .  " Inicio del método
*----------------------------------------------------------------------*
* Sol. desarrollo Abap :                                               *
* Autor                : Ing. Enrique Martinez (HSJ)                   *
* Fecha                : 19.01.2006                                     *
* Descripción          : Realizar validaciones de unidad de admision   *
*                        para laboratorio.                             *
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
*	Log de modificaciones	*
*----------------------------------------------------------------------*
* Modified by       : Ram�n Atdiel P�rez Quintana    DEVBT02           *
* Requerimiento     : 3271                                             *
* Fecha             : 29/07/2025                                       *
*	Descripci�n       : Actualizar Altas en tabla de PRE ALTAS           *
* Transporte        : DEVK911759                                       *
*----------------------------------------------------------------------*

  " Declaración de variables de datos
  DATA :         hbapiret2      TYPE bapiret2.        " Variable para mensajes de retorno.
  DATA :         wa_znish_lab   TYPE znish_lab.       " Estructura para unidad de admisión en laboratorio.
  DATA :         wa_nfal        TYPE nfal.            " Estructura para datos de la tabla nfal.
  DATA :         wa_nbew        TYPE nbew.            " Estructura para datos de la tabla nbew.
  DATA : lv_asoc TYPE xfeld.                          " Variable para asociación.

  " Declaración de tablas internas y estructuras para las mismas.
  DATA: it_0050 TYPE TABLE OF zist0050,              " Tabla interna para datos de zist0050.
        ls_0050 TYPE zist0050.                       " Estructura para un registro de zist0050.
  DATA: it_0047 TYPE TABLE OF zist0047,              " Tabla interna para datos de zist0047.
        ls_0047 TYPE zist0047.                       " Estructura para un registro de zist0047.
  DATA: it_0062 TYPE TABLE OF zist0062,              " Tabla interna para datos de zist0062.
        ls_0062 TYPE zist0062.                       " Estructura para un registro de zist0062.

  DATA: lv_espe TYPE xfeld.                          " Variable para especial.
  DATA: ls_0089 TYPE zist0089.                       " Estructura para datos de zist0089.
  DATA: ls_0094 TYPE zist0094,                       " Estructura para datos de zist0094.
        ls_npnt TYPE npnt.                           " Estructura para datos de npnt.

  DATA: lv_ind TYPE xfeld.                           " Variable indicador.

  DATA : rc1 TYPE sy-subrc,                          " Variable para código de retorno de la asignación.
         rc2 TYPE sy-subrc,
         rc3 TYPE sy-subrc,
         rc4 TYPE sy-subrc.

  DATA: lv_filename TYPE string,                     " Variable para nombre de archivo.
        lv_path     TYPE string.                     " Variable para ruta de archivo.

  DATA: it_d07v   TYPE TABLE OF dd07v,              " Tabla interna para datos de dd07v.
        ls_d07v   TYPE dd07v,                       " Estructura para un registro de dd07v.
        lv_motivo TYPE char50.                      " Variable para motivo.

  DATA: lv_mess1 TYPE char100,                      " Variable para primer mensaje.
        lv_mess2 TYPE char100,                      " Variable para segundo mensaje.
        lv_mess3 TYPE char100.                      " Variable para tercer mensaje.

  DATA: ls_0104 TYPE zist0104,                      " Estructura para datos de zist0104.
        ls_0105 TYPE zist0105.                      " Estructura para datos de zist0105.

  DATA: ls_0107 TYPE zist0107,                      " Estructura para datos de zist0107.
        it_0107 TYPE TABLE OF zist0107.            " Tabla interna para datos de zist0107.

  DATA: ivals  TYPE TABLE OF sval.                   " Tabla interna para valores.
  DATA: xvals  TYPE sval.                            " Estructura para un valor.

  DATA: ls_0082    TYPE zist0082,                   " Estructura para datos de zist0082.
        ls_folio   TYPE zmmmxt1005,                 " Estructura para folio.
        ls_message TYPE string,                      " Estructura para mensaje.
        ls_mesfec  TYPE string.                       " Estructura para fecha de mensaje

  DATA: lt_reserva TYPE STANDARD TABLE OF resb,
        ls_reserva TYPE resb.                       "Estructura para folio

  DATA: lv_text1 TYPE string,
        lv_text2 TYPE string.

  DATA  lv_kzear TYPE char1.


  DATA: lt_dynpfields TYPE TABLE OF dynpread,
        ls_dynpfield  TYPE dynpread.

  CLEAR: c_worst_message_type, ls_0089.             " Limpiar variables de mensaje y ls_0089.

  FIELD-SYMBOLS: <rndbew> TYPE rndbew,              " Símbolo de campo para datos de rndbew.
                 <rnpat>  TYPE rnpat,              " Símbolo de campo para datos de rnpat.
                 <rndfal> TYPE rndfal,              " Símbolo de campo para datos de rndfal.
                 <rndpnt> TYPE rndpnt,
                 <rnpa1>  TYPE rnpa1,
                 <rndia>  TYPE rndia.

  DATA: flag TYPE c.                               " Variable de tipo carácter.

  " Asignar referencias a los símbolos de campo
  ASSIGN ('(SAPLNBE2)RNDBEW') TO <rndbew>.         " Asignar referencia a <rndbew>.
  rc1 = sy-subrc.                                   " Guardar código de retorno.

  ASSIGN ('(SAPLNPA2)RNPAT')  TO <rnpat>.          " Asignar referencia a <rnpat>.
  rc2 = sy-subrc.                                   " Guardar código de retorno.

  ASSIGN ('(SAPLNFA2)RNDFAL') TO <rndfal>.          " Asignar referencia a <rndfal>.
  rc3 = sy-subrc.                                   " Guardar código de retorno.

  IF rc1 = '0' AND rc2 = '0' AND rc3 = '0' .          " Verificar que las asignaciones anteriores fueron exitosas.

***** Validaci�n de Farmatools

    DATA: st_publiclist TYPE TABLE OF zish_publiclist_alv,
          wa_publiclist LIKE LINE OF st_publiclist.
    DATA lo_censo_ft_ws TYPE REF TO zclish_censo_ft.
    DATA: lv_partner TYPE nbup-partner,
          lv_barnr   TYPE rnpa1-barnr.

    FREE lo_censo_ft_ws.

    IF ( i_vcode EQ 'UPD' OR i_vcode = 'INS' ) AND      " Repetir la verificación inicial de operación.
         ( sy-ucomm = 'SAVE' OR sy-ucomm = 'FURT' ).       " Y de acción del usuario.

      IF ( <rndbew>-falar = '1' AND <rndbew>-bewty = '3' ) OR
        ( <rndfal>-falar = '1' AND <rndbew>-bwart = 'E' AND <rndbew>-bewty = '2' ).

        IF ( <rndbew>-falar = '1' AND <rndbew>-bewty = '3' ).
          wa_publiclist-ambito = '3'.
          ASSIGN ('(SAPLN00Z)RNPA1')  TO <rnpa1>.
          IF sy-subrc = 0.
            lv_barnr = <rnpa1>-barnr.
          ENDIF.
        ELSEIF ( <rndfal>-falar = '1' AND <rndbew>-bwart = 'E' AND <rndbew>-bewty = '2' ).
          wa_publiclist-ambito = '2'.
          SELECT SINGLE pernr INTO lv_barnr
            FROM nfpz
            WHERE einri = <rndbew>-einri
              AND falnr = <rndbew>-falnr
              AND farzt = '6'
              AND storn = ''.
        ENDIF.

        IF lv_barnr IS NOT INITIAL.
          ASSIGN ('(SAPLNBUPA_PNAM_SCR)RNDPNT')  TO <rndpnt>.
          IF sy-subrc = 0.
            wa_publiclist-falnr = <rndbew>-falnr.
            wa_publiclist-patnr = i_patnr.
            wa_publiclist-bett = <rndbew>-bett.
            IF <rndbew>-falar = '1'.
              wa_publiclist-kzamb = 'H'.
            ENDIF.
*          wa_publiclist-kzamb = <rndbew>-falar.
            wa_publiclist-nname = <rndpnt>-last_name_pat_long.
            wa_publiclist-vname = <rndpnt>-frst_name_pat_long.
            wa_publiclist-gbdat = <rndpnt>-birthdt.
            wa_publiclist-orgfa = <rndbew>-orgfa.
            wa_publiclist-gschl = <rndpnt>-sexid.
            wa_publiclist-aufdt = <rndbew>-bwidt.

            wa_publiclist-pernr = lv_barnr.
            SELECT SINGLE partner FROM nbup
              INTO lv_partner
              WHERE gpart = lv_barnr.
            IF sy-subrc = 0.
              SELECT SINGLE name_first name_last
                INTO (wa_publiclist-name1, wa_publiclist-name2)
                FROM but000
                WHERE partner = lv_partner.
            ENDIF.
            ASSIGN ('(SAPLN_DIAGNOSIS_SC)RNDIA')  TO <rndia>.
            IF sy-subrc = 0.
              wa_publiclist-dkey1 = <rndia>-dkey1.
            ENDIF.

            APPEND wa_publiclist TO st_publiclist.

            lo_censo_ft_ws = NEW #( ).
            lo_censo_ft_ws->send_json( CORRESPONDING #( st_publiclist ) ).
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
** F. Validaci�n de Farmatools

* Verificar si se presionó el botón 'SAVE', 'BACK' o 'END'.
*  IF ( sy-ucomm = 'SAVE' OR sy-ucomm = 'BACK' OR sy-ucomm = 'END').  " Comprobar si se realizó alguna acción de guardado o navegación.
*      IF <rndbew>-orgpf IS INITIAL.                  " Comprobar si el campo 'orgpf' está vacío.
*        MESSAGE 'Favor de llenar los campos obligatorios' TYPE 'I' DISPLAY LIKE 'E'. " Mostrar mensaje de error.
*          LEAVE PROGRAM.                            " Salir del programa.
*      ENDIF.
*  ENDIF.

*----------------------------------------------------------------------*
*	Log de modificaciones	                                               *
*----------------------------------------------------------------------*
* Modified by       : Bryan Bautista Prado                             *
* Requerimiento     : 3288                                             *
* Modificado por    : Bryan Bautista Prado        20                   *
* Fecha             : 08/07/2025                                       *
*	Descripción       : Creación de una tabla para la acción relacionada *
* Transporte        : DEVK911761                                       *
*----------------------------------------------------------------------*
* Modified by       : Bryan Bautista Prado                             *
* Requerimiento     : 3469                                             *
* Modificado por    : Bryan Bautista Prado        20                   *
* Fecha             : 26/11/2025                                       *
*	Descripción       : Delimitar que el POPUP de guardar las acciones   *
*                     sea de un único uso                              *
* Transporte        : DEVK911761                                       *
*----------------------------------------------------------------------*

*** INICIO MODIF. - 3288 - 08/07/2025 - Bryan Bautista Prado

    TYPES: BEGIN OF ty_zmmt0109,
             accion TYPE char50,
           END OF ty_zmmt0109.
    DATA: ls_zmmt0109  TYPE ty_zmmt0109,
          lt_zmmt0110  TYPE STANDARD TABLE OF zmmt0110,
          ls_zmmt0110  TYPE zmmt0110,
          ls_zmmt0111  TYPE zmmt0111,
          lt_zmmt0109  TYPE STANDARD TABLE OF ty_zmmt0109,
          lv_resp      TYPE c,
          lv_respuesta TYPE c VALUE 'A',
          lv_accion    TYPE zmmt0111-zzaccion.
    FIELD-SYMBOLS: <lv_bwart> TYPE any.
    ASSIGN COMPONENT 'BWART' OF STRUCTURE i_data TO <lv_bwart>.
*** MODIF. - 3469 - 26/11/2025 - Bryan Bautista Prado
    SELECT SINGLE zzaccion
        FROM zmmt0111
        INTO lv_accion
        WHERE falnr = <rndbew>-falnr
          AND lfdnr = <rndbew>-lfdnr
          AND einri = <rndbew>-einri.
    IF ( sy-ucomm = 'OPT2' OR sy-ucomm = 'BACK' ) AND sy-subrc = 0.
*** MODIF. - 3469 - 26/11/2025 - Bryan Bautista Prado
      IF lv_accion IS INITIAL.
        SELECT SINGLE *
          FROM zmmt0110
          INTO ls_zmmt0110
          WHERE clmovimiento = <lv_bwart>
          AND activador = 'X'.
        IF sy-subrc = 0.
          SELECT accion
           FROM zmmt0109
           INTO TABLE lt_zmmt0109
           WHERE clmovimiento = <lv_bwart>
           AND   cesanitario  = ls_zmmt0110-cesanitario.
          IF lt_zmmt0109 IS NOT INITIAL.
            CALL FUNCTION 'POPUP_TO_CONFIRM'
              EXPORTING
                titlebar              = 'Confirmación'          " Título del popup
                text_question         = '¿Desea guardar un tipo de selección?'     " Texto de la pregunta
                text_button_1         = 'Sí'                    " Texto botón 1
                icon_button_1         = 'ICON_OKAY'             " Icono para botón Sí
                text_button_2         = 'No'                    " Texto botón 2
                icon_button_2         = 'ICON_CANCEL'           " Icono para botón No
                default_button        = '2'                     " Botón por defecto (2=No)
                display_cancel_button = abap_false              " Ocultar bot�n Cancelar
              IMPORTING
                answer                = lv_resp              " 1=Sí, 2=No
              EXCEPTIONS
                text_not_found        = 1
                OTHERS                = 2.
          ENDIF.
        ENDIF.
*** INICIO MODIF. - 3469 - 26/11/2025 - Bryan Bautista Prado
      ELSE.
        lv_respuesta = 'B'.
      ENDIF.
*** FIN MODIF. - 3469 - 26/11/2025 - Bryan Bautista Prado
    ENDIF.
    IF ( i_vcode = 'INS' AND sy-ucomm = 'SAVE' ) OR lv_resp = 1.
      ASSIGN COMPONENT 'BWART' OF STRUCTURE i_data TO <lv_bwart>.
      IF sy-subrc = 0.
        DATA: lt_lista TYPE TABLE OF vrm_value,
              ls_lista LIKE LINE OF lt_lista,
              lv_lfdnr TYPE nbew-lfdnr,
              lv_falnr TYPE nbew-falnr.
        CLEAR: lt_zmmt0109, lt_zmmt0110.
        SELECT SINGLE *
          FROM zmmt0110
          INTO ls_zmmt0110
          WHERE clmovimiento = <lv_bwart>
          AND activador = 'X'.
        IF sy-subrc = 0.
          SELECT accion
            FROM zmmt0109
            INTO TABLE lt_zmmt0109
            WHERE clmovimiento = <lv_bwart>
            AND   cesanitario  = ls_zmmt0110-cesanitario.
          IF lt_zmmt0109 IS NOT INITIAL.
*         Crea la lista para el popup
            LOOP AT lt_zmmt0109 INTO ls_zmmt0109.
              ls_lista-text = ls_zmmt0109-accion.
              APPEND ls_lista TO lt_lista.
            ENDLOOP.
*** INICIO MODIF. - 3469 - 26/11/2025 - Bryan Bautista Prado
            IF lv_accion IS NOT INITIAL.
              lv_respuesta = 'B'.
            ELSE.
*** FIN MODIF. - 3469 - 26/11/2025 - Bryan Bautista Prado
*         Mostrar el popup con la lista
              CALL FUNCTION 'POPUP_TO_DECIDE_LIST'
                EXPORTING
                  textline1          = 'Seleccione una opción'   "Texto de cabecera
                  titel              = 'Menú de acciones'        "Título del popup
                  start_col          = 10                        "Columna inicial
                  start_row          = 5                         "Fila inicial
                IMPORTING
                  answer             = lv_respuesta              "Respuesta del usuario
                TABLES
                  t_spopli           = lt_lista                  "Lista de opciones
                EXCEPTIONS
                  not_enough_answers = 1
                  too_much_answers   = 2
                  too_much_marks     = 3
                  OTHERS             = 4.
            ENDIF.
*** INICIO MODIF. - 3469 - 26/11/2025 - Bryan Bautista Prado
            IF lv_respuesta = 'B'.
*              No debe de pasar nada, solo saltarse la siguiente función
*** FIN MODIF. - 3469 - 26/11/2025 - Bryan Bautista Prado
            ELSEIF lv_respuesta <> 'A'.
              IF <rndbew> IS ASSIGNED.
                SELECT MAX( lfdnr )
                  FROM nbew
                  INTO lv_lfdnr
                  WHERE falnr = <rndbew>-falnr.
                IF sy-subrc = 0.
                  lv_lfdnr = lv_lfdnr + 1.
                ELSE.
                  lv_lfdnr = 1.
                ENDIF.
                IF <rndbew>-falnr = ''.
                  SELECT MAX( falnr )
                    FROM nbew
                    INTO lv_falnr.
                  IF sy-subrc = 0.
                    <rndbew>-falnr = lv_falnr + 1.
                    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                      EXPORTING
                        input  = <rndbew>-falnr
                      IMPORTING
                        output = <rndbew>-falnr.
                  ENDIF.
                ENDIF.
                READ TABLE lt_lista INDEX lv_respuesta INTO ls_lista.
                <rndbew>-zzaccion = ls_lista-text.
                ls_zmmt0111       = CORRESPONDING #( <rndbew> ).
                ls_zmmt0111-lfdnr = lv_lfdnr.
                INSERT zmmt0111 FROM ls_zmmt0111.
                IF sy-subrc = 0.
                  COMMIT WORK.
                ELSE.
                  ROLLBACK WORK.
                ENDIF.
              ENDIF.
            ELSE.
              sy-ucomm = 'PASE'.
              MESSAGE 'El usuario cancelo la acción.' TYPE 'E'.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ELSEIF ( sy-ucomm = 'PASE' AND lv_respuesta = 'A' ) OR ( sy-ucomm = 'OPT2' AND lv_resp = 2 ).
      MESSAGE 'El usuario cancelo la acción.' TYPE 'E'.
    ENDIF.
*** FIN MODIF.    - 3288 - 08/07/2025 - Bryan Bautista Prado SAPMNPA10


* Validación de paciente inactivo
    IF i_vcode EQ 'UPD' OR i_vcode = 'INS'.          " Verificar si la operación es actualización o inserción.
**********
      SELECT SINGLE partner patnr ina_ind
        FROM npnt
        INTO CORRESPONDING FIELDS OF ls_npnt
        WHERE patnr = i_patnr.
      IF sy-subrc = 0 AND ls_npnt-ina_ind = 'X'.
        SELECT SINGLE *
          FROM zist0094
          INTO CORRESPONDING FIELDS OF ls_0094
          WHERE partner = ls_npnt-partner
            AND bloq = 'X'.
        IF sy-subrc = 0.
          IF <rndfal>-falar = '1'.
            CLEAR: lv_motivo, lv_mess1.
            CALL FUNCTION 'DDUT_DOMVALUES_GET'
              EXPORTING
                name      = 'ZISHD_MOTIN'
              TABLES
                dd07v_tab = it_d07v.

            READ TABLE it_d07v INTO ls_d07v WITH KEY domvalue_l = ls_0094-motiv.
            IF sy-subrc = 0.
              lv_motivo = ls_d07v-ddtext.
            ELSE.
              lv_motivo = 'No especificado'.
            ENDIF.

*            CONCATENATE 'Paciente bloqueado por' lv_motivo
*              INTO lv_mess1 SEPARATED BY space.
*
*            lv_mess2 = ls_0094-text.
*            lv_mess3 = 'Informar al Paciente'.
*            CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'
*              EXPORTING
*                titel     = 'PACIENTE BLOQUEADO'
*                textline1 = lv_mess1
*                textline2 = lv_mess2
*                textline3 = lv_mess3.
*
*            CLEAR: lv_mess1, lv_mess2, lv_mess3.
            CONCATENATE 'Paciente bloqueado por' lv_motivo '. Imposible crear episodio hospitalizado'
            INTO lv_mess1 SEPARATED BY space.
            MESSAGE lv_mess1 TYPE 'E'.
          ELSE.
            IF <rndbew>-orgfa IS NOT INITIAL OR <rndbew>-orgpf IS NOT INITIAL.
              REFRESH: it_0107.
              SELECT * FROM zist0107
                INTO CORRESPONDING FIELDS OF TABLE it_0107
                WHERE einri = <rndfal>-einri
                  AND orgfa = <rndbew>-orgfa.
              IF sy-subrc NE 0.
                SELECT * FROM zist0107
                  INTO CORRESPONDING FIELDS OF TABLE it_0107
                  WHERE einri = <rndfal>-einri
                    AND orgfa = <rndbew>-orgpf.
                IF sy-subrc NE 0.
                  CLEAR: lv_motivo, lv_mess1.
                  CALL FUNCTION 'DDUT_DOMVALUES_GET'
                    EXPORTING
                      name      = 'ZISHD_MOTIN'
                    TABLES
                      dd07v_tab = it_d07v.

                  READ TABLE it_d07v INTO ls_d07v WITH KEY domvalue_l = ls_0094-motiv.
                  IF sy-subrc = 0.
                    lv_motivo = ls_d07v-ddtext.
                  ELSE.
                    lv_motivo = 'No especificado'.
                  ENDIF.

                  SELECT SINGLE *
                    FROM zist0168
                    INTO @DATA(ls)
                    WHERE orgid IN (@<rndbew>-orgfa, @<rndbew>-orgpf)
                      AND motiv = @ls_0094-motiv.

                  " Verifica si la selección fue exitosa
                  IF sy-subrc NE 0.

                    CONCATENATE 'Paciente bloqueado por' lv_motivo '. Imposible crear episodio hospitalizado'
                      INTO lv_mess1 SEPARATED BY space.
                    MESSAGE lv_mess1 TYPE 'E'.

*                  CONCATENATE 'Paciente bloqueado por' lv_motivo
*                    INTO lv_mess1 SEPARATED BY space.
*                  lv_mess2 = ls_0094-text.
*                  lv_mess3 = 'Informar al Paciente'.
*                  CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'
*                    EXPORTING
*                      titel     = 'PACIENTE BLOQUEADO'
*                      textline1 = lv_mess1
*                      textline2 = lv_mess2
*                      textline3 = lv_mess3.
*
*                  CLEAR: lv_mess1, lv_mess2, lv_mess3.
*                  CONCATENATE 'Paciente bloqueado por' lv_motivo '. Imposible crear episodio hospitalizado'
*                  INTO lv_mess1 SEPARATED BY space.
*                  MESSAGE lv_mess1 TYPE 'E'.
                  ENDIF.
                ENDIF.
              ENDIF.
              IF sy-ucomm = 'SAVE' OR sy-ucomm ='LEIS'.
                lv_ind = 'X'.
                SET PARAMETER ID 'INDI' FIELD lv_ind.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

**********
*      SELECT SINGLE partner patnr ina_ind           " Consultar datos del paciente.
*        FROM npnt
*        INTO CORRESPONDING FIELDS OF ls_npnt
*        WHERE patnr = i_patnr.                      " Obtener el registro del paciente por su número.
*      IF sy-subrc = 0 AND ls_npnt-ina_ind = 'X'.    " Verificar si el paciente está inactivo.
*        SELECT SINGLE *                             " Consultar estado de bloqueo.
*          FROM zist0094
*          INTO CORRESPONDING FIELDS OF ls_0094
*          WHERE partner = ls_npnt-partner
*            AND bloq = 'X'.                          " Comprobar si el paciente está bloqueado.
*        IF sy-subrc = 0.                           " Si se encontró un registro bloqueado.
*          IF <rndfal>-falar = '1'.                   " Verificar estado de 'falar'.
*            CLEAR: lv_motivo, lv_mess1.            " Limpiar variables de mensaje.
*            CALL FUNCTION 'DDUT_DOMVALUES_GET'      " Llamar función para obtener valores de dominio.
*              EXPORTING
*                name      = 'ZISHD_MOTIN'
*              TABLES
*                dd07v_tab = it_d07v.
*
*            READ TABLE it_d07v INTO ls_d07v WITH KEY domvalue_l = ls_0094-motiv. " Leer el motivo de bloqueo.
*            IF sy-subrc = 0.                         " Si se encontró el motivo.
*              lv_motivo = ls_d07v-ddtext.            " Guardar el motivo.
*            ELSE.
*              lv_motivo = 'No especificado'.           " Asignar valor por defecto si no se encontró motivo.
*            ENDIF.
*
*            CONCATENATE 'Paciente bloqueado por' lv_motivo
*              INTO lv_mess1 SEPARATED BY space.         " Concatenar mensaje de bloqueo.
*            lv_mess2 = ls_0094-text.                   " Guardar texto del bloqueo.
*            lv_mess3 = 'Informar al Paciente'.         " Mensaje adicional.
*            CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'    " Mostrar mensaje emergente al usuario.
*              EXPORTING
*                titel     = 'PACIENTE BLOQUEADO'
*                textline1 = lv_mess1
*                textline2 = lv_mess2
*                textline3 = lv_mess3.
*
*            CLEAR: lv_mess1, lv_mess2, lv_mess3.        " Limpiar mensajes.
*            CONCATENATE 'Paciente bloqueado por' lv_motivo '. Imposible crear episodio hospitalizado'
*            INTO lv_mess1 SEPARATED BY space.           " Mensaje de error adicional.
*            MESSAGE lv_mess1 TYPE 'E'.                  " Mostrar mensaje de error.
*          ELSE.
*
*            IF <rndbew>-orgfa IS NOT INITIAL OR <rndbew>-orgpf IS NOT INITIAL. " Verificar campos obligatorios.
*              REFRESH: it_0107.                         " Limpiar tabla interna it_0107.
*              SELECT * FROM zist0107                   " Consultar datos relacionados en zist0107.
*                INTO CORRESPONDING FIELDS OF TABLE it_0107
*                WHERE einri = <rndfal>-einri
*                  AND orgfa = <rndbew>-orgfa.
*              IF sy-subrc NE 0.                          " Si no se encontró, intentar con otro campo.
*                SELECT * FROM zist0107
*                  INTO CORRESPONDING FIELDS OF TABLE it_0107
*                  WHERE einri = <rndfal>-einri
*                    AND orgfa = <rndbew>-orgpf.
*                IF sy-subrc NE 0.                       " Si aún no se encontró.
*                  CLEAR: lv_motivo, lv_mess1.           " Limpiar mensajes.
*                  CALL FUNCTION 'DDUT_DOMVALUES_GET'     " Obtener motivos de bloqueo.
*                    EXPORTING
*                      name      = 'ZISHD_MOTIN'
*                    TABLES
*                      dd07v_tab = it_d07v.
*
*                  READ TABLE it_d07v INTO ls_d07v WITH KEY domvalue_l = ls_0094-motiv. " Leer motivo.
*                  IF sy-subrc = 0.                        " Si se encontró motivo.
*                    lv_motivo = ls_d07v-ddtext.           " Guardar motivo.
*                  ELSE.
*                    lv_motivo = 'No especificado'.          " Valor por defecto si no se encontró motivo.
*                  ENDIF.
*
*                  CLEAR: lv_motivo, lv_mess1. " Limpiar variables de motivo y mensaje
*
*                  " Validación de unidad organizativa y motivo
**                  lv_tipo_bloqueo = '1'. " Asigna tipo de bloqueo adecuado
*
*                  " Selecciona unidad organizativa y motivo
*                  SELECT SINGLE *
*                    FROM zist0168
*                    INTO @DATA(ls)
*                    WHERE orgid IN (@<rndbew>-orgfa, @<rndbew>-orgpf)
*                      AND motiv = @ls_0094-motiv.
*
*                  " Verifica si la selección fue exitosa
*                  IF sy-subrc NE 0.
**                    MESSAGE 'Error: Unidad organizativa o tipo de bloqueo no coinciden con zist0168' TYPE 'E'.
**                    EXIT. " Sale del método
**                    DATA(mess) = |Error: Unidad organizativa o tipo de bloqueo no coinciden con zist0168|.
*
*                    CONCATENATE 'Paciente bloqueado por' lv_motivo
*                      INTO lv_mess1 SEPARATED BY space.       " Mensaje de bloqueo.
*                    lv_mess2 = ls_0094-text.                  " Texto adicional.
*                    lv_mess3 = 'Informar al Paciente'.        " Mensaje de información.
*                    CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'  " Mostrar mensaje emergente al usuario.
*                      EXPORTING
*                        titel     = 'PACIENTE BLOQUEADO'
*                        textline1 = lv_mess1
*                        textline2 = lv_mess2
*                        textline3 = lv_mess3.
*
*                    CLEAR: lv_mess1, lv_mess2, lv_mess3.       " Limpiar mensajes.
*                    CONCATENATE 'Paciente bloqueado por' lv_motivo '. Imposible crear episodio hospitalizado'
*                    INTO lv_mess1 SEPARATED BY space.         " Mensaje de error adicional.
*                    MESSAGE lv_mess1 TYPE 'E'.                 " Mostrar mensaje de error.
*                  ENDIF.
*
**                  CONCATENATE 'Paciente bloqueado por' lv_motivo
**                    INTO lv_mess1 SEPARATED BY space.       " Mensaje de bloqueo.
**                  lv_mess2 = ls_0094-text.                  " Texto adicional.
**                  lv_mess3 = 'Informar al Paciente'.        " Mensaje de información.
**                  CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'  " Mostrar mensaje emergente al usuario.
**                    EXPORTING
**                      titel     = 'PACIENTE BLOQUEADO'
**                      textline1 = lv_mess1
**                      textline2 = lv_mess2
**                      textline3 = lv_mess3.
**
**                  CLEAR: lv_mess1, lv_mess2, lv_mess3.       " Limpiar mensajes.
**                  CONCATENATE 'Paciente bloqueado por' lv_motivo '. Imposible crear episodio hospitalizado'
**                  INTO lv_mess1 SEPARATED BY space.         " Mensaje de error adicional.
**                  MESSAGE lv_mess1 TYPE 'E'.                 " Mostrar mensaje de error.
*                ENDIF.
*              ENDIF.
*              IF sy-ucomm = 'SAVE' OR sy-ucomm ='LEIS'.    " Si se presiona 'SAVE' o 'LEIS'.
*                lv_ind = 'X'.                              " Marcar indicador.
*                SET PARAMETER ID 'INDI' FIELD lv_ind.    " Establecer parámetro en la sesión.
*              ENDIF.
*            ENDIF.
*          ENDIF.
*        ENDIF.
*      ENDIF.
    ENDIF.

    IF ( i_vcode EQ 'UPD' OR i_vcode = 'INS' ) AND    " Verificar si el código de operación es 'UPD' o 'INS'
        ( sy-ucomm = 'SAVE' OR sy-ucomm = 'FURT' ).   " Y si la acción del usuario es 'SAVE' o 'FURT'.

*** INICIO MODIF. - 3271 (Monitor Pre-Altas) - 29/07/2025 - DEVBT02 Ram�n Atdiel P�rez Quintana
      DATA: lv_need_pre TYPE abap_bool.
      CLEAR: lv_need_pre.

      IF <rndfal>-enddt IS NOT INITIAL. "Esta dandole fin al episodio.
        CALL FUNCTION 'ZISMF_VALIDAR_AREAS'
          EXPORTING
            iv_einri         = <rndbew>-einri    " IS-H: Centro sanitario
            iv_falnr         = <rndbew>-falnr    " IS-H: N�mero de episodio
          IMPORTING
            ev_need_pre_alta = lv_need_pre
          EXCEPTIONS
            falnr_not_found  = 1
            OTHERS           = 2.
        IF sy-subrc <> 0.
*         MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*        ENDIF.

          "Solicitar pre-alta validar
          IF lv_need_pre = abap_true.
            "Validar si su usuario tiene permisos para pre-altas
            SELECT SINGLE * FROM zist0188
              INTO @DATA(ls_zist0188)
              WHERE
                area      = @<rndbew>-orgfa OR
                area      = @<rndbew>-orgpf AND
                uname     = @sy-uname.

            IF sy-subrc <> 0.
              MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '003' WITH text-003 DISPLAY LIKE 'E'.
              LEAVE PROGRAM.
            ENDIF.
            "Validar si ya tiene una pre-alta y que este liberada si/no - continua proceso normal/salir del programa(evitar que guarde)
            SELECT SINGLE * FROM zist0186
              INTO @DATA(ls_zist0186)
              WHERE
                einri   = @<rndbew>-einri AND
                falnr   = @<rndbew>-falnr AND
                deleted = @abap_false.
            "Si no esta una pre alta, debe generarla
            IF sy-subrc <> 0.
              MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '001' WITH text-001 DISPLAY LIKE 'E'.
              LEAVE PROGRAM.
            ENDIF.
            "Si aun no esta liberada, no puede dar fin al episodio
            IF ls_zist0186-status <> icon_green_light.
              MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '002' WITH text-002 DISPLAY LIKE 'E'.
              LEAVE PROGRAM.
            ELSE.
              "Actualizar la hora de alta de la pre alta
              ls_zist0186-alta_date = sy-datum.
              ls_zist0186-alta_hour = sy-uzeit.
              ls_zist0186-diff_hour = ls_zist0186-alta_hour - ls_zist0186-pre_hour.
              UPDATE zist0186 FROM ls_zist0186.
            ENDIF.

          ENDIF.
        ENDIF.
      ENDIF.
** FIN MODIF.    - 3271 (Monitor Pre-Altas) - 29/07/2025 - DEVBT02 Ram�n Atdiel P�rez Quintana

      IF <rndfal>-emtyp IS NOT INITIAL AND <rndfal>-kztxt IS INITIAL.  " Comprobar si el tipo de emergencia no está vacío y el texto de convenio está vacío.

        SELECT SINGLE * FROM zist0104                     " Consultar la tabla zist0104.
          INTO CORRESPONDING FIELDS OF ls_0104              " Guardar resultados en ls_0104.
          WHERE einri = <rndfal>-einri                      " Filtrar por el identificador de la unidad de emergencia.
            AND emtyp = <rndfal>-emtyp.                     " Y el tipo de emergencia.

        IF sy-subrc EQ 0.                                   " Verificar si la consulta fue exitosa.
          CLEAR: xvals.                                     " Limpiar la estructura xvals.
          REFRESH: ivals.                                   " Limpiar la tabla interna ivals.

          xvals-tabname   = 'ZIST0104'.                    " Establecer nombre de la tabla en xvals.
          xvals-fieldname = 'CLAVE'.                        " Establecer el nombre del campo en xvals.
          APPEND xvals TO ivals.                            " Agregar xvals a la tabla interna ivals.

          CALL FUNCTION 'POPUP_GET_VALUES'                 " Llamar a la función para mostrar un popup de entrada.
            EXPORTING
              popup_title     = 'Proporcione la clave del convenio'  " Título del popup.
            TABLES
              fields          = ivals                          " Pasar la tabla de campos al popup.
            EXCEPTIONS
              error_in_fields = 1                              " Manejar excepciones en caso de error.
              OTHERS          = 2.                             " Otras excepciones.

          READ TABLE ivals INTO xvals WITH KEY fieldname = 'CLAVE'.  " Leer el valor ingresado por el usuario.
          IF sy-subrc  = 0.                                  " Si se encontró el valor.
            IF xvals-value = ls_0104-clave.                  " Comprobar si el valor coincide con la clave en ls_0104.
              CLEAR xvals.                                   " Limpiar xvals.
              REFRESH: ivals.                               " Limpiar la tabla interna ivals.
              xvals-tabname   = 'NFAL'.                     " Establecer la tabla en xvals.
              xvals-fieldname = 'FAMIL'.                    " Establecer el campo en xvals.
              xvals-fieldtext = 'Familia convenio'.         " Establecer texto descriptivo del campo.
              APPEND xvals TO ivals.                        " Agregar xvals a la tabla interna ivals.

              SET PARAMETER ID 'EMTYP' FIELD <rndfal>-emtyp. " Establecer el parámetro EMTYP en la sesión.

              CALL FUNCTION 'POPUP_GET_VALUES'              " Mostrar otro popup para ingresar los datos del convenio.
                EXPORTING
                  popup_title     = 'Proporcione los datos del convenio'  " Título del popup.
                TABLES
                  fields          = ivals                       " Pasar la tabla de campos al popup.
                EXCEPTIONS
                  error_in_fields = 1                           " Manejar excepciones en caso de error.
                  OTHERS          = 2.                          " Otras excepciones.

              READ TABLE ivals INTO xvals WITH KEY fieldname = 'FAMIL'.  " Leer el valor de familia del convenio.
              IF sy-subrc  = 0.                               " Si se encontró el valor.
                <rndfal>-kztxt = xvals-value.                 " Asignar el valor a la variable kztxt de <rndfal>.
              ENDIF.
            ELSE.                                            " Si el valor no coincide con la clave.
              CLEAR: xvals.                                   " Limpiar xvals.
              <rndfal>-emtyp = ''.                            " Limpiar el tipo de emergencia.
              MESSAGE 'El convenio no coincide. Validar' TYPE 'E'.  " Mostrar mensaje de error.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSE.                                                " Si el tipo de emergencia está inicializado y el texto también.
        IF <rndfal>-emtyp IS NOT INITIAL AND <rndfal>-kztxt IS NOT INITIAL.  " Verificar si ambos campos tienen valor.
          SELECT SINGLE * FROM zist0104                     " Consultar la tabla zist0104.
            INTO CORRESPONDING FIELDS OF ls_0104              " Guardar resultados en ls_0104.
            WHERE einri = <rndfal>-einri                      " Filtrar por el identificador de la unidad de emergencia.
              AND emtyp = <rndfal>-emtyp.                     " Y el tipo de emergencia.

          IF sy-subrc EQ 0.                                   " Si la consulta fue exitosa.
            SELECT SINGLE * FROM zist0105                     " Consultar la tabla zist0105.
              INTO CORRESPONDING FIELDS OF ls_0105           " Guardar resultados en ls_0105.
              WHERE einri = <rndfal>-einri                    " Filtrar por el identificador de la unidad de emergencia.
                AND emtyp = <rndfal>-emtyp                    " Y el tipo de emergencia.
                AND famil = <rndfal>-kztxt.                  " Y la familia del convenio.

            IF sy-subrc NE 0.                                 " Si no se encontró un registro en zist0105.
              CLEAR <rndfal>-kztxt.                           " Limpiar el texto de convenio.
              MESSAGE 'El convenio no coincide. Validar' TYPE 'E'.  " Mostrar mensaje de error.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

      IF ( i_vcode EQ 'UPD' OR i_vcode = 'INS' ) AND      " Repetir la verificación inicial de operación.
        ( sy-ucomm = 'SAVE' OR sy-ucomm = 'FURT' ).       " Y de acción del usuario.

** Validación de Imagenología
*      IF ( <rndbew>-orgfa IS NOT INITIAL OR <rndbew>-orgpf IS NOT INITIAL )
*        AND <rndbew>-falnr IS NOT INITIAL AND <rndbew>-bwart = 'Z8'.
*        SELECT SINGLE * FROM zist0082 INTO ls_0082
*                                     WHERE einri = <rndbew>-einri
*                                       AND orgfa = <rndbew>-orgfa.
*        IF sy-subrc EQ '0'.
*          CALL FUNCTION 'ZBCMF_ALV_IMAGEN'
*            EXPORTING
*              i_einri = <rndbew>-einri
*              i_falnr = <rndbew>-falnr
*              i_lfdnr = <rndbew>-lfdnr
*              i_kztxt = <rndbew>-kztxt
*              i_vcode = i_vcode.
*        ELSE.
*          SELECT SINGLE * FROM zist0082 INTO ls_0082
*                                       WHERE einri = <rndbew>-einri
*                                         AND orgfa = <rndbew>-orgpf.
*          IF sy-subrc EQ '0'.
*            CALL FUNCTION 'ZBCMF_ALV_IMAGEN'
*              EXPORTING
*                i_einri = <rndbew>-einri
*                i_falnr = <rndbew>-falnr
*                i_lfdnr = <rndbew>-lfdnr
*                i_kztxt = <rndbew>-kztxt
*                i_vcode = i_vcode.
*          ENDIF.
*        ENDIF.
*      ENDIF.
** Validación de divergentes
*        IF <rndfal>-enddt IS NOT INITIAL.
***        CLEAR wa_nfal.
***        SELECT SINGLE einri falnr enddt
***          INTO CORRESPONDING FIELDS OF wa_nfal
***          FROM nfal
***          WHERE einri = <rndfal>-einri
***            AND falnr = <rndfal>-falnr.
***        IF wa_nfal-enddt IS INITIAL.
***          CALL FUNCTION 'ZBCMF_ORD_DIVERGENTES'
***            EXPORTING
***              i_patnr = <rndfal>-patnr
***              i_falnr = <rndfal>-falnr.
***        ENDIF.
**
****        Validacion de boton guardar
*          i_falnr = <rndfal>-falnr.
*          IF i_falnr IS NOT INITIAL.
*            SELECT SINGLE * FROM zmmmxt1005               "Obtener folio
*              INTO CORRESPONDING FIELDS OF ls_folio
*              WHERE einri = i_institution
*                AND falnr = i_falnr.
**              AND ( asig = '' OR pick = '' ).
*
*            IF sy-subrc = 0.
*
*              SELECT * FROM resb                   " Validar si hay posiciones RESB con KZEAR lleno
*                INTO TABLE lt_reserva
*                WHERE rsnum = ls_folio-rsnum.
*
*              LOOP AT lt_reserva INTO ls_reserva.
*                IF ls_reserva-kzear IS NOT INITIAL.
*                  lv_kzear = 'X'.
*                  EXIT.
*                ENDIF.
*              ENDLOOP.
*
*              IF lv_kzear IS INITIAL.
*                CONCATENATE 'El episodio tiene el folio pendiente' ls_folio-folio
*                            'imposible asignar fecha final' INTO ls_mesfec SEPARATED BY space.
*                MESSAGE ls_mesfec TYPE 'I' DISPLAY LIKE 'E'.
*                LEAVE PROGRAM.
*              ENDIF.
*            ENDIF.
*
*            IF sy-ucomm = 'SAVE' AND sy-cprog NE 'SAPMNPA10'.  " Comprobar si la acción del usuario es 'SAVE' y el programa actual no es 'SAPMNPA10'.
*              IF <rndbew>-orgfa IS INITIAL AND <rndbew>-orgpf IS INITIAL.  " Verificar si ambos campos de organización están vacíos.
*                MESSAGE 'Requiere llenar los campos  UO MEDICA y UO TRATAMIENTO para continuar.' TYPE 'E'.  " Mostrar mensaje de error si faltan campos.
*                LEAVE PROGRAM.  " Salir del programa.
*              ENDIF.
*            ENDIF.
*          ENDIF.
*        ENDIF.
      ENDIF.


*
** Modif. OSS03062018 - Validación de asociados
*      DATA: ls_0049  TYPE zist0049,    " Declarar variable para la tabla zist0049.
*            ls_0045  TYPE zist0045,    " Declarar variable para la tabla zist0045.
*            lv_subrc TYPE sy-subrc,     " Declarar variable para almacenar el código de retorno.
*            ls_0162  TYPE zist0162,    " Declarar variable para la tabla zist0162.
*            ls_0163  TYPE zist0163.    " Declarar variable para la tabla zist0163.
*
*      CLEAR lv_asoc.  " Limpiar la variable lv_asoc.
**    GET PARAMETER ID 'ASOC_ID' FIELD lv_asoc.  " (Código comentado que podría obtener un ID de asociado).
**    IF lv_asoc = ''.  " (Código comentado que verifica si lv_asoc está vacío).
*      CLEAR: wa_nfal, lv_subrc.  " Limpiar la estructura wa_nfal y lv_subrc.
*      SELECT SINGLE * FROM nfal INTO wa_nfal  " Consultar la tabla nfal.
*      WHERE falnr EQ i_falnr AND storn EQ ''.  " Filtrar por el número de fallo y asegurarse de que 'storn' está vacío.
*      IF sy-subrc NE 0 OR sy-subrc EQ 0. "<rndbew>-lfdnr = '00000'.  " (La condición parece redundante, puede simplificarse).
*        CLEAR ls_0045.  " Limpiar la estructura ls_0045.
*        SELECT SINGLE * FROM zist0045  " Consultar la tabla zist0045.
*          INTO CORRESPONDING FIELDS OF ls_0045  " Guardar resultados en ls_0045.
*          WHERE patnr = i_patnr.  " Filtrar por el número de paciente.
*        lv_subrc = sy-subrc.  " Almacenar el código de retorno de la consulta.
*
*        IF ls_0045-notas IS NOT INITIAL OR ls_0045-nota1 IS NOT INITIAL.  " Comprobar si hay notas presentes.
*          IF <rndfal>-falnr IS INITIAL OR <rndbew>-bewty = '1'.  " Verificar si el número de fallo es inicial o si el tipo de documento es '1'.
*            IF sy-ucomm = 'TS_EADM_FC2' OR sy-ucomm = 'TS_EADM_FC4'.  " Comprobar si la acción del usuario corresponde a ciertos comandos.
*              CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'  " Llamar a la función para mostrar un popup.
*                EXPORTING
*                  titel        = 'Notas Asociado'  " Título del popup.
*                  textline1    = ls_0045-notas  " Primera línea de texto del popup.
*                  textline2    = ls_0045-nota1  " Segunda línea de texto del popup.
*                  textline3    = ls_0045-nota2  " Tercera línea de texto del popup.
**                 TEXTLINE3    = ' '  " (Línea de texto comentada).
*                  start_column = 15  " Columna de inicio para el texto.
*                  start_row    = 6.  " Fila de inicio para el texto.
*            ENDIF.
*          ENDIF.
*        ENDIF.
*
*        IF lv_subrc = 0 AND <rndfal>-emtyp IS NOT INITIAL.  " Si la consulta fue exitosa y el tipo de emergencia no está vacío.
*          CLEAR: ls_0049.  " Limpiar la estructura ls_0049.
*          SELECT SINGLE * FROM zist0049  " Consultar la tabla zist0049.
*            INTO CORRESPONDING FIELDS OF ls_0049  " Guardar resultados en ls_0049.
*            WHERE emtyp = <rndfal>-emtyp.  " Filtrar por tipo de emergencia.
*          IF sy-subrc = 0.  " Si la consulta fue exitosa.
*            IF ls_0045-conse = 'X'.  " Comprobar si el campo 'conse' en ls_0045 es 'X'.
*              SELECT SINGLE * FROM zist0049  " Realizar otra consulta a zist0049.
*                INTO CORRESPONDING FIELDS OF ls_0049  " Guardar resultados en ls_0049.
*                WHERE emtyp = <rndfal>-emtyp
*                  AND tasoc = ''.  " Filtrar por tipo de emergencia y asegurarse de que tasoc está vacío.
*            ELSE.  " Si 'conse' no es 'X'.
*              SELECT SINGLE * FROM zist0049  " Realizar otra consulta a zist0049.
*                INTO CORRESPONDING FIELDS OF ls_0049  " Guardar resultados en ls_0049.
*                WHERE emtyp = <rndfal>-emtyp
*                  AND tasoc = ls_0045-tasoc.  " Filtrar por tipo de emergencia y tasoc.
*            ENDIF.
*            IF sy-subrc NE 0.  " Si no se encontró un registro en zist0049.
*              MESSAGE e001(zasoc) WITH i_patnr.  " Mostrar mensaje de error indicando que no corresponde a asociados.
**       El paciente & no corresponde a asociados. El convenio no puede utilizarse
*            ELSE.  " Si se encontró un registro.
*              IF ls_0045-ultpg LT sy-datum.  " Verificar si la fecha de última página es anterior a la fecha actual.
*                MESSAGE e007(zasoc) WITH ls_0045-kunnr.  " Mostrar mensaje de advertencia.
*              ELSE.
*                IF ls_0045-statu NE '1'.  " Comprobar si el estado no es '1'.
*                  MESSAGE e009(zasoc) WITH ls_0045-kunnr.  " Mostrar mensaje de error.
*                ELSE.
*                  IF <rndbew>-orgfa IS NOT INITIAL OR <rndbew>-orgpf IS NOT INITIAL.  " Verificar si alguna unidad organizacional está definida.
*                    REFRESH: it_0050, it_0047, it_0062.  " Limpiar las tablas internas relacionadas.
*                    SELECT * FROM zist0050  " Consultar la tabla zist0050.
*                      INTO CORRESPONDING FIELDS OF TABLE it_0050  " Guardar resultados en it_0050.
*                      WHERE kunnr = ls_0045-kunnr
*                        AND fefin GE sy-datum.  " Filtrar por número de cliente y fecha de finalización.
*
*                    SELECT * FROM zist0047  " Consultar la tabla zist0047.
*                      INTO CORRESPONDING FIELDS OF TABLE it_0047  " Guardar resultados en it_0047.
*                      WHERE kunnr = ls_0045-kunnr
*                        AND fefin GE sy-datum.  " Filtrar por número de cliente y fecha de finalización.
*
*                    SELECT * FROM zist0062  " Consultar la tabla zist0062.
*                      INTO CORRESPONDING FIELDS OF TABLE it_0062  " Guardar resultados en it_0062.
*                      WHERE kunnr = ls_0045-kunnr
*                        AND feini LE sy-datum
*                        AND fefin GE sy-datum.  " Filtrar por número de cliente y rango de fechas.
*
*                    CLEAR lv_espe.  " Limpiar la variable lv_espe.
*
*                    LOOP AT it_0062 INTO ls_0062.  " Iterar sobre la tabla it_0062.
*                      IF ls_0062-orgpf = <rndbew>-orgfa OR  " Verificar si la unidad organizacional es igual a orgfa.
*                         ls_0062-orgpf = <rndbew>-orgpf.  " O si es igual a orgpf.
*                        IF ls_0062-feini LE <rndbew>-bwidt AND  " Verificar si la fecha de inicio es anterior o igual a bwidt.
*                          ls_0062-fefin GE <rndbew>-bwidt.  " Y si la fecha de finalización es posterior o igual a bwidt.
*                          lv_espe = 'X'.  " Marcar que hay una coincidencia especial.
*                        ENDIF.
*                      ENDIF.
*                    ENDLOOP.
*
*                    IF lv_espe = ''.  " Si no hay coincidencias especiales.
*                      LOOP AT it_0050 INTO ls_0050.  " Iterar sobre la tabla it_0050.
*                        IF ls_0050-orgpf = <rndbew>-orgfa OR  " Verificar si la unidad organizacional es igual a orgfa.
*                           ls_0050-orgpf = <rndbew>-orgpf.  " O si es igual a orgpf.
*                          MESSAGE e008(zasoc) WITH ls_0050-orgpf ls_0050-fefin.  " Mostrar mensaje de error.
**                   La unidad organizacional & no es vigente para el asociado hasta el &
*                        ENDIF.
*                      ENDLOOP.
*
*                      LOOP AT it_0047 INTO ls_0047.  " Iterar sobre la tabla it_0047.
*                        IF ls_0047-orgpf = <rndbew>-orgfa OR  " Verificar si la unidad organizacional es igual a orgfa.
*                           ls_0047-orgpf = <rndbew>-orgpf.  " O si es igual a orgpf.
*                          MESSAGE e008(zasoc) WITH ls_0047-orgpf ls_0047-fefin.  " Mostrar mensaje de error.
**                   La unidad organizacional & no es vigente para el asociado hasta el &
*                        ENDIF.
*                      ENDLOOP.
*                    ENDIF.
*                  ENDIF.
*                ENDIF.
*              ENDIF.
*            ENDIF.
*          ENDIF.
*        ELSEIF <rndfal>-emtyp IS NOT INITIAL.  " Si el tipo de emergencia no está vacío.
*          CLEAR: ls_0049.  " Limpiar la estructura ls_0049.
*          SELECT SINGLE * FROM zist0049  " Consultar la tabla zist0049.
*            INTO CORRESPONDING FIELDS OF ls_0049  " Guardar resultados en ls_0049.
*            WHERE emtyp = <rndfal>-emtyp.  " Filtrar por tipo de emergencia.
*          IF sy-subrc = 0.  " Si la consulta fue exitosa.
*            MESSAGE e001(zasoc) WITH i_patnr.  " Mostrar mensaje de error.
*          ENDIF.
*        ENDIF.
*      ENDIF.

*Validacion de colaboradores

      DATA: ls_0174 TYPE zist0174,
            it_0174 TYPE TABLE OF zist0174.
      DATA: lv_vali  TYPE xfeld,
            ls_0162  TYPE zist0162,    " Declarar variable para la tabla zist0162.
            ls_0163  TYPE zist0163,    " Declarar variable para la tabla zist0163.
            ls_0049  TYPE zist0049,    " Declarar variable para la tabla zist0049.
            ls_0045  TYPE zist0045,    " Declarar variable para la tabla zist0045.
            lv_subrc TYPE sy-subrc.     " Declarar variable para almacenar el código de retorno.

      SELECT SINGLE pnt_extnr
        FROM npnt
        WHERE patnr = @<rndfal>-patnr
        INTO @DATA(colaborador).  " Consultar el número externo del colaborador asociado al paciente.

      DATA(num) = strlen( colaborador ).  " Calcular la longitud del número de colaborador.
      CLEAR: ls_0162, ls_0163, lv_subrc, lv_vali.  " Limpiar estructuras y variables para uso posterior.

      IF <rndfal>-emtyp IS NOT INITIAL AND colaborador IS NOT INITIAL.  " Comprobar si el tipo de emergencia no está vacío y si el número de colaborador es menor a 5.

        SELECT *
          FROM zist0174 " Consulta a la tabla ZIST0174 para ver si tiene descuentos
          INTO CORRESPONDING FIELDS OF TABLE it_0174
          WHERE ( colaborador = colaborador OR colaborador = '*' )
          AND checkbox = 'X'.


        IF it_0174[] IS NOT INITIAL.
          READ TABLE it_0174 INTO ls_0174 WITH KEY colaborador = colaborador
                                                   falnr = <rndfal>-falnr.
          IF sy-subrc = 0.
            lv_vali = 'X'.
          ELSE.
            READ TABLE it_0174 INTO ls_0174 WITH KEY colaborador = colaborador
                                                      falnr = '*'.
            IF sy-subrc = 0.
              lv_vali = 'X'.
            ELSE.
              READ TABLE it_0174 INTO ls_0174 WITH KEY colaborador = '*'.
              IF sy-subrc = 0.
                lv_vali = 'X'.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.

        IF lv_vali = ''.

          SELECT SINGLE *
            FROM zist0163  " Consultar la tabla zist0163 para obtener información sobre el tipo de emergencia.
            WHERE emtyp = @<rndfal>-emtyp
            INTO CORRESPONDING FIELDS OF @ls_0163.  " Almacenar resultados en ls_0163.

          IF sy-subrc = 0.
            SELECT SINGLE *
              FROM zist0162  " Consultar la tabla zist0162 para verificar la validez del colaborador.
              WHERE colaborador = @colaborador
              OR paciente_benef = @<rndfal>-patnr
              INTO CORRESPONDING FIELDS OF @ls_0162.  " Almacenar resultados en ls_0162.
            IF sy-subrc = 0.
              IF ls_0162-fin_vigencia < sy-datum.  " Comprobar si la fecha de vigencia ha expirado.
                " Mostrar mensaje de error indicando que el colaborador no está vigente.
                MESSAGE e089(zish) WITH <rndfal>-patnr 'no esta vigente como colaborador' <rndfal>-emtyp.
              ENDIF.
            ELSE.
              " Mostrar mensaje de error indicando que el paciente no es colaborador.
              MESSAGE e088(zish) WITH <rndfal>-patnr <rndfal>-emtyp.
              RETURN.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

*    ELSEIF lv_subrc EQ 0.
*      "El paciente & no es un colaborador. El convenio & no se puede utilizar
*      MESSAGE e088(zish) WITH <rndfal>-patnr <rndfal>-emtyp.
*    ENDIF.

* F. Modif. OSS03062018

* Checo tabla de unidades de lab.
      SELECT SINGLE * FROM znish_lab INTO wa_znish_lab  " Consultar la tabla de unidades de laboratorio.
                                   WHERE erboe EQ <rndbew>-orgpf.  " Filtrar por la unidad organizacional.
* --> Si la encuentra hago las validaciones.
      IF sy-subrc EQ '0'.  " Si se encontró un registro en znish_lab.
* --> Si intenta actualizar una sol. de lab. marca WARNING.
        IF i_vcode EQ 'UPD' AND ( sy-ucomm = 'SAVE' OR sy-ucomm ='LEIS').  " Si se intenta actualizar un registro.
*-->  consulta directamente la tabla para ver la fecha guardada.
          CLEAR wa_nfal.  " Limpiar la estructura wa_nfal.
          SELECT SINGLE * FROM nfal INTO wa_nfal  " Consultar la tabla nfal.
          WHERE falnr EQ i_falnr AND storn EQ ''.  " Filtrar por el número de fallo y asegurarse de que 'storn' está vacío.

* --> Si ya tiene una fecha de terminacion en la tabla marca error.
          IF NOT wa_nfal-enddt IS INITIAL OR <rndfal>-enddt IS INITIAL.  " Comprobar si ya hay una fecha de finalización.
* --> Antes de marcar error checo si es plan. directamente en la tabla.
            SELECT SINGLE * FROM nbew INTO wa_nbew  " Consultar la tabla nbew.
            WHERE einri EQ <rndbew>-einri AND
                  falnr EQ i_falnr AND
                  lfdnr EQ <rndbew>-lfdnr AND
                  planb EQ ' ' AND  " Verificar si el campo 'planb' está vacío.
                  storn EQ ''.  " Asegurarse de que 'storn' está vacío.
* --> Si lo encuentra es que ya es REAL y Sí marca error.
            IF sy-subrc EQ '0'.  " Si se encontró un registro en nbew.
              IF sy-ucomm EQ 'LEIS'.  " Si la acción del usuario es 'LEIS'.
                c_worst_message_type = 'W'.  " Marcar como advertencia.
              ELSE.
                c_worst_message_type = 'E'.  " Marcar como error.
              ENDIF. " sy-ucomm eq 'LEIS'.
              CLEAR hbapiret2.  " Limpiar la estructura de retorno.
              hbapiret2-type = 'W'.  " Establecer el tipo de mensaje a advertencia.
              hbapiret2-id = 'ZISH'.  " Establecer ID del mensaje.
              hbapiret2-number = '055'.  " Establecer número del mensaje.
              INSERT hbapiret2 INTO TABLE c_messages.  " Insertar el mensaje en la tabla de mensajes.
            ENDIF. " sy-subrc eq '0'.
          ENDIF.
        ENDIF.

* --> No deja continuar si no tiene una unidad de admision definida.*
        IF <rndbew>-orgau IS INITIAL AND i_vcode EQ 'INS'.  " Comprobar si el campo de unidad de admisión está vacío al intentar insertar un registro.
          SELECT SINGLE * FROM zist0089  " Consultar la tabla zist0089.
            INTO CORRESPONDING FIELDS OF ls_0089  " Guardar resultados en ls_0089.
            WHERE einri EQ <rndbew>-einri
              AND erboe EQ <rndbew>-orgpf.  " Filtrar por la unidad organizacional.
          IF sy-subrc NE 0.  " Si no se encontró un registro.
            c_worst_message_type = 'E'.  " Marcar como error.
            CLEAR hbapiret2.  " Limpiar la estructura de retorno.
            hbapiret2-type = 'E'.  " Establecer el tipo de mensaje a error.
            hbapiret2-id = 'ZISH'.  " Establecer ID del mensaje.
            hbapiret2-number = '013'.  " Establecer número del mensaje.
            INSERT hbapiret2 INTO TABLE c_messages.  " Insertar el mensaje en la tabla de mensajes.
          ENDIF.
        ENDIF.
        IF <rndbew>-orgau IS INITIAL  " Si la unidad de admisión está vacía.
*        ( i_vcode EQ 'UPD' OR i_vcode EQ 'INS' )
            AND sy-ucomm = 'SAVE'.  " Y la acción del usuario es 'SAVE'.
          SELECT SINGLE * FROM zist0089  " Consultar la tabla zist0089.
            INTO CORRESPONDING FIELDS OF ls_0089  " Guardar resultados en ls_0089.
            WHERE einri EQ <rndbew>-einri
              AND erboe EQ <rndbew>-orgpf.  " Filtrar por la unidad organizacional.
          IF sy-subrc EQ 0.  " Si se encontró un registro.
            c_worst_message_type = 'E'.  " Marcar como error.
            CLEAR hbapiret2.  " Limpiar la estructura de retorno.
            hbapiret2-type = 'E'.  " Establecer el tipo de mensaje a error.
            hbapiret2-id = 'ZISH'.  " Establecer ID del mensaje.
            hbapiret2-number = '013'.  " Establecer número del mensaje.
            INSERT hbapiret2 INTO TABLE c_messages.  " Insertar el mensaje en la tabla de mensajes.
          ENDIF.
        ENDIF.
* --> Valido el sexo del paciente.
*      IF <rnpat>-gschl NE '1' AND <rnpat>-gschl NE '2'.  " Validar que el sexo del paciente no sea masculino (1) ni femenino (2).
*        c_worst_message_type = 'E'.  " Establecer el tipo de mensaje como error.
*        CLEAR hbapiret2.  " Limpiar la estructura hbapiret2.
*        hbapiret2-type = 'E'.  " Establecer el tipo del mensaje a error.
*        hbapiret2-id = 'ZISH'.  " Establecer el ID del mensaje.
*        hbapiret2-number = '026'.  " Establecer el número del mensaje de error.
*        INSERT hbapiret2 INTO TABLE c_messages.  " Insertar el mensaje en la tabla de mensajes.
*      ENDIF.
* --> Valido que el episodio no este cerrado.
        IF <rndfal>-abrkz EQ '2'.  " Verificar si el estado del episodio es 'cerrado' (2).
          c_worst_message_type = 'W'.  " Establecer el tipo de mensaje como advertencia.
          CLEAR hbapiret2.  " Limpiar la estructura hbapiret2.
          hbapiret2-type = 'W'.  " Establecer el tipo del mensaje a advertencia.
          hbapiret2-id = 'ZISH'.  " Establecer el ID del mensaje.
          hbapiret2-number = '025'.  " Establecer el número del mensaje de advertencia.
          INSERT hbapiret2 INTO TABLE c_messages.  " Insertar el mensaje en la tabla de mensajes.
        ENDIF.
      ENDIF .  " Fin de la validación del estado del episodio.
    ENDIF. " Fin de las condiciones Rc1, rc2, rc3.



    IF ( ( i_vcode EQ 'UPD' OR i_vcode = 'INS' ) AND
        ( sy-ucomm = 'SAVE' OR sy-ucomm = 'FURT' ) ) OR
      ( ( sy-ucomm = 'TS_EADM_FC4' OR sy-ucomm = 'TS_EADM_FC2' ) AND
      ( i_vcode EQ 'UPD' OR i_vcode EQ 'INS' ) ).
      CLEAR lv_asoc.  " Limpiar la variable lv_asoc.
*    GET PARAMETER ID 'ASOC_ID' FIELD lv_asoc.  " (Código comentado que podría obtener un ID de asociado).
*    IF lv_asoc = ''.  " (Código comentado que verifica si lv_asoc está vacío).
      CLEAR: wa_nfal, lv_subrc.  " Limpiar la estructura wa_nfal y lv_subrc.
      SELECT SINGLE * FROM nfal INTO wa_nfal  " Consultar la tabla nfal.
      WHERE falnr EQ i_falnr AND storn EQ ''.  " Filtrar por el número de fallo y asegurarse de que 'storn' está vacío.
      IF sy-subrc NE 0 OR sy-subrc EQ 0. "<rndbew>-lfdnr = '00000'.  " (La condición parece redundante, puede simplificarse).
        CLEAR ls_0045.  " Limpiar la estructura ls_0045.
        SELECT SINGLE * FROM zist0045  " Consultar la tabla zist0045.
          INTO CORRESPONDING FIELDS OF ls_0045  " Guardar resultados en ls_0045.
          WHERE patnr = i_patnr.  " Filtrar por el número de paciente.
        lv_subrc = sy-subrc.  " Almacenar el código de retorno de la consulta.

        IF ls_0045-notas IS NOT INITIAL OR ls_0045-nota1 IS NOT INITIAL.  " Comprobar si hay notas presentes.
          IF <rndfal>-falnr IS INITIAL OR <rndbew>-bewty = '1'.  " Verificar si el número de fallo es inicial o si el tipo de documento es '1'.
            IF sy-ucomm = 'TS_EADM_FC2' OR sy-ucomm = 'TS_EADM_FC4'.  " Comprobar si la acción del usuario corresponde a ciertos comandos.
              CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'  " Llamar a la función para mostrar un popup.
                EXPORTING
                  titel        = 'Notas Asociado'  " Título del popup.
                  textline1    = ls_0045-notas  " Primera línea de texto del popup.
                  textline2    = ls_0045-nota1  " Segunda línea de texto del popup.
                  textline3    = ls_0045-nota2  " Tercera línea de texto del popup.
*                 TEXTLINE3    = ' '  " (Línea de texto comentada).
                  start_column = 15  " Columna de inicio para el texto.
                  start_row    = 6.  " Fila de inicio para el texto.
            ENDIF.
          ENDIF.
        ENDIF.

        IF lv_subrc = 0 AND <rndfal>-emtyp IS NOT INITIAL.  " Si la consulta fue exitosa y el tipo de emergencia no está vacío.
          CLEAR: ls_0049.  " Limpiar la estructura ls_0049.
          SELECT SINGLE * FROM zist0049  " Consultar la tabla zist0049.
            INTO CORRESPONDING FIELDS OF ls_0049  " Guardar resultados en ls_0049.
            WHERE emtyp = <rndfal>-emtyp.  " Filtrar por tipo de emergencia.
          IF sy-subrc = 0.  " Si la consulta fue exitosa.
            IF ls_0045-conse = 'X'.  " Comprobar si el campo 'conse' en ls_0045 es 'X'.
              SELECT SINGLE * FROM zist0049  " Realizar otra consulta a zist0049.
                INTO CORRESPONDING FIELDS OF ls_0049  " Guardar resultados en ls_0049.
                WHERE emtyp = <rndfal>-emtyp
                  AND tasoc = ''.  " Filtrar por tipo de emergencia y asegurarse de que tasoc está vacío.
            ELSE.  " Si 'conse' no es 'X'.
              SELECT SINGLE * FROM zist0049  " Realizar otra consulta a zist0049.
                INTO CORRESPONDING FIELDS OF ls_0049  " Guardar resultados en ls_0049.
                WHERE emtyp = <rndfal>-emtyp
                  AND tasoc = ls_0045-tasoc.  " Filtrar por tipo de emergencia y tasoc.
            ENDIF.
            IF sy-subrc NE 0.  " Si no se encontró un registro en zist0049.
              MESSAGE e001(zasoc) WITH i_patnr.  " Mostrar mensaje de error indicando que no corresponde a asociados.
*       El paciente & no corresponde a asociados. El convenio no puede utilizarse
            ELSE.  " Si se encontró un registro.
              IF ls_0045-ultpg LT sy-datum.  " Verificar si la fecha de última página es anterior a la fecha actual.
                MESSAGE e007(zasoc) WITH ls_0045-kunnr.  " Mostrar mensaje de advertencia.
              ELSE.
                IF ls_0045-statu NE '1'.  " Comprobar si el estado no es '1'.
                  MESSAGE e009(zasoc) WITH ls_0045-kunnr.  " Mostrar mensaje de error.
                ELSE.
                  IF <rndbew>-orgfa IS NOT INITIAL OR <rndbew>-orgpf IS NOT INITIAL.  " Verificar si alguna unidad organizacional está definida.
                    REFRESH: it_0050, it_0047, it_0062.  " Limpiar las tablas internas relacionadas.
                    SELECT * FROM zist0050  " Consultar la tabla zist0050.
                      INTO CORRESPONDING FIELDS OF TABLE it_0050  " Guardar resultados en it_0050.
                      WHERE kunnr = ls_0045-kunnr
                        AND fefin GE sy-datum.  " Filtrar por número de cliente y fecha de finalización.

                    SELECT * FROM zist0047  " Consultar la tabla zist0047.
                      INTO CORRESPONDING FIELDS OF TABLE it_0047  " Guardar resultados en it_0047.
                      WHERE kunnr = ls_0045-kunnr
                        AND fefin GE sy-datum.  " Filtrar por número de cliente y fecha de finalización.

                    SELECT * FROM zist0062  " Consultar la tabla zist0062.
                      INTO CORRESPONDING FIELDS OF TABLE it_0062  " Guardar resultados en it_0062.
                      WHERE kunnr = ls_0045-kunnr
                        AND feini LE sy-datum
                        AND fefin GE sy-datum.  " Filtrar por número de cliente y rango de fechas.

                    CLEAR lv_espe.  " Limpiar la variable lv_espe.

                    LOOP AT it_0062 INTO ls_0062.  " Iterar sobre la tabla it_0062.
                      IF ls_0062-orgpf = <rndbew>-orgfa OR  " Verificar si la unidad organizacional es igual a orgfa.
                         ls_0062-orgpf = <rndbew>-orgpf.  " O si es igual a orgpf.
                        IF ls_0062-feini LE <rndbew>-bwidt AND  " Verificar si la fecha de inicio es anterior o igual a bwidt.
                          ls_0062-fefin GE <rndbew>-bwidt.  " Y si la fecha de finalización es posterior o igual a bwidt.
                          lv_espe = 'X'.  " Marcar que hay una coincidencia especial.
                        ENDIF.
                      ENDIF.
                    ENDLOOP.

                    IF lv_espe = ''.  " Si no hay coincidencias especiales.
                      LOOP AT it_0050 INTO ls_0050.  " Iterar sobre la tabla it_0050.
                        IF ls_0050-orgpf = <rndbew>-orgfa OR  " Verificar si la unidad organizacional es igual a orgfa.
                           ls_0050-orgpf = <rndbew>-orgpf.  " O si es igual a orgpf.
                          MESSAGE e008(zasoc) WITH ls_0050-orgpf ls_0050-fefin.  " Mostrar mensaje de error.
*                   La unidad organizacional & no es vigente para el asociado hasta el &
                        ENDIF.
                      ENDLOOP.

                      LOOP AT it_0047 INTO ls_0047.  " Iterar sobre la tabla it_0047.
                        IF ls_0047-orgpf = <rndbew>-orgfa OR  " Verificar si la unidad organizacional es igual a orgfa.
                           ls_0047-orgpf = <rndbew>-orgpf.  " O si es igual a orgpf.
                          MESSAGE e008(zasoc) WITH ls_0047-orgpf ls_0047-fefin.  " Mostrar mensaje de error.
*                   La unidad organizacional & no es vigente para el asociado hasta el &
                        ENDIF.
                      ENDLOOP.
                    ENDIF.
                  ENDIF.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        ELSEIF <rndfal>-emtyp IS NOT INITIAL.  " Si el tipo de emergencia no está vacío.
          CLEAR: ls_0049.  " Limpiar la estructura ls_0049.
          SELECT SINGLE * FROM zist0049  " Consultar la tabla zist0049.
            INTO CORRESPONDING FIELDS OF ls_0049  " Guardar resultados en ls_0049.
            WHERE emtyp = <rndfal>-emtyp.  " Filtrar por tipo de emergencia.
          IF sy-subrc = 0.  " Si la consulta fue exitosa.
            MESSAGE e001(zasoc) WITH i_patnr.  " Mostrar mensaje de error.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

* Validaciones en consultas de Laboratorio
    DATA: lt_0189 TYPE TABLE OF zist0189,
          ls_0189 TYPE zist0189.
    DATA: lt_0100      TYPE  TABLE OF zist0100,
          ls_0100      TYPE zist0100,
          lv_area      TYPE xfeld,
          lv_mail      TYPE xfeld,
          lv_statu     TYPE nbew-statu,
          lv_kztxt     TYPE nbew-kztxt,
          lt_0170      TYPE TABLE OF zist0170,
          ls_0170      TYPE zist0170,
          lt_lines     TYPE tline_tab,
          ls_lines     TYPE tline,
          it_lines     TYPE tline_tab,
          wa_lines     TYPE tline,
          lt_mail      TYPE TABLE OF soli,
          ls_mail      TYPE soli,
          lv_sender    TYPE so_dir_ext,
          lv_title     TYPE char50,
          lv_name      TYPE thead-tdname,
          lv_origen    TYPE so_dir_ext,
          lv_fecha(10) TYPE c,
          lv_hora(8)   TYPE c.
    DATA: theader TYPE thead,
          tlines  TYPE TABLE OF tline,
          llines  TYPE tline.
    DATA: memory_id(30) VALUE 'SAPLSTXD000001'.
    DATA: lv_txtor TYPE string,
          lv_txtde TYPE string.

    IF sy-ucomm = 'TS_EADM_FC4' AND i_vcode EQ 'UPD'.
      CLEAR: lv_statu, lv_kztxt, lv_area, lv_txtor, lv_txtde, theader,
             lv_mail, lv_sender, lv_title, lv_origen, lv_fecha, lv_hora,
             lv_name.
      REFRESH: lt_0189, lt_0100, tlines, lt_0170, lt_lines, lt_mail,
               it_lines.

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
        CLEAR lv_name.
        CONCATENATE <rndbew>-einri <rndbew>-falnr <rndbew>-lfdnr
          INTO lv_name.

        CALL FUNCTION 'READ_TEXT'
          EXPORTING
            client                  = sy-mandt
            id                      = '0000'
            language                = sy-langu
            name                    = lv_name
            object                  = 'NBEW'
          TABLES
            lines                   = it_lines
          EXCEPTIONS
            id                      = 1
            language                = 2
            name                    = 3
            not_found               = 4
            object                  = 5
            reference_check         = 6
            wrong_access_to_archive = 7
            OTHERS                  = 8.

        IF it_lines[] IS NOT INITIAL.
          EXPORT tlines FROM it_lines TO SHARED MEMORY indx(aa) ID 'ZTXT'.
        ENDIF.
      ENDIF.
    ENDIF.

    IF sy-ucomm = 'SAVE' AND i_vcode EQ 'UPD'.
      CLEAR: lv_statu, lv_kztxt, lv_area, lv_txtor, lv_txtde, theader,
             lv_mail, lv_sender, lv_title, lv_origen, lv_fecha, lv_hora,
             lv_name.
      REFRESH: lt_0189, lt_0100, tlines, lt_0170, lt_lines, lt_mail,
               it_lines.

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
                MESSAGE 'Sin autorizaci�n para modificar una consulta concluida'
                   TYPE 'E'.
              ENDIF.
            ENDIF.
          ELSE.
            MESSAGE 'Sin autorizaci�n para modificar una consulta concluida'
               TYPE 'E'.
          ENDIF.
*        ENDIF.
        ELSEIF lv_statu = '20'.
          IF <rndbew>-kztxt <> lv_kztxt.

            CLEAR: llines, wa_lines.
            llines-tdline = lv_kztxt.
            APPEND llines TO tlines.

            wa_lines-tdline = <rndbew>-kztxt.
            APPEND wa_lines TO it_lines.

            lv_mail = 'X'.
          ELSE.
            IMPORT thead TO theader                              "
                   tline TO tlines                                "
            FROM MEMORY ID memory_id.                          "
            LOOP AT tlines INTO llines.
              IF sy-tabix = 1.
                lv_txtde = llines-tdline.
              ELSE.
                CONCATENATE lv_txtde llines-tdline INTO lv_txtde
                  SEPARATED BY space.
              ENDIF.
            ENDLOOP.

            IMPORT tlines TO it_lines FROM SHARED MEMORY indx(aa) ID 'ZTXT'.

            IF it_lines[] IS NOT INITIAL.
              LOOP AT it_lines INTO wa_lines.
                IF sy-tabix = 1.
                  lv_txtor = wa_lines-tdline.
                ELSE.
                  CONCATENATE lv_txtor wa_lines-tdline INTO lv_txtor
                    SEPARATED BY space.
                ENDIF.
              ENDLOOP.
            ELSE.
              wa_lines-tdline = <rndbew>-kztxt.
              APPEND wa_lines TO it_lines.
              lv_txtor = <rndbew>-kztxt.
            ENDIF.
            IF lv_txtde NE lv_txtor.
              lv_mail = 'X'.
            ENDIF.
          ENDIF.

          IF lv_mail = 'X'.
            SELECT * FROM zist0170
              INTO TABLE lt_0170.

            IF sy-subrc = 0.
              REFRESH: lt_lines.
              CALL FUNCTION 'READ_TEXT'
                EXPORTING
                  client                  = sy-mandt
                  id                      = 'ST'
                  language                = sy-langu
                  name                    = 'ZCORREOS_MOD_MLABO'
                  object                  = 'TEXT'
                TABLES
                  lines                   = lt_lines
                EXCEPTIONS
                  id                      = 1
                  language                = 2
                  name                    = 3
                  not_found               = 4
                  object                  = 5
                  reference_check         = 6
                  wrong_access_to_archive = 7
                  OTHERS                  = 8.
              IF sy-subrc <> 0.
                REFRESH: lt_lines.
              ELSE.
                REFRESH lt_mail.
                CLEAR: lv_fecha, lv_hora.

                CONCATENATE sy-datum+6(2)'/' sy-datum+4(2) '/' sy-datum(4)
                  INTO lv_fecha.
                CONCATENATE sy-uzeit(2) ':' sy-uzeit+2(2) ':' sy-uzeit+4(2)
                  INTO lv_hora.

                LOOP AT lt_lines INTO ls_lines.
                  CLEAR: ls_mail.
                  REPLACE ALL OCCURRENCES OF '&1' IN ls_lines-tdline
                    WITH sy-uname.
                  REPLACE ALL OCCURRENCES OF '&2' IN ls_lines-tdline
                    WITH <rndbew>-patnr.
                  REPLACE ALL OCCURRENCES OF '&3' IN ls_lines-tdline
                    WITH <rndbew>-falnr.
                  REPLACE ALL OCCURRENCES OF '&4' IN ls_lines-tdline
                    WITH lv_fecha.
                  REPLACE ALL OCCURRENCES OF '&5' IN ls_lines-tdline
                    WITH lv_hora.
                  CONCATENATE '<p>' ls_lines-tdline '</p>'
                    INTO ls_mail-line.
                  APPEND ls_mail TO lt_mail.
                ENDLOOP.

                CLEAR ls_mail.
                APPEND ls_mail TO lt_mail.
                ls_mail-line = '<p> *** TEXTO ACTUALIZADO *** </p>'.
                APPEND ls_mail TO lt_mail.
                LOOP AT it_lines INTO wa_lines.
                  CLEAR: ls_mail.
                  CONCATENATE '<p>' wa_lines-tdline '</p>'
                    INTO ls_mail-line.
                  APPEND ls_mail TO lt_mail.
                ENDLOOP.

                CLEAR ls_mail.
                APPEND ls_mail TO lt_mail.
                ls_mail-line = '<p> *** TEXTO ORIGINAL *** </p>'.
                APPEND ls_mail TO lt_mail.

                LOOP AT tlines INTO llines.
                  CLEAR: ls_mail.
                  CONCATENATE '<p>' llines-tdline '</p>'
                    INTO ls_mail-line.
                  APPEND ls_mail TO lt_mail.
                ENDLOOP.

                CLEAR: lv_title, lv_origen.
                CONCATENATE 'Modificaci�n en comentarios de consulta'
                  ls_0189-orgfa INTO lv_title.

                lv_origen = 'notificaciones@sanatorio.com.mx'.

                LOOP AT lt_0170 INTO ls_0170.
                  CLEAR lv_sender.
                  lv_sender = ls_0170-email.

                  CALL FUNCTION 'ZISH_SEND_MAIL'
                    EXPORTING
                      mail_send  = lv_sender
                      mail_orig  = lv_origen
                      mail_title = lv_title
                    TABLES
                      mail_body  = lt_mail.
                ENDLOOP.

                REFRESH it_lines.
                EXPORT tlines FROM it_lines TO SHARED MEMORY indx(aa) ID 'ZTXT'.

              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
*----------------------------------------------------------------------*
*	Log de modificaciones	                                               *
*----------------------------------------------------------------------*
* Modified by       : Erick Juarez Espinosa                            *
* Requerimiento     : S/N                                              *
* Modificado por    : Erick Juarez Espinosa        DEVBT02             *
* Fecha             : 22/12/2025                                       *
*	Descripción       : Creacion de codigo de vinculacion para App Movil *
* Transporte        : DEVK912053                                       *
*----------------------------------------------------------------------*
*** INICIO MODIF. - (App Movil) - 22/12/2025 - Erick Juarez Espinosa DEVBT02
      DATA: lv_object    TYPE tnro-object,
            lv_codigo    TYPE n LENGTH 10,
            ls_zisht009  TYPE zisht009,
            lv_direccion TYPE kna1-adrnr,
            lv_but000    TYPE but000-partner,
            lv_correo    TYPE string.

      IF <rndfal>-enddt IS NOT INITIAL.

        lv_object = 'ZISH_CODIGO'.
        CALL FUNCTION 'NUMBER_GET_NEXT'
          EXPORTING
            nr_range_nr             = '01'
            object                  = lv_object
          IMPORTING
            number                  = lv_codigo
          EXCEPTIONS
            interval_not_found      = 1
            number_range_not_intern = 2
            object_not_found        = 3
            quantity_is_0           = 4
            quantity_is_not_1       = 5
            interval_overflow       = 6
            buffer_overflow         = 7
            OTHERS                  = 8.
        IF sy-subrc <> 0.
          MESSAGE 'Error al obtener el código de vinculación' TYPE 'E'.
        ENDIF.

        CLEAR: ls_zisht009, lv_but000, lv_direccion, lv_correo.
        SELECT SINGLE partner
          FROM npnt
          INTO lv_but000
          WHERE patnr = <rndbew>-patnr.
        IF sy-subrc = 0.
          SELECT SINGLE addrnumber
            FROM but020
            INTO lv_direccion
            WHERE partner = lv_but000.
          IF sy-subrc = 0.
            SELECT SINGLE smtp_addr
              FROM adr6
              INTO lv_correo
              WHERE addrnumber = lv_direccion.
            CONDENSE lv_correo.
          ENDIF.
        ENDIF.
        ls_zisht009-codigo  = lv_codigo.
        ls_zisht009-patnr   = <rndbew>-patnr.
        ls_zisht009-falnr   = <rndbew>-falnr.
        ls_zisht009-email   = lv_correo.
        ls_zisht009-fecha_c = sy-datum.
        ls_zisht009-hora_c  = sy-uzeit.
        ls_zisht009-fecha_x = sy-datum + 1.
        ls_zisht009-hora_x  = sy-uzeit.
        ls_zisht009-usuario = sy-uname.

        INSERT zisht009 FROM ls_zisht009.
        IF sy-subrc = 0.
          CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
            EXPORTING
              titel        = 'Codigo de vinculacion'
              textline1    = 'Su codigo de vinculacion es:'
              textline2    = lv_codigo
              start_column = 25
              start_row    = 6.
        ENDIF.

      ENDIF.
*** FIN MODIF.    - (App Movil) - 22/12/2025 - Erick Juarez Espinosa DEVBT02
    ENDIF.

    UNASSIGN <rndbew>.  " Liberar la asignación de la variable <rndbew>.
    UNASSIGN <rnpat>.  " Liberar la asignación de la variable <rnpat>.
    UNASSIGN <rndfal>.  " Liberar la asignación de la variable <rndfal>.
* --> Fin Modificacion para Validacion de Estudios de laboratorio

*----------------------------------------------------------------------*
* Sol. desarrollo Abap : DISH-G01                                      *
* Autor                : Alejandro Hernández Morán (BYTE TECH)         *
* Descripción          : Realizar cambio de estatus en habitaciones al *
* momento de crear el alta del paciente.                               *
*----------------------------------------------------------------------*
*Inicio: DISH-G01
    TYPES: t_nwplace_ad1 TYPE STANDARD TABLE OF nwplace_ad1_bwty.  " Definir un tipo de tabla estándar para nwplace_ad1_bwty.

    DATA: husr05       TYPE usr05,  " Declarar variable para datos de usuario.
          wmodoct      TYPE c,  " Declarar una variable de tipo carácter.
*        HBAPIRET2 TYPE BAPIRET2,  " Comentado, posible estructura de retorno para BAPIs.
          wbdc_fval    TYPE bdc_fval,  " Declarar una variable de tipo bdc_fval.
          hnwplace_ad1 TYPE nwplace_ad1_bwty,  " Declarar una variable para nwplace_ad1_bwty.
          inwplace_ad1 TYPE t_nwplace_ad1,  " Declarar una tabla interna de tipo t_nwplace_ad1.
          inbewtab     TYPE STANDARD TABLE OF nbew,  " Declarar una tabla interna estándar de nbew.
          hnbewtab     TYPE nbew,  " Declarar una variable de tipo nbew.
          wcontinua(1).  " Declarar un carácter de longitud 1 para continuar.

*INICIO: SOLO BLOQUEAR CAMA EN UNIDADES DE EDIFICIO IGUALES A
*BM, BI, BT Y BN ALEJANDRO HDEZ 11/OCT/04
    DATA: hnbau TYPE nbau.  " Declarar una variable de tipo nbau.
*INICIO: IDENTIFICAR VARIANTES DE ALTA ALEJANDRO HDEZ 12/10/2004
    DATA: wi_wplaceid TYPE rnpa10_wp-wplaceid.  " Declarar una variable para identificar el lugar de alta.
*FIN: IDENTIFICAR VARIANTES DE ALTA ALEJANDRO HDEZ 12/10/2004
*break devbt02.  " COMENTADO POR ART-15072008, posiblemente un punto de interrupción.
    DATA: it_nbew TYPE TABLE OF nbew,  " Declarar una tabla interna de tipo nbew.
          ls_nbew TYPE nbew.  " Declarar una variable de tipo nbew.
    DATA: ls_6080 TYPE hrp6080.  " Declarar una variable de tipo hrp6080.

    FIELD-SYMBOLS: <wokcode> TYPE sy-ucomm,  " Declarar un símbolo de campo para el código de función.
                   <hnbew>   TYPE nbew.  " Declarar un símbolo de campo para nbew.
*NMO 21-Septiembre-2004 Se agrega la búsqueda de las variantes en
*la tabla  NWPLACE_AD1_BWTY cuyo tipo de entorno es  'AD1'.
    SELECT * INTO CORRESPONDING FIELDS OF TABLE inwplace_ad1  " Consultar la tabla nwplace_ad1_bwty.
      FROM nwplace_ad1_bwty
      WHERE wplacetype = 'AD1'  AND  " Filtrar por tipo de lugar de alta.
            ( transfer   = 'X'   OR  " Comprobar si se permite la transferencia.
              discharge  = 'X' ).  " Comprobar si se permite el alta.
* Busca si el valor de I_WPLACEID_AD1 existe en la tabla interna entra a
* hacer las validaciones correspondientes de región.

    READ TABLE inwplace_ad1 WITH KEY wplacetype =  'AD1'  " Leer la tabla interna para verificar el lugar de alta.
                                 wplaceid   =  i_wplaceid  " Filtrar por el ID del lugar de alta.
                                 INTO hnwplace_ad1.  " Almacenar el resultado en hnwplace_ad1.

*INICIO: IDENTIFICAR VARIANTES DE ALTA ALEJANDRO HDEZ 12/10/2004
    IF hnwplace_ad1-discharge EQ 'X'.  " Si el alta es posible.
      wi_wplaceid = 'SAP_DISCHARGE'.  " Asignar el ID de alta a 'SAP_DISCHARGE'.
    ELSE.
      wi_wplaceid = 'SAP_TRANSFER'.  " Asignar el ID de alta a 'SAP_TRANSFER'.
    ENDIF.
*FIN: IDENTIFICAR VARIANTES DE ALTA ALEJANDRO HDEZ 12/10/2004

*  IF ( I_WPLACEID EQ 'SAP_DISCHARGE' OR
*       I_WPLACEID EQ 'SAP_TRANSFER' ) AND WCALLTR IS INITIAL.
    IF sy-subrc = 0 AND wcalltr IS INITIAL.  " Si se encontró un registro y no hay llamadas pendientes.
      ASSIGN ('(SAPMNPA10)OK-CODE') TO <wokcode>.  " Asignar el código de función a <wokcode>.
      IF sy-subrc EQ 0 AND <wokcode> EQ 'SAVE'.  " Si se asignó correctamente y la acción es 'SAVE'.
*INICIO: IDENTIFICAR VARIANTES DE ALTA ALEJANDRO HDEZ 12/10/2004
*      IF I_WPLACEID EQ 'SAP_DISCHARGE'.
        IF wi_wplaceid EQ 'SAP_DISCHARGE'.  " Si el ID de lugar de alta es de alta.
*FIN: IDENTIFICAR VARIANTES DE ALTA ALEJANDRO HDEZ 12/10/2004
          ASSIGN ('(SAPMNPA10)NBEW') TO <hnbew>.  " Asignar la estructura de datos de la tabla nbew.
** NMO si no trae valor, lo recupera de la tabla nbew.
          IF <hnbew>-zimmr = ' '.  " Si el campo zimmr está vacío.
            SELECT *  " Consultar la tabla nbew para obtener información adicional.
              FROM nbew
              INTO CORRESPONDING FIELDS OF TABLE it_nbew  " Almacenar en la tabla interna it_nbew.
              WHERE einri = <hnbew>-einri  " Filtrar por la institución.
                AND falnr = <hnbew>-falnr  " Filtrar por el número de fallo.
                AND storn = ''  " Asegurarse de que 'storn' esté vacío.
                AND zimmr NE ''  " Asegurarse de que zimmr no esté vacío.
                AND ( bewty = '1' OR bewty = '3' )  " Filtrar por tipos de beneficio.
                AND statu NE '70'.  " Asegurarse de que el estado no sea '70'.

            SORT it_nbew BY lfdnr DESCENDING.  " Ordenar la tabla it_nbew por el número de línea en orden descendente.

            READ TABLE it_nbew INTO ls_nbew INDEX 1.  " Leer el primer registro de it_nbew en ls_nbew.
            IF sy-subrc = 0.  " Si se encontró un registro.
              ASSIGN ls_nbew TO <hnbew>.  " Asignar el registro encontrado a <hnbew>.
            ENDIF.
*select single * into <HNBEW> from nbew where
*    einri  =   I_INSTITUTION                and
*    falnr  =   I_FALNR                     .
*
          ENDIF.
** Fin
          SELECT SINGLE * FROM usr05 INTO husr05 WHERE bname EQ sy-uname  " Consultar la tabla de usuarios para obtener información del usuario.
          AND parid EQ 'TESTRUN'.  " Filtrar por el identificador de parámetro 'TESTRUN'.
          IF sy-subrc EQ 0.  " Si se encontró un registro de usuario.
            SEARCH husr05-parva FOR 'X'.  " Buscar en los permisos del usuario.
            IF sy-subrc NE 0.  " Si no se encontró 'X', limpiar husr05.
              CLEAR husr05.  " Limpiar la variable husr05.
            ENDIF.
          ENDIF.
          wcontinua = 'X'.  " Marcar que se debe continuar.
          CALL METHOD me->send_mail  " Llamar al método para enviar un correo.
            EXPORTING
              i_wplaceid = wi_wplaceid  " Pasar el ID de lugar de alta.
              i_patnr    = i_patnr  " Pasar el número de paciente.
              i_falnr    = i_falnr.  " Pasar el número de fallo.
        ELSE.

*        CALL FUNCTION 'ISH_NBEWTAB_READ'
*          EXPORTING
*            ss_einri   = i_institution
*            ss_falnr   = i_falnr
*          TABLES
*            ss_nbewtab = inbewtab
*          EXCEPTIONS
*            not_found  = 1
*            OTHERS     = 2.
*        DELETE inbewtab WHERE planb NE space OR
*                              ( bewty NE '1' AND
*                                bewty NE '3' ).
*        SORT inbewtab BY falnr DESCENDING
*                         bwidt DESCENDING
*                         lfdnr DESCENDING.
*        READ TABLE inbewtab INTO hnbewtab INDEX 1.
*        IF sy-subrc EQ 0.
*          wcontinua = 'X'.
*          ASSIGN hnbewtab TO <hnbew>.
*        ELSE.
*          CLEAR wcontinua.
*        ENDIF.
        ENDIF.  " Fin de la verificación de condiciones previas.
        IF wcontinua IS NOT INITIAL.  " Verificar si se debe continuar con el proceso.
          IF <hnbew>-planb = space AND <hnbew>-storn = space AND  " Verificar que los campos planb y storn estén vacíos.
             husr05 IS INITIAL.  " Asegurarse de que no haya información de usuario.
            wmodoct = 'N'.  " Establecer el modo de operación a 'N' (nuevo).

*INICIO: SOLO BLOQUEAR CAMA EN UNIDADES DE EDIFICIO IGUALES A
*BM, BI, BT Y BN ALEJANDRO HDEZ 11/OCT/04
            CLEAR ls_6080.  " Limpiar la estructura ls_6080.
            SELECT SINGLE * FROM hrp6080  " Consultar la tabla hrp6080 para obtener información de la unidad.
                INTO CORRESPONDING FIELDS OF ls_6080  " Almacenar los resultados en ls_6080.
                WHERE ishid = <hnbew>-zimmr.  " Filtrar por el identificador de la unidad.

            IF ls_6080-objcat EQ 'BM'.  " Si la categoría del objeto es 'BM'.
*          IF ls_6080-objcat EQ 'HN' OR ls_6080-objcat EQ 'HR' OR
*             ls_6080-objcat EQ 'HS' OR ls_6080-objcat EQ 'jr' OR
*             ls_6080-objcat EQ 'MS'.  " Otras categorías comentadas, probablemente no relevantes.

              sy-subrc = 0.  " Establecer el código de retorno a 0 (sin errores).
            ELSE.
*FIN: SOLO BLOQUEAR CAMA EN UNIDADES DE EDIFICIO IGUALES A
*BM, BI, BT Y BN ALEJANDRO HDEZ 11/OCT/04
              CLEAR: ibdcdata, imesstab.  " Limpiar las estructuras ibdcdata y imesstab.
              CALL METHOD me->bdc_dynpro  " Llamar al método para interactuar con la dynpro.
                EXPORTING
                  program = 'SAPLOM_NAVFRAMEWORK_OO_OBJ'  " Especificar el programa a usar.
                  dynpro  = '1000'.  " Especificar la dynpro a mostrar.
              CALL METHOD me->bdc_field  " Llamar al método para establecer campos en la dynpro.
                EXPORTING
                  fnam = 'BDC_OKCODE'  " Establecer el campo del código de función.
                  fval = '=SAVE'.  " Asignar el valor para guardar.

              "
              wbdc_fval = 'X'.  " Asignar un valor a wbdc_fval.
              CALL METHOD me->bdc_field  " Llamar nuevamente para establecer otro campo.
                EXPORTING
                  fnam = 'P6093-BLK_IND'  " Establecer el campo de indicador de bloqueo.
                  fval = wbdc_fval.  " Asignar el valor de bloqueo.

              "
              wbdc_fval = 'LI'.  " Asignar un valor para la razón de bloqueo.
              CALL METHOD me->bdc_field  " Establecer otro campo en la dynpro.
                EXPORTING
                  fnam = 'P6093-BLK_RSN'  " Campo para la razón de bloqueo.
                  fval = wbdc_fval.

              CALL METHOD me->bdc_dynpro  " Volver a llamar a la dynpro.
                EXPORTING
                  program = 'SAPLOM_NAVFRAMEWORK_OO_OBJ'  " Especificar el programa.
                  dynpro  = '1000'.  " Especificar la dynpro.

              CALL METHOD me->bdc_field  " Llamar al método para establecer campos.
                EXPORTING
                  fnam = 'BDC_OKCODE'  " Establecer el campo del código de función.
                  fval = '=SAVE'.  " Asignar el valor para guardar.

              "
              wbdc_fval = 'X'.  " Asignar valor para el indicador de bloqueo.
              CALL METHOD me->bdc_field  " Establecer el campo de indicador de bloqueo.
                EXPORTING
                  fnam = 'P6093-BLK_IND'  " Campo de indicador de bloqueo.
                  fval = wbdc_fval.

              "
              wbdc_fval = 'ZALT'.  " Asignar valor para la razón de bloqueo.
              CALL METHOD me->bdc_field  " Establecer el campo de razón de bloqueo.
                EXPORTING
                  fnam = 'P6093-BLK_RSN'  " Campo para la razón de bloqueo.
                  fval = wbdc_fval.

              CALL METHOD me->bdc_field  " Llamar al método para establecer el código de función.
                EXPORTING
                  fnam = 'BDC_OKCODE'  " Campo del código de función.
                  fval = '/EEXIT'.  " Valor para salir de la dynpro.

              SET PARAMETER ID 'EPIS' FIELD <hnbew>-falnr.  " Establecer un parámetro para el número de fallo.

              CALL TRANSACTION 'NB45' USING ibdcdata MODE wmodoct  " Llamar a la transacción NB45.
                                      MESSAGES INTO imesstab.  " Almacenar los mensajes de la transacción en imesstab.

*INICIO: SOLO BLOQUEAR CAMA EN UNIDADES DE EDIFICIO IGUALES A
*BM, BI, BT Y BN ALEJANDRO HDEZ 11/OCT/04
            ENDIF.
*FIN: SOLO BLOQUEAR CAMA EN UNIDADES DE EDIFICIO IGUALES A
*BM, BI, BT Y BN ALEJANDRO HDEZ 11/OCT/04



            IF sy-subrc NE 0.  " Si la llamada a la transacción devolvió un código de error.
              LOOP AT imesstab INTO hmesstab WHERE msgtyp = 'E'.  " Recorrer los mensajes de error.
                CLEAR hbapiret2.  " Limpiar la estructura de retorno.
                hbapiret2-type = hmesstab-msgtyp.  " Asignar el tipo de mensaje.
                hbapiret2-id = hmesstab-msgid.  " Asignar el ID del mensaje.
                hbapiret2-number = hmesstab-msgnr.  " Asignar el número del mensaje.
                hbapiret2-message_v1 = hmesstab-msgv1.  " Asignar el primer mensaje adicional.
                hbapiret2-message_v2 = hmesstab-msgv2.  " Asignar el segundo mensaje adicional.
                hbapiret2-message_v3 = hmesstab-msgv3.  " Asignar el tercer mensaje adicional.
                hbapiret2-message_v4 = hmesstab-msgv4.  " Asignar el cuarto mensaje adicional.
                INSERT hbapiret2 INTO TABLE c_messages.  " Insertar el mensaje en la tabla de mensajes.
              ENDLOOP.  " Fin del bucle sobre los mensajes de error.
              IF c_messages[] IS NOT INITIAL.  " Si hay mensajes en la tabla de mensajes.
                c_worst_message_type = 'E'.  " Establecer el tipo de mensaje como error.
              ENDIF.
            ELSE.  " Si la transacción se ejecutó correctamente.

**            CALL METHOD me->send_mail
**              EXPORTING
**                i_wplaceid = wi_wplaceid
**                i_patnr    = i_patnr
**                i_falnr    = i_falnr.
*            wcalltr = 'X'.
*            CLEAR: ibdcdata, imesstab.
*            CALL METHOD me->bdc_dynpro
*              EXPORTING
*                program = 'SAPLOM_NAVFRAMEWORK_OO_OBJ'
*                dynpro  = '1000'.
*            CALL METHOD me->bdc_field
*              EXPORTING
*                fnam = 'BDC_OKCODE'
*                fval = '=SAVE'.
*            "
*            wbdc_fval = 'X'.
*            CALL METHOD me->bdc_field
*              EXPORTING
*                fnam = 'P6093-BLK_IND'
*                fval = wbdc_fval.
*            "
*            wbdc_fval = 'LI'.
*            CALL METHOD me->bdc_field
*              EXPORTING
*                fnam = 'P6093-BLK_RSN'
*                fval = wbdc_fval.
*
*            CALL METHOD me->bdc_dynpro
*              EXPORTING
*                program = 'SAPLOM_NAVFRAMEWORK_OO_OBJ'
*                dynpro  = '1000'.
*
*            CALL METHOD me->bdc_field
*              EXPORTING
*                fnam = 'BDC_OKCODE'
*                fval = '=SAVE'.
*            "
*            wbdc_fval = 'X'.
*            CALL METHOD me->bdc_field
*              EXPORTING
*                fnam = 'P6093-BLK_IND'
*                fval = wbdc_fval.
*            "
*            wbdc_fval = 'LI'.
*            CALL METHOD me->bdc_field
*              EXPORTING
*                fnam = 'P6093-BLK_RSN'
*                fval = wbdc_fval.
*
*            CALL METHOD me->bdc_field
*              EXPORTING
*                fnam = 'BDC_OKCODE'
*                fval = '/EEXIT'.
*
*            SET PARAMETER ID 'EPIS' FIELD <hnbew>-falnr.
*
*            IF <hnbew>-bett IS NOT INITIAL.
*              CALL TRANSACTION 'NB45' USING ibdcdata MODE wmodoct
*                                      MESSAGES INTO imesstab.
*            ELSE.
*              sy-subrc = 0.
*            ENDIF.
*            IF sy-subrc EQ 0.
*              wcalltr = 'X'.
*            ELSE.
*              c_worst_message_type = 'E'.
*              LOOP AT imesstab INTO hmesstab.
*                CLEAR hbapiret2.
*                hbapiret2-type = hmesstab-msgtyp.
*                hbapiret2-id = hmesstab-msgid.
*                hbapiret2-number = hmesstab-msgnr.
*                hbapiret2-message_v1 = hmesstab-msgv1.
*                hbapiret2-message_v2 = hmesstab-msgv2.
*                hbapiret2-message_v3 = hmesstab-msgv3.
*                hbapiret2-message_v4 = hmesstab-msgv4.
*                INSERT hbapiret2 INTO TABLE c_messages.
*              ENDLOOP.
*            ENDIF.
            ENDIF.  " Fin de la verificación anterior.
          ENDIF.  " Fin de la verificación de wcontinua.
          wcalltr = 'X'.  " Marcar que se ha llamado a la transacción.
          UNASSIGN <hnbew>.  " Liberar la referencia al campo símbolo <hnbew>.
        ENDIF.  " Fin de la condición principal.
      ENDIF.  " Fin de la condición de finalización.
      UNASSIGN <wokcode>.  " Liberar la referencia al campo símbolo <wokcode>.
    ENDIF.  " Fin de la verificación de la operación.
*Fin: DISH-G01
*----------------------------------------------------------------------*
* Sol. desarrollo Abap : DISH-G02                                      *
* Autor                : Alejandro Hernández Morán (BYTE TECH)         *
* Descripción          : Actualizar la Región en base al C.P.          *
*----------------------------------------------------------------------*
*Inicio: DISH-G02
    TYPES: t_nadr    TYPE STANDARD TABLE OF nadr,  " Definición de tipo de tabla para direcciones.
           t_nwplace TYPE STANDARD TABLE OF nwplace.  " Definición de tipo de tabla para lugares.
    DATA: inadr    TYPE t_nadr,  " Declaración de tabla interna inadr.
          htnch10  TYPE tnch10,  " Declaración de estructura para información de región.
          hnwplace TYPE nwplace,  " Declaración de estructura para lugares.
          inwplace TYPE t_nwplace.  " Declaración de tabla interna para lugares.

    FIELD-SYMBOLS: <fs_inadr> TYPE t_nadr,  " Campo símbolo para dirección interna.
                   <fs_nadr>  TYPE nadr,  " Campo símbolo para dirección.
                   <hnadr>    TYPE nadr,  " Campo símbolo para dirección.
                   <hrnadr>   TYPE rnadr.  " Campo símbolo para dirección de registro.

*NMO 17-Agosto-2004  Se agrega la busqueda de las variantes en la tabla
*NWPLACE cuyo tipo de entorno es  'AD1'.
    SELECT * INTO CORRESPONDING FIELDS OF TABLE inwplace FROM nwplace  " Consultar tabla nwplace para lugares tipo 'AD1'.
       WHERE wplacetype = 'AD1'.

* Busca si el valor de I_WPLACEID existe en la tabla interna entra a
* hacer las validaciones correspondientes de región.

    READ TABLE inwplace WITH KEY wplacetype =  'AD1'  " Leer la tabla interna inwplace buscando por wplacetype y wplaceid.
                             wplaceid   =  i_wplaceid INTO  hnwplace.  " Almacenar el resultado en hnwplace.

*  IF I_WPLACEID EQ 'SAP_PATIENT' OR
*     I_WPLACEID EQ 'SAP_DEF' OR
*     I_WPLACEID BETWEEN 'CSTDEV000002' AND 'CSTDEV000099'.

    IF sy-subrc = 0.  " Comprobar si la lectura fue exitosa.
      ASSIGN ('(SAPLNADR)RNADR') TO <hrnadr>.  " Asignar la dirección de registro a <hrnadr>.
      CHECK sy-subrc EQ 0 AND <hrnadr>-adrob EQ 'NPAT'.  " Verificar que la asignación fue exitosa y el tipo de dirección sea 'NPAT'.
      ASSIGN ('(SAPLNADR)INADR') TO <fs_inadr>.  " Asignar la dirección interna a <fs_inadr>.
      IF sy-subrc EQ 0.  " Comprobar si la asignación fue exitosa.
        inadr = <fs_inadr>.  " Asignar la dirección interna a inadr.
        ASSIGN ('(SAPMNPA10)NADR_NPAT') TO <fs_nadr>.  " Asignar la dirección de paciente a <fs_nadr>.
        READ TABLE inadr WITH KEY adrnr = <fs_nadr>-adrnr  " Leer la tabla inadr buscando por número de dirección.
                               adrob = <fs_nadr>-adrob  " Y por tipo de dirección, asignando a <hnadr>.
                       ASSIGNING <hnadr>.
        IF ( <hrnadr>-pstlz NE <fs_nadr>-pstlz OR  " Comparar códigos postales.
             <hrnadr>-land NE <fs_nadr>-land OR  " Comparar países.
             <hrnadr>-regio IS INITIAL ) AND  " Verificar que la región esté vacía.
           <hrnadr>-pstlz IS NOT INITIAL AND  " Asegurarse de que el código postal no esté vacío.
           <hrnadr>-land IS NOT INITIAL.  " Asegurarse de que el país no esté vacío.
          SELECT SINGLE * FROM tnch10 INTO htnch10 WHERE  " Buscar en tnch10 para obtener la región.
                               land1 EQ <hrnadr>-land AND  " Filtrar por país.
                               pstlz EQ <hrnadr>-pstlz AND  " Y por código postal.
                               regio NE space.  " Asegurarse de que la región no esté vacía.
          IF sy-subrc EQ 0.  " Si se encontró un registro.
            <hnadr>-regio = htnch10-regio.  " Asignar la región encontrada a <hnadr>.
          ELSE.
            CLEAR <hnadr>-regio.  " Limpiar la región si no se encontró.
          ENDIF.
          <fs_inadr> = inadr.  " Asignar la dirección interna nuevamente.
        ENDIF.
        UNASSIGN <hnadr>.  " Liberar la referencia al campo símbolo <hnadr>.
        UNASSIGN <fs_nadr>.  " Liberar la referencia al campo símbolo <fs_nadr>.
        UNASSIGN <fs_inadr>.  " Liberar la referencia al campo símbolo <fs_inadr>.
        UNASSIGN <hrnadr>.  " Liberar la referencia al campo símbolo <hrnadr>.
      ENDIF.
    ENDIF.
*Fin: DISH-G02
**----------------------------------------------------------------------
*
** Autor                : Juan Carlos Licea Palafox
*
** Fecha                : 06.07.2010
** Descripción          : Realizar validaciones de convenios marcados
**
**                        como borrados.
**
**----------------------------------------------------------------------
*
*  CASE sy-ucomm.
*    WHEN 'OKAY'.
*
*      DATA: vl2_kostr TYPE ish_nira_display-kostr. "Almacena Aseg.
*      DATA: vl_kostr, "Almacena aseg de tabla NKTR
*            vl_loekz. "Almacena Indicador de tabla NKTR
**Limpiar Variables
*      CLEAR:  vl2_kostr,
*              vl_kostr,
*              vl_loekz.
*
*
**Obtener número de aseguradora y el indicador de borrado.
*
*      SELECT SINGLE kostr
*                    loekz
*      INTO          (vl_kostr,
*                     vl_loekz)
*      FROM          nktr
*      WHERE         kostr = vl2_kostr.
**Si trajo datos de tabla NKTR
*      IF sy-subrc EQ 0.
**Si la aseguradora que trajo esta marcada como borrada
*        IF vl_loekz = 'X'.
*       MESSAGE i016(spec) WITH 'El convenio esta marcado como borrado.'
*                               'Imposible modificar'.
*        ENDIF.
*      ENDIF.
*    WHEN OTHERS.
*  ENDCASE.

*{   DELETE         PROK900141                                        1
*\*--------------------------------------------------------------------#
*\* Autor      :  Victor Reyes - Deloitte
*\* Fecha      :  15/07/2010
*\* Descripcion:  Validar si la asegu                                  \
*\radora ha sido marcada para borrado,
*\*               no permita la seleccion de la aseguradora.
*\*----------------------------------                                  \
*\-----------------------------------
*\
*Break devbt02.
*\  DATA: l_borrado type c,
*\        w_message TYPE bapiret2,
*\        lt_rnira  TYPE ISH_T_RNIRA,
*\        w_rnira   LIKE LINE OF lt_rnira.
*\
*\* CHECK SY-UNAME = 'DEVBT02'.
*\  IF i_data IS NOT INITIAL.
*\      select single loekz
*\        into l_borrado
*\        from nktr
*\       where kostr = i_data+6(10).
*\      if sy-subrc = 0
*\        AND l_borrado = 'X'
*\        AND SY-DATAR = 'X'.
*\          MESSAGE E003(ZISH).
*\      endif.
*\  ENDIF.
*}   DELETE

  ENDIF.
ENDMETHOD.