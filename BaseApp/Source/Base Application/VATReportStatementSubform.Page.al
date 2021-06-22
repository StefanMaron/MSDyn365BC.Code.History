page 742 "VAT Report Statement Subform"
{
    Caption = 'VAT Report Statement Subform';
    Editable = false;
    PageType = ListPart;
    ShowFilter = false;
    SourceTable = "VAT Statement Report Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Row No."; "Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT report statement.';
                }
                field("Box No."; "Box No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number on the box that the VAT statement applies to.';
                }
                field(Base; Base)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the VAT amount in the amount is calculated from.';
                    Visible = false;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the entry in the report statement.';
                }
            }
        }
    }

    actions
    {
    }

    procedure SelectFirst()
    begin
        if Count > 0 then
            FindFirst;
    end;
}

