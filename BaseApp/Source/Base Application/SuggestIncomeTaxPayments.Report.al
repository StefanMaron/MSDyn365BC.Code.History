report 17459 "Suggest Income Tax Payments"
{
    Caption = 'Suggest Income Tax Payments';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Employee; Employee)
        {
            DataItemTableView = WHERE("Person No." = FILTER(<> ''));
            RequestFilterFields = "No.", "Org. Unit Code", "Job Title Code";

            trigger OnAfterGetRecord()
            begin
                PostedPayrollDoc.Reset;
                PostedPayrollDoc.SetCurrentKey("Employee No.");
                PostedPayrollDoc.SetRange("Employee No.", Employee."No.");
                PostedPayrollDoc.SetRange("Posting Date", StartingDate, EndingDate);
                if PostedPayrollDoc.FindSet then
                    repeat
                        if PostedPayrollDoc."Calc Group Code" <> '' then begin
                            PostedPayrollDocLine.Reset;
                            PostedPayrollDocLine.SetCurrentKey("Document No.", "Element Type");
                            PostedPayrollDocLine.SetRange("Document No.", PostedPayrollDoc."No.");
                            PostedPayrollDocLine.SetRange("Element Type", PostedPayrollDocLine."Element Type"::"Income Tax");
                            if PostedPayrollDocLine.FindSet then
                                repeat
                                    if PostedPayrollDocLine."Payroll Amount" <> 0 then
                                        if TempPayrollAEBuffer.Get(PostedPayrollDocLine."Period Code", PostedPayrollDocLine."Element Code") then begin
                                            TempPayrollAEBuffer.Amount += PostedPayrollDocLine."Payroll Amount";
                                            TempPayrollAEBuffer.Modify;
                                        end else begin
                                            TempPayrollAEBuffer.Init;
                                            TempPayrollAEBuffer."Period Code" := PostedPayrollDocLine."Period Code";
                                            TempPayrollAEBuffer."Element Code" := PostedPayrollDocLine."Element Code";
                                            TempPayrollAEBuffer.Amount := PostedPayrollDocLine."Payroll Amount";
                                            TempPayrollAEBuffer.Insert;
                                        end;
                                until PostedPayrollDocLine.Next = 0;
                        end;
                    until PostedPayrollDoc.Next = 0;
            end;

            trigger OnPostDataItem()
            begin
                TempPayrollAEBuffer.Reset;
                if TempPayrollAEBuffer.FindSet then
                    repeat
                        CreateJnlLine(TempPayrollAEBuffer);
                    until TempPayrollAEBuffer.Next = 0;

                TempPayrollAEBuffer.DeleteAll;
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
                    field(BankAccountCode; BankAccountCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account No.';
                        TableRelation = "Bank Account";
                        ToolTip = 'Specifies the number used by the bank for the bank account.';
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
        TempPayrollAEBuffer: Record "Payroll AE Buffer" temporary;
        BankAccount: Record "Bank Account";
        HRSetup: Record "Human Resources Setup";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        PostedPayrollDoc: Record "Posted Payroll Document";
        PostedPayrollDocLine: Record "Posted Payroll Document Line";
        PayrollElement: Record "Payroll Element";
        PayrollPostingGr: Record "Payroll Posting Group";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        StartingDate: Date;
        EndingDate: Date;
        PostingDate: Date;
        LineNo: Integer;
        BankAccountCode: Code[20];
        Text001: Label 'Please enter Bank Account Code.';
        NextDocNo: Code[20];
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
    procedure CreateJnlLine(PayrollAEBuffer: Record "Payroll AE Buffer")
    var
        PayrollDocCalc: Codeunit "Payroll Document - Calculate";
    begin
        GenJnlLine.Init;

        GenJnlLine."Line No." := LineNo;
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine."Document No." := NextDocNo;
        NextDocNo := IncStr(NextDocNo);
        PayrollElement.Get(PayrollAEBuffer."Element Code");
        PayrollPostingGr.Get(PayrollElement."Payroll Posting Group");
        GenJnlLine.Validate("Account No.", PayrollPostingGr."Account No.");
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
        GenJnlLine.Validate("Bal. Account No.", BankAccountCode);
        PayrollAEBuffer.Amount := PayrollDocCalc.RoundAmountToPay(PayrollAEBuffer.Amount);
        GenJnlLine.Validate(Amount, -PayrollAEBuffer.Amount);
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

