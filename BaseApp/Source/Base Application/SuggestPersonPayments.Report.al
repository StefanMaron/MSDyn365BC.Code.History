report 17455 "Suggest Person Payments"
{
    Caption = 'Suggest Person Payments';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Person; Person)
        {
            DataItemTableView = WHERE("Vendor No." = FILTER(<> ''));
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            var
                PayrollDocCalc: Codeunit "Payroll Document - Calculate";
            begin
                TestField("Vendor No.");
                Vendor.Get("Vendor No.");

                Employee.SetRange("Person No.", "No.");
                if OrgUnitCodeFilter <> '' then
                    Employee.SetRange("Org. Unit Code", OrgUnitCodeFilter);
                if Employee.FindSet then
                    repeat
                        PostedPayrollDoc.Reset;
                        PostedPayrollDoc.SetCurrentKey("Employee No.");
                        PostedPayrollDoc.SetRange("Employee No.", Employee."No.");
                        PostedPayrollDoc.SetRange("Posting Date", StartingDate, EndingDate);
                        if PostedPayrollDoc.FindSet then
                            repeat
                                PayrollCalcGroup.Get(PostedPayrollDoc."Calc Group Code");
                                if PaymentsBetweenPeriod and (PayrollCalcGroup.Type = PayrollCalcGroup.Type::Between) or
                                   not PaymentsBetweenPeriod and (PayrollCalcGroup.Type = PayrollCalcGroup.Type::" ")
                                then begin
                                    Vendor.SetRange("Date Filter", 0D, PostedPayrollDoc."Posting Date");
                                    Vendor.CalcFields("Net Change (LCY)");
                                    AmountAvailable := Vendor."Net Change (LCY)";
                                    PaymentAmount := PostedPayrollDoc.CalcPayrollAmount;

                                    if not PaymentsBetweenPeriod then
                                        if AmountAvailable < 0 then
                                            PaymentAmount := 0
                                        else
                                            if PaymentAmount > AmountAvailable then
                                                PaymentAmount := AmountAvailable;

                                    PaymentAmount := PayrollDocCalc.RoundAmountToPay(PaymentAmount);

                                    if PaymentAmount <> 0 then
                                        CreateJnlLine;
                                end;
                            until PostedPayrollDoc.Next = 0;
                    until Employee.Next = 0;
            end;

            trigger OnPreDataItem()
            begin
                GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
                if GenJnlLine.FindLast then begin
                    LineNo := GenJnlLine."Line No.";
                    GenJnlLine.Init;
                end;
                LineNo := LineNo + 10000;

                GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                NextDocNo := NoSeriesMgt.GetNextNo(GenJnlBatch."No. Series", PostingDate, false);
                Clear(NoSeriesMgt);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date of the entries that you want to include in the report or batch job.';
                    }
                    field(OrgUnitCodeFilter; OrgUnitCodeFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Org. Unit Code Filter';
                        TableRelation = "Organizational Unit";
                    }
                    field(BankAccountCode; BankAccountCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account No.';
                        TableRelation = "Bank Account";
                        ToolTip = 'Specifies the number used by the bank for the bank account.';
                    }
                    field(PaymentsBetweenPeriod; PaymentsBetweenPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payments Between Period';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
            GenJnlBatch.TestField("No. Series");
            StartingDate := CalcDate('<-CM>', WorkDate);
            EndingDate := CalcDate('<CM>', StartingDate);
            PostingDate := EndingDate;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if BankAccountCode = '' then
            Error(Text001);

        BankAccount.Get(BankAccountCode);
        case BankAccount."Account Type" of
            BankAccount."Account Type"::"Bank Account":
                BankAccount.TestField("Bank Payment Order No. Series");
            BankAccount."Account Type"::"Cash Account":
                BankAccount.TestField("Credit Cash Order No. Series");
        end;

        HRSetup.Get;
    end;

    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        Employee: Record Employee;
        HRSetup: Record "Human Resources Setup";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendorAgreement: Record "Vendor Agreement";
        LaborContract: Record "Labor Contract";
        PayrollCalcGroup: Record "Payroll Calc Group";
        PostedPayrollDoc: Record "Posted Payroll Document";
        PostedPayrollDocLine: Record "Posted Payroll Document Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        StartingDate: Date;
        EndingDate: Date;
        PostingDate: Date;
        LineNo: Integer;
        OrgUnitCodeFilter: Code[1024];
        BankAccountCode: Code[20];
        Text001: Label 'Please enter Bank Account Code.';
        NextDocNo: Code[20];
        AmountAvailable: Decimal;
        PaymentAmount: Decimal;
        PaymentsBetweenPeriod: Boolean;

    [Scope('OnPrem')]
    procedure SetGenJnlLine(NewGenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine := NewGenJnlLine;
    end;

    [Scope('OnPrem')]
    procedure SetParameters(NewGenJnlLine: Record "Gen. Journal Line"; NewStartingDate: Date; NewEndingDate: Date; NewPostingDate: Date; NewBankAccountCode: Code[20]; NewPaymentsBetweenPeriod: Boolean)
    begin
        GenJnlLine := NewGenJnlLine;
        StartingDate := NewStartingDate;
        EndingDate := NewEndingDate;
        PostingDate := NewPostingDate;
        BankAccountCode := NewBankAccountCode;
        PaymentsBetweenPeriod := NewPaymentsBetweenPeriod;
    end;

    [Scope('OnPrem')]
    procedure CreateJnlLine()
    begin
        GenJnlLine.Init;

        GenJnlLine."Line No." := LineNo;
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine."Document No." := NextDocNo;
        NextDocNo := IncStr(NextDocNo);
        GenJnlLine.Validate("Account No.", Person."Vendor No.");
        if LaborContract.Get(Employee."Contract No.") then
            if LaborContract."Vendor Agreement No." <> '' then begin
                VendorAgreement.Get(LaborContract."Vendor No.", LaborContract."Vendor Agreement No.");
                VendorAgreement.Validate("Vendor Posting Group");
                GenJnlLine.Validate("Agreement No.", VendorAgreement."No.");
                GenJnlLine.Validate("Posting Group", VendorAgreement."Vendor Posting Group");
            end;
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
        GenJnlLine.Validate("Bal. Account No.", BankAccountCode);
        GenJnlLine.Validate(Amount, PaymentAmount);
        case BankAccount."Account Type" of
            BankAccount."Account Type"::"Bank Account":
                GenJnlLine."Posting No. Series" := BankAccount."Bank Payment Order No. Series";
            BankAccount."Account Type"::"Cash Account":
                GenJnlLine."Posting No. Series" := BankAccount."Credit Cash Order No. Series";
        end;
        GenJnlLine."Bank Payment Type" := GenJnlLine."Bank Payment Type"::"Computer Check";
        GenJnlLine."Applies-to ID" := '';
        GenJnlLine."Applies-to Doc. Date" := 0D;
        GenJnlLine.Insert;
        LineNo := LineNo + 10000;
    end;
}

