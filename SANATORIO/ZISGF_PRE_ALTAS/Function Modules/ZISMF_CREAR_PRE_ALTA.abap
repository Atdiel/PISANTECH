FUNCTION zismf_crear_pre_alta.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  IMPORTING
*"     REFERENCE(IV_EINRI) TYPE  EINRI
*"     REFERENCE(IV_FALNR) TYPE  FALNR
*"     REFERENCE(IV_ORGFA) TYPE  NZUWFA
*"  EXCEPTIONS
*"      FALNR_NOT_FOUND
*"      CREATION_FAILED
*"      NOT_AUTHORIZED
*"----------------------------------------------------------------------
  DATA: lt_um_pre TYPE TABLE OF zist0187.


  DATA: ls_pre_alta TYPE zist0186,
        lv_pat_name TYPE char60_cp,
        lv_room     TYPE ish_zimmid,
        lv_message  TYPE char50,
        lv_need_pre TYPE char1.

  REFRESH:  lt_um_pre.

  CLEAR:  ls_pre_alta,
          lv_pat_name,
          lv_room,
          lv_need_pre.

**********************************************************************
* V A L I D A C I O N E S
**********************************************************************


  "Validar que exista el episodio en la tabla NFAL
  SELECT SINGLE * FROM nfal
    INTO @DATA(ls_nfal)
    WHERE
      einri   = @iv_einri AND
      falnr   = @iv_falnr.

  IF sy-subrc <> 0.
    MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '002' WITH text-001 DISPLAY LIKE 'E'.
    RAISE falnr_not_found.
  ENDIF.

  "Validar si no tiene folios pendientes
  SELECT SINGLE * FROM zmmmxt1005
    INTO @DATA(ls_folio)
    WHERE
      einri     = @iv_einri AND
      falnr     = @iv_falnr.
*      pick      = @space.

  IF sy-subrc = 0.
    SELECT SINGLE * FROM resb                   " Validar si hay posiciones RESB con KZEAR lleno
      INTO @DATA(ls_reserva)
      WHERE
        rsnum = @ls_folio-rsnum AND
        kzear = @abap_false.

    IF sy-subrc = 0.
      MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '009'
        WITH text-010 ls_folio-folio text-011 DISPLAY LIKE 'E'.
      RAISE creation_failed.
    ENDIF.

  ENDIF.

  "Validar si es ambulatorio y si esta en tabla ZIST0190

  CALL FUNCTION 'ZISMF_VALIDAR_AREAS'
    EXPORTING
      iv_einri         =  iv_einri   " IS-H: Centro sanitario
      iv_falnr         =  iv_falnr   " IS-H: Número de episodio
    IMPORTING
      ev_need_pre_alta = lv_need_pre
    EXCEPTIONS
      falnr_not_found  = 1
      others           = 2
    .
  IF sy-subrc <> 0.
*   MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    RAISE creation_failed.
  ENDIF.

  IF ls_nfal-falar = '1'.
    IF lv_need_pre = abap_false.
      "No necesita pre-alta
      MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '010' WITH text-012 iv_orgfa DISPLAY LIKE 'E'.
      RAISE creation_failed.
    ENDIF.
  ELSEIF ls_nfal-falar = '2'.
    IF lv_need_pre = abap_false.
      "No necesita pre-alta
      MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '007' WITH text-008 iv_orgfa DISPLAY LIKE 'E'.
      RAISE creation_failed.
    ENDIF.
  ENDIF.

  "Validar um donde se levanta pre-alta
  SELECT * FROM zist0188
    INTO TABLE @DATA(lt_authorized)
    WHERE
      uname     = @sy-uname.
  IF sy-subrc <> 0.
    MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '003' WITH text-005 DISPLAY LIKE 'E'.
    RAISE creation_failed.
  ENDIF.

  "Validar permisos para area
  READ TABLE lt_authorized WITH KEY area = iv_orgfa INTO DATA(ls_authorized).
  IF sy-subrc <> 0.
    MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '004' WITH text-006 iv_orgfa DISPLAY LIKE 'E'.
    RAISE not_authorized.
  ENDIF.

  "Buscar en la tabla de registros de pre altas
  SELECT SINGLE * FROM zist0186
    INTO ls_pre_alta
    WHERE
      einri       = iv_einri AND
      falnr       = iv_falnr AND
      deleted     = abap_false. "Solo traer si no esta marcada para borrado


  IF sy-subrc = 0.
    "Si la hora de alta ya se registro, significa que ya fue dado de alta
    IF ls_pre_alta-alta_hour IS NOT INITIAL.
      MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '004' WITH text-002 DISPLAY LIKE 'E'.
    ELSE.
      MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '008' WITH text-009 DISPLAY LIKE 'W'.
    ENDIF.
    "Salir de funcion, ya esta creada la pre-alta.
    RAISE creation_failed.
  ENDIF.

