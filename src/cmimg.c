/***************************************************************
**
** TBReAI Header File
**
** File         :  cmimg.c
** Module       :  tbrert
** Author       :  SH
** Created      :  2025-04-16 (YYYY-MM-DD)
** License      :  MIT
** Description  :  CarMaker Image Client
**
***************************************************************/

/***************************************************************
** MARK: INCLUDES
***************************************************************/

#include "cmimg.h"

#include <stdio.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <signal.h>
#include <inttypes.h>


#if WIN32
    #include <winsock2.h>
    #include <ws2tcpip.h>
    #include <windows.h>
    #include <io.h>
#else
#include <unistd.h>
    #include <sys/time.h>
    #include <sys/socket.h>
    #include <sys/types.h>
    #include <net/if.h>
    #include <netinet/in.h>
    #include <arpa/inet.h>
    #include <netdb.h>
    #include <pthread.h>
#endif

#include <fcntl.h>

#include <xif_server.h>

/***************************************************************
** MARK: CONSTANTS & MACROS
***************************************************************/

#if WIN32
    #define close closesocket
    #define snprintf _snprintf
    #define strcasecmp _stricmp
    #define strncasecmp _strnicmp
    #define sleep Sleep
    #define usleep Sleep
    #define pthread_t HANDLE
#endif

/***************************************************************
** MARK: TYPEDEFS
***************************************************************/

typedef enum {
    SaveFormat_DataNotSaved = 0,
    SaveFormat_Raw,
    SaveFormat_PPM,
    SaveFormat_PGM_byte,
    SaveFormat_PGM_short,
    SaveFormat_PGM_float,
} tSaveFormat;

static struct {
    FILE *EmbeddedDataCollectionFile;
    char *MovieHost; // pc on which IPGMovie or Movie NX runs
    int MoviePort; // TCP/IP port for RSDS
    int sock; // TCP/IP Socket
    char sbuf[64]; // Buffer for transmitted information
    int RecvFlags; // Receive Flags
    int Verbose; // Logging Output
    int ConnectionTries;
    tSaveFormat SaveFormat;
    int TerminationRequested;
} RSDScfg;

struct {
    double tFirstDataTime;
    double tStartSim;
    double tEndSim;
    double tLastSimTime;
    unsigned long long int nBytesTotal;
    unsigned long long int nBytesSim;
    unsigned long int nImagesTotal;
    unsigned long int nImagesSim;
    unsigned char nChannels;
} RSDSIF;


/***************************************************************
** MARK: STATIC FUNCTION DEFS
***************************************************************/

static void cmimg_thread_main(void);

static int connect_with_timeout(int sockfd, struct sockaddr *addr, socklen_t addrlen, int timeout_ms);

static void RSDS_Init(void);
static int RSDS_GetData(void);
static int RSDS_Connect(void);
static int RSDS_RecvHdr(int sock, char *buf);
static void RSDS_PrintSimInfo();
static void RSDS_PrintClosingInfo(void);
static void RSDSIF_AddDataToStats(unsigned int len);
static void RSDSIF_UpdateStats(unsigned int ImgLen, const char *ImgType, int Channel, int ImgWidth, int ImgHeight, float SimTime);
static void RSDSIF_UpdateEndSimTime();
static void WriteEmbeddedDataToCSVFile(const char* data, unsigned int dataLen, int Channel, float SimTime, const char* AniMode);
static void PrintEmbeddedData (const char* data, unsigned int dataLen);

#if WIN32
static inline double GetTime()  // in seconds
{
    FILETIME ft;
    ULARGE_INTEGER ui;
    GetSystemTimeAsFileTime(&ft);
    ui.LowPart = ft.dwLowDateTime;
    ui.HighPart = ft.dwHighDateTime;
    return (double)(ui.QuadPart - 116444736000000000ULL) / 10000000.0; // Convert to seconds since 1970-01-01
}

#else
static inline double GetTime()  // in seconds
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec * 1e-6;
}
#endif


/***************************************************************
** MARK: STATIC VARIABLES
***************************************************************/

static pthread_t cmimg_thread;
static volatile bool running = true;

