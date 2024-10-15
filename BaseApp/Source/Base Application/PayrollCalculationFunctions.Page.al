page 17409 "Payroll Calculation Functions"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payroll Calculation Functions';
    Editable = false;
    PageType = List;
    SourceTable = "Payroll Calculation Function";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Function No."; "Function No.")
                {
                    Visible = false;
                }
                field("Range Type"; "Range Type")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Export)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export';
                    Ellipsis = true;
                    Image = Export;

                    trigger OnAction()
                    var
                        PayrollCalcFunction: Record "Payroll Calculation Function";
                        PayrollDataExchangeMgt: Codeunit "Payroll Data Exchange Mgt.";
                    begin
                        CurrPage.SetSelectionFilter(PayrollCalcFunction);
                        PayrollDataExchangeMgt.ExportPayrollCalcFunctions(PayrollCalcFunction);
                    end;
                }
            }
        }
    }
}

