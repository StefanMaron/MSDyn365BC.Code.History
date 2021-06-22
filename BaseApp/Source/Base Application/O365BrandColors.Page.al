page 2158 "O365 Brand Colors"
{
    Caption = 'Email Color Schemas';
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "O365 Brand Color";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the name.';
                }
                field("Sample Picture"; "Sample Picture")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CheckCreateDefaultBrandColors;
    end;

    local procedure CheckCreateDefaultBrandColors()
    var
        O365BrandColor: Record "O365 Brand Color";
    begin
        if O365BrandColor.IsEmpty then
            O365BrandColor.CreateDefaultBrandColors;
    end;
}