/***************************************************************
** MARK: PUBLIC FUNCTIONS
***************************************************************/

int cmimg_init(void)
{
    printf("cmimg_init\n");

    running = true;

    #if WIN32
        WSADATA WSAdata;
        if (WSAStartup(MAKEWORD(2,2), &WSAdata) != 0) {
            fprintf(stderr, "WSAStartup failed: %d\n", WSAGetLastError());
            return -1;
        }

        cmimg_thread = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)cmimg_thread_main, NULL, 0, NULL);
        if (cmimg_thread == NULL) {
            fprintf(stderr, "Error creating thread\n");
            return -1;
        }
    #else
        if (pthread_create(&cmimg_thread, NULL, (void *)cmimg_thread_main, NULL) != 0)
        {
            fprintf(stderr, "Error creating thread\n");
            return -1;
        }
    #endif

    return 0;   
}

void cmimg_quit(void)
{
    running = false;

    #if WIN32
        if (cmimg_thread != NULL)
        {
            // Wait for the thread to finish
            WaitForSingleObject(cmimg_thread, INFINITE);
            CloseHandle(cmimg_thread);
            cmimg_thread = NULL;
        }
    #else
        if (pthread_cancel(cmimg_thread) != 0)
        {
            fprintf(stderr, "Error cancelling thread\n");
        }
        
        if (pthread_join(cmimg_thread, NULL) != 0)
        {
            fprintf(stderr, "Error joining thread\n");
        }
    #endif

    printf("cmimg_quit\n");
}



/***************************************************************
** MARK: STATIC FUNCTIONS
***************************************************************/

static void cmimg_thread_main(void)
{
    int connectState = -1;

    RSDS_Init();

    while (running)
    {

        //printf("cmimg_thread_main\n");
        
        if (connectState != 0)
        {
            connectState = RSDS_Connect();
        }
        else
        {
            RSDS_RecvHdr(RSDScfg.sock, RSDScfg.sbuf);

            if (!RSDScfg.TerminationRequested)
            {
                RSDS_GetData();
                fflush(stdout);
            }
        }

        sleep(0);
    }
    
    RSDScfg.TerminationRequested = 1;

    RSDS_PrintClosingInfo();
    close(RSDScfg.sock);
}

int connect_with_timeout(int sockfd, struct sockaddr *addr, socklen_t addrlen, int timeout_ms) {
    // Set non-blocking
    #if WIN32
        unsigned long mode = 1; // 1 for non-blocking
        ioctlsocket(sockfd, FIONBIO, &mode);

        int res = connect(sockfd, addr, addrlen);
        if (res == 0) {
            // Connected immediately
            mode = 0; // Reset to blocking mode
            ioctlsocket(sockfd, FIONBIO, &mode);
            return 0;
        } else if (WSAGetLastError() != WSAEWOULDBLOCK) {
            // Some other error
            return -1;
        }
    #else
        int flags = fcntl(sockfd, F_GETFL, 0);
        fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);

        int res = connect(sockfd, addr, addrlen);
        if (res == 0) {
            // Connected immediately
            fcntl(sockfd, F_SETFL, flags); // Reset to original flags
            return 0;
        } else if (errno != EINPROGRESS) {
            // Some other error
            return -1;
        }
    #endif
    

    // Wait for socket to become writable (connected)
    fd_set wait_set;
    FD_ZERO(&wait_set);
    FD_SET(sockfd, &wait_set);

    struct timeval tv;
    tv.tv_sec = timeout_ms / 1000;
    tv.tv_usec = (timeout_ms % 1000) * 1000;

    res = select(sockfd + 1, NULL, &wait_set, NULL, &tv);
    if (res <= 0) {
        // Timeout or error
        return -2;
    }

    // Check for errors
    int err;
    socklen_t len = sizeof(err);
    getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &err, &len);
    if (err != 0) {
        // Connection failed
        return -3;
    }

    // Success
    #if WIN32
        mode = 0; // Reset to blocking mode
        ioctlsocket(sockfd, FIONBIO, &mode);
    #else
        fcntl(sockfd, F_SETFL, flags); // Reset to original flags
    #endif
    
    return 0;
}

