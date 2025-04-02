// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN24
pageextension 10030 "No. Series Lines NA" extends "No. Series Lines"
{
    ObsoleteReason = 'These fields are no longer used.';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';

    layout
    {
        addafter(Open)
        {
            field(Series; Rec.Series)
            {
                ApplicationArea = BasicMX;
                ToolTip = 'Specifies the series of control numbers that are assigned by the tax authorities (SAT).';
                ObsoleteReason = 'These fields are no longer used.';
                ObsoleteState = Pending;
                ObsoleteTag = '24.0';
            }
            field("Authorization Code"; Rec."Authorization Code")
            {
                ApplicationArea = BasicMX;
                ToolTip = 'Specifies the code assigned by the tax authorities for series and folio numbers.';
                ObsoleteReason = 'These fields are no longer used.';
                ObsoleteState = Pending;
                ObsoleteTag = '24.0';
            }
            field("Authorization Year"; Rec."Authorization Year")
            {
                ApplicationArea = BasicMX;
                ToolTip = 'Specifies the year assigned by the tax authorities for series and folio numbers.';
                ObsoleteReason = 'These fields are no longer used.';
                ObsoleteState = Pending;
                ObsoleteTag = '24.0';
            }
        }
    }
}
#endif
