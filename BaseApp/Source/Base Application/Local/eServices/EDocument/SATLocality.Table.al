﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

table 27028 "SAT Locality"
{
    DataPerCompany = false;
    DrillDownPageID = "SAT Localities";
    LookupPageID = "SAT Localities";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; State; Code[10])
        {
            Caption = 'State';
            TableRelation = "SAT State";
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code", State)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

