page 11000016 "Import Protocol List"
{
    Caption = 'Import Protocol List';
    Editable = false;
    PageType = List;
    SourceTable = "Import Protocol";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an import protocol code that you want attached to the entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of what the import protocol stands for.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Modify)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Modify';
                Image = EditFilter;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Change the setup of the selected import protocol.';

                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"Import Protocols", Rec);
                    CurrPage.Update();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Find('-') then begin
            PAGE.RunModal(PAGE::"Import Protocols", Rec);
            if not Find('-') then
                CurrPage.Close;
        end;
    end;
}

