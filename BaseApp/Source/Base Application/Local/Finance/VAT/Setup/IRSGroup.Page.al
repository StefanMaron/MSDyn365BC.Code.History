#if not CLEAN24
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance;

page 10901 "IRS Group"
{
    ApplicationArea = Basic, Suite;
    Caption = 'IRS Group';
    PageType = List;
    SourceTable = "IRS Groups";
    UsageCategory = Administration;
    ObsoleteReason = 'Moved to IS Core App.';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number for this group of Internal Revenue Service (IRS) tax numbers.';
                }
                field(Class; Rec.Class)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Class';
                    ToolTip = 'Specifies a class of Internal Revenue Service (IRS) tax numbers.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        ISCoreAppSetup: Record "IS Core App Setup";
    begin
        if ISCoreAppSetup.IsEnabled() then begin
            Page.RunModal(14600); // Page -  "IS IRS Groups"
            Error('');
        end;
    end;
}
#endif
