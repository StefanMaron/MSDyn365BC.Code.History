page 17439 "Payroll Expression Stops"
{
    Caption = 'Payroll Expression Stops';
    PageType = List;
    SourceTable = "Payroll Calculation Stop";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Variable; Variable)
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        PayrollElementExpr.Reset;
                        PayrollElementExpr.SetRange("Element Code", "Element Code");
                        PayrollElementExpr.SetRange("Period Code", "Period Code");
                        PayrollElementExpr.SetFilter("Assign to Variable", '<>%1', '');

                        PayrollElementVariables.SetTableView(PayrollElementExpr);
                        PayrollElementVariables.LookupMode(true);
                        PayrollElementVariables.Editable(false);
                        if ACTION::LookupOK = PayrollElementVariables.RunModal then begin
                            PayrollElementVariables.GetRecord(PayrollElementExpr);
                            Variable := PayrollElementExpr."Assign to Variable";
                        end;
                        Clear(PayrollElementVariables);
                    end;
                }
                field(Comparison; Comparison)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Value; Value)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    var
        PayrollElementExpr: Record "Payroll Element Expression";
        PayrollElementVariables: Page "Payroll Element Variables";
}

