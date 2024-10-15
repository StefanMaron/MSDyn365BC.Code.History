#if not CLEAN22
page 13400 "Intrastat - File Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Transfer File';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Intrastat - File Setup";
    UsageCategory = Tasks;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Custom Code"; Rec."Custom Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a custom code for the Intrastat file setup information.';
                }
                field("Company Serial No."; Rec."Company Serial No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a company serial number for the Intrastat file setup information.';
                }
                field("Last Transfer Date"; Rec."Last Transfer Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a last transfer date for the Intrastat file setup information.';
                }
                field("File No."; Rec."File No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a file number for the Intrastat file setup information.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
#endif