// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 11013 "Electronic VAT Decl. Setup"
{
    Caption = 'Electronic VAT Decl. Setup';
    ReplicateData = false;
    ObsoleteReason = 'Moved to Elster extension, new table Elec. VAT Decl. Setup.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Use Authentication"; Boolean)
        {
            Caption = 'Use Authentication';
        }
        field(5; "Use Proxy Server"; Boolean)
        {
            Caption = 'Use Proxy Server';
        }
        field(6; "Proxy Server Authent. Required"; Boolean)
        {
            Caption = 'Proxy Server Authent. Required';
        }
        field(7; "Proxy Server IP-Address/Port"; Code[250])
        {
            Caption = 'Proxy Server IP-Address/Port';
        }
        field(8; "HTTP Server URL 1"; Text[250])
        {
            Caption = 'HTTP Server URL 1';
            ExtendedDatatype = URL;
        }
        field(9; "HTTP Server URL 2"; Text[250])
        {
            Caption = 'HTTP Server URL 2';
            ExtendedDatatype = URL;
        }
        field(10; "HTTP Server URL 3"; Text[250])
        {
            Caption = 'HTTP Server URL 3';
            ExtendedDatatype = URL;
        }
        field(11; "HTTP Server URL 4"; Text[250])
        {
            Caption = 'HTTP Server URL 4';
            ExtendedDatatype = URL;
        }
        field(12; "Sales VAT Adv. Notif. Path"; Text[250])
        {
            Caption = 'Sales VAT Adv. Notif. Path';
            DataClassification = CustomerContent;
        }
        field(13; "XML File Default Name"; Text[250])
        {
            Caption = 'XML File Default Name';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

