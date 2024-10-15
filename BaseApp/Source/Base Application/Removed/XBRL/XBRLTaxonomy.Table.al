// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.XBRL;

table 394 "XBRL Taxonomy"
{
    Caption = 'XBRL Taxonomy';
    ObsoleteReason = 'XBRL feature will be discontinued';
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[20])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "xmlns:xbrli"; Text[250])
        {
            Caption = 'xmlns:xbrli';
        }
        field(4; targetNamespace; Text[250])
        {
            Caption = 'targetNamespace';
        }
        field(5; schemaLocation; Text[250])
        {
            Caption = 'schemaLocation';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

