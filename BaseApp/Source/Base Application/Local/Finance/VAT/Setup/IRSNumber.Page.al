#if not CLEAN24
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance;

page 10911 "IRS Number"
{
    ApplicationArea = Basic, Suite;
    Caption = 'IRS Number';
    PageType = List;
    SourceTable = "IRS Numbers";
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
                field("IRS Number"; Rec."IRS Number")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an Internal Revenue Service (IRS) tax number as defined by the Icelandic tax authorities.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a name for the Internal Revenue Service (IRS) tax number.';
                }
                field("Reverse Prefix"; Rec."Reverse Prefix")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the balance of the general ledger accounts with this IRS tax number must reverse the negative operator in IRS reports.';
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
            Page.Run(14601); // Page -  "IS IRS Numbers"
            Error('');
        end;
    end;
}
#endif
