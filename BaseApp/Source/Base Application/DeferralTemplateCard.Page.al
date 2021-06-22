page 1700 "Deferral Template Card"
{
    Caption = 'Deferral Template Card';
    SourceTable = "Deferral Template";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Deferral Code"; "Deferral Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a code for deferral template.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the record.';
                }
                field("Deferral Account"; "Deferral Account")
                {
                    ApplicationArea = Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the G/L account that the deferred expenses are posted to.';
                }
            }
            group("Deferral Schedule")
            {
                Caption = 'Deferral Schedule';
                field("Deferral %"; "Deferral %")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ShowMandatory = true;
                    ToolTip = 'Specifies how much of the total amount will be deferred.';
                }
                field("Calc. Method"; "Calc. Method")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how the Amount field for each period is calculated.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when to start calculating deferral amounts.';
                }
                field("No. of Periods"; "No. of Periods")
                {
                    ApplicationArea = Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies how many accounting periods the total amounts will be deferred to.';
                }
                field("Period Description"; "Period Description")
                {
                    ApplicationArea = Suite;
                    Caption = 'Period Desc.';
                    ToolTip = 'Specifies a description that will be shown on entries for the deferral posting.';
                }
            }
        }
    }

    actions
    {
    }
}

