xmlport 17402 "Payroll Calc. Functions"
{
    Caption = 'Payroll Calc. Functions';

    schema
    {
        textelement(PayrollCalcFunctions)
        {
            tableelement("payroll calculation function"; "Payroll Calculation Function")
            {
                XmlName = 'PayrollCalcFunction';
                UseTemporary = true;
                fieldelement(Code; "Payroll Calculation Function".Code)
                {
                }
                fieldelement(Description; "Payroll Calculation Function".Description)
                {
                }
                fieldelement(FunctionNo; "Payroll Calculation Function"."Function No.")
                {
                }
                fieldelement(RangeType; "Payroll Calculation Function"."Range Type")
                {
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    var
        PayrollCalcFunction: Record "Payroll Calculation Function";

    [Scope('OnPrem')]
    procedure SetData(var SourcePayrollCalcFunction: Record "Payroll Calculation Function")
    begin
        if SourcePayrollCalcFunction.FindSet then
            repeat
                "Payroll Calculation Function" := SourcePayrollCalcFunction;
                "Payroll Calculation Function".Insert();
            until SourcePayrollCalcFunction.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ImportData()
    begin
        "Payroll Calculation Function".Reset();
        if "Payroll Calculation Function".FindSet then
            repeat
                if PayrollCalcFunction.Get("Payroll Calculation Function".Code) then
                    PayrollCalcFunction.Delete(true);
                PayrollCalcFunction := "Payroll Calculation Function";
                PayrollCalcFunction.Insert();
            until "Payroll Calculation Function".Next() = 0;
    end;
}

