report 17408 "Copy Payroll Calculation"
{
    Caption = 'Copy Payroll Calculation';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number);
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            begin
                PayrollCalcLine.Reset();
                PayrollCalcLine.SetRange("Element Code", FromElementCode);
                PayrollCalcLine.SetRange("Period Code", FromPeriodCode);
                if PayrollCalcLine.FindSet then
                    repeat
                        PayrollCalcLine2.Init();
                        PayrollCalcLine2 := PayrollCalcLine;
                        PayrollCalcLine2."Element Code" := PayrollCalculation."Element Code";
                        PayrollCalcLine2."Period Code" := PayrollCalculation."Period Code";
                        PayrollCalcLine2.Insert();
                    until PayrollCalcLine.Next = 0;

                PayrollElementExpr.Reset();
                PayrollElementExpr.SetRange("Element Code", FromElementCode);
                PayrollElementExpr.SetRange("Period Code", FromPeriodCode);
                if PayrollElementExpr.FindSet then
                    repeat
                        PayrollElementExpr2.Init();
                        PayrollElementExpr2 := PayrollElementExpr;
                        PayrollElementExpr2."Element Code" := PayrollCalculation."Element Code";
                        PayrollElementExpr2."Period Code" := PayrollCalculation."Period Code";
                        PayrollElementExpr2.Insert();
                    until PayrollElementExpr.Next = 0;

                PayrollElementVar.Reset();
                PayrollElementVar.SetRange("Element Code", FromElementCode);
                PayrollElementVar.SetRange("Period Code", FromPeriodCode);
                if PayrollElementVar.FindFirst then
                    repeat
                        PayrollElementVar2.Init();
                        PayrollElementVar2 := PayrollElementVar;
                        PayrollElementVar2."Element Code" := PayrollCalculation."Element Code";
                        PayrollElementVar2."Period Code" := PayrollCalculation."Period Code";
                        PayrollElementVar2.Insert();
                    until PayrollElementExpr.Next = 0;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(FromElementCode; FromElementCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From Payroll Element';
                        TableRelation = "Payroll Element";
                    }
                    field(FromPeriodCode; FromPeriodCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From Payroll Period';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        PayrollCalculation: Record "Payroll Calculation";
        PayrollCalcLine: Record "Payroll Calculation Line";
        PayrollCalcLine2: Record "Payroll Calculation Line";
        PayrollElementExpr: Record "Payroll Element Expression";
        PayrollElementExpr2: Record "Payroll Element Expression";
        PayrollElementVar: Record "Payroll Element Variable";
        PayrollElementVar2: Record "Payroll Element Variable";
        FromElementCode: Code[20];
        FromPeriodCode: Code[10];

    [Scope('OnPrem')]
    procedure SetCalculation(NewPayrollCalculation: Record "Payroll Calculation")
    begin
        PayrollCalculation := NewPayrollCalculation;
    end;
}

