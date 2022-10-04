page 6309 "PBI Aged Inventory Chart"
{
    Caption = 'PBI Aged Inventory Chart';
    Editable = false;
    PageType = List;
    SourceTable = "Power BI Chart Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(ID; ID)
                {
                    ApplicationArea = All;
                    Caption = 'ID';
                    ToolTip = 'Specifies the ID.';
                }
                field(Value; Value)
                {
                    ApplicationArea = All;
                    Caption = 'Value';
                    ToolTip = 'Specifies the value.';
                }
                field(Date; Date)
                {
                    ApplicationArea = All;
                    Caption = 'Date';
                    ToolTip = 'Specifies the date.';
                }
                field("Period Type"; Rec."Period Type")
                {
                    ApplicationArea = All;
                    Caption = 'Period Type';
                    ToolTip = 'Specifies the sorting.';
                }
                field("Period Type Sorting"; Rec."Period Type Sorting")
                {
                    ApplicationArea = All;
                    Caption = 'Period Type Sorting';
                    ToolTip = 'Specifies the sorting.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        PBIAgedInventoryCalc: Codeunit "PBI Aged Inventory Calc.";
    begin
        PBIAgedInventoryCalc.GetValues(Rec);
    end;
}

