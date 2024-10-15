page 11798 "User Setup Lines"
{
    AutoSplitKey = true;
    Caption = 'User Setup Lines';
    DataCaptionFields = "User ID";
    PageType = Worksheet;
    SourceTable = "User Setup Line";

    layout
    {
        area(content)
        {
            field("UserSetupLine.Type"; UserSetupLine.Type)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Enabled Code / Journal';
                OptionCaption = 'Location (quantity increase),Location (quantity decrease),Bank Account,General Journal,Item Journal,BOM Journal,Resource Journal,Job Journal,Intrastat Journal,FA Journal,Insurance Journal,FA Reclass. Journal,Req. Worksheet,VAT Statement,Purchase Adv. Payments,Sales Adv. Payments,Whse. Journal,Whse. Worksheet,Payment Order,Bank Statement,Whse. Net Change Templates,Release Location (quantity increase),Release Location (quantity decrease),Tool Template';
                ToolTip = 'Specifies selecting an area, for which will be setuped the user''s filters.';

                trigger OnValidate()
                begin
                    SetLinesFilter;
                    UserCheckLineTypeOnAfterVal;
                end;
            }
            repeater(Control1220001)
            {
                ShowCaption = false;
                field("Code / Name"; "Code / Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code/name for related row type.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&List")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&List';
                Image = List;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Open the page for user setup lines.';

                trigger OnAction()
                var
                    UserSetupLine: Record "User Setup Line";
                begin
                    UserSetupLine.SetRange("User ID", GetRangeMin("User ID"));
                    PAGE.Run(PAGE::"User Setup Lines List", UserSetupLine);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        UserSetupLine.Init;
        SetLinesFilter;
    end;

    var
        UserSetupLine: Record "User Setup Line";

    [Scope('OnPrem')]
    procedure SetLinesFilter()
    begin
        FilterGroup(2);
        SetRange(Type, UserSetupLine.Type);
        FilterGroup(0);
    end;

    local procedure UserCheckLineTypeOnAfterVal()
    begin
        CurrPage.Update;
    end;
}

