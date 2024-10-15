// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

enum 13 "VAT Statement Report Period Selection"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Before and Within Period") { Caption = 'Before and Within Period'; }
    value(1; "Within Period") { Caption = 'Within Period'; }
}
