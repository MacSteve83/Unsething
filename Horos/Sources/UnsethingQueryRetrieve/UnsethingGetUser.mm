/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/
/*
**
** Author: Andrew Hewett                Created: 1998.09.03
** 
** Module: dimget
**
** Purpose: 
**      This file contains the routines which help with
**      query/retrieve services using the C-GET operation.
**
**      Module Prefix: DIMSE_
**
** Last Update:         $Author: lpysher $
** Update Date:         $Date: 2006/03/01 20:15:50 $
** Source File:         $Source: /cvsroot/osirix/osirix/Binaries/dcmtk-source/dcmnet/dimget.cc,v $
** CVS/RCS Revision:    $Revision: 1.1 $
** Status:              $State: Exp $
**
** CVS/RCS Log at end of file
*/

/* 
** Include Files
*/

#import "DicomDatabase.h"
#include "osconfig.h"    /* make sure OS specific configuration is included first */

#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <cstdarg>
#include "ofstdinc.h"

#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif

#include "diutil.h"
#include "dimse.h"              /* always include the module header */
#include "cond.h"

#include "dcmqrdbq.h"

/*
**
*/

static int
selectReadable(T_ASC_Association *assoc, 
    T_ASC_Network *net, T_ASC_Association *subAssoc,
    T_DIMSE_BlockingMode blockMode, int timeout)
{
    T_ASC_Association *assocList[2];
    int assocCount = 0;
    
    if (net != NULL && subAssoc == NULL) {
        if (ASC_associationWaiting(net, 0)) {
            /* association request waiting on network */
            return 2;
        }
    } 
    assocList[0] = assoc; 
    assocCount = 1;
    assocList[1] = subAssoc;
    if (subAssoc != NULL) assocCount++;
    if (subAssoc == NULL) {
        timeout = 5;    /* poll wait until an assoc req or move rsp */
    } else {
        if (blockMode == DIMSE_BLOCKING) {
            timeout = 10000;    /* a long time */
        }
    }
    if (!ASC_selectReadableAssociation(assocList, assocCount, timeout)) {
        /* none readable */
        return 0;
    }
    if (assocList[0] != NULL) {
        /* main association readable */
        return 1;
    }
    if (assocList[1] != NULL) {
        /* sub association readable */
        return 2;
    }
    /* should not be reached */
    return 0;
}

extern BOOL forkedProcess;
extern OFCondition mainStoreSCP(T_ASC_Association * assoc, T_DIMSE_C_StoreRQ * request, T_ASC_PresentationContextID presId, UnsethingQueryRetrieveDatabaseHandle *dbHandle);

