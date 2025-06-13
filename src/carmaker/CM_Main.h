/***************************************************************
**
** TBReAI Header File
**
** File         :  CM_Main.h
** Module       :  tbrert
** Author       :  SH
** Created      :  2025-04-16 (YYYY-MM-DD)
** License      :  MIT
** Description  :  CarMaker Main Interface
**
***************************************************************/

#ifndef CM_MAIN_H
#define CM_MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/***************************************************************
** MARK: INCLUDES
***************************************************************/

#include <stdbool.h>
#include <stdint.h>

/***************************************************************
** MARK: CONSTANTS & MACROS
***************************************************************/

/***************************************************************
** MARK: TYPEDEFS
***************************************************************/

typedef struct
{
    double x;
    double y;
    double z;
    double azimuth;
    double elevation;
} beam_entry_t;


/***************************************************************
** MARK: FUNCTION DEFS
***************************************************************/


int CM_Main_init(int argc, char **argv);

bool CM_Main_running(void);

void CM_Main_update(void);

int CM_Main_quit(void);

void CM_Main_capture_pointcloud(void);

void CM_Main_capture_imu(void);

uint64_t CM_Main_get_ms(void);

#ifdef __cplusplus
}
#endif

#endif /* CM_MAIN_H */