**********************************************************************
*     F I N   V A L I D A C I O N E S
**********************************************************************

***********************************************
  "Crear pre alta
***********************************************

  SELECT MAX( id ) FROM zist0186
    INTO @DATA(lv_next_id).

  lv_next_id = lv_next_id + 1.

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

  "Estructura Pre-Alta
  ls_pre_alta = VALUE #( id    = lv_next_id
                         einri = iv_einri
                         falnr = iv_falnr
                         uname = sy-uname
                         patnr = ls_epi_pat-patnr
                         zimmr = lv_room
                         full_name = lv_pat_name
                         pre_date = sy-datum
                         pre_hour = sy-uzeit
                         status   = icon_red_light
                         ).

  "User-Area Buscamos usuarios suscritos para monitor
  SELECT * FROM zist0185
    INTO TABLE @DATA(lt_utonotify).

  "Buscamos todas las UNIDADES por donde paso el episodio con base a areas suscritas a monitor
  SELECT orgfa, orgpf FROM nbew
    INTO TABLE @DATA(lt_unidades)
    WHERE
      einri   = @iv_einri AND
      falnr   = @iv_falnr.

  "Eliminamos la unidad medica que solicita la pre-alta
*  DELETE lt_utonotify WHERE uname = ls_user-uname.

*** INICIO MODIF. - 3565 - 26/01/2026 - PTECHABAP01
  "Buscamos la clase de aseguradora para este episodio
  SELECT SINGLE kostr FROM ncir
    INTO @DATA(lv_kostr)
    WHERE
      einri   = @iv_einri AND
      falnr   = @iv_falnr AND
*** INICIO MODIF. - 3565 - 25/02/2026 - DEVBT02 Ramón Quintana
      patkz   = @abap_false AND "Corresponda al de compañia no al de particular
      storn   = @abap_false. "No este anulado
*** FIN MODIF.    - 3565 - 25/02/2026 - DEVBT02 Ramón Quintana

  "Obtener clase aseguradora
  SELECT SINGLE ins_prov_type FROM nins
    INTO @DATA(lv_ins_cls)
    WHERE
      partner   = @lv_kostr.

  "Buscar en la tabla de usuarios-aseguradora por clase aseguradora
  SELECT * FROM zist0195
    INTO TABLE @DATA(lt_usr_ins)
    WHERE
      ins_prov_type   = @lv_ins_cls.

*** FIN MODIF.    - 3565 - 26/01/2026 - PTECHABAP01

  LOOP AT lt_utonotify INTO DATA(ls_utonotify).
    "Buscar si la unidad esta registrada en monitor por ORGFA.
    READ TABLE lt_unidades WITH KEY orgfa = ls_utonotify-area TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      "Por ORGPF
      READ TABLE lt_unidades WITH KEY orgpf = ls_utonotify-area TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        "Saltamos al siguiente al no encontrar registrado el usuario
        CONTINUE.
      ENDIF.
    ENDIF.

*** INICIO MODIF. - 3565 - 26/01/2026 - PTECHABAP01
    "Validamos si el rol del usuario es aseguradora, de ser asi verificamos si por clase de aseg. necesita la notif.
    IF ls_utonotify-role = 4.
      READ TABLE lt_usr_ins WITH KEY uname = ls_utonotify-uname TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        "Saltamos al sig. registro al no estar en tabla clase aseguradora.
        CONTINUE.
      ENDIF.
    ENDIF.
*** FIN MODIF.    - 3565 - 26/01/2026 - PTECHABAP01
    "Agregamos unidad para mandar notificacion
    APPEND VALUE #(   id    = lv_next_id
                      einri = iv_einri
                      falnr = iv_falnr
                      area  = ls_utonotify-area
                      role  = ls_utonotify-role
                      patnr = ls_epi_pat-patnr
                      full_name = lv_pat_name
                      ) TO lt_um_pre.
  ENDLOOP.

  IF lt_um_pre IS INITIAL.
    MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '011' WITH text-013 DISPLAY LIKE 'E'.
    RAISE creation_failed.
  ENDIF.

  MODIFY zist0186 FROM ls_pre_alta.
  IF sy-subrc <> 0.
    MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '005' WITH text-003 DISPLAY LIKE 'E'.
    RAISE creation_failed.
  ENDIF.
  MODIFY zist0187 FROM TABLE lt_um_pre.
  IF sy-subrc <> 0.
    MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '005' WITH text-003 DISPLAY LIKE 'E'.
    RAISE creation_failed.
  ENDIF.

  COMMIT WORK.
  MESSAGE ID 'PRE-ALTA' TYPE 'S' NUMBER '006' WITH text-007.


ENDFUNCTION.