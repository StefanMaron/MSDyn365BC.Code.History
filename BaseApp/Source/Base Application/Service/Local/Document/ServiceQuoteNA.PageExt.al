#if not CLEAN26
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

pageextension 10026 "Service Quote NA" extends "Service Quote"
{
    actions
    {
        modify(Statistics)
        {
            trigger OnBeforeAction()
            begin
                OnBeforeCalculateSalesTaxStatistics(Rec, true);
            end;
        }
    }

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesTaxStatistics(var ServiceHeader: Record "Service Header"; ShowDialog: Boolean)
    begin
    end;
}
#endif
