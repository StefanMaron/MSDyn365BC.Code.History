﻿namespace Microsoft.FixedAssets.Journal;

enum 5603 "Gen. Journal Line FA Posting Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; "Acquisition Cost")
    {
        Caption = 'Acquisition Cost';
    }
    value(2; Depreciation)
    {
        Caption = 'Depreciation';
    }
    value(3; "Write-Down")
    {
        Caption = 'Write-Down';
    }
    value(4; Appreciation)
    {
        Caption = 'Appreciation';
    }
    value(5; "Custom 1")
    {
        Caption = 'Custom 1';
    }
    value(6; "Custom 2")
    {
        Caption = 'Custom 2';
    }
    value(7; Disposal)
    {
        Caption = 'Disposal';
    }
    value(8; Maintenance)
    {
        Caption = 'Maintenance';
    }
}
