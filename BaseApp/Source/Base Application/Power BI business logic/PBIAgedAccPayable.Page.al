page 6307 "PBI Aged Acc. Payable"
{
    Caption = 'PBI Aged Acc. Payable';
    Editable = false;
    PageType = List;
    SourceTable = "Power BI Chart Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control8)
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
                field("Period Type"; "Period Type")
                {
                    ApplicationArea = All;
                    Caption = 'Period Type';
                    ToolTip = 'Specifies the type.';
                }
                field(Date; Date)
                {
                    ApplicationArea = All;
                    Caption = 'Date';
                    ToolTip = 'Specifies the date.';
                }
                field("Date Sorting"; "Date Sorting")
                {
                    ApplicationArea = All;
                    Caption = 'Date Sorting';
                    ToolTip = 'Specifies the sorting.';
                }
                field("Period Type Sorting"; "Period Type Sorting")
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
        PBIAgedAccCalc: Codeunit "PBI Aged Acc. Calc";
        ChartManagement: Codeunit "Chart Management";
    begin
        PBIAgedAccCalc.GetValues(Rec, CODEUNIT::"Aged Acc. Payable", ChartManagement.AgedAccPayableName);
    end;
}

