report 17411 "Batch Post Payroll Documents"
{
    Caption = 'Batch Post Payroll Documents';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Payroll Document"; "Payroll Document")
        {
            RequestFilterFields = "No.", "Employee No.", "Posting Date";

            trigger OnAfterGetRecord()
            begin
                Counter := Counter + 1;
                Window.Update(1, "No.");
                Window.Update(2, Round(Counter / CounterTotal * 10000, 1));
                Clear(PayrollDocPost);
                if PayrollDocPost.Run("Payroll Document") then begin
                    CounterOK := CounterOK + 1;
                    if MarkedOnly then
                        Mark(false);
                end;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close;
                Message(Text002, CounterOK, CounterTotal);
            end;

            trigger OnPreDataItem()
            begin
                CounterTotal := Count;
                Window.Open(Text001);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

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
        Text001: Label 'Posting payroll documents  #1########## @2@@@@@@@@@@@@@';
        Text002: Label '%1 payroll documents out of a total of %2 have now been posted.';
        PayrollDocPost: Codeunit "Payroll Document - Post";
        Window: Dialog;
        CounterTotal: Integer;
        Counter: Integer;
        CounterOK: Integer;
}