static void RSDS_Init(void)
{
    RSDScfg.MovieHost = "localhost";
    RSDScfg.MoviePort = 2210;
    RSDScfg.Verbose = 0;
    RSDScfg.SaveFormat = SaveFormat_DataNotSaved;
    RSDScfg.EmbeddedDataCollectionFile = NULL;
    RSDScfg.RecvFlags = 0;
    RSDScfg.ConnectionTries = 5;
    RSDScfg.TerminationRequested = 0;

    RSDSIF.tFirstDataTime = 0.0;
    RSDSIF.tStartSim = 0.0;
    RSDSIF.tEndSim = 0.0;
    RSDSIF.tLastSimTime = -1.0;
    RSDSIF.nImagesSim = 0;
    RSDSIF.nImagesTotal = 0;
    RSDSIF.nBytesTotal = 0;
    RSDSIF.nBytesSim = 0;
    RSDSIF.nChannels = 0;
}

static void RSDS_PrintSimInfo()
{
    double dtSimReal = RSDSIF.tEndSim - RSDSIF.tStartSim;
    // at least 1 sec of data is required
    if (dtSimReal > 1.0) {
        printf("\nLast Simulation------------------\n");
        double MiBytes = RSDSIF.nBytesSim / (1024.0 * 1024.0);
        printf("Duration: %.3f (real) %.3f (sim) -> x%.2f\n", dtSimReal, RSDSIF.tLastSimTime, RSDSIF.tLastSimTime / dtSimReal);
        printf("Channels: %d\n", RSDSIF.nChannels);
        printf("Images:   %ld (%.3f FPS)\n", RSDSIF.nImagesSim, RSDSIF.nImagesSim / dtSimReal);
        printf("Bytes:    %.3f MiB (%.3f MiB/s)\n\n", MiBytes, MiBytes / dtSimReal);
    }
    if (RSDScfg.EmbeddedDataCollectionFile != NULL)
        fflush(RSDScfg.EmbeddedDataCollectionFile);

}

static void RSDS_PrintClosingInfo()
{
    // from the very first image to the very last
    double dtSession = RSDSIF.tEndSim - RSDSIF.tFirstDataTime;
    printf("\n-> Closing RSDS-Client...\n");

    // at least 1 sec of data is required
    if (dtSession > 1.0) {
        RSDS_PrintSimInfo();
        printf("Session--------------------------\n");
        double MiBytes = RSDSIF.nBytesTotal / (1024.0 * 1024.0);
        printf("Duration: %g seconds\n", dtSession);
        printf("Images:   %ld (%.3f FPS)\n", RSDSIF.nImagesTotal, RSDSIF.nImagesTotal / dtSession);
        printf("Bytes:    %.3f MiB (%.3f MiB per second)\n", MiBytes, MiBytes / dtSession);
    }
    fflush(stdout);

    if (RSDScfg.EmbeddedDataCollectionFile != NULL)
        fclose(RSDScfg.EmbeddedDataCollectionFile);
}

static void RSDSIF_AddDataToStats(unsigned int len)
{
    RSDSIF.nImagesTotal++;
    RSDSIF.nBytesTotal += len;
    RSDSIF.nImagesSim++;
    RSDSIF.nBytesSim += len;
}

static void RSDSIF_UpdateStats(unsigned int ImgLen, const char *ImgType, int Channel, int ImgWidth, int ImgHeight, float SimTime)
{
    if (RSDSIF.tFirstDataTime == 0.0)
        RSDSIF.tFirstDataTime = GetTime();

    if (SimTime < 0.005 || RSDSIF.tLastSimTime < 0) {
        if (Channel == 0) {
            if (RSDSIF.tLastSimTime > 0)
                RSDS_PrintSimInfo();
            printf("-> Simulation started... (@ %.3f)\n", SimTime);
            RSDSIF.tStartSim = GetTime();
            RSDSIF.nBytesSim = 0;
            RSDSIF.nImagesSim = 0;
            RSDSIF.nChannels = 1;
        }
        // this text will appear only for the first img of each channel
        if (RSDScfg.Verbose == 2)
            printf("%-6.3f : %-2d : %-8s %dx%d %d\n", SimTime, Channel, ImgType, ImgWidth, ImgHeight, ImgLen);
    }
    if (Channel == 0)
        RSDSIF.tLastSimTime = SimTime;

    if (Channel >= RSDSIF.nChannels)
        RSDSIF.nChannels = Channel + 1;
}

