// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.XBRL;

table 399 "XBRL Schema"
{
    Caption = 'XBRL Schema';
    ObsoleteReason = 'XBRL feature will be discontinued';
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "XBRL Taxonomy Name"; Code[20])
        {
            Caption = 'XBRL Taxonomy Name';
            NotBlank = true;
            TableRelation = "XBRL Taxonomy";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; targetNamespace; Text[250])
        {
            Caption = 'targetNamespace';
        }
        field(5; XSD; BLOB)
        {
            Caption = 'XSD';
            SubType = Memo;
        }
        field(6; "xmlns:xbrli"; Text[250])
        {
            Caption = 'xmlns:xbrli';
        }
        field(7; schemaLocation; Text[250])
        {
            Caption = 'schemaLocation';
        }
        field(8; "Folder Name"; Text[250])
        {
            Caption = 'Folder Name';
        }
    }

    keys
    {
        key(Key1; "XBRL Taxonomy Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

