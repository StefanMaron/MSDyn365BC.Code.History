codeunit 2000042 "Post Coded Bank Statement"
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "Gen. Journal Template" = r,
                  TableData "Gen. Journal Line" = rimd,
                  TableData "Gen. Journal Batch" = ri;
    TableNo = "CODA Statement Line";

    trigger OnRun()
    begin
        EBSetup.Get();
        CodBankStmtLine.SetCurrentKey("Bank Account No.", "Statement No.", "Statement Line No.");
        CodBankStmtLine.CopyFilters(Rec);
        Code;
        Copy(CodBankStmtLine);
    end;

    var
        Text000: Label 'There are unapplied Statement lines.';
        Text001: Label 'Do you want to transfer the statement lines to the General Ledger ?';
        Text002: Label 'There is no general journal template for bank account number %1.';
        Text003: Label 'Line                  #2###### @3@@@@@@@@@@@@@';
        Text004: Label '%1 %2 is transferring to journal %3...', Comment = 'Parameter 1 - bank account number, 2 - statement number, 3 - general journal template name.';
        Text005: Label 'CODA statement line %1 has already been transferred to the general ledger.';
        Text006: Label 'Internal error: recursive call of Default Posting.';
        Text007: Label 'CV', Locked = true;
        Text008: Label 'VC', Locked = true;
        Text009: Label 'C', Locked = true;
        Text010: Label 'V', Locked = true;
        Text011: Label 'Type standard format message %1 was not found.';
        Text012: Label 'Error in %1 %2 on line number %3.', Comment = 'Parameter 1 - message type (Non standard format,Standard format), 2 - statement message (text), 3 - statement line number (integer).';
        Text013: Label 'The Open field in customer ledger entry is %1.';
        Text014: Label '%1 is partially applied.';
        Text015: Label '%1 was not found.';
        EBSetup: Record "Electronic Banking Setup";
        CodBankStmtLine: Record "CODA Statement Line";
        CodedTrans: Record "Transaction Coding";
        BankAcc: Record "Bank Account";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
        Cust: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        Vend: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLAcc: Record "G/L Account";
        PaymJnlManagement: Codeunit PmtJrnlManagement;
        GenJnlManagement: Codeunit GenJnlManagement;
        CodeFound: Boolean;
        ProcessingDefaultPosting: Boolean;
        Testing: Boolean;
        DefaultApplication: Boolean;
        ErrorMsg: Text[250];
        BatchName: Code[10];

    [Scope('OnPrem')]
    procedure "Code"()
    var
        CodedBankStmtLine: Record "CODA Statement Line";
    begin
        with CodBankStmtLine do begin
            CodedBankStmtLine.SetCurrentKey("Bank Account No.", "Statement No.", "Statement Line No.");
            CodedBankStmtLine.CopyFilters(CodBankStmtLine);
            CodedBankStmtLine.SetRange(ID, ID::Movement);
            CodedBankStmtLine.SetRange("Application Status", "Application Status"::" ");
            if not CodedBankStmtLine.IsEmpty then
                Error(Text000);

            if not Confirm(Text001, false) then
                exit;

            CodedBankStmtLine.Reset();

            SetFilter("Application Status", '%1|%2', "Application Status"::Applied, "Application Status"::"Partly applied");
            FindFirst;
            GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::Financial);
            GenJnlTemplate.SetRange("Bal. Account Type", GenJnlTemplate."Bal. Account Type"::"Bank Account");
            GenJnlTemplate.SetRange("Bal. Account No.", "Bank Account No.");
            if not GenJnlTemplate.FindFirst then
                Error(Text002, "Bank Account No.");
            GenJnlLine.SetRange("Journal Template Name", GenJnlTemplate.Name);
            GenJnlManagement.OpenJnl(BatchName, GenJnlLine);
            TransferCodBankStmtLines;
        end
    end;

    [Scope('OnPrem')]
    procedure TransferCodBankStmtLines()
    var
        Window: Dialog;
        LineNo: Integer;
        TotLines: Integer;
        LineCounter: Integer;
    begin
        Window.Open(
          '#1#################################\\' +
          Text003);

        if GenJnlLine.FindLast then;
        LineNo := GenJnlLine."Line No.";
        with CodBankStmtLine do begin
            TotLines := Count;
            LineCounter := 0;
            Window.Update(1, StrSubstNo(Text004, "Bank Account No.", "Statement No.", GenJnlTemplate.Name));
            FindSet;
            repeat
                // Test if Coded Bank statement line has been posted yet
                if ("Journal Template Name" <> '') or
                   ("Journal Batch Name" <> '') or
                   ("Line No." <> 0)
                then
                    Error(Text005, "Document No.");

                if Amount <> 0 then begin
                    OnTransferCodBankStmtLinesOnBeforeInitGenJnlLine(CodBankStmtLine);
                    LineCounter := LineCounter + 1;
                    GenJnlLine.Init();
                    LineNo := LineNo + 10000;
                    GenJnlLine."Journal Template Name" := GenJnlTemplate.Name;
                    GenJnlLine."Journal Batch Name" := BatchName;
                    GenJnlLine."Line No." := LineNo;
                    GenJnlLine."Posting Date" := "Posting Date";
                    GenJnlLine.Validate("Bal. Account Type", GenJnlTemplate."Bal. Account Type");
                    GenJnlLine.Validate("Bal. Account No.", GenJnlTemplate."Bal. Account No.");
                    GenJnlLine."Account Type" := "Account Type";
                    GenJnlLine."Document Type" := "Document Type";
                    GenJnlLine."Document No." := "Document No.";
                    if Description <> '' then
                        GenJnlLine.Description := CopyStr(Description, 1, MaxStrLen(GenJnlLine.Description));

                    // Bank account is Balancing Account, hence Amount takes the opposite sign
                    BankAcc.Get("Bank Account No.");
                    if BankAcc."Currency Code" = '' then begin
                        GenJnlLine."Currency Factor" := "Currency Factor";
                        GenJnlLine."Currency Code" := "Currency Code";
                    end;
                    GenJnlLine.Validate("Account No.", "Account No.");
                    GenJnlLine."Applies-to ID" := "Applies-to ID";
                    GenJnlLine.Validate(Amount, -Amount);
                    GenJnlLine."System-Created Entry" := true;
                    OnTransferCodBankStmtLinesOnBeforeGenJnlLineInsert(GenJnlLine, CodBankStmtLine);
                    GenJnlLine.Insert();

                    // Link Coded Bank Statement line to Gen. Jnl. Line
                    "Journal Template Name" := GenJnlLine."Journal Template Name";
                    "Journal Batch Name" := GenJnlLine."Journal Batch Name";
                    "Line No." := GenJnlLine."Line No.";
                    Modify;

                    Window.Update(2, LineNo);
                    Window.Update(3, Round(LineCounter / TotLines * 10000, 1));
                end;
            until Next = 0;
        end;
        Window.Close
    end;

    [Scope('OnPrem')]
    procedure ProcessCodBankStmtLine(var CodedBankStmtLine: Record "CODA Statement Line")
    var
        CodBankStmtLine: Record "CODA Statement Line";
    begin
        with CodedBankStmtLine do begin
            if FetchCodedTransaction(CodedBankStmtLine) then
                // Type 0 lines don't have details.
                if (CodedTrans."Globalisation Code" = CodedTrans."Globalisation Code"::Global) or
               ("Transaction Type" = 0)
            then begin
                    ApplyCodedTransaction(CodedBankStmtLine);

                    if Type = Type::Global then begin
                        CodBankStmtLine.Reset();
                        CodBankStmtLine.SetRange("Bank Account No.", "Bank Account No.");
                        CodBankStmtLine.SetRange("Statement No.", "Statement No.");
                        CodBankStmtLine.SetRange(ID, ID);
                        CodBankStmtLine.SetRange("Attached to Line No.", "Statement Line No.");
                        if CodBankStmtLine.FindSet then
                            repeat
                                CodBankStmtLine."Unapplied Amount" := 0;
                                CodBankStmtLine."Application Status" := "Application Status"::"Indirectly applied";
                                CodBankStmtLine.Modify
                            until CodBankStmtLine.Next = 0
                    end;
                end else begin
                    CodBankStmtLine.Reset();
                    CodBankStmtLine.SetRange("Bank Account No.", "Bank Account No.");
                    CodBankStmtLine.SetRange("Statement No.", "Statement No.");
                    CodBankStmtLine.SetRange(ID, ID);
                    CodBankStmtLine.SetRange("Attached to Line No.", "Statement Line No.");
                    if CodBankStmtLine.FindSet then
                        repeat
                            ProcessCodBankStmtLine(CodBankStmtLine);
                            "Unapplied Amount" := "Unapplied Amount" - CodBankStmtLine.Amount;
                            if "Unapplied Amount" = 0 then
                                "Application Status" := "Application Status"::"Indirectly applied"
                        until CodBankStmtLine.Next = 0
                    else
                        ApplyCodedTransaction(CodedBankStmtLine)
                end;
            "System-Created Entry" := true;
            Modify;
        end
    end;

    [Scope('OnPrem')]
    procedure FetchCodedTransaction(var CodedBankStmtLine: Record "CODA Statement Line"): Boolean
    var
        TransactionFound: Boolean;
    begin
        if ProcessingDefaultPosting then begin
            CodedTrans."Bank Account No." := '';
            CodedTrans."Transaction Family" := 0;
            CodedTrans.Transaction := 0;
            CodedTrans."Transaction Category" := 0;

            // Error if default posting entry is not found
            CodedTrans.Find;
            TransactionFound := true;
        end else
            with CodedBankStmtLine do begin
                CodedTrans."Bank Account No." := "Bank Account No.";
                CodedTrans."Transaction Family" := "Transaction Family";
                CodedTrans.Transaction := Transaction;
                CodedTrans."Transaction Category" := "Transaction Category";
                TransactionFound := CodedTrans.Find;
                if not TransactionFound then begin
                    CodedTrans."Bank Account No." := '';
                    TransactionFound := CodedTrans.Find;
                end;
                if not TransactionFound then begin
                    CodedTrans."Transaction Family" := 0;
                    CodedTrans.Transaction := 0;
                    TransactionFound := CodedTrans.Find;
                end;
                if not (Testing or TransactionFound) then begin
                    CodedTrans."Transaction Category" := 0;
                    TransactionFound := CodedTrans.Find;
                end;
            end;
        exit(TransactionFound);
    end;

    [Scope('OnPrem')]
    procedure ApplyCodedTransaction(var CodedBankStmtLine: Record "CODA Statement Line")
    begin
        CodBankStmtLine := CodedBankStmtLine;
        with CodBankStmtLine do begin
            if "Message Type" = "Message Type"::"Standard format" then
                InterpretStandardFormat(CodBankStmtLine);

            // Post line according to Coded Transaction definition
            if "Application Status" in ["Application Status"::" ", "Application Status"::"Partly applied"] then begin
                if ("Message Type" = "Message Type"::"Non standard format") and ("Statement Message" <> '') then
                    Description := CopyStr(DelChr("Statement Message", '>', ' '), 1, MaxStrLen(Description));
                case CodedTrans."Account Type" of
                    CodedTrans."Account Type"::" ":
                        NotCodedPosting;
                    CodedTrans."Account Type"::"G/L Account", CodedTrans."Account Type"::"Bank Account":
                        begin
                            CodedTrans.TestField("Account No.");
                            InitCodBankStmtLine(CodedTrans."Account Type" - 1);
                            if ("Message Type" = "Message Type"::"Non standard format") and ("Statement Message" = '') then
                                Description := CodedTrans.Description;
                        end;
                    CodedTrans."Account Type"::Customer:
                        begin
                            SearchCustLedgEntry;
                            if CodedTrans."Account No." <> '' then
                                InitCodBankStmtLine(CodedTrans."Account Type" - 1);
                        end;
                    CodedTrans."Account Type"::Vendor:
                        begin
                            SearchVendLedgEntry;
                            if CodedTrans."Account No." <> '' then
                                InitCodBankStmtLine(CodedTrans."Account Type" - 1);
                        end;
                end;
            end;
            if "Message Type" = "Message Type"::"Non standard format" then
                if "Statement Message" <> '' then
                    Description := CopyStr(DelChr("Statement Message", '>', ' '), 1, MaxStrLen(Description));
            // Everything else failed
            if ("Application Status" = "Application Status"::" ") and DefaultApplication then
                DefaultPosting(CodBankStmtLine);
        end;
        CodedBankStmtLine := CodBankStmtLine;
    end;

    [Scope('OnPrem')]
    procedure DefaultPosting(var CodedBankStmtLine: Record "CODA Statement Line")
    begin
        if ProcessingDefaultPosting then
            Error(Text006);
        ProcessingDefaultPosting := true;
        ProcessCodBankStmtLine(CodedBankStmtLine);
        ProcessingDefaultPosting := false
    end;

    [Scope('OnPrem')]
    procedure NotCodedPosting()
    var
        Sequence: Text[30];
        i: Integer;
    begin
        with CodBankStmtLine do begin
            if "Statement Amount" > 0 then
                Sequence := Text007
            else
                Sequence := Text008;
            for i := 1 to StrLen(Sequence) do begin
                case Format(Sequence[i]) of
                    Text009:
                        SearchCustLedgEntry;
                    Text010:
                        SearchVendLedgEntry;
                end;
                if "Application Status" = "Application Status"::Applied then
                    exit;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure InterpretStandardFormat(var CodedBankStmtLine: Record "CODA Statement Line"): Text[250]
    begin
        ErrorMsg := '';
        CodBankStmtLine := CodedBankStmtLine;
        with CodBankStmtLine do begin
            if "Message Type" = "Message Type"::"Non standard format" then
                exit;
            CodeFound := false;
            case "Type Standard Format Message" of
                10:
                    CodeFound := true;
                11:
                    CodeFound := true;
                101, 102:
                    begin
                        DecodeOGM;
                        CodeFound := true;
                    end;
                103:
                    begin
                        DecodeNumber;
                        CodeFound := true
                    end;
                104:
                    begin
                        DecodeEquivalent;
                        CodeFound := true
                    end;
                105:
                    begin
                        DecodeOriginalAmount;
                        CodeFound := true
                    end;
                106:
                    begin
                        DecodeMethodOfCalculation;
                        CodeFound := true
                    end;
                107:
                    begin
                        DecodeDomiciliation;
                        CodeFound := true
                    end;
                126:
                    begin
                        TermInvestment;
                        CodeFound := true
                    end;
                else
                    CodeFound := true;
            end;
            if not CodeFound then
                ErrorMsg := StrSubstNo(Text011, "Type Standard Format Message");
        end;
        CodedBankStmtLine := CodBankStmtLine;
        if Testing then
            exit(ErrorMsg);

        if ErrorMsg <> '' then
            Error(ErrorMsg);
    end;

    [Scope('OnPrem')]
    procedure InitCodeunit(NewTesting: Boolean; DefaultPosting: Boolean)
    begin
        Testing := NewTesting;
        DefaultApplication := DefaultPosting
    end;

    local procedure DecodeOGM()
    begin
        with CodBankStmtLine do
            if not PaymJnlManagement.Mod97Test("Statement Message") then
                ErrorMsg :=
                  StrSubstNo(Text012,
                    "Message Type", "Statement Message", "Statement Line No.")
            else
                if "Statement Amount" > 0 then begin
                    DecodeCustLedgEntry;
                    if "Application Status" = "Application Status"::" " then
                        SearchCustLedgEntry;
                end else begin
                    DecodeVendLedgEntry;
                    if "Application Status" = "Application Status"::" " then
                        SearchVendLedgEntry;
                end;
    end;

    [Scope('OnPrem')]
    procedure DecodeNumber()
    begin
        // 103
        with CodBankStmtLine do
            Description := CopyStr("Statement Message", 1, 12)
    end;

    [Scope('OnPrem')]
    procedure DecodeEquivalent()
    begin
        // 104
        with CodBankStmtLine do
            Evaluate("Amount (LCY)", CopyStr("Statement Message", 1, 15));
    end;

    [Scope('OnPrem')]
    procedure DecodeOriginalAmount()
    begin
    end;

    local procedure DecodeCustLedgEntry()
    var
        DocNo: Code[20];
    begin
        Clear(CustLedgEntry);
        with CodBankStmtLine do begin
            if "Type Standard Format Message" = 107 then begin
                if Type = Type::Global then
                    DocNo := DelChr(CopyStr("Customer Reference", 1, 10), '<', '0')
                else
                    DocNo := DelChr(CopyStr("Customer Reference", 14, 11), '<', '0');
            end else
                DocNo := DelChr(CopyStr("Statement Message", 1, 10), '<', '0');

            CustLedgEntry.SetCurrentKey("Document No.");
            if "Statement Amount" > 0 then
                CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
            CustLedgEntry.SetRange("Document No.", DocNo);
            OnDecodeCustLedgEntryOnBeforePost(CustLedgEntry, CodBankStmtLine, DocNo);
            if CustLedgEntry.FindFirst then
                PostCustLedgEntry;
        end
    end;

    local procedure SearchCustomer(): Boolean
    var
        CustBankAcc: Record "Customer Bank Account";
        DomiciliationNo: Text[12];
        BankAccNo: Text[30];
    begin
        Clear(Cust);
        with CodBankStmtLine do begin
            if "Type Standard Format Message" = 107 then begin
                if Cust.SetCurrentKey("Domiciliation No.") then;
                DomiciliationNo := CopyStr("Statement Message", 1, 12);
                Cust.SetRange("Domiciliation No.", DomiciliationNo);
                exit(Cust.FindFirst);
            end;
            if "Bank Account No. Other Party" <> '' then begin
                CustBankAcc.SetRange(IBAN, "Bank Account No. Other Party");
                if not CustBankAcc.FindFirst then begin
                    CustBankAcc.SetRange(IBAN);
                    if StrLen("Bank Account No. Other Party") <= MaxStrLen(CustBankAcc."Bank Account No.") then
                        CustBankAcc.SetRange("Bank Account No.", "Bank Account No. Other Party");
                    if not CustBankAcc.FindFirst then begin
                        BankAccNo := // try format xxx-xxxxxxx-xx
                          CopyStr("Bank Account No. Other Party", 1, 3) +
                          '-' + CopyStr("Bank Account No. Other Party", 4, 7) +
                          '-' + CopyStr("Bank Account No. Other Party", 11, 2);
                        CustBankAcc.SetRange("Bank Account No.", BankAccNo);
                        if not CustBankAcc.FindFirst then
                            if CodedTrans."Account Type" = CodedTrans."Account Type"::Customer then
                                CustBankAcc."Customer No." := CodedTrans."Account No.";
                    end;
                end;
                exit(Cust.Get(CustBankAcc."Customer No."));
            end
        end;
    end;

    local procedure SearchCustLedgEntry()
    var
        CustLedgEntry2: Record "Cust. Ledger Entry";
        Found: Integer;
    begin
        Clear(CustLedgEntry);
        with CodBankStmtLine do begin
            if SearchCustomer then begin
                CustLedgEntry2.SetCurrentKey("Customer No.", Open, Positive);
                CustLedgEntry2.SetRange("Customer No.", Cust."No.");
                CustLedgEntry2.SetRange(Open, true);
                CustLedgEntry2.SetRange(Positive, "Statement Amount" > 0);
                if CustLedgEntry2.FindSet then
                    repeat
                        CustLedgEntry2.CalcFields("Remaining Amount");
                        if CustLedgEntry2."Remaining Amount" = "Statement Amount" then begin
                            Found := Found + 1;
                            CustLedgEntry := CustLedgEntry2;
                        end;
                    until CustLedgEntry2.Next = 0;

                // Multiple Entries with Same Amount: Do Not Assign
                if Found <> 1 then
                    Clear(CustLedgEntry);
                CustLedgEntry."Customer No." := Cust."No.";

                PostCustLedgEntry
            end;
            Clear(Cust)
        end
    end;

    [Scope('OnPrem')]
    procedure PostCustLedgEntry()
    begin
        with CodBankStmtLine do begin
            "Application Status" := "Application Status"::Applied;
            Cust.Get(CustLedgEntry."Customer No.");
            if "Statement Amount" > 0 then
                "Document Type" := "Document Type"::Payment
            else
                "Document Type" := "Document Type"::Refund;
            "Account Type" := "Account Type"::Customer;
            "Account No." := CustLedgEntry."Customer No.";
            Amount := "Statement Amount";
            "Unapplied Amount" := "Unapplied Amount" - Amount;
            Validate("Account Name", Cust.Name);
            if CustLedgEntry."Entry No." > 0 then
                if not CustLedgEntry.Open then begin
                    "Application Status" := "Application Status"::"Partly applied";
                    "Application Information" :=
                      StrSubstNo(Text013, CustLedgEntry.Open);
                end else begin
                    if "Unapplied Amount" <> 0 then begin
                        "Application Information" := StrSubstNo(Text014, CustLedgEntry.TableCaption);
                        "Application Status" := "Application Status"::"Partly applied";
                    end;
                    "Applies-to ID" := "Document No.";
                    CustLedgEntry."Applies-to ID" := "Document No.";
                    CustLedgEntry.CalcFields("Remaining Amount");
                    CustLedgEntry."Amount to Apply" := CustLedgEntry."Remaining Amount";
                    CustLedgEntry.Modify
                end
            else begin
                "Application Status" := "Application Status"::"Partly applied";
                "Application Information" := StrSubstNo(Text015, CustLedgEntry.TableCaption);
            end;
            Clear(CustLedgEntry)
        end
    end;

    local procedure DecodeVendLedgEntry()
    var
        Message: Text[50];
    begin
        Clear(VendLedgEntry);
        with CodBankStmtLine do begin
            if "Type Standard Format Message" = 107 then
                Message := DelChr(CopyStr("Statement Message", 19, 15), '<', '0')
            else
                Message := DelChr(CopyStr("Statement Message", 1, 50), '<', '0');
            VendLedgEntry.SetCurrentKey(Open);
            if "Statement Amount" > 0 then
                VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo")
            else
                VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);

            VendLedgEntry.SetRange(Description, Message);
            OnDecodeVendLedgEntryOnAfterVendLedgEntrySetFilters(VendLedgEntry, CodBankStmtLine, Message);
            if VendLedgEntry.FindFirst then
                PostVendLedgEntry;
        end
    end;

    local procedure SearchVendor(): Boolean
    var
        VendBankAcc: Record "Vendor Bank Account";
        BankAccNo: Text[30];
    begin
        Clear(Vend);
        with CodBankStmtLine do
            if "Bank Account No. Other Party" <> '' then begin
                VendBankAcc.SetRange(IBAN, "Bank Account No. Other Party");
                if not VendBankAcc.FindFirst then begin
                    VendBankAcc.SetRange(IBAN);
                    if StrLen("Bank Account No. Other Party") <= MaxStrLen(VendBankAcc."Bank Account No.") then
                        VendBankAcc.SetRange("Bank Account No.", "Bank Account No. Other Party");
                    if not VendBankAcc.FindFirst then begin
                        BankAccNo := // try format xxx-xxxxxxx-xx
                          CopyStr("Bank Account No. Other Party", 1, 3) +
                          '-' + CopyStr("Bank Account No. Other Party", 4, 7) +
                          '-' + CopyStr("Bank Account No. Other Party", 11, 2);
                        VendBankAcc.SetRange("Bank Account No.", BankAccNo);
                        if not VendBankAcc.FindFirst then
                            if CodedTrans."Account Type" = CodedTrans."Account Type"::Vendor then
                                VendBankAcc."Vendor No." := CodedTrans."Account No.";
                    end;
                end;
                OnAfterSearchVendor(Vend, VendBankAcc, CodBankStmtLine);
                exit(Vend.Get(VendBankAcc."Vendor No."));
            end;
    end;

    local procedure SearchVendLedgEntry()
    var
        VendLedgEntry2: Record "Vendor Ledger Entry";
        Found: Integer;
    begin
        Clear(VendLedgEntry);
        with CodBankStmtLine do begin
            if SearchVendor then begin
                VendLedgEntry2.SetCurrentKey("Vendor No.", Open, Positive);
                VendLedgEntry2.SetRange("Vendor No.", Vend."No.");
                VendLedgEntry2.SetRange(Open, true);
                VendLedgEntry2.SetRange(Positive, "Statement Amount" > 0);
                if VendLedgEntry2.FindSet then
                    repeat
                        VendLedgEntry2.CalcFields("Remaining Amount");
                        if VendLedgEntry2."Remaining Amount" = "Statement Amount" then begin
                            Found := Found + 1;
                            VendLedgEntry := VendLedgEntry2
                        end;
                    until VendLedgEntry2.Next = 0;

                // Multiple Entries with Same Amount: Do Not Assign
                if Found <> 1 then
                    Clear(VendLedgEntry);
                VendLedgEntry."Vendor No." := Vend."No.";

                PostVendLedgEntry;
            end;
            Clear(Vend);
        end
    end;

    [Scope('OnPrem')]
    procedure PostVendLedgEntry()
    begin
        with CodBankStmtLine do begin
            Vend.Get(VendLedgEntry."Vendor No.");
            "Application Status" := "Application Status"::Applied;
            if "Statement Amount" < 0 then
                "Document Type" := "Document Type"::Payment
            else
                "Document Type" := "Document Type"::Refund;
            "Account Type" := "Account Type"::Vendor;
            "Account No." := VendLedgEntry."Vendor No.";
            Amount := "Statement Amount";
            "Unapplied Amount" := "Unapplied Amount" - Amount;
            Validate("Account Name", Vend.Name);
            if VendLedgEntry."Entry No." > 0 then begin
                if "Unapplied Amount" <> 0 then begin
                    "Application Information" := StrSubstNo(Text014, VendLedgEntry.TableCaption);
                    "Application Status" := "Application Status"::"Partly applied"
                end;
                "Applies-to ID" := "Document No.";
                VendLedgEntry."Applies-to ID" := "Document No.";
                VendLedgEntry.CalcFields("Remaining Amount");
                VendLedgEntry."Amount to Apply" := VendLedgEntry."Remaining Amount";
                VendLedgEntry.Modify
            end else begin
                "Application Information" := StrSubstNo(Text015, VendLedgEntry.TableCaption);
                "Application Status" := "Application Status"::"Partly applied"
            end;
            Clear(VendLedgEntry)
        end
    end;

    [Scope('OnPrem')]
    procedure DecodeMethodOfCalculation()
    begin
        // 106
        // Not implemented
    end;

    [Scope('OnPrem')]
    procedure DecodeDomiciliation()
    var
        Sequence: Text[30];
        i: Integer;
    begin
        // 107
        if CodedTrans."Account Type" <> CodedTrans."Account Type"::"G/L Account" then
            with CodBankStmtLine do begin
                if CodedTrans."Account Type" = CodedTrans."Account Type"::Customer then
                    Sequence := Text009
                else
                    if CodedTrans."Account Type" = CodedTrans."Account Type"::Vendor then
                        Sequence := Text010
                    else
                        if "Statement Amount" > 0 then
                            Sequence := Text007
                        else
                            Sequence := Text008;
                for i := 1 to StrLen(Sequence) do begin
                    case Format(Sequence[i]) of
                        Text009:
                            begin
                                DecodeCustLedgEntry;
                                if "Application Status" = "Application Status"::" " then
                                    SearchCustLedgEntry
                            end;
                        Text010:
                            begin
                                DecodeVendLedgEntry;
                                if "Application Status" = "Application Status"::" " then
                                    SearchVendLedgEntry
                            end
                    end;
                    if "Application Status" = "Application Status"::Applied then
                        exit;
                end;
            end;
    end;

    [Scope('OnPrem')]
    procedure TermInvestment()
    begin
        // 126
        // Not implemented
    end;

    [Scope('OnPrem')]
    procedure InitCodBankStmtLine(AccountType: Integer)
    begin
        with CodBankStmtLine do begin
            "Application Status" := "Application Status"::"Partly applied";
            "Application Information" := CodedTrans.Description;
            "Account Type" := AccountType;
            "Account No." := CodedTrans."Account No.";
            case "Account Type" of
                "Account Type"::Customer:
                    begin
                        if Cust.Get("Account No.") then
                            Description := Cust.Name;
                        "Document Type" := "Document Type"::Payment;
                    end;
                "Account Type"::Vendor:
                    begin
                        if Vend.Get("Account No.") then
                            Description := Vend.Name;
                        "Document Type" := "Document Type"::Payment;
                    end;
                "Account Type"::"G/L Account":
                    begin
                        if GLAcc.Get("Account No.") then
                            Description := GLAcc.Name;
                    end;
            end;
            Amount := "Statement Amount";
            if "Currency Code" = '' then
                "Amount (LCY)" := "Statement Amount"
            else
                "Amount (LCY)" := Round(Amount * "Currency Factor" / 100);
            "Unapplied Amount" := "Unapplied Amount" - Amount;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSearchVendor(var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account"; var CODAStatementLine: Record "CODA Statement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDecodeCustLedgEntryOnBeforePost(var CustLedgerEntry: Record "Cust. Ledger Entry"; var CODAStatementLine: Record "CODA Statement Line"; var DocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDecodeVendLedgEntryOnAfterVendLedgEntrySetFilters(var VendLedgEntry: Record "Vendor Ledger Entry"; var CODAStatementLine: Record "CODA Statement Line"; var Message: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferCodBankStmtLinesOnBeforeInitGenJnlLine(CODAStatementLine: Record "CODA Statement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferCodBankStmtLinesOnBeforeGenJnlLineInsert(var GenJnlLine: Record "Gen. Journal Line"; CodBankStmtLine: Record "CODA Statement Line")
    begin
    end;
}

