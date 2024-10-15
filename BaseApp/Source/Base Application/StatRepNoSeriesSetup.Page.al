page 31075 "Stat. Rep. No. Series Setup"
{
    Caption = 'Stat. Rep. No. Series Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SourceTable = "Stat. Reporting Setup";

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
                field("Reverse Charge Nos."; "Reverse Charge Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies number series of reverse charge report.';
                    Visible = ReverseChargeNosVisible;
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

    [Scope('OnPrem')]
    procedure SetFieldsVisibility(DocType: Option "VIES Declaration","Reverse Charge")
    begin
        VIESDeclarationNosVisible := (DocType = DocType::"VIES Declaration");
        ReverseChargeNosVisible := (DocType = DocType::"Reverse Charge");
    end;
}