static void RSDSIF_UpdateEndSimTime()
{
    RSDSIF.tEndSim = GetTime();
}


static void WriteEmbeddedDataToCSVFile(const char* data, unsigned int dataLen, int Channel, float SimTime, const char* AniMode)
{
    if (RSDScfg.EmbeddedDataCollectionFile != NULL) {
        double * buf = (double *)data;
        unsigned int len =  dataLen/sizeof(double), i;

        fprintf(RSDScfg.EmbeddedDataCollectionFile, "%d,%f,%s", Channel, SimTime, AniMode);
        for (i = 0; i < len; i++ ) {
            fprintf(RSDScfg.EmbeddedDataCollectionFile, ",%f", buf[i]);
        }
        fprintf(RSDScfg.EmbeddedDataCollectionFile, "\n");
    }
}

static void PrintEmbeddedData (const char* data, unsigned int dataLen)
{
    double * buf = (double *)data;
    unsigned int len =  dataLen/sizeof(double), i;
    for (i = 0; i < len; i++ ) {
        printf("(%d) %f ", i, buf[i]);
    }
    printf("\n");
}


/*
 ** RSDS_RecvHdr
 **
 ** Scan TCP/IP Socket and writes to buffer
 */
static int RSDS_RecvHdr(int sock, char *hdr)
{
    const int HdrSize = 64;
    int len = 0;
    int nSkipped = 0;
    int i;

    //while (1) {
        if (RSDScfg.TerminationRequested)
            return -1;
        for (; len < HdrSize; len += i) {
            if ((i = recv(sock, hdr + len, HdrSize - len, RSDScfg.RecvFlags)) <= 0) {
                if (errno == EAGAIN || errno == EWOULDBLOCK) {
                    return 1; // indicate would-block; try again later
                }
                if (!RSDScfg.TerminationRequested) {
                    printf("RSDS_RecvHdr Error during recv: %s\n", strerror(errno));
                    RSDScfg.TerminationRequested = 1;
                }
                return -1;
            }
        }
        if (hdr[0] == '*' && hdr[1] >= 'A' && hdr[1] <= 'Z') {
            /* remove white spaces at end of line */
            while (len > 0 && hdr[len - 1] <= ' ')
                len--;
            hdr[len] = 0;
            if (RSDScfg.Verbose == 1 && nSkipped > 0)
                printf("RSDS: HDR resync, %d bytes skipped\n", nSkipped);
            return 0;
        }
        for (i = 1; i < len && hdr[i] != '*'; i++)
            ;
        len -= i;
        nSkipped += i;
        memmove(hdr, hdr + i, len);
    //}
}

/*
 ** RSDS_Connect
 **
 ** Connect over TCP/IP socket
 */
static int RSDS_Connect(void)
{
#ifdef WIN32
    WSADATA WSAdata;
    if (WSAStartup(MAKEWORD(2,2), &WSAdata) != 0) {
        fprintf (stderr, "RSDS: WSAStartup ((2,2),0) => %d\n", WSAGetLastError());
        return -1;
    }
#endif

    if (RSDScfg.sock > 0)
    {
        close(RSDScfg.sock);
    }
    
    struct sockaddr_in DestAddr;
    struct hostent *he;
    int tries = RSDScfg.ConnectionTries;

    if ((he = gethostbyname(RSDScfg.MovieHost)) == NULL) {
        fprintf(stderr, "RSDS: unknown host: %s\n", RSDScfg.MovieHost);
        return -2;
    }
    DestAddr.sin_family = AF_INET;
    DestAddr.sin_port = htons((unsigned short) RSDScfg.MoviePort);
    DestAddr.sin_addr.s_addr = *(unsigned *) he->h_addr;

    RSDScfg.sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

    int result = connect_with_timeout(RSDScfg.sock, (struct sockaddr*)&DestAddr, sizeof(DestAddr), 100);

    if (result != 0) {
        //fprintf(stderr, "RSDS: can't connect '%s:%d'\n", RSDScfg.MovieHost, RSDScfg.MoviePort);
        return -4;
    }
    
    if (RSDS_RecvHdr(RSDScfg.sock, RSDScfg.sbuf) < 0)
    {
        return -3;
    }

    printf("RSDS: Connected: %s\n", RSDScfg.sbuf + 1);

    memset(RSDScfg.sbuf, 0, 64);

    return 0;
}

