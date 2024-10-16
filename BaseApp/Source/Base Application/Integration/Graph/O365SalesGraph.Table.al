// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

table 2190 "O365 Sales Graph"
{
    Caption = 'O365 Sales Graph';
    ReplicateData = false;
    TableType = MicrosoftGraph;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Component; Text[60])
        {
            Caption = 'Component';
            ExternalName = 'component';
            ExternalType = 'Edm.String';
        }
        field(2; Type; Text[60])
        {
            Caption = 'Type';
            ExternalName = 'type';
            ExternalType = 'Edm.String';
        }
        field(3; "Schema"; Text[60])
        {
            Caption = 'Schema';
            ExternalName = 'schema';
            ExternalType = 'Edm.String';
        }
        field(4; Details; BLOB)
        {
            Caption = 'Details';
            ExternalName = 'details';
            ExternalType = 'Edm.Json';
            SubType = Json;
        }
        field(5; InvoiceId; Text[60])
        {
            Caption = 'InvoiceId';
            ExternalName = 'invoiceId';
            ExternalType = 'Edm.String';
        }
        field(6; EmployeeId; Text[250])
        {
            Caption = 'EmployeeId';
            ExternalName = 'employeeId';
            ExternalType = 'Edm.String';
        }
        field(7; ContactId; Text[250])
        {
            Caption = 'ContactId';
            ExternalName = 'customerId';
            ExternalType = 'Edm.String';
        }
        field(8; ActivityDate; Text[60])
        {
            Caption = 'ActivityDate';
            ExternalName = 'activityDate';
            ExternalType = 'Edm.String';
        }
        field(9; Kind; Text[60])
        {
            Caption = 'Kind';
            ExternalName = 'kind';
            ExternalType = 'Edm.String';
        }
        field(10; EstimateId; Text[60])
        {
            Caption = 'EstimateId';
            ExternalName = 'EstimateId';
            ExternalType = 'Edm.String';
        }
    }

    keys
    {
        key(Key1; Component)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

