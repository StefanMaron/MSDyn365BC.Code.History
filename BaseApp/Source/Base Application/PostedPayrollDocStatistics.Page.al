page 17399 "Posted Payroll Doc. Statistics"
{
    Caption = 'Posted Payroll Doc. Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SourceTable = "Posted Payroll Document";

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
        TempPayrollDocLine: Record "Payroll Document Line" temporary;
        PayrollDocBuffer: Record "Payroll Document Buffer" temporary;
        PayrollDocCalc: Codeunit "Payroll Document - Calculate";
    begin
        ClearAll;

        Employee.Get("Employee No.");
        Person.Get(Employee."Person No.");

        PayrollAmount := CalcPayrollAmount;
        AmountToPay := PayrollDocCalc.RoundAmountToPay(PayrollAmount);

        PostedPayrollDocLine.Reset();
        PostedPayrollDocLine.SetRange("Document No.", "No.");
        if PostedPayrollDocLine.FindSet then
            repeat
                TempPayrollDocLine.TransferFields(PostedPayrollDocLine);
                TempPayrollDocLine.Insert();
            until PostedPayrollDocLine.Next = 0;

        PayrollDocPost.AggregateTaxes(TempPayrollDocLine);
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
        PostedPayrollDocLine: Record "Posted Payroll Document Line";
        PayrollDocPost: Codeunit "Payroll Document - Post";
        PayrollAmount: Decimal;
        AmountToPay: Decimal;
}

