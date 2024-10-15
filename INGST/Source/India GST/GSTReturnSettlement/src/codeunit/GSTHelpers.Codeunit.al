codeunit 18317 "GST Helpers"
{
    procedure CheckGSTAccountingPeriod(PostingDate: Date)
    var
        TaxAccountingPeriod: Record "Tax Accounting Period";
        TaxAccountingPeriod2: Record "Tax Accounting Period";
        LastClosedDate: Date;
    begin
        LastClosedDate := GetLastClosedAccPeriod();
        TaxAccountingPeriod2.SetFilter("Starting Date", '<=%1', PostingDate);
        if TaxAccountingPeriod2.FindLast() then begin
            TaxAccountingPeriod2.SetFilter("Starting Date", '>=%1', PostingDate);
            if not TaxAccountingPeriod2.FindFirst() then
                Error(AccountingPeriodErr, PostingDate);

            if LastClosedDate <> 0D then
                if PostingDate < CalcDate('<1M>', LastClosedDate) then
                    Error(PeriodClosedErr,
                          CalcDate('<-1D>', CalcDate('<1M>', LastClosedDate)),
                          CalcDate('<1M>', LastClosedDate));

            TaxAccountingPeriod.Get(GetGSTAccountingType(), TaxAccountingPeriod2."Starting Date");
        end else
            Error(AccountingPeriodErr, PostingDate);

        TaxAccountingPeriod2.SetRange(Closed, false);
        TaxAccountingPeriod2.SetFilter("Starting Date", '<=%1', PostingDate);
        if TaxAccountingPeriod2.FindLast() then begin
            TaxAccountingPeriod2.SetFilter("Starting Date", '>=%1', PostingDate);
            if not TaxAccountingPeriod2.FindFirst() then
                if LastClosedDate <> 0D then
                    if PostingDate < CalcDate('<1M>', LastClosedDate) then
                        Error(PeriodClosedErr,
                              CalcDate('<-1D>', CalcDate('<1M>', LastClosedDate)),
                              CalcDate('<1M>', LastClosedDate));

            TaxAccountingPeriod2.TestField(Closed, false);
        end else
            if LastClosedDate <> 0D then
                if PostingDate < CalcDate('<1M>', LastClosedDate) then
                    Error(PeriodClosedErr, CalcDate('<-1D>', CalcDate('<1M>', LastClosedDate)),
                        CalcDate('<1M>', LastClosedDate));
    end;

    local procedure GetLastClosedAccPeriod(): Date
    var
        TaxAccountingPeriod: Record "Tax Accounting Period";
    begin
        TaxAccountingPeriod.SetRange("Tax Type Code", GetGSTAccountingType());
        TaxAccountingPeriod.SetRange(Closed, true);
        if TaxAccountingPeriod.FindLast() then
            exit(TaxAccountingPeriod."Starting Date");
    end;

    local procedure GetGSTAccountingType(): Code[20]
    var
        TaxType: Record "Tax Type";
        TaxTypeSetup: Record "Tax Type Setup";
    begin
        if not TaxTypeSetup.Get() then
            exit;
        TaxTypeSetup.TestField(Code);
        if TaxType.Get(TaxTypeSetup.Code) then
            exit(TaxType."Accounting Period");
    end;

    procedure GetGSTPayableAccountNo(StateCode: Code[10]; GSTComponentCode: Code[10]): Code[20]
    var
        GSTPostingSetup: Record "GST Posting Setup";
    begin
        GSTPostingSetup.Get(StateCode, GetComponentID(GSTComponentCode));
        GSTPostingSetup.TestField("Payable Account");
        exit(GSTPostingSetup."Payable Account");
    end;

    procedure GetGSTReceivableDistAccountNo(StateCode: Code[10]; GSTComponentCode: Code[10]): Code[20]
    var
        GSTPostingSetup: Record "GST Posting Setup";
    begin
        GSTPostingSetup.Get(StateCode, GetComponentID(GSTComponentCode));
        GSTPostingSetup.TestField("Receivable Acc. (Dist)");
        exit(GSTPostingSetup."Receivable Acc. (Dist)");
    end;

    procedure GetGSTReceivableAccountNo(StateCode: Code[10]; GSTComponentCode: Code[10]): Code[20]
    var
        GSTPostingSetup: Record "GST Posting Setup";
    begin
        GSTPostingSetup.Get(StateCode, GetComponentID(GSTComponentCode));
        GSTPostingSetup.TestField("Receivable Account");
        exit(GSTPostingSetup."Receivable Account");
    end;

    procedure GetGSTExpenseAccountNo(StateCode: Code[10]; GSTComponentCode: Code[10]): Code[20]
    var
        GSTPostingSetup: Record "GST Posting Setup";
    begin
        GSTPostingSetup.Get(StateCode, GetComponentID(GSTComponentCode));
        GSTPostingSetup.TestField("Expense Account");
        exit(GSTPostingSetup."Expense Account");
    end;

    procedure GetGSTMismatchAccountNo(StateCode: Code[10]; GSTComponentCode: Code[10]): Code[20]
    var
        GSTPostingSetup: Record "GST Posting Setup";
    begin
        GSTPostingSetup.Get(StateCode, GetComponentID(GSTComponentCode));
        GSTPostingSetup.TestField("GST Credit Mismatch Account");
        exit(GSTPostingSetup."GST Credit Mismatch Account");
    end;

    procedure GetGSTRcvblInterimAccountNo(StateCode: Code[10]; GSTComponentCode: Code[10]): Code[20]
    var
        GSTPostingSetup: Record "GST Posting Setup";
    begin
        GSTPostingSetup.Get(StateCode, GetComponentID(GSTComponentCode));
        GSTPostingSetup.TestField("Receivable Account (Interim)");
        exit(GSTPostingSetup."Receivable Account (Interim)");
    end;

    procedure GetGSTPayableInterimAccountNo(StateCode: Code[10]; GSTComponentCode: Code[10]): Code[20]
    var
        GSTPostingSetup: Record "GST Posting Setup";
    begin
        GSTPostingSetup.Get(StateCode, GetComponentID(GSTComponentCode));
        GSTPostingSetup.TestField("Payables Account (Interim)");
        exit(GSTPostingSetup."Payables Account (Interim)");
    end;

    local procedure GetComponentID(ComponentName: code[10]): decimal
    Var
        TaxTypeSetup: Record "Tax Type Setup";
        TaxComponent: Record "Tax Component";
    begin
        if not TaxTypeSetup.Get() then
            exit;
        TaxTypeSetup.TestField(Code);

        TaxComponent.Setrange("Tax Type", TaxTypeSetup.Code);
        TaxComponent.SetRange(Name, ComponentName);
        if TaxComponent.FindFirst() then
            exit(TaxComponent.ID);
    end;

    var
        AccountingPeriodErr: Label 'GST Accounting Period does not exist for the given Date %1.',
            Comment = '%1  = Posting Date';
        PeriodClosedErr: Label 'Accounting Period has been closed till %1, Document Posting Date must be greater than or equal to %2.',
            Comment = '%1 = Date, %2 = Posting Date';
}