page 6308 "PBI Aged Acc. Receivable"
{
    Caption = 'PBI Aged Acc. Receivable';
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
                    ToolTip = 'Specifies the date.';
                }
                field(Date; Date)
                {
                    ApplicationArea = All;
                    Caption = 'Date';
                    ToolTip = 'Specifies the sorting.';
                }
                field("Measure Name"; "Measure Name")
                {
                    ApplicationArea = All;
                    Caption = 'Measure Name';
                    ToolTip = 'Specifies the sorting.';
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
        PBIAgedAccCalc.GetValues(Rec, CODEUNIT::"Aged Acc. Receivable", ChartManagement.AgedAccReceivableName);
    end;
}

