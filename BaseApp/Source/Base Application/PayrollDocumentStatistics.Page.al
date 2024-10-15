page 17358 "Payroll Document Statistics"
{
    Caption = 'Payroll Document Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SourceTable = "Payroll Document";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(PayrollAmount; PayrollAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Amount';
                    Editable = false;
                }
                field(AmountToPay; AmountToPay)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount to Pay';
                    Editable = false;
                }
            }
            part(Subform; "Payroll Document Stat. Subform")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        PayrollDocBuffer: Record "Payroll Document Buffer" temporary;
        PayrollDocCalc: Codeunit "Payroll Document - Calculate";
    begin
        ClearAll;

        Employee.Get("Employee No.");
        Person.Get(Employee."Person No.");

        PayrollAmount := CalcPayrollAmount;
        AmountToPay := PayrollDocCalc.RoundAmountToPay(PayrollAmount);

        PayrollDocLine.Reset();
        PayrollDocLine.SetRange("Document No.", "No.");
        PayrollDocPost.AggregateTaxes(PayrollDocLine);
        PayrollDocPost.GetPayrollDocBuffer(PayrollDocBuffer);

        CurrPage.Subform.PAGE.SetPayrollDocBuffer(PayrollDocBuffer);
    end;

    trigger OnOpenPage()
    begin
        HRSetup.Get();
    end;

    var
        Employee: Record Employee;
        HRSetup: Record "Human Resources Setup";
        Person: Record Person;
        PayrollDocLine: Record "Payroll Document Line";
        PayrollDocPost: Codeunit "Payroll Document - Post";
        PayrollAmount: Decimal;
        AmountToPay: Decimal;
}

