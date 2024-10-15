report 12425 "Copy Pay Document"
{
    Caption = 'Copy Pay Document';
    ProcessingOnly = true;

    dataset
    {
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
                    field(DocType; DocType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Type';
                        OptionCaption = 'Payment order,Ingoing order,Outgoing order';
                        ToolTip = 'Specifies the type of the related document.';

                        trigger OnValidate()
                        begin
                            EntryNo := 0;
                            CheckEntryNo;
                        end;
                    }
                    field(EntryNo; EntryNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Entry No.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            SelectEntryNo;
                        end;

                        trigger OnValidate()
                        begin
                            CheckEntryNo;
                        end;
                    }
                    field("FromCheckLedgerEntry.""Document No."""; FromCheckLedgerEntry."Document No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        Editable = false;
                        ToolTip = 'Specifies the number of the related document.';
                    }
                    field("FromCheckLedgerEntry.Description"; FromCheckLedgerEntry.Description)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Description';
                        Editable = false;
                        ToolTip = 'Specifies a description of the record or entry.';
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

    trigger OnPreReport()
    begin
        if EntryNo = 0 then
            Error(Text000);

        FromCheckLedgerEntry.Get(EntryNo);

        with GenJournalLine do begin
            Init;
            "Journal Template Name" := xGenJournalLine."Journal Template Name";
            "Journal Batch Name" := xGenJournalLine."Journal Batch Name";
            xGenJournalLine.SetRange("Journal Template Name", xGenJournalLine."Journal Template Name");
            xGenJournalLine.SetRange("Journal Batch Name", xGenJournalLine."Journal Batch Name");

            if xGenJournalLine.Find('+') then
                "Line No." := xGenJournalLine."Line No." + 10000
            else
                "Line No." := 10000;

            SetUpNewLine(xGenJournalLine, 0, true);

            Validate("Account Type", FromCheckLedgerEntry."Bal. Account Type");
            Validate("Account No.", FromCheckLedgerEntry."Bal. Account No.");
            Validate("Document Type", FromCheckLedgerEntry."Document Type");
            Validate("Document No.", '');
            Validate(Description, FromCheckLedgerEntry.Description);

            if BankAccountLedgerEntry.Get(FromCheckLedgerEntry."Bank Account Ledger Entry No.") then
                if BankAccountLedgerEntry."Currency Code" <> "Currency Code" then
                    Error(Text001, "Currency Code", BankAccountLedgerEntry."Currency Code");

            Validate(Amount, -FromCheckLedgerEntry.Amount);
            Validate("Bank Payment Type", 1);
            Validate("Beneficiary Bank Code", FromCheckLedgerEntry."Beneficiary Bank Code");
            Validate("Payment Purpose", FromCheckLedgerEntry."Payment Purpose");
            Validate("Cash Order Including", FromCheckLedgerEntry."Cash Order Including");
            Validate("Cash Order Supplement", FromCheckLedgerEntry."Cash Order Supplement");
            Validate("Payment Method", FromCheckLedgerEntry."Payment Method");
            Validate("Payment Date", FromCheckLedgerEntry."Payment Before Date");
            Validate("Payment Subsequence", FromCheckLedgerEntry."Payment Subsequence");
            Validate("Payment Code", FromCheckLedgerEntry."Payment Code");
            Validate("Payment Assignment", FromCheckLedgerEntry."Payment Assignment");
            Validate("Payment Type", FromCheckLedgerEntry."Payment Type");
            Insert;
        end;
    end;

    var
        FromCheckLedgerEntry: Record "Check Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        xGenJournalLine: Record "Gen. Journal Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        DocType: Option "Payment order","Ingoing order","Outgoing order";
        EntryNo: Integer;
        Text000: Label 'Please enter Entry No.';
        Text001: Label 'Currency Code mismatch: Bank Acc %1 not equal to Check Ledger Entry %2';

    [Scope('OnPrem')]
    procedure CheckEntryNo()
    begin
        if EntryNo = 0 then
            FromCheckLedgerEntry.Init
        else
            if EntryNo <> FromCheckLedgerEntry."Entry No." then
                FromCheckLedgerEntry.Get(EntryNo);
    end;

    [Scope('OnPrem')]
    procedure SelectEntryNo()
    begin
        FromCheckLedgerEntry.FilterGroup(2);
        FromCheckLedgerEntry.Reset;
        FromCheckLedgerEntry.CalcFields("Bank Account Type");
        case DocType of
            0:
                begin
                    FromCheckLedgerEntry.SetRange("Bank Account Type", 0);
                    FromCheckLedgerEntry.SetFilter(Amount, '<0');
                end;
            1:
                begin
                    FromCheckLedgerEntry.SetRange("Bank Account Type", 1);
                    FromCheckLedgerEntry.SetFilter(Amount, '>0');
                end;
            2:
                begin
                    FromCheckLedgerEntry.SetRange("Bank Account Type", 1);
                    FromCheckLedgerEntry.SetFilter(Amount, '<0');
                end;
            3:
                begin
                    FromCheckLedgerEntry.SetRange("Bank Account Type", 0);
                    FromCheckLedgerEntry.SetFilter(Amount, '>0');
                end;
        end;
        FromCheckLedgerEntry.SetRange("Entry Status", 3);
        FromCheckLedgerEntry.FilterGroup(0);

        if PAGE.RunModal(0, FromCheckLedgerEntry) = ACTION::LookupOK then
            EntryNo := FromCheckLedgerEntry."Entry No.";

        CheckEntryNo;
    end;

    [Scope('OnPrem')]
    procedure SetJournalLine(var NewGenJournalLine: Record "Gen. Journal Line")
    begin
        xGenJournalLine := NewGenJournalLine;
    end;
}

