#if not CLEAN23
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
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code.';
                }
                field("Gen. Posting Type"; "Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Shows the general posting type that is linked to the VAT code.';
                }
                field("Test Gen. Posting Type"; "Test Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to test the general posting type when posting.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description.';
                }
                field("Trade Settlement 2017 Box No."; "Trade Settlement 2017 Box No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reporting field that links the VAT code to the Box No. field in the Trade Settlement 2017 report.';
                }
                field("Reverse Charge Report Box No."; "Reverse Charge Report Box No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reporting field that links the VAT code to the Box No. field in the Trade Settlement 2017 report in case of reverse charge VAT.';
                }
                field("VAT Specification Code"; "VAT Specification Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification code';
                }
                field("VAT Note Code"; "VAT Note Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT note code.';
                }
                field("SAF-T VAT Code"; "SAF-T VAT Code")
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
