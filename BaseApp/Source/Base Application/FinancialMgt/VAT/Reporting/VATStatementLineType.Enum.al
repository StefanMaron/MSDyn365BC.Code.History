// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

enum 256 "VAT Statement Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Account Totaling")
    {
        Caption = 'Account Totaling';
    }
    value(1; "VAT Entry Totaling")
    {
        Caption = 'VAT Entry Totaling';
    }
    value(2; "Row Totaling")
    {
        Caption = 'Row Totaling';
    }
    value(3; Description)
    {
        Caption = 'Description';
    }
    value(4; "EC Entry Totaling") 
    { 
        Caption = 'EC Entry Totaling'; 
    }
}