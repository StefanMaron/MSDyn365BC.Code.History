// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN23
namespace Microsoft.Finance.VAT.Setup;

page 10602 "VAT Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Codes';
    PageType = List;
    SourceTable = "VAT Code";
    UsageCategory = Lists;
    ObsoleteReason = 'Use the page "VAT Reporting Codes" instead.';
    ObsoleteState = Pending;
    ObsoleteTag = '23.0';

    layout
    {
        area(content)
        {
            repeater(Control1080000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code.';
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Shows the general posting type that is linked to the VAT code.';
                }
                field("Test Gen. Posting Type"; Rec."Test Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to test the general posting type when posting.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description.';
                }
                field("Trade Settlement 2017 Box No."; Rec."Trade Settlement 2017 Box No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reporting field that links the VAT code to the Box No. field in the Trade Settlement 2017 report.';
                }
                field("Reverse Charge Report Box No."; Rec."Reverse Charge Report Box No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reporting field that links the VAT code to the Box No. field in the Trade Settlement 2017 report in case of reverse charge VAT.';
                }
                field("VAT Specification Code"; Rec."VAT Specification Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification code';
                }
                field("VAT Note Code"; Rec."VAT Note Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT note code.';
                }
                field("SAF-T VAT Code"; Rec."SAF-T VAT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SAF-T VAT code.';
                }
            }
        }
    }

    actions
    {
    }
}
#endif
