FUNCTION zismf_check_new_reservation.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  IMPORTING
*"     REFERENCE(IV_EINRI) TYPE  EINRI
*"     REFERENCE(IV_FALNR) TYPE  FALNR
*"     REFERENCE(IV_ANFOE) TYPE  ISH_MANFOE
*"     REFERENCE(IV_ANPOE) TYPE  ISH_MANPOE
*"----------------------------------------------------------------------
  DATA: lo_send_request    TYPE REF TO cl_bcs,
        mailsubject        TYPE so_obj_des,
        mailtext           TYPE bcsy_text,
        lo_document        TYPE REF TO cl_document_bcs,
        lo_sender          TYPE REF TO cl_cam_address_bcs,
        lo_recipient_to    TYPE REF TO cl_cam_address_bcs,
        lo_lo_recipient_cc TYPE REF TO cl_cam_address_bcs,
        lo_recipient_bcc   TYPE REF TO cl_cam_address_bcs,
        lo_bcs_exception   TYPE REF TO cx_bcs,
        lv_room            TYPE ish_zimmid,
        lv_pat_name        TYPE char60_cp.

  CONSTANTS lc_pharm_role TYPE n VALUE 2.

  CLEAR: lv_room, lv_pat_name.

  "Validar si este episodio tiene una pre-alta
  SELECT SINGLE * FROM zist0186
    INTO @DATA(ls_pre_alta)
    WHERE
      einri   = @iv_einri AND
      falnr   = @iv_falnr AND
      deleted = @abap_false. "que no sea eliminado

  IF sy-subrc = 0.

    SELECT SINGLE * FROM zist0187
      INTO @DATA(ls_area)
      WHERE
        einri = @iv_einri AND
        falnr = @iv_falnr AND
        area  IN ( @iv_anfoe, @iv_anpoe ) AND
        deleted = @abap_false AND "que no este eliminada la check-list
        role  = @lc_pharm_role. "farmacia
    IF sy-subrc = 0 AND ls_area-verif = abap_true. "Solo daremos reversa si la um libero previamente

      "manejar el status de la check-list
      SELECT * FROM zist0187
      INTO TABLE @DATA(lt_pending_areas)
      WHERE
        id        = @ls_area-id AND
        verif     = @abap_true. "que si se haya liberado

      DELETE lt_pending_areas WHERE area = ls_area-area AND role = ls_area-role.
      IF lt_pending_areas IS NOT INITIAL.
        "almenos una area libero
        ls_pre_alta-status = icon_yellow_light.
      ELSE.
        "ninguna area libero ademas de la que estamos modificando
        ls_pre_alta-status = icon_red_light.
      ENDIF.
      "Dar reversa para impedir la ALTA
      ls_area-verif = abap_false.
      MODIFY zist0187 FROM ls_area.
      IF sy-subrc <> 0.
        MESSAGE text-018 TYPE 'S' DISPLAY LIKE 'E'.
        RETURN. "salir en caso de error
      ENDIF.
      MODIFY zist0186 FROM ls_pre_alta.
      IF sy-subrc <> 0.
        MESSAGE text-018 TYPE 'S' DISPLAY LIKE 'E'.
        RETURN. "salir en caso de error
      ENDIF.

**********************************************************************
**            E N V I A R     C O R R E O
**********************************************************************
      "Obtener habitacion y nombre paciente
      SELECT SINGLE epi~patnr, epi~falar, but~name_first, but~name_last
        FROM nfal AS epi INNER JOIN npnt AS pat
        ON epi~patnr = pat~patnr
        INNER JOIN but000 AS but
        ON pat~partner = but~partner
        INTO @DATA(ls_epi_pat)
        WHERE
          epi~einri     = @iv_einri AND
          epi~falnr     = @iv_falnr.


      SELECT * FROM nbew
        INTO TABLE @DATA(lt_nbew)
        WHERE
          einri   = @iv_einri AND
          falnr   = @iv_falnr.

      IF ls_epi_pat-falar = '1'. "Para Hospitalizados
        "Admisión
        READ TABLE lt_nbew WITH KEY bewty = '1' INTO DATA(ls_bew1).
        IF sy-subrc = 0.
          lv_room = ls_bew1-zimmr.
        ELSE.
          "Traslados
          READ TABLE lt_nbew WITH KEY bewty = '3' INTO DATA(ls_bew3).
          IF sy-subrc = 0.
            lv_room = ls_bew3-zimmr.
          ENDIF.
        ENDIF.
      ELSEIF ls_epi_pat-falar = '2'.
        "Para ambulatorios el primer movimiento
        READ TABLE lt_nbew WITH KEY lfdnr = 1 INTO DATA(ls_first_mov).
        IF sy-subrc = 0.
          lv_room = ls_first_mov-zimmr.
        ENDIF.
      ENDIF.

      lv_pat_name = |{ ls_epi_pat-name_first } { ls_epi_pat-name_last }|.

      SELECT SINGLE * FROM zist0185
        INTO @DATA(ls_email)
        WHERE
          uname     = @ls_area-resp_user AND
          area      = @ls_area-area AND
          role      = @ls_area-role.

      IF sy-subrc <> 0.
        MESSAGE text-019 TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.

      IF ls_email-email IS INITIAL.
        MESSAGE text-020 && |{ ls_area-area }| TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.

      TRY.
          lo_send_request = cl_bcs=>create_persistent( ).

          mailsubject = 'Nueva Reserva Check-list'.
          mailtext = VALUE #( ( |Por medio de este correo| )
                              ( |Se le notifica que la liberación Check-list para el episodio { iv_falnr ALPHA = OUT }| )
                              ( |del paciente { lv_pat_name }| )
                              ( |en la cama { lv_room }| )
                              ( |en la unidad médica { ls_email-area } con el rol de farmacia| )
                              ( |se ha anulado debido a nuevos cargos al paciente| )
                              ( |favor de validar y realizar nuevamente la liberacion en su monitor ZISH194| ) ).

          lo_document = cl_document_bcs=>create_document(
           i_type = 'RAW'
           i_text = mailtext
           i_subject = mailsubject ).
          lo_send_request->set_document( lo_document ).

          lo_sender = cl_cam_address_bcs=>create_internet_address( 'notificaciones@sanatorio.com.mx' ).
          lo_send_request->set_sender( lo_sender ).


          lo_recipient_to = cl_cam_address_bcs=>create_internet_address( ls_email-email ).
          lo_send_request->add_recipient( i_recipient = lo_recipient_to i_express = abap_true ).

          lo_send_request->set_send_immediately( i_send_immediately = abap_true ).

          DATA(lv_sent_to_all) = lo_send_request->send( ).


        CATCH cx_bcs INTO lo_bcs_exception.

          WRITE: 'Error occurred while sending email: Error Type', lo_bcs_exception->error_type.

      ENDTRY.

      IF lv_sent_to_all = abap_true.
        MESSAGE text-014 TYPE 'S'.
      ELSE.
        MESSAGE text-015 TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.

      COMMIT WORK.

      SUBMIT rsconn01 WITH mode = 'INT'
                WITH output = space
                AND RETURN.

    ENDIF.
  ENDIF.




ENDFUNCTION.