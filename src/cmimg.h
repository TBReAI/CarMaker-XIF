/***************************************************************
**
** TBReAI Header File
**
** File         :  cmimg.h
** Module       :  tbrert
** Author       :  SH
** Created      :  2025-04-16 (YYYY-MM-DD)
** License      :  MIT
** Description  :  CarMaker Image Client
**
***************************************************************/

#ifndef CMIMG_H
#define CMIMG_H

#ifdef __cplusplus
extern "C" {
#endif

/***************************************************************
** MARK: INCLUDES
***************************************************************/

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>


/***************************************************************
** MARK: CONSTANTS & MACROS
***************************************************************/

/***************************************************************
** MARK: TYPEDEFS
***************************************************************/

/***************************************************************
** MARK: FUNCTION DEFS
***************************************************************/

int cmimg_init(void);

void cmimg_update(void);

void cmimg_quit(void);

#ifdef __cplusplus
}
#endif

#endif /* CMIMG_H */



