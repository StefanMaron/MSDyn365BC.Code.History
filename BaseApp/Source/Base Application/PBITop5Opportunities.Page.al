page 6315 "PBI Top 5 Opportunities"
{
    Caption = 'PBI Top 5 Opportunities';
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
                field(ID; ID)
                {
                    ApplicationArea = All;
                    Caption = 'ID';
                    ToolTip = 'Specifies the ID.';
                }
                field("Measure No."; "Measure No.")
                {
                    ApplicationArea = All;
                    Caption = 'Opportunity No.';
                    ToolTip = 'Specifies the opportunity.';
                }
                field(Value; Value)
                {
                    ApplicationArea = All;
                    Caption = 'Value';
                    ToolTip = 'Specifies the value.';
                }
                field("Measure Name"; "Measure Name")
                {
                    ApplicationArea = All;
                    Caption = 'Measure Name';
                    ToolTip = 'Specifies the name.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        PBITopOpportunitiesCalc: Codeunit "PBI Top Opportunities Calc.";
    begin
        PBITopOpportunitiesCalc.GetValues(Rec);
    end;
}

