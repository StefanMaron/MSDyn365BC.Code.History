// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

enum 9120 "Company Data Type (Internal)"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Evaluation Data")
    {
        Caption = 'Evaluation Data';
    }
    value(1; "Standard Data")
    {
        Caption = 'Standard Data';
    }
    value(2; "None")
    {
        Caption = 'None';
    }
    value(3; "Extended Data")
    {
        Caption = 'Extended Data';
    }
    value(4; "Full No Data")
    {
        Caption = 'Full No Data';
    }
}