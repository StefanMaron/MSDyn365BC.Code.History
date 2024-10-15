page 13400 "Intrastat - File Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Transfer File';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Intrastat - File Setup";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Custom Code"; "Custom Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a custom code for the Intrastat file setup information.';
                }
                field("Company Serial No."; "Company Serial No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a company serial number for the Intrastat file setup information.';
                }
                field("Last Transfer Date"; "Last Transfer Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a last transfer date for the Intrastat file setup information.';
                }
                field("File No."; "File No.")
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
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}

