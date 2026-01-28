*&---------------------------------------------------------------------*
*&  Include           ZISR0084_TOP
*&---------------------------------------------------------------------*

* ****************************************
*	VARIABLE DEFINITION AND WORK AREA
* ****************************************
CLASS lcl_pre_management DEFINITION DEFERRED.
CLASS lcl_are_management DEFINITION DEFERRED.
CLASS lcl_det_management DEFINITION DEFERRED.
CLASS lcl_timer DEFINITION DEFERRED.

CONSTANTS: gc_pre_cname      TYPE tabname VALUE 'CC_PRE_ALTAS',
           gc_are_cname      TYPE tabname VALUE 'CC_AREAS',
           gc_det_cname      TYPE tabname VALUE 'CC_DETAIL',
           gc_timer_interval TYPE i VALUE '30'.

DATA: go_timer_management TYPE REF TO lcl_timer,
      gt_areas_roles       TYPE TABLE OF zist0185,
      gv_ok_code           TYPE sy-ucomm.

**********************************************************************
*         A L V  -  A R E A S
**********************************************************************
TYPES: BEGIN OF ty_areas_output.
         INCLUDE STRUCTURE   zist0187.
         TYPES: button    TYPE icon_d,
         status    TYPE icon_d,
         nursing   TYPE sy-uzeit,
         pharmacy  TYPE sy-uzeit,
         reception TYPE sy-uzeit,
*** MODIF. - 3565 - 27/01/2026 - PTECHABAP01
         insurance TYPE sy-uzeit,
         role_name TYPE char15,
       END OF ty_areas_output.

DATA: go_are_contain TYPE REF TO cl_gui_custom_container,
      go_det_contain TYPE REF TO cl_gui_custom_container,
      go_are_alv     TYPE REF TO cl_gui_alv_grid,
      go_det_alv     TYPE REF TO cl_gui_alv_grid,
      gt_are_fcat    TYPE lvc_t_fcat,
      gt_det_fcat    TYPE lvc_t_fcat,
      gs_are_layout  TYPE lvc_s_layo,
      gs_det_layout  TYPE lvc_s_layo,
      gt_are_output  TYPE TABLE OF ty_areas_output,
      gt_are_all     TYPE TABLE OF ty_areas_output,
      gt_are_det_all TYPE TABLE OF ty_areas_output,
      gt_are_det_out TYPE TABLE OF ty_areas_output,
      go_are_alv_man TYPE REF TO lcl_are_management,
      go_det_alv_man TYPE REF TO lcl_det_management.


**********************************************************************
*         A L V  -  P R E - A L T A S
**********************************************************************
DATA: go_pre_contain TYPE REF TO cl_gui_custom_container,
      go_pre_alv     TYPE REF TO cl_gui_alv_grid,
      gt_pre_fcat    TYPE lvc_t_fcat,
      gs_pre_layout  TYPE lvc_s_layo,
      gt_pre_output  TYPE TABLE OF zist0186,
      go_pre_alv_man TYPE REF TO lcl_pre_management.


**********************************************************************
*    S E L E C T - O P T I O N S
**********************************************************************
SELECTION-SCREEN BEGIN OF BLOCK admin
    WITH FRAME TITLE text-004.
SELECT-OPTIONS: s_datum FOR sy-datum OBLIGATORY.
SELECTION-SCREEN END OF BLOCK admin.

**********************************************************************
*   SELECT OPTION RANGO FECHAS HISTORIAL
**********************************************************************
SELECTION-SCREEN BEGIN OF SCREEN 1999 AS SUBSCREEN.
    SELECT-OPTIONS:   s_log FOR sy-datum .
SELECTION-SCREEN END OF SCREEN 1999.