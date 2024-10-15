// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

enum 9122 "Company Data Type (Sandbox)"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Evaluation - Sample Data")
    {
        Caption = 'Evaluation - Sample Data';
    }
    value(1; "Production - Setup Data Only")
    {
        Caption = 'Production - Setup Data Only';
    }
    value(3; "Advanced Evaluation - Complete Sample Data")
    {
        Caption = 'Advanced Evaluation - Complete Sample Data';
    }
    value(4; "Create New - No Data")
    {
        Caption = 'Create New - No Data';
    }
}