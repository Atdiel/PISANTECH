*&---------------------------------------------------------------------*
*& Include          ZMMR_VENCIMIENTO_OC_TOP
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_restantes,
         lifnr  TYPE ekko-lifnr,
         ebeln  TYPE ekpo-ebeln,
         ekgrp  TYPE ekko-ekgrp,
         matnr  TYPE ekpo-matnr,
         pos    TYPE ekpo-ebelp,
         d_rest TYPE i,
       END OF ty_restantes,
       ty_tb_restantes TYPE TABLE OF ty_restantes.
