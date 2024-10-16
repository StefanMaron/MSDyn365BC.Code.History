// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

#pragma warning disable AS0125
tableextension 11307 SourceCodeSetupBE extends "Source Code Setup"
{
    Caption = 'Source Code Setup';

    fields
    {
        field(11307; "Financial Journal"; Code[10])
        {
            Caption = 'Financial Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
        }
        field(2000020; "Domiciliation Journal"; Code[10])
        {
            Caption = 'Domiciliation Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
        }
    }
}