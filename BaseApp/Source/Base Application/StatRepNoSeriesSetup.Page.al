#if not CLEAN17
page 31075 "Stat. Rep. No. Series Setup"
{
    Caption = 'Stat. Rep. No. Series Setup (Obsolete)';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SourceTable = "Stat. Reporting Setup";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.4';

    layout
    {
        area(content)
        {
            group(Numbering)
            {
                Caption = 'Numbering';
                InstructionalText = 'To fill the Document No. field automatically, you must set up a number series.';
                field("VIES Declaration Nos."; "VIES Declaration Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to VIES declaration.';
                    Visible = VIESDeclarationNosVisible;
                }
                field("VAT Control Report Nos."; "VAT Control Report Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies number series of VAT control report.';
                    Visible = VATControlReportNosVisible;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Setup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Stat. Reporting Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Stat. Reporting Setup";
                ToolTip = 'Specifies statutory reporting setup page';
            }
        }
    }

    var
        VIESDeclarationNosVisible: Boolean;
        ReverseChargeNosVisible: Boolean;
        VATControlReportNosVisible: Boolean;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure SetFieldsVisibility(DocType: Option "VIES Declaration","Reverse Charge","VAT Control Report")
    begin
        VIESDeclarationNosVisible := DocType = DocType::"VIES Declaration";
        ReverseChargeNosVisible := DocType = DocType::"Reverse Charge";
        VATControlReportNosVisible := DocType = DocType::"VAT Control Report";
    end;
}
#endif