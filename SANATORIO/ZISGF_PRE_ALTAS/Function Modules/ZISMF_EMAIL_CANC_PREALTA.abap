FUNCTION zismf_email_canc_prealta.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  IMPORTING
*"     REFERENCE(IV_ID_PREALTA) TYPE  /DSD/HH_LFDNR
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


  CLEAR: lv_room, lv_pat_name.
  "Lookup for users emails information
  SELECT * FROM zist0187
    INTO TABLE @DATA(lt_areas_to_notify)
    WHERE
      id    = @iv_id_prealta AND
      verif = @abap_true.

  READ TABLE lt_areas_to_notify INDEX 1 INTO DATA(ls_episodio).
  IF sy-subrc <> 0.
    "RAISE ERROR
    EXIT.
  ENDIF.
  DATA(lv_episodio) = |{ ls_episodio-falnr ALPHA = OUT }|.

  "Obtener habitacion y nombre paciente
  SELECT SINGLE epi~patnr, epi~falar, but~name_first, but~name_last
    FROM nfal AS epi INNER JOIN npnt AS pat
    ON epi~patnr = pat~patnr
    INNER JOIN but000 AS but
    ON pat~partner = but~partner
    INTO @DATA(ls_epi_pat)
    WHERE
      epi~einri     = @ls_episodio-einri AND
      epi~falnr     = @ls_episodio-falnr.


  SELECT * FROM nbew
    INTO TABLE @DATA(lt_nbew)
    WHERE
      einri   = @ls_episodio-einri AND
      falnr   = @ls_episodio-falnr.

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

  SELECT * FROM zist0185
    INTO TABLE @DATA(lt_emails)
    FOR ALL ENTRIES IN @lt_areas_to_notify
    WHERE
      uname     = @lt_areas_to_notify-resp_user AND
      area      = @lt_areas_to_notify-area AND
      role      = @lt_areas_to_notify-role.
  LOOP AT lt_emails INTO DATA(ls_emails).
    DATA(lv_area) = ls_emails-area.
    DATA(lv_email) = ls_emails-email.
    DATA(lv_role) = COND #( WHEN ls_emails-role = '1'
                              THEN 'Enfermeria'
                            WHEN ls_emails-role = '2'
                              THEN 'Farmacia'
                            WHEN ls_emails-role = '4'
                              THEN 'Aseguradora'
                            ELSE 'Recepción' ).
    TRY.
        lo_send_request = cl_bcs=>create_persistent( ).

        mailsubject = 'Cancelación de prealta'.
        mailtext = VALUE #( ( |Por medio de este correo| )
                            ( |Se le notifica que la prealta para el episodio { lv_episodio }| )
                            ( |del paciente { lv_pat_name }| )
                            ( |en la cama { lv_room }| )
                            ( |en la unidad médica { lv_area } con el rol de { lv_role }| )
                            ( |se ha cancelado| ) ).

        lo_document = cl_document_bcs=>create_document(
         i_type = 'RAW'
         i_text = mailtext
         i_subject = mailsubject ).
        lo_send_request->set_document( lo_document ).

        lo_sender = cl_cam_address_bcs=>create_internet_address( 'notificaciones@sanatorio.com.mx' ).
        lo_send_request->set_sender( lo_sender ).


        lo_recipient_to = cl_cam_address_bcs=>create_internet_address( lv_email ).
        lo_send_request->add_recipient( i_recipient = lo_recipient_to i_express = abap_true ).

        lo_send_request->set_send_immediately( i_send_immediately = abap_true ).

        DATA(lv_sent_to_all) = lo_send_request->send( ).


      CATCH cx_bcs INTO lo_bcs_exception.

        WRITE: 'Error occurred while sending email: Error Type', lo_bcs_exception->error_type.

    ENDTRY.



  ENDLOOP.

  IF lv_sent_to_all = abap_true.
    MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '001' WITH text-014.
  ELSE.
    MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '002' WITH text-015 DISPLAY LIKE 'E'.
  ENDIF.

  COMMIT WORK.

  SUBMIT rsconn01 WITH mode = 'INT'
            WITH output = space
            AND RETURN.


ENDFUNCTION.