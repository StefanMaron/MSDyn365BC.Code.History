codeunit 32 "Customer Card Calculations"
{
    trigger OnRun()
    var
        Customer: record Customer;
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        CustomerMgt: Codeunit "Customer Mgt.";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        CustomerNo: Code[20];
    begin
        Params := Page.GetBackgroundParameters();
        CustomerNo := CopyStr(Params.Get(GetCustomerNoLabel()), 1, MaxStrLen(CustomerNo));
        if not Customer.Get(CustomerNo) then
            exit;

        Results.Add(GetAvgDaysPastDueDateLabel(), Format(AgedAccReceivable.InvoicePaymentDaysAverage(Customer."No.")));
        Results.Add(GetExpectedMoneyOwedLabel(), Format(CustomerMgt.CalculateAmountsWithVATOnUnpostedDocuments(Customer."No.")));
        Results.Add(GetAvgDaysToPayLabel(), Format(CustomerMgt.AvgDaysToPay(Customer."No.")));
        Page.SetBackgroundTaskResult(Results);
    end;

    var
        ExpectedMoneyOwedLbl: label 'Expected Money Owed', Locked = true;
        AvgDaysPastDueDateLbl: label 'Avg. Days Past Due', Locked = true;
        AvgDaysToPayLbl: label 'Avg. Days to pay', Locked = true;
        CustomerNoLbl: label 'Customer No.', Locked = true;

    internal procedure GetExpectedMoneyOwedLabel(): Text
    begin
        exit(ExpectedMoneyOwedLbl);
    end;

    internal procedure GetAvgDaysPastDueDateLabel(): Text
    begin
        exit(AvgDaysPastDueDateLbl);
    end;

    internal procedure GetAvgDaysToPayLabel(): Text
    begin
        exit(AvgDaysToPayLbl);
    end;

    internal procedure GetCustomerNoLabel(): Text
    begin
        exit(CustomerNoLbl);
    end;


}