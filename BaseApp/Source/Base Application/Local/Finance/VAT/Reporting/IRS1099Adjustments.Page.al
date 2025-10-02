#if not CLEAN25
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 10018 "IRS 1099 Adjustments"
{
    DelayedInsert = true;
    PageType = List;
    SourceTable = "IRS 1099 Adjustment";
    ObsoleteReason = 'Moved to IRS Forms App.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor account.';
                }
                field(Year; Rec.Year)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax year for the 1099 forms.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the adjustment amount.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        IRS1099Management: Codeunit "IRS 1099 Management";
    begin
        IRS1099Management.ThrowUseNewIRSFormsFeatureError();
    end;
}
#endif
