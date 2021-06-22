page 6311 "PBI Job Profitability"
{
    Caption = 'PBI Job Profitability';
    Editable = false;
    PageType = List;
    SourceTable = "Power BI Chart Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Measure No."; "Measure No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job No.';
                    ToolTip = 'Specifies the job.';
                }
                field("Measure Name"; "Measure Name")
                {
                    ApplicationArea = All;
                    Caption = 'Measure Name';
                    ToolTip = 'Specifies the name.';
                }
                field(Value; Value)
                {
                    ApplicationArea = All;
                    Caption = 'Value';
                    ToolTip = 'Specifies the value.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        PBIJobChartCalc: Codeunit "PBI Job Chart Calc.";
        JobChartType: Option Profitability,"Actual to Budget Cost","Actual to Budget Price";
    begin
        PBIJobChartCalc.GetValues(Rec, JobChartType::Profitability);
    end;
}

