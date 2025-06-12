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
#include <stdint.h>
#include <math.h>

#include <xif_server.h>

#include "carmaker/CM_Main.h"

#include "cmimg.h" // Include the cmimg header for CarMaker image client functionality

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
    xifs_init();
    int cmInit = CM_Main_init(argc, argv);

    if (cmInit != 0) 
    {
        fprintf(stderr, "CarMaker initialization failed with error code: %d\n", cmInit);
        return EXIT_FAILURE;
    }

    cmimg_init(); // Initialize the CarMaker image client


    uint64_t time = 0;

    uint64_t last_lidar = 0;

    while (CM_Main_running()) 
    {

        cmimg_update(); // Update the CarMaker image client

        uint64_t time_now = CM_Main_get_ms();

        if (time_now > time) 
        {
            time = time_now;

            xifs_transmit_timestep(time);
        }

        if (time_now - last_lidar > 50) 
        {
            CM_Main_capture_pointcloud();

            last_lidar = time_now;
        }


        
        CM_Main_update();
    }

    cmimg_quit(); // Clean up the CarMaker image client
    return CM_Main_quit();
}

/***************************************************************
** MARK: STATIC FUNCTIONS
***************************************************************/

