report 17415 "Calculate Person Income"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Calculate Person Income';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Person; Person)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            dataitem(Employee; Employee)
            {
                DataItemLink = "Person No." = FIELD("No.");
                DataItemTableView = SORTING("No.");
                RequestFilterFields = "No.";

                trigger OnAfterGetRecord()
                begin
                    if "Employment Date" = 0D then
                        CurrReport.Skip;

                    PayrollPeriod.SetFilter(Code, '%1..', PayrollPeriod.PeriodByDate("Employment Date"));
                    if PayrollPeriod.FindSet then
                        repeat
                            PersonIncomeMgt.CreateIncomeHeader(PersonIncomeHeader, Person."No.", Date2DMY(PayrollPeriod."Ending Date", 3));
                            PersonIncomeMgt.CreateIncomeLine(PersonIncomeHeader, PayrollPeriod.Code);
                            PersonIncomeHeader.Recalculate;
                        until PayrollPeriod.Next = 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
            end;

            trigger OnPostDataItem()
            begin
                Window.Close;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open('#1####################');
            end;
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

    labels
    {
    }

    var
        PayrollPeriod: Record "Payroll Period";
        PersonIncomeHeader: Record "Person Income Header";
        PersonIncomeMgt: Codeunit "Person Income Management";
        Window: Dialog;
}

