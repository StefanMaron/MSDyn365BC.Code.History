﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 10536 "MTD-Missing Fraud Prev. Hdr"
{
    Caption = 'HMRC Missing Fraud Prevention Header';
    ObsoleteReason = 'Moved to extension Making Tax Digital';
    ObsoleteState = Pending;
    ObsoleteTag = '19.0';

    fields
    {
        field(1; Header; Code[100])
        {
            Caption = 'Header';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Header)
        {
            Clustered = true;
        }
    }
}
