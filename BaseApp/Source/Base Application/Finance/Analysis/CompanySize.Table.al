// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

table 532 "Company Size"
{
    LookupPageId = "Company Sizes";
    DrillDownPageId = "Company Sizes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Description; Text[100]) { }
        /// <summary>
        /// Indicates whether the company size category represents a small business.
        /// </summary>
        field(3; "Small Business"; Boolean)
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }
}
