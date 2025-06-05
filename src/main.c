/***************************************************************
**
** TBReAI Source File
**
** File         :  main.c
** Module       :  CarMaker-XIF
** Author       :  SH
** Created      :  2025-06-05 (YYYY-MM-DD)
** License      :  MIT
** Description  :  CarMaker Entry Point
**
***************************************************************/

/***************************************************************
** MARK: INCLUDES
***************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#include "carmaker/CM_Main.h"

/***************************************************************
** MARK: CONSTANTS & MACROS
***************************************************************/

/***************************************************************
** MARK: TYPEDEFS
***************************************************************/

/***************************************************************
** MARK: STATIC FUNCTION DEFS
***************************************************************/

/***************************************************************
** MARK: STATIC VARIABLES
***************************************************************/

/***************************************************************
** MARK: PUBLIC FUNCTIONS
***************************************************************/

int main(int argc, char **argv)
{
    int cmInit = CM_Main_init(argc, argv);

    if (cmInit != 0) {
        fprintf(stderr, "CarMaker initialization failed with error code: %d\n", cmInit);
        return EXIT_FAILURE;
    }

    while (CM_Main_running()) {
        CM_Main_update();
        printf("CarMaker is running...\n");
    }

    return CM_Main_quit();
}

/***************************************************************
** MARK: STATIC FUNCTIONS
***************************************************************/

