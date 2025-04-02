// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

enum 1207 "Credit Transfer Account Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Customer") { Caption = 'Customer'; }
    value(1; "Vendor") { Caption = 'Vendor'; }
    value(2; "Employee") { Caption = 'Employee'; }
}
