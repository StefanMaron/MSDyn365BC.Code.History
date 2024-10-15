// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Pricing;

enum 7008 "Job Price Source Type"
{
    Extensible = true;
    value(30; "All Jobs")
    {
        Caption = 'All Jobs';
    }
    value(31; Job)
    {
        Caption = 'Job';
    }
    value(32; "Job Task")
    {
        Caption = 'Job Task';
    }
}