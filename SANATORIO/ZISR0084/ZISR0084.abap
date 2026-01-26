*----------------------------------------------------------------------*
* Delivery PISANTECH  *
*----------------------------------------------------------------------*
* Proyecto  : Control de Pre-Alta                                      *
* Requerimiento : 3271                                                 *
* Programa  : ZISR0084                                                 *
* Creado por  : Ramón Atdiel Pérez Quintana DEVBT02                    *
* Fecha de creacion : 09/07/2025                                       *
*	Descripcion	: Control de Altas de paciente para                      *
*               verificar pendientes de Areas por las que paso         *
* Transporte  : DEVK911759                                             *
*----------------------------------------------------------------------*

REPORT ZISR0084.

* *********************
*	INCLUDES DEFINITION
* *********************

INCLUDE ZISR0084_TOP.
INCLUDE ZISR0084_CLS.
INCLUDE ZISR0084_PBO.
INCLUDE ZISR0084_PAI.
INCLUDE ZISR0084_F01.

**********************************************************************
*     P R I N C I P A L   L O G I C
**********************************************************************

START-OF-SELECTION.

CALL SCREEN '666'.

END-OF-SELECTION.