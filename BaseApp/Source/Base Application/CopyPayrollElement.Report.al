report 17407 "Copy Payroll Element"
{
    Caption = 'Copy Payroll Element';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number);
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            begin
                NewElementCode := PayrollElement2.Code;

                PayrollElement2.Init();
                PayrollElement2 := PayrollElement;
                PayrollElement2.Code := NewElementCode;
                PayrollElement2.Insert();

                PayrollBaseAmount.Reset();
                PayrollBaseAmount.SetRange("Element Code", PayrollElement.Code);
                if PayrollBaseAmount.FindSet then
                    repeat
                        PayrollBaseAmount2 := PayrollBaseAmount;
                        PayrollBaseAmount2."Element Code" := NewElementCode;
                        PayrollBaseAmount2.Insert();
                    until PayrollBaseAmount.Next = 0;

                RangeHeader.Reset();
                RangeHeader.SetRange("Element Code", PayrollElement.Code);
                if RangeHeader.FindSet then
                    repeat
                        RangeHeader2 := RangeHeader;
                        RangeHeader2."Element Code" := NewElementCode;
                        RangeHeader2.Insert();
                    until RangeHeader.Next = 0;

                RangeLine.Reset();
                RangeLine.SetRange("Element Code", PayrollElement.Code);
                if RangeLine.FindSet then
                    repeat
                        RangeLine2 := RangeLine;
                        RangeLine2."Element Code" := NewElementCode;
                        RangeLine2.Insert();
                    until RangeLine.Next = 0;

                PayrollCalculation.Reset();
                PayrollCalculation.SetRange("Element Code", PayrollElement.Code);
                if PayrollCalculation.FindSet then
                    repeat
                        PayrollCalculation2 := PayrollCalculation;
                        PayrollCalculation2."Element Code" := NewElementCode;
                        PayrollCalculation2.Insert();
                    until PayrollCalculation.Next = 0;

                PayrollCalcLine.Reset();
                PayrollCalcLine.SetRange("Element Code", PayrollElement.Code);
                if PayrollCalcLine.FindSet then
                    repeat
                        PayrollCalcLine2 := PayrollCalcLine;
                        PayrollCalcLine2."Element Code" := NewElementCode;
                        PayrollCalcLine2.Insert();
                    until PayrollCalcLine.Next = 0;

                PayrollExprLine.Reset();
                PayrollExprLine.SetRange("Element Code", PayrollElement.Code);
                if PayrollExprLine.FindSet then
                    repeat
                        PayrollExprLine2 := PayrollExprLine;
                        PayrollExprLine2."Element Code" := NewElementCode;
                        PayrollExprLine2.Insert();
                    until PayrollExprLine.Next = 0;
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
                    field(NewPayrollElementCode; PayrollElement2.Code)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Element';

                        trigger OnValidate()
                        begin
                            if PayrollElement2.Code = '' then
                                Error(Text14800);
                            if PayrollElement2.Get(PayrollElement2.Code) then
                                Error(Text14801, PayrollElement2.Code);
                        end;
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
        PayrollElement: Record "Payroll Element";
        PayrollElement2: Record "Payroll Element";
        RangeHeader: Record "Payroll Range Header";
        RangeHeader2: Record "Payroll Range Header";
        RangeLine: Record "Payroll Range Line";
        RangeLine2: Record "Payroll Range Line";
        PayrollCalculation: Record "Payroll Calculation";
        PayrollCalculation2: Record "Payroll Calculation";
        PayrollCalcLine: Record "Payroll Calculation Line";
        PayrollCalcLine2: Record "Payroll Calculation Line";
        PayrollBaseAmount: Record "Payroll Base Amount";
        PayrollBaseAmount2: Record "Payroll Base Amount";
        PayrollExprLine: Record "Payroll Element Expression";
        PayrollExprLine2: Record "Payroll Element Expression";
        Text14800: Label 'Please enter new Payroll Element Code';
        Text14801: Label 'Payroll Element %1 already exist.';
        NewElementCode: Code[20];

    [Scope('OnPrem')]
    procedure SetPayrollElement(NewManagementElement: Record "Payroll Element")
    begin
        PayrollElement := NewManagementElement;
    end;
}