OFCondition
UnsethingDIMSE_getUser(
        /* in */
        T_ASC_Association *assoc, 
        T_ASC_PresentationContextID presID,
        T_DIMSE_C_GetRQ *request,
        DcmDataset *requestIdentifiers,
        DIMSE_GetUserCallback callback, void *callbackData,
        /* blocking info for response */
        T_DIMSE_BlockingMode blockMode, int timeout,
        /* sub-operation provider callback */
        T_ASC_Network *net,
        DIMSE_SubOpProviderCallback subOpCallback, void *subOpCallbackData,
        /* out */
        T_DIMSE_C_GetRSP *response, DcmDataset **statusDetail,
        DcmDataset **rspIds)
{
    T_DIMSE_Message req, rsp;
    DIC_US msgId = 0;
    int responseCount = 0;
    T_ASC_Association *subAssoc = NULL;
    DIC_US status = STATUS_Pending;

    if (requestIdentifiers == NULL) return DIMSE_NULLKEY;

    bzero((char*)&req, sizeof(req));
    bzero((char*)&rsp, sizeof(rsp));
    
    req.CommandField = DIMSE_C_GET_RQ;
    request->DataSetType = DIMSE_DATASET_PRESENT;
    req.msg.CGetRQ = *request;

    msgId = request->MessageID;

    OFCondition cond = DIMSE_sendMessageUsingMemoryData(assoc, presID, &req,
                                          NULL, requestIdentifiers, 
                                          NULL, NULL);
    if (cond != EC_Normal) {
        return cond;
    }

    /* receive responses */
	UnsethingQueryRetrieveOsiriXDatabaseHandleFactory factory;
	UnsethingQueryRetrieveDatabaseHandle *dbHandle = factory.createDBHandle( assoc->params->DULparams.calledAPTitle, assoc->params->DULparams.calledAPTitle, cond);
	
    int index = 0;
    
    while (cond == EC_Normal && status == STATUS_Pending) {

		if( [NSThread currentThread].isCancelled)
			return EC_Normal;
		
        /* if user wants, multiplex between net/subAssoc 
         * and responses over main assoc.
         */
        switch (selectReadable(assoc, net, subAssoc, blockMode, timeout)) {
        case 0:
            /* none are readble, timeout */
            if (blockMode == DIMSE_BLOCKING) {
                continue;       /* continue with while loop */
            } else {
                return DIMSE_NODATAAVAILABLE;
            }
            /* break; */ // never reached after continue or return.
        case 1:
            /* main association readable */
            break;
        case 2:
            /* net/subAssoc readable */
            if (subOpCallback) {
                subOpCallback(subOpCallbackData, net, &subAssoc);
            }
            continue;   /* continue with main loop */
            /* break; */ // never reached after continue statement
        }

        bzero((char*)&rsp, sizeof(rsp));

        cond = DIMSE_receiveCommand(assoc, blockMode, timeout, &presID, 
                &rsp, statusDetail);
        if (cond != EC_Normal)
		{
            return cond;
        }
		
		switch (rsp.CommandField)
		{
			case DIMSE_C_GET_RSP:
				*response = rsp.msg.CGetRSP;
			
				if (response->MessageIDBeingRespondedTo != msgId)
				{
				  char buf2[256];
				  sprintf(buf2, "DIMSE: Unexpected Response MsgId: %d (expected: %d)", response->MessageIDBeingRespondedTo, msgId);
				  return makeDcmnetCondition(DIMSEC_UNEXPECTEDRESPONSE, OF_error, buf2);
				}
				
				status = response->DimseStatus;
				responseCount++;

				switch (status)
				{
				case STATUS_Pending:
					if (*statusDetail != NULL)
					{
						DCMNET_WARN("getUser: Pending with statusDetail, ignoring detail");
						delete *statusDetail;
						*statusDetail = NULL;
					}
					if (response->DataSetType != DIMSE_DATASET_NULL)
					{
						DCMNET_WARN("getUser: Status Pending, but DataSetType!=NULL");
						DCMNET_WARN("  Assuming NO response identifiers are present");
					}

					/* execute callback */
					if (callback) {
						callback(callbackData, request, responseCount, response);
					}
					break;
				default:
					if (response->DataSetType != DIMSE_DATASET_NULL)
					{
						cond = DIMSE_receiveDataSetInMemory(assoc, blockMode, timeout, &presID, rspIds, NULL, NULL);
						if (cond != EC_Normal)
						{
							return cond;
						}
					}
					break;
				}
			break;
			
			case DIMSE_C_STORE_RQ:
				 cond = mainStoreSCP(assoc, &rsp.msg.CStoreRQ, presID, dbHandle);
                
                if( forkedProcess == NO && index == 0)
                    [[DicomDatabase activeLocalDatabase] initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
                
                index++;
			break;
			
			default:
			{
				char buf1[256];
				sprintf(buf1, "DIMSE: Unexpected Response Command Field: 0x%x", (unsigned)rsp.CommandField);
				return makeDcmnetCondition(DIMSEC_UNEXPECTEDRESPONSE, OF_error, buf1);
			}
			
		}
    }

    /* do remaining sub-association work, we may receive a non-pending
     * status before the sub-association has cleaned up.
     */
    while (subAssoc != NULL) {
        if (subOpCallback) {
            subOpCallback(subOpCallbackData, net, &subAssoc);
        }
    }
	
    if( forkedProcess == NO)
        [[DicomDatabase activeLocalDatabase] initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
    
	delete dbHandle;
	
    return cond;
}

