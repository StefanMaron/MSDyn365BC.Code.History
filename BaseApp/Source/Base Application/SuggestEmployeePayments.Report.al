report 394 "Suggest Employee Payments"
{
    Caption = 'Suggest Employee Payments';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Employee; Employee)
        {
            DataItemTableView = SORTING("No.") WHERE("Privacy Blocked" = CONST(false));
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                Clear(EmployeeBalance);
                CalcFields(Balance);
                EmployeeBalance := Balance;

                if StopPayments then
                    CurrReport.Break();
                Window.Update(1, "No.");
                if EmployeeBalance > 0 then begin
                    GetEmplLedgEntries(true);
                    GetEmplLedgEntries(false);
                    CheckAmounts();
                    ClearNegative();
                end;
            end;

            trigger OnPostDataItem()
            begin
                if FindSet then
                    repeat
                        ClearNegative();
                    until Next = 0;

                DimSetEntry.LockTable();
                GenJnlLine.LockTable();
                GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
                GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
                if GenJnlLine.FindLast then begin
                    LastLineNo := GenJnlLine."Line No.";
                    GenJnlLine.Init();
                end;

                Window2.Open(InsertingJournalLinesMsg);

                TempPayableEmployeeLedgerEntry.Reset();
                MakeGenJnlLines;
                TempPayableEmployeeLedgerEntry.Reset();
                TempPayableEmployeeLedgerEntry.DeleteAll();

                Window2.Close;
                Window.Close;
                ShowMessage(MessageText);
            end;

            trigger OnPreDataItem()
            begin
                if PostingDate = 0D then
                    Error(PostingDateRequiredErr);

                BankPmtType := GenJnlLine2."Bank Payment Type";
                BalAccType := GenJnlLine2."Bal. Account Type";
                BalAccNo := GenJnlLine2."Bal. Account No.";
                GenJnlLineInserted := false;
                MessageText := '';

                if ((BankPmtType = GenJnlLine2."Bank Payment Type"::" ") or
                    SummarizePerEmpl) and
                   (NextDocNo = '')
                then
                    Error(StartingDocNoErr);

                if ((BankPmtType = GenJnlLine2."Bank Payment Type"::"Manual Check") and
                    not SummarizePerEmpl and
                    not DocNoPerLine)
                then
                    Error(ManualCheckErr);

                Empl2.CopyFilters(Employee);

                OriginalAmtAvailable := AmountAvailable;

                Window.Open(ProcessingEmployeesMsg);

                SelectedDim.SetRange("User ID", UserId);
                SelectedDim.SetRange("Object Type", 3);
                SelectedDim.SetRange("Object ID", REPORT::"Suggest Employee Payments");
                SummarizePerDim := SelectedDim.Find('-') and SummarizePerEmpl;

                NextEntryNo := 1;
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
                    group("Find Payments")
                    {
                        Caption = 'Find Payments';
                        field("Available Amount (LCY)"; AmountAvailable)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Available Amount (LCY)';
                            Importance = Additional;
                            ToolTip = 'Specifies a maximum amount (in LCY) that is available for payments.';
                        }
                        field(SkipExportedPayments; SkipExportedPayments)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Skip Exported Payments';
                            Importance = Additional;
                            ToolTip = 'Specifies if you do not want the batch job to insert payment journal lines for documents for which payments have already been exported to a bank file.';
                        }
                    }
                    group("Summarize Results")
                    {
                        Caption = 'Summarize Results';
                        field(SummarizePerEmployee; SummarizePerEmpl)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Summarize per Employee';
                            ToolTip = 'Specifies if you want the batch job to make one line per employee';
                        }
                        field(SummarizePerDimText; SummarizePerDimText)
                        {
                            ApplicationArea = Dimensions;
                            Caption = 'By Dimension';
                            Editable = false;
                            Enabled = SummarizePerDimTextEnable;
                            Importance = Additional;
                            ToolTip = 'Specifies the dimensions that you want the batch job to consider.';

                            trigger OnAssistEdit()
                            var
                                DimSelectionBuf: Record "Dimension Selection Buffer";
                            begin
                                DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Suggest Employee Payments", SummarizePerDimText);
                            end;
                        }
                    }
                    group("Fill in Journal Lines")
                    {
                        Caption = 'Fill in Journal Lines';
                        field(PostingDate; PostingDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Posting Date';
                            Importance = Promoted;
                            ToolTip = 'Specifies the date for the posting of this batch job. By default, the working date is entered, but you can change it.';

                            trigger OnValidate()
                            begin
                                ValidatePostingDate;
                            end;
                        }
                        field(StartingDocumentNo; NextDocNo)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Document No.';
                            ToolTip = 'Specifies the next available number in the number series for the journal batch that is linked to the payment journal. When you run the batch job, this is the document number that appears on the first payment journal line. You can also fill in this field manually.';

                            trigger OnValidate()
                            begin
                                if NextDocNo <> '' then
                                    if IncStr(NextDocNo) = '' then
                                        Error(StartingDocumentNoErr);
                            end;
                        }
                        field(NewDocNoPerLine; DocNoPerLine)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'New Doc. No. per Line';
                            Importance = Additional;
                            ToolTip = 'Specifies if you want the batch job to fill in the payment journal lines with consecutive document numbers, starting with the document number specified in the Starting Document No. field.';
                        }
                        field(BalAccountType; GenJnlLine2."Bal. Account Type")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Bal. Account Type';
                            Importance = Additional;
                            ToolTip = 'Specifies the balancing account type that payments on the payment journal are posted to.';

                            trigger OnValidate()
                            begin
                                if not (GenJnlLine2."Bal. Account Type" in
                                    [GenJnlLine2."Bal. Account Type"::"Bank Account", GenJnlLine2."Bal. Account Type"::"G/L Account"])
                                then
                                    error(
                                        BalAccountTypeErr,
                                        GenJnlLine2."Bal. Account Type"::"Bank Account", GenJnlLine2."Bal. Account Type"::"G/L Account");
                                GenJnlLine2."Bal. Account No." := '';
                            end;
                        }
                        field(BalAccountNo; GenJnlLine2."Bal. Account No.")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Bal. Account No.';
                            Importance = Additional;
                            ToolTip = 'Specifies the balancing account number that payments on the payment journal are posted to.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                case GenJnlLine2."Bal. Account Type" of
                                    GenJnlLine2."Bal. Account Type"::"G/L Account":
                                        if PAGE.RunModal(0, GLAcc) = ACTION::LookupOK then
                                            GenJnlLine2."Bal. Account No." := GLAcc."No.";
                                    GenJnlLine2."Bal. Account Type"::Customer,
                                  GenJnlLine2."Bal. Account Type"::Vendor,
                                  GenJnlLine2."Bal. Account Type"::Employee:
                                        Error(AccountTypeErr, GenJnlLine2.FieldCaption("Bal. Account Type"));
                                    GenJnlLine2."Bal. Account Type"::"Bank Account":
                                        if PAGE.RunModal(0, BankAcc) = ACTION::LookupOK then
                                            GenJnlLine2."Bal. Account No." := BankAcc."No.";
                                end;
                            end;

                            trigger OnValidate()
                            begin
                                if GenJnlLine2."Bal. Account No." <> '' then
                                    case GenJnlLine2."Bal. Account Type" of
                                        GenJnlLine2."Bal. Account Type"::"G/L Account":
                                            GLAcc.Get(GenJnlLine2."Bal. Account No.");
                                        GenJnlLine2."Bal. Account Type"::Customer,
                                      GenJnlLine2."Bal. Account Type"::Vendor,
                                      GenJnlLine2."Bal. Account Type"::Employee:
                                            Error(AccountTypeErr, GenJnlLine2.FieldCaption("Bal. Account Type"));
                                        GenJnlLine2."Bal. Account Type"::"Bank Account":
                                            BankAcc.Get(GenJnlLine2."Bal. Account No.");
                                    end;
                            end;
                        }
                        field(BankPaymentType; GenJnlLine2."Bank Payment Type")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Bank Payment Type';
                            Importance = Additional;
                            ToolTip = 'Specifies the check type to be used, if you use Bank Account as the balancing account type.';

                            trigger OnValidate()
                            begin
                                if (GenJnlLine2."Bal. Account Type" <> GenJnlLine2."Bal. Account Type"::"Bank Account") and
                                   (GenJnlLine2."Bank Payment Type" > 0)
                                then
                                    Error(BankPaymentTypeErr);
                            end;
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            SummarizePerDimTextEnable := true;
            SkipExportedPayments := true;
        end;

        trigger OnOpenPage()
        begin
            PostingDate := WorkDate;
            ValidatePostingDate;
            SetDefaults;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Commit();
        if not TempEmployeeLedgerEntry.IsEmpty then
            if Confirm(UnprocessedEntriesQst) then
                PAGE.RunModal(0, TempEmployeeLedgerEntry);
    end;

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        TempEmployeeLedgerEntry.DeleteAll();
        ShowPostingDateWarning := false;
    end;

    var
        PostingDateRequiredErr: Label 'In the Posting Date field, specify the date that will be used as the posting date for the journal entries.';
        StartingDocNoErr: Label 'In the Starting Document No. field, specify the first document number to be used.';
        ProcessingEmployeesMsg: Label 'Processing employees     #1##########', Comment = '#1########## is for the progress dialog. Don''t translate that part of the string';
        InsertingJournalLinesMsg: Label 'Inserting payment journal lines #1##########', Comment = '#1########## is for the progress dialog. Don''t translate that part of the string';
        AccountTypeErr: Label '%1 must be G/L Account or Bank Account.', Comment = '%1 - balancing account type';
        BankPaymentTypeErr: Label 'Bank Payment Type field must be filled only when Bal. Account Type is set to Bank Account.';
        BalAccountTypeErr: label 'Balancing account must be %1 or %2.';
        ManualCheckErr: Label 'If bank payment type is set to Manual Check, and you have not selected the Summarize per Employee field,\ then you must select the New Doc. No. per Line.';
        EmployeePaymentLinesCreatedTxt: Label 'You have created suggested employee payment lines.';
        Empl2: Record Employee;
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        DimSetEntry: Record "Dimension Set Entry";
        GenJnlLine2: Record "Gen. Journal Line";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        GLAcc: Record "G/L Account";
        BankAcc: Record "Bank Account";
        TempPayableEmployeeLedgerEntry: Record "Payable Employee Ledger Entry" temporary;
        CompanyInformation: Record "Company Information";
        TempEmplPaymentBuffer: Record "Employee Payment Buffer" temporary;
        OldTempEmplPaymentBuffer: Record "Employee Payment Buffer" temporary;
        SelectedDim: Record "Selected Dimension";
        TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        Window: Dialog;
        Window2: Dialog;
        PostingDate: Date;
        NextDocNo: Code[20];
        AmountAvailable: Decimal;
        OriginalAmtAvailable: Decimal;
        SummarizePerEmpl: Boolean;
        SummarizePerDim: Boolean;
        SummarizePerDimText: Text[250];
        LastLineNo: Integer;
        NextEntryNo: Integer;
        StopPayments: Boolean;
        DocNoPerLine: Boolean;
        BankPmtType: Option;
        BalAccType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner",Employee;
        BalAccNo: Code[20];
        MessageText: Text;
        GenJnlLineInserted: Boolean;
        UnprocessedEntriesQst: Label 'There are one or more entries for which no payment suggestions have been made because the posting dates of the entries are later than the requested posting date. Do you want to see the entries?';
        [InDataSet]
        SummarizePerDimTextEnable: Boolean;
        ShowPostingDateWarning: Boolean;
        EmployeeBalance: Decimal;
        ReplacePostingDateMsg: Label 'For one or more entries, the requested posting date is before the work date.\\These posting dates will use the work date.';
        SkipExportedPayments: Boolean;
        StartingDocumentNoErr: Label 'The value in the Starting Document No. field must have a number so that we can assign the next number in the series.';
        UnsupportedCurrencyErr: Label 'The balancing bank account must have local currency.';

    procedure SetGenJnlLine(NewGenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine := NewGenJnlLine;
    end;

    local procedure ValidatePostingDate()
    begin
        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        if GenJnlBatch."No. Series" = '' then
            NextDocNo := ''
        else begin
            NextDocNo := NoSeriesMgt.GetNextNo(GenJnlBatch."No. Series", PostingDate, false);
            Clear(NoSeriesMgt);
        end;
    end;

    procedure InitializeRequest(NewAvailableAmount: Decimal; NewSkipExportedPayments: Boolean; NewPostingDate: Date; NewStartDocNo: Code[20]; NewSummarizePerEmpl: Boolean; BalAccType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner",Employee; BalAccNo: Code[20]; BankPmtType: Option)
    begin
        AmountAvailable := NewAvailableAmount;
        SkipExportedPayments := NewSkipExportedPayments;
        PostingDate := NewPostingDate;
        NextDocNo := NewStartDocNo;
        SummarizePerEmpl := NewSummarizePerEmpl;
        GenJnlLine2."Bal. Account Type" := BalAccType;
        GenJnlLine2."Bal. Account No." := BalAccNo;
        GenJnlLine2."Bank Payment Type" := BankPmtType;
    end;

    local procedure GetEmplLedgEntries(Positive: Boolean)
    begin
        EmployeeLedgerEntry.Reset();
        EmployeeLedgerEntry.SetCurrentKey("Employee No.", Open, Positive);
        EmployeeLedgerEntry.SetRange("Employee No.", Employee."No.");
        EmployeeLedgerEntry.SetRange(Open, true);
        EmployeeLedgerEntry.SetRange(Positive, Positive);
        EmployeeLedgerEntry.SetRange("Applies-to ID", '');

        if SkipExportedPayments then
            EmployeeLedgerEntry.SetRange("Exported to Payment File", false);
        EmployeeLedgerEntry.SetFilter("Global Dimension 1 Code", Employee.GetFilter("Global Dimension 1 Filter"));
        EmployeeLedgerEntry.SetFilter("Global Dimension 2 Code", Employee.GetFilter("Global Dimension 2 Filter"));

        if EmployeeLedgerEntry.FindSet then
            repeat
                SaveAmount;
            until EmployeeLedgerEntry.Next = 0;
    end;

    local procedure SaveAmount()
    begin
        with GenJnlLine do begin
            Init;
            Validate("Posting Date", PostingDate);
            "Document Type" := "Document Type"::Payment;
            "Account Type" := "Account Type"::Employee;
            Empl2.Get(EmployeeLedgerEntry."Employee No.");
            Description := CopyStr(Empl2.FullName, 1, MaxStrLen(Description));
            "Posting Group" := Empl2."Employee Posting Group";
            "Salespers./Purch. Code" := Empl2."Salespers./Purch. Code";
            Validate("Bill-to/Pay-to No.", "Account No.");
            Validate("Sell-to/Buy-from No.", "Account No.");
            "Gen. Posting Type" := 0;
            "Gen. Prod. Posting Group" := '';
            "Gen. Bus. Posting Group" := '';
            "VAT Bus. Posting Group" := '';
            "VAT Prod. Posting Group" := '';
            Validate("Currency Code", EmployeeLedgerEntry."Currency Code");
            EmployeeLedgerEntry.CalcFields("Remaining Amount");
            Amount := -EmployeeLedgerEntry."Remaining Amount";
            Validate(Amount);
        end;

        TempPayableEmployeeLedgerEntry."Employee No." := EmployeeLedgerEntry."Employee No.";
        TempPayableEmployeeLedgerEntry."Entry No." := NextEntryNo;
        TempPayableEmployeeLedgerEntry."Employee Ledg. Entry No." := EmployeeLedgerEntry."Entry No.";
        TempPayableEmployeeLedgerEntry.Amount := GenJnlLine.Amount;
        TempPayableEmployeeLedgerEntry.Positive := (TempPayableEmployeeLedgerEntry.Amount > 0);
        TempPayableEmployeeLedgerEntry."Currency Code" := EmployeeLedgerEntry."Currency Code";
        TempPayableEmployeeLedgerEntry.Insert();
        NextEntryNo := NextEntryNo + 1;
    end;

    local procedure CheckAmounts()
    var
        CurrencyBalance: Decimal;
        PrevCurrency: Code[10];
    begin
        TempPayableEmployeeLedgerEntry.SetRange("Employee No.", Employee."No.");

        if TempPayableEmployeeLedgerEntry.Find('-') then begin
            repeat
                if TempPayableEmployeeLedgerEntry."Currency Code" <> PrevCurrency then begin
                    if CurrencyBalance > 0 then
                        AmountAvailable := AmountAvailable - CurrencyBalance;
                    CurrencyBalance := 0;
                    PrevCurrency := TempPayableEmployeeLedgerEntry."Currency Code";
                end;
                if (OriginalAmtAvailable = 0) or
                   (AmountAvailable >= CurrencyBalance + TempPayableEmployeeLedgerEntry.Amount)
                then
                    CurrencyBalance := CurrencyBalance + TempPayableEmployeeLedgerEntry.Amount
                else
                    TempPayableEmployeeLedgerEntry.Delete();
            until TempPayableEmployeeLedgerEntry.Next = 0;
            if OriginalAmtAvailable > 0 then
                AmountAvailable := AmountAvailable - CurrencyBalance;
            if (OriginalAmtAvailable > 0) and (AmountAvailable <= 0) then
                StopPayments := true;
        end;
        TempPayableEmployeeLedgerEntry.Reset();
    end;

    local procedure MakeGenJnlLines()
    var
        RemainingAmtAvailable: Decimal;
    begin
        TempEmplPaymentBuffer.Reset();
        TempEmplPaymentBuffer.DeleteAll();

        if BalAccType = BalAccType::"Bank Account" then
            CheckCurrencies(BalAccType, BalAccNo);

        if OriginalAmtAvailable <> 0 then begin
            RemainingAmtAvailable := OriginalAmtAvailable;
            RemovePaymentsAboveLimit(TempPayableEmployeeLedgerEntry, RemainingAmtAvailable);
        end;

        CopyEmployeeLedgerEntriesToTempEmplPaymentBuffer(RemainingAmtAvailable);
        CopyTempEmpPaymentBuffersToGenJnlLines;
    end;

    local procedure CopyEmployeeLedgerEntriesToTempEmplPaymentBuffer(RemainingAmtAvailable: Decimal)
    var
        DimBuf: Record "Dimension Buffer";
    begin
        if TempPayableEmployeeLedgerEntry.Find('-') then
            repeat
                TempPayableEmployeeLedgerEntry.SetRange("Employee No.", TempPayableEmployeeLedgerEntry."Employee No.");
                TempPayableEmployeeLedgerEntry.Find('-');
                repeat
                    EmployeeLedgerEntry.Get(TempPayableEmployeeLedgerEntry."Employee Ledg. Entry No.");

                    TempEmplPaymentBuffer."Employee No." := EmployeeLedgerEntry."Employee No.";
                    TempEmplPaymentBuffer."Currency Code" := EmployeeLedgerEntry."Currency Code";
                    TempEmplPaymentBuffer."Payment Method Code" := EmployeeLedgerEntry."Payment Method Code";
                    TempEmplPaymentBuffer."Creditor No." := EmployeeLedgerEntry."Creditor No.";
                    TempEmplPaymentBuffer."Payment Reference" := EmployeeLedgerEntry."Payment Reference";
                    TempEmplPaymentBuffer."Exported to Payment File" := EmployeeLedgerEntry."Exported to Payment File";

                    SetTempEmplPaymentBufferDims(DimBuf);

                    EmployeeLedgerEntry.CalcFields("Remaining Amount");

                    if SummarizePerEmpl then begin
                        TempEmplPaymentBuffer."Employee Ledg. Entry No." := 0;
                        if TempEmplPaymentBuffer.Find then begin
                            TempEmplPaymentBuffer.Amount := TempEmplPaymentBuffer.Amount + TempPayableEmployeeLedgerEntry.Amount;
                            TempEmplPaymentBuffer.Modify();
                        end else begin
                            TempEmplPaymentBuffer."Document No." := NextDocNo;
                            NextDocNo := IncStr(NextDocNo);
                            TempEmplPaymentBuffer.Amount := TempPayableEmployeeLedgerEntry.Amount;
                            Window2.Update(1, EmployeeLedgerEntry."Employee No.");
                            TempEmplPaymentBuffer.Insert();
                        end;
                        EmployeeLedgerEntry."Applies-to ID" := TempEmplPaymentBuffer."Document No.";
                    end else
                        if not IsEntryAlreadyApplied(GenJnlLine, EmployeeLedgerEntry) then begin
                            TempEmplPaymentBuffer."Employee Ledg. Entry Doc. Type" := EmployeeLedgerEntry."Document Type";
                            TempEmplPaymentBuffer."Employee Ledg. Entry Doc. No." := EmployeeLedgerEntry."Document No.";
                            TempEmplPaymentBuffer."Global Dimension 1 Code" := EmployeeLedgerEntry."Global Dimension 1 Code";
                            TempEmplPaymentBuffer."Global Dimension 2 Code" := EmployeeLedgerEntry."Global Dimension 2 Code";
                            TempEmplPaymentBuffer."Dimension Set ID" := EmployeeLedgerEntry."Dimension Set ID";
                            TempEmplPaymentBuffer."Employee Ledg. Entry No." := EmployeeLedgerEntry."Entry No.";
                            TempEmplPaymentBuffer.Amount := TempPayableEmployeeLedgerEntry.Amount;
                            Window2.Update(1, EmployeeLedgerEntry."Employee No.");
                            TempEmplPaymentBuffer.Insert();
                        end;

                    EmployeeLedgerEntry."Amount to Apply" := EmployeeLedgerEntry."Remaining Amount";
                    CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", EmployeeLedgerEntry);

                    TempPayableEmployeeLedgerEntry.Delete();
                    if OriginalAmtAvailable <> 0 then begin
                        RemainingAmtAvailable := RemainingAmtAvailable - TempPayableEmployeeLedgerEntry.Amount;
                        RemovePaymentsAboveLimit(TempPayableEmployeeLedgerEntry, RemainingAmtAvailable);
                    end;

                until not TempPayableEmployeeLedgerEntry.FindSet;
                TempPayableEmployeeLedgerEntry.DeleteAll();
                TempPayableEmployeeLedgerEntry.SetRange("Employee No.");
            until not TempPayableEmployeeLedgerEntry.Find('-');
    end;

    local procedure CopyTempEmpPaymentBuffersToGenJnlLines()
    var
        Employee: Record Employee;
    begin
        Clear(OldTempEmplPaymentBuffer);
        TempEmplPaymentBuffer.SetCurrentKey("Document No.");
        TempEmplPaymentBuffer.SetFilter(
          "Employee Ledg. Entry Doc. Type", '<>%1&<>%2', TempEmplPaymentBuffer."Employee Ledg. Entry Doc. Type"::Refund,
          TempEmplPaymentBuffer."Employee Ledg. Entry Doc. Type"::Payment);
        if TempEmplPaymentBuffer.FindSet then
            repeat
                with GenJnlLine do begin
                    Init;
                    Window2.Update(1, TempEmplPaymentBuffer."Employee No.");
                    LastLineNo := LastLineNo + 10000;
                    "Line No." := LastLineNo;
                    "Document Type" := "Document Type"::Payment;
                    "Posting No. Series" := GenJnlBatch."Posting No. Series";
                    if SummarizePerEmpl then
                        "Document No." := TempEmplPaymentBuffer."Document No."
                    else
                        if DocNoPerLine then begin
                            if TempEmplPaymentBuffer.Amount < 0 then
                                "Document Type" := "Document Type"::Refund;

                            "Document No." := NextDocNo;
                            NextDocNo := IncStr(NextDocNo);
                        end else
                            if (TempEmplPaymentBuffer."Employee No." = OldTempEmplPaymentBuffer."Employee No.") and
                               (TempEmplPaymentBuffer."Currency Code" = OldTempEmplPaymentBuffer."Currency Code")
                            then
                                "Document No." := OldTempEmplPaymentBuffer."Document No."
                            else begin
                                "Document No." := NextDocNo;
                                NextDocNo := IncStr(NextDocNo);
                                OldTempEmplPaymentBuffer := TempEmplPaymentBuffer;
                                OldTempEmplPaymentBuffer."Document No." := "Document No.";
                            end;
                    "Account Type" := "Account Type"::Employee;
                    SetHideValidation(true);
                    Validate("Posting Date", PostingDate);
                    Validate("Account No.", TempEmplPaymentBuffer."Employee No.");
                    Validate("Recipient Bank Account", TempEmplPaymentBuffer."Employee No.");
                    Employee.Get(TempEmplPaymentBuffer."Employee No.");

                    "Bal. Account Type" := BalAccType;
                    Validate("Bal. Account No.", BalAccNo);
                    Validate("Currency Code", TempEmplPaymentBuffer."Currency Code");
                    "Message to Recipient" := CompanyInformation.Name;
                    "Bank Payment Type" := BankPmtType;
                    if SummarizePerEmpl then
                        "Applies-to ID" := "Document No.";
                    Description := CopyStr(Employee.FullName, 1, MaxStrLen(Description));
                    "Source Line No." := TempEmplPaymentBuffer."Employee Ledg. Entry No.";
                    "Shortcut Dimension 1 Code" := TempEmplPaymentBuffer."Global Dimension 1 Code";
                    "Shortcut Dimension 2 Code" := TempEmplPaymentBuffer."Global Dimension 2 Code";
                    "Dimension Set ID" := TempEmplPaymentBuffer."Dimension Set ID";
                    "Source Code" := GenJnlTemplate."Source Code";
                    "Reason Code" := GenJnlBatch."Reason Code";
                    Validate(Amount, TempEmplPaymentBuffer.Amount);
                    "Applies-to Doc. Type" := TempEmplPaymentBuffer."Employee Ledg. Entry Doc. Type";
                    "Applies-to Doc. No." := TempEmplPaymentBuffer."Employee Ledg. Entry Doc. No.";
                    "Payment Method Code" := TempEmplPaymentBuffer."Payment Method Code";
                    "Creditor No." := CopyStr(TempEmplPaymentBuffer."Creditor No.", 1, MaxStrLen("Creditor No."));
                    "Payment Reference" := CopyStr(TempEmplPaymentBuffer."Payment Reference", 1, MaxStrLen("Payment Reference"));
                    "Exported to Payment File" := TempEmplPaymentBuffer."Exported to Payment File";
                    "Applies-to Ext. Doc. No." := TempEmplPaymentBuffer."Applies-to Ext. Doc. No.";

                    UpdateDimensions(GenJnlLine);
                    Insert;
                    GenJnlLineInserted := true;
                end;
            until TempEmplPaymentBuffer.Next = 0;
    end;

    local procedure UpdateDimensions(var GenJnlLine: Record "Gen. Journal Line")
    var
        DimBuf: Record "Dimension Buffer";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        TempDimSetEntry2: Record "Dimension Set Entry" temporary;
        DimVal: Record "Dimension Value";
        NewDimensionID: Integer;
        DimSetIDArr: array[10] of Integer;
    begin
        with GenJnlLine do begin
            NewDimensionID := "Dimension Set ID";
            if SummarizePerEmpl then begin
                DimBuf.Reset();
                DimBuf.DeleteAll();
                DimBufMgt.GetDimensions(TempEmplPaymentBuffer."Dimension Entry No.", DimBuf);
                if DimBuf.FindSet then
                    repeat
                        DimVal.Get(DimBuf."Dimension Code", DimBuf."Dimension Value Code");
                        TempDimSetEntry."Dimension Code" := DimBuf."Dimension Code";
                        TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
                        TempDimSetEntry."Dimension Value Code" := DimBuf."Dimension Value Code";
                        TempDimSetEntry.Insert();
                    until DimBuf.Next = 0;
                NewDimensionID := DimMgt.GetDimensionSetID(TempDimSetEntry);
                "Dimension Set ID" := NewDimensionID;
            end;
            CreateDim(
              DimMgt.TypeToTableID1("Account Type"), "Account No.",
              DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
              DATABASE::Job, "Job No.",
              DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
              DATABASE::Campaign, "Campaign No.");
            if NewDimensionID <> "Dimension Set ID" then begin
                DimSetIDArr[2] := NewDimensionID;
                DimSetIDArr[1] := "Dimension Set ID";
                "Dimension Set ID" :=
                  DimMgt.GetCombinedDimensionSetID(DimSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;

            if SummarizePerEmpl then begin
                DimMgt.GetDimensionSet(TempDimSetEntry, "Dimension Set ID");
                if AdjustAgainstSelectedDim(TempDimSetEntry, TempDimSetEntry2) then
                    "Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry2);
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code",
                  "Shortcut Dimension 2 Code");
            end;
        end;
    end;

    local procedure ShowMessage(Text: Text)
    begin
        if GenJnlLineInserted then begin
            if ShowPostingDateWarning then
                Text += ReplacePostingDateMsg;
            if Text <> '' then
                Message(Text);
        end;
    end;

    local procedure CheckCurrencies(BalAccType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner",Employee; BalAccNo: Code[20])
    var
        BankAcc: Record "Bank Account";
    begin
        if BalAccType = BalAccType::"Bank Account" then
            if BalAccNo <> '' then begin
                BankAcc.Get(BalAccNo);
                if BankAcc."Currency Code" <> '' then
                    Error(UnsupportedCurrencyErr);

                MessageText := EmployeePaymentLinesCreatedTxt;
            end;
    end;

    local procedure ClearNegative()
    var
        TempCurrency: Record Currency temporary;
        TempPayableEmplLedgEntry2: Record "Payable Employee Ledger Entry" temporary;
        CurrencyBalance: Decimal;
    begin
        Clear(TempPayableEmployeeLedgerEntry);
        TempPayableEmployeeLedgerEntry.SetRange("Employee No.", Employee."No.");

        while TempPayableEmployeeLedgerEntry.Next <> 0 do begin
            TempCurrency.Code := TempPayableEmployeeLedgerEntry."Currency Code";
            CurrencyBalance := 0;
            if TempCurrency.Insert() then begin
                TempPayableEmplLedgEntry2 := TempPayableEmployeeLedgerEntry;
                TempPayableEmplLedgEntry2.SetRange("Currency Code", TempPayableEmployeeLedgerEntry."Currency Code");
                repeat
                    CurrencyBalance := CurrencyBalance + TempPayableEmployeeLedgerEntry.Amount
                until TempPayableEmployeeLedgerEntry.Next = 0;
                if CurrencyBalance < 0 then begin
                    TempPayableEmployeeLedgerEntry.DeleteAll();
                    AmountAvailable += CurrencyBalance;
                end;
                TempPayableEmployeeLedgerEntry.SetRange("Currency Code");
                TempPayableEmployeeLedgerEntry := TempPayableEmplLedgEntry2;
            end;
        end;
        TempPayableEmployeeLedgerEntry.Reset();
    end;

    local procedure DimCodeIsInDimBuf(DimCode: Code[20]; DimBuf: Record "Dimension Buffer"): Boolean
    begin
        DimBuf.Reset();
        DimBuf.SetRange("Dimension Code", DimCode);
        exit(not DimBuf.IsEmpty);
    end;

    local procedure RemovePaymentsAboveLimit(var PayableEmplLedgEntry: Record "Payable Employee Ledger Entry"; RemainingAmtAvailable: Decimal)
    begin
        PayableEmplLedgEntry.SetFilter(Amount, '>%1', RemainingAmtAvailable);
        PayableEmplLedgEntry.DeleteAll();
        PayableEmplLedgEntry.SetRange(Amount);
    end;

    local procedure InsertDimBuf(var DimBuf: Record "Dimension Buffer"; TableID: Integer; EntryNo: Integer; DimCode: Code[20]; DimValue: Code[20])
    begin
        DimBuf.Init();
        DimBuf."Table ID" := TableID;
        DimBuf."Entry No." := EntryNo;
        DimBuf."Dimension Code" := DimCode;
        DimBuf."Dimension Value Code" := DimValue;
        DimBuf.Insert();
    end;

    local procedure AdjustAgainstSelectedDim(var TempDimSetEntry: Record "Dimension Set Entry" temporary; var TempDimSetEntry2: Record "Dimension Set Entry" temporary): Boolean
    begin
        if SelectedDim.FindSet then begin
            repeat
                TempDimSetEntry.SetRange("Dimension Code", SelectedDim."Dimension Code");
                if TempDimSetEntry.FindFirst then begin
                    TempDimSetEntry2.TransferFields(TempDimSetEntry, true);
                    TempDimSetEntry2.Insert();
                end;
            until SelectedDim.Next = 0;
            exit(true);
        end;
        exit(false);
    end;

    local procedure SetTempEmplPaymentBufferDims(var DimBuf: Record "Dimension Buffer")
    var
        GLSetup: Record "General Ledger Setup";
        EntryNo: Integer;
    begin
        if SummarizePerDim then begin
            DimBuf.Reset();
            DimBuf.DeleteAll();
            if SelectedDim.Find('-') then
                repeat
                    if DimSetEntry.Get(
                         EmployeeLedgerEntry."Dimension Set ID", SelectedDim."Dimension Code")
                    then
                        InsertDimBuf(DimBuf, DATABASE::"Dimension Buffer", 0, DimSetEntry."Dimension Code",
                          DimSetEntry."Dimension Value Code");
                until SelectedDim.Next = 0;
            EntryNo := DimBufMgt.FindDimensions(DimBuf);
            if EntryNo = 0 then
                EntryNo := DimBufMgt.InsertDimensions(DimBuf);
            TempEmplPaymentBuffer."Dimension Entry No." := EntryNo;
            if TempEmplPaymentBuffer."Dimension Entry No." <> 0 then begin
                GLSetup.Get();
                if DimCodeIsInDimBuf(GLSetup."Global Dimension 1 Code", DimBuf) then
                    TempEmplPaymentBuffer."Global Dimension 1 Code" := EmployeeLedgerEntry."Global Dimension 1 Code"
                else
                    TempEmplPaymentBuffer."Global Dimension 1 Code" := '';
                if DimCodeIsInDimBuf(GLSetup."Global Dimension 2 Code", DimBuf) then
                    TempEmplPaymentBuffer."Global Dimension 2 Code" := EmployeeLedgerEntry."Global Dimension 2 Code"
                else
                    TempEmplPaymentBuffer."Global Dimension 2 Code" := '';
            end else begin
                TempEmplPaymentBuffer."Global Dimension 1 Code" := '';
                TempEmplPaymentBuffer."Global Dimension 2 Code" := '';
            end;
            TempEmplPaymentBuffer."Dimension Set ID" := EmployeeLedgerEntry."Dimension Set ID";
        end else begin
            TempEmplPaymentBuffer."Dimension Entry No." := 0;
            TempEmplPaymentBuffer."Global Dimension 1 Code" := '';
            TempEmplPaymentBuffer."Global Dimension 2 Code" := '';
            TempEmplPaymentBuffer."Dimension Set ID" := 0;
        end;
    end;

    local procedure IsEntryAlreadyApplied(GenJnlLine3: Record "Gen. Journal Line"; EmplLedgEntry2: Record "Employee Ledger Entry"): Boolean
    var
        GenJnlLine4: Record "Gen. Journal Line";
    begin
        GenJnlLine4.SetRange("Journal Template Name", GenJnlLine3."Journal Template Name");
        GenJnlLine4.SetRange("Journal Batch Name", GenJnlLine3."Journal Batch Name");
        GenJnlLine4.SetRange("Account Type", GenJnlLine4."Account Type"::Employee);
        GenJnlLine4.SetRange("Account No.", EmplLedgEntry2."Employee No.");
        GenJnlLine4.SetRange("Applies-to Doc. Type", EmplLedgEntry2."Document Type");
        GenJnlLine4.SetRange("Applies-to Doc. No.", EmplLedgEntry2."Document No.");
        exit(not GenJnlLine4.IsEmpty);
    end;

    local procedure SetDefaults()
    begin
        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        GenJnlLine2."Bal. Account Type" := GenJnlBatch."Bal. Account Type";
        GenJnlLine2."Bal. Account No." := GenJnlBatch."Bal. Account No.";
    end;
}