/*
 ** RSDS_GetData
 **
 ** data and image processing
 */
static int RSDS_GetData(void)
{
    unsigned int len = 0;
    int res = 0;

    /* Variables for Image Processing */
    char ImgType[32], AniMode[16];
    int ImgWidth, ImgHeight, Channel;
    float SimTime;
    unsigned int ImgLen, dataLen;

    if (sscanf(RSDScfg.sbuf, "*RSDS %d %s %f %dx%d %u", &Channel, ImgType, &SimTime, &ImgWidth, &ImgHeight, &ImgLen) == 6) {

        RSDSIF_UpdateStats(ImgLen, ImgType,Channel, ImgWidth, ImgHeight, SimTime);

        if (RSDScfg.Verbose == 1)
            printf("%-6.3f : %-2d : %-8s %dx%d %d\n", SimTime, Channel, ImgType, ImgWidth, ImgHeight, ImgLen);

        if (ImgLen > 0) {

            // this is how we get the data
            char *img = (char *) malloc(ImgLen);
            for (len = 0; len < ImgLen; len += res) {
                if ((res = recv(RSDScfg.sock, img + len, ImgLen - len, RSDScfg.RecvFlags)) < 0) {
                    printf("RSDS: Socket Reading Failure\n");
                    free(img);
                    break;
                }
            }

	    // save the data to disc
            //WriteImgDataToFile(img, ImgLen, ImgType, Channel, ImgWidth, ImgHeight, SimTime);

            // Publish the image to ROS
            //node->PublishImage(img, ImgLen, ImgType, Channel, ImgWidth, ImgHeight, SimTime);
            printf("GOT IMAGE WITH SIZE %u %u LEN %d CHANNEL %d TYPE %d at time %lu\n", ImgWidth, ImgHeight, ImgLen, Channel, ImgType, SimTime);

            // Call the image callback if set
            
            xif_image_t image;
            image.timestamp = (uint64_t)(SimTime * 1000.0); // Convert seconds to milliseconds
            image.width = ImgWidth;
            image.height = ImgHeight;
            image.channels = 3; // Assuming RGB image
            image.data = img;
                
            xifs_transmit_image(image);

            free(img);

            RSDSIF_AddDataToStats(len);
        }
        // needed for all channels, since we want the time until the last image
        RSDSIF_UpdateEndSimTime();
    } else if (sscanf(RSDScfg.sbuf, "*RSDSEmbeddedData %d %f %u %s", &Channel, &SimTime, &dataLen, AniMode) == 4) {

        if (RSDScfg.Verbose == 1)
            printf("Embedded Data: %d %f %d %s\n", Channel, SimTime, dataLen, AniMode);

        if (dataLen > 0) {
            char *data = (char *) malloc(dataLen);

            // get the data
            for (len = 0; len < dataLen; len += res) {
                if ((res = recv(RSDScfg.sock, data + len, dataLen - len, RSDScfg.RecvFlags)) < 0) {
                    printf("RSDS: Socket Reading Failure\n");
                    free(data);
                    break;
                }
            }

	    // save the data to disc
            WriteEmbeddedDataToCSVFile(data, dataLen, Channel, SimTime, AniMode);
            if (RSDScfg.Verbose == 1)
                PrintEmbeddedData(data, dataLen);

            free(data);
        }
    } else {
        //printf("RSDS: not handled: %s\n", RSDScfg.sbuf);
    }

    return 0;
}
