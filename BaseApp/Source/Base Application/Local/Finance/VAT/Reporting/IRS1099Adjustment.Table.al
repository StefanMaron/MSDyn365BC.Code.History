#if not CLEANSCHEMA28 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Purchases.Vendor;

table 10016 "IRS 1099 Adjustment"
{
#if not CLEAN25
    DrillDownPageID = "IRS 1099 Adjustments";
    LookupPageID = "IRS 1099 Adjustments";
#endif
    DataClassification = CustomerContent;
    ObsoleteReason = 'Moved to IRS Forms App.';
#if not CLEAN25
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '28.0';
#endif

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            TableRelation = Vendor;
        }
        field(2; "IRS 1099 Code"; Code[10])
        {
            TableRelation = "IRS 1099 Form-Box";
        }
        field(3; Year; Integer)
        {
        }
        field(4; Amount; Decimal)
        {
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "IRS 1099 Code", Year)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
 
#endif
