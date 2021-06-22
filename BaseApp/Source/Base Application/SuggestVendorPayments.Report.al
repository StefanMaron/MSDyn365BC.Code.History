report 393 "Suggest Vendor Payments"
{
    Caption = 'Suggest Vendor Payments';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = SORTING(Blocked) WHERE(Blocked = FILTER(= " "));
            RequestFilterFields = "No.", "Payment Method Code";

            trigger OnAfterGetRecord()
            begin
                Clear(VendorBalance);
                CalcFields("Balance (LCY)");
                VendorBalance := "Balance (LCY)";

                if StopPayments then
                    CurrReport.Break;
                Window.Update(1, "No.");
                if VendorBalance > 0 then begin
                    GetVendLedgEntries(true, false);
                    GetVendLedgEntries(false, false);
                    CheckAmounts(false);
                    ClearNegative;
                end;
            end;

            trigger OnPostDataItem()
            begin
                if UsePriority and not StopPayments then begin
                    Reset;
                    CopyFilters(Vend2);
                    SetCurrentKey(Priority);
                    SetRange(Priority, 0);
                    if FindSet then
                        repeat
                            Clear(VendorBalance);
                            CalcFields("Balance (LCY)");
                            VendorBalance := "Balance (LCY)";
                            if VendorBalance > 0 then begin
                                Window.Update(1, "No.");
                                GetVendLedgEntries(true, false);
                                GetVendLedgEntries(false, false);
                                CheckAmounts(false);
                                ClearNegative;
                            end;
                        until (Next = 0) or StopPayments;
                end;

                if UsePaymentDisc and not StopPayments then begin
                    Reset;
                    CopyFilters(Vend2);
                    Window2.Open(Text007);
                    if FindSet then
                        repeat
                            Clear(VendorBalance);
                            CalcFields("Balance (LCY)");
                            VendorBalance := "Balance (LCY)";
                            Window2.Update(1, "No.");
                            PayableVendLedgEntry.SetRange("Vendor No.", "No.");
                            if VendorBalance > 0 then begin
                                GetVendLedgEntries(true, true);
                                GetVendLedgEntries(false, true);
                                CheckAmounts(true);
                                ClearNegative;
                            end;
                        until (Next = 0) or StopPayments;
                    Window2.Close;
                end else
                    if FindSet then
                        repeat
                            ClearNegative;
                        until Next = 0;

                DimSetEntry.LockTable;
                GenJnlLine.LockTable;
                GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
                GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
                if GenJnlLine.FindLast then begin
                    LastLineNo := GenJnlLine."Line No.";
                    GenJnlLine.Init;
                end;

                Window2.Open(Text008);

                PayableVendLedgEntry.Reset;
                PayableVendLedgEntry.SetRange(Priority, 1, 2147483647);
                MakeGenJnlLines;
                PayableVendLedgEntry.Reset;
                PayableVendLedgEntry.SetRange(Priority, 0);
                MakeGenJnlLines;
                PayableVendLedgEntry.Reset;
                PayableVendLedgEntry.DeleteAll;

                Window2.Close;
                Window.Close;
                ShowMessage(MessageText);
            end;

            trigger OnPreDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if LastDueDateToPayReq = 0D then
                    Error(Text000);
                if (PostingDate = 0D) and (not UseDueDateAsPostingDate) then
                    Error(Text001);

                BankPmtType := GenJnlLine2."Bank Payment Type";
                BalAccType := GenJnlLine2."Bal. Account Type";
                BalAccNo := GenJnlLine2."Bal. Account No.";
                GenJnlLineInserted := false;
                SeveralCurrencies := false;
                MessageText := '';

                if ((BankPmtType = GenJnlLine2."Bank Payment Type"::" ") or
                    SummarizePerVend) and
                   (NextDocNo = '')
                then
                    Error(Text002);

                if ((BankPmtType = GenJnlLine2."Bank Payment Type"::"Manual Check") and
                    not SummarizePerVend and
                    not DocNoPerLine)
                then
                    Error(Text017, GenJnlLine2.FieldCaption("Bank Payment Type"), Format(GenJnlLine2."Bank Payment Type"::"Manual Check"));

                if UsePaymentDisc and (LastDueDateToPayReq < WorkDate) then
                    if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text003, WorkDate), true) then
                        Error(Text005);

                Vend2.CopyFilters(Vendor);

                OriginalAmtAvailable := AmountAvailable;
                if UsePriority then begin
                    SetCurrentKey(Priority);
                    SetRange(Priority, 1, 2147483647);
                    UsePriority := true;
                end;
                Window.Open(Text006);

                SelectedDim.SetRange("User ID", UserId);
                SelectedDim.SetRange("Object Type", 3);
                SelectedDim.SetRange("Object ID", REPORT::"Suggest Vendor Payments");
                SummarizePerDim := (not SelectedDim.IsEmpty) and SummarizePerVend;

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
                        field(LastPaymentDate; LastDueDateToPayReq)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Last Payment Date';
                            ToolTip = 'Specifies the latest payment date that can appear on the vendor ledger entries to be included in the batch job. Only entries that have a due date or a payment discount date before or on this date will be included. If the payment date is earlier than the system date, a warning will be displayed.';
                        }
                        field(FindPaymentDiscounts; UsePaymentDisc)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Find Payment Discounts';
                            Importance = Additional;
                            MultiLine = true;
                            ToolTip = 'Specifies if you want the batch job to include vendor ledger entries for which you can receive a payment discount.';

                            trigger OnValidate()
                            begin
                                if UsePaymentDisc and UseDueDateAsPostingDate then
                                    Error(PmtDiscUnavailableErr);
                            end;
                        }
                        field(UseVendorPriority; UsePriority)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Use Vendor Priority';
                            Importance = Additional;
                            ToolTip = 'Specifies if the Priority field on the vendor cards will determine in which order vendor entries are suggested for payment by the batch job. The batch job always prioritizes vendors for payment suggestions if you specify an available amount in the Available Amount (LCY) field.';

                            trigger OnValidate()
                            begin
                                if not UsePriority and (AmountAvailable <> 0) then
                                    Error(Text011);
                            end;
                        }
                        field("Available Amount (LCY)"; AmountAvailable)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Available Amount (LCY)';
                            Importance = Additional;
                            ToolTip = 'Specifies a maximum amount (in LCY) that is available for payments. The batch job will then create a payment suggestion on the basis of this amount and the Use Vendor Priority check box. It will only include vendor entries that can be paid fully.';

                            trigger OnValidate()
                            begin
                                if AmountAvailable <> 0 then
                                    UsePriority := true;
                            end;
                        }
                        field(SkipExportedPayments; SkipExportedPayments)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Skip Exported Payments';
                            Importance = Additional;
                            ToolTip = 'Specifies if you do not want the batch job to insert payment journal lines for documents for which payments have already been exported to a bank file.';
                        }
                        field(CheckOtherJournalBatches; CheckOtherJournalBatches)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Check Other Journal Batches';
                            ToolTip = 'Specifies whether to exclude payments that are already included in another journal batch from new suggested payments. This helps avoid duplicate payments.';
                        }
                    }
                    group("Summarize Results")
                    {
                        Caption = 'Summarize Results';
                        field(SummarizePerVendor; SummarizePerVend)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Summarize per Vendor';
                            ToolTip = 'Specifies if you want the batch job to make one line per vendor for each currency in which the vendor has ledger entries. If, for example, a vendor uses two currencies, the batch job will create two lines in the payment journal for this vendor. The batch job then uses the Applies-to ID field when the journal lines are posted to apply the lines to vendor ledger entries. If you do not select this check box, then the batch job will make one line per invoice.';

                            trigger OnValidate()
                            begin
                                if SummarizePerVend and UseDueDateAsPostingDate then
                                    Error(PmtDiscUnavailableErr);
                            end;
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
                                DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Suggest Vendor Payments", SummarizePerDimText);
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
                            Editable = UseDueDateAsPostingDate = FALSE;
                            Importance = Promoted;
                            ToolTip = 'Specifies the date for the posting of this batch job. By default, the working date is entered, but you can change it.';

                            trigger OnValidate()
                            begin
                                ValidatePostingDate;
                            end;
                        }
                        field(UseDueDateAsPostingDate; UseDueDateAsPostingDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Calculate Posting Date from Applies-to-Doc. Due Date';
                            Importance = Additional;
                            ToolTip = 'Specifies if the due date on the purchase invoice will be used as a basis to calculate the payment posting date.';

                            trigger OnValidate()
                            begin
                                if UseDueDateAsPostingDate and (SummarizePerVend or UsePaymentDisc) then
                                    Error(PmtDiscUnavailableErr);
                                if not UseDueDateAsPostingDate then
                                    Clear(DueDateOffset);
                            end;
                        }
                        field(DueDateOffset; DueDateOffset)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Applies-to-Doc. Due Date Offset';
                            Editable = UseDueDateAsPostingDate;
                            Enabled = UseDueDateAsPostingDate;
                            Importance = Additional;
                            ToolTip = 'Specifies a period of time that will separate the payment posting date from the due date on the invoice. Example 1: To pay the invoice on the Friday in the week of the due date, enter CW-2D (current week minus two days). Example 2: To pay the invoice two days before the due date, enter -2D (minus two days).';
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

                            trigger OnValidate()
                            begin
                                if not UsePriority and (AmountAvailable <> 0) then
                                    Error(Text013);
                            end;
                        }
                        field(BalAccountType; GenJnlLine2."Bal. Account Type")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Bal. Account Type';
                            Importance = Additional;
                            OptionCaption = 'G/L Account,,,Bank Account';
                            ToolTip = 'Specifies the balancing account type that payments on the payment journal are posted to.';

                            trigger OnValidate()
                            begin
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
                                    GenJnlLine2."Bal. Account Type"::Customer, GenJnlLine2."Bal. Account Type"::Vendor:
                                        Error(Text009, GenJnlLine2.FieldCaption("Bal. Account Type"));
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
                                        GenJnlLine2."Bal. Account Type"::Customer, GenJnlLine2."Bal. Account Type"::Vendor:
                                            Error(Text009, GenJnlLine2.FieldCaption("Bal. Account Type"));
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
                                    Error(
                                      Text010,
                                      GenJnlLine2.FieldCaption("Bank Payment Type"),
                                      GenJnlLine2.FieldCaption("Bal. Account Type"));
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
            if LastDueDateToPayReq = 0D then
                LastDueDateToPayReq := WorkDate;
            if PostingDate = 0D then
                PostingDate := WorkDate;
            ValidatePostingDate;
            SetDefaults;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if EnvironmentInfo.IsSaaS then
            CheckOtherJournalBatches := true;
    end;

    trigger OnPostReport()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Commit;
        if not VendorLedgEntryTemp.IsEmpty then
            if ConfirmManagement.GetResponse(Text024, true) then
                PAGE.RunModal(0, VendorLedgEntryTemp);

        if CheckOtherJournalBatches then
            if not TempErrorMessage.IsEmpty then
                if ConfirmManagement.GetResponse(ReviewNotSuggestedLinesQst, true) then
                    TempErrorMessage.ShowErrorMessages(false);
    end;

    trigger OnPreReport()
    begin
        CompanyInformation.Get;
        VendorLedgEntryTemp.DeleteAll;
        ShowPostingDateWarning := false;
    end;

    var
        Text000: Label 'In the Last Payment Date field, specify the last possible date that payments must be made.';
        Text001: Label 'In the Posting Date field, specify the date that will be used as the posting date for the journal entries.';
        Text002: Label 'In the Starting Document No. field, specify the first document number to be used.';
        Text003: Label 'The payment date is earlier than %1.\\Do you still want to run the batch job?', Comment = '%1 is a date';
        Text005: Label 'The batch job was interrupted.';
        Text006: Label 'Processing vendors     #1##########';
        Text007: Label 'Processing vendors for payment discounts #1##########';
        Text008: Label 'Inserting payment journal lines #1##########';
        Text009: Label '%1 must be G/L Account or Bank Account.';
        Text010: Label '%1 must be filled only when %2 is Bank Account.';
        Text011: Label 'Use Vendor Priority must be activated when the value in the Amount Available field is not 0.';
        Text013: Label 'Use Vendor Priority must be activated when the value in the Amount Available Amount (LCY) field is not 0.';
        Text017: Label 'If %1 = %2 and you have not selected the Summarize per Vendor field,\ then you must select the New Doc. No. per Line.', Comment = 'If Bank Payment Type = Computer Check and you have not selected the Summarize per Vendor field,\ then you must select the New Doc. No. per Line.';
        Text020: Label 'You have only created suggested vendor payment lines for the %1 %2.\ However, there are other open vendor ledger entries in currencies other than %2.\\', Comment = 'You have only created suggested vendor payment lines for the Currency Code EUR.\ However, there are other open vendor ledger entries in currencies other than EUR.';
        Text021: Label 'You have only created suggested vendor payment lines for the %1 %2.\ There are no other open vendor ledger entries in other currencies.\\', Comment = 'You have only created suggested vendor payment lines for the Currency Code EUR\ There are no other open vendor ledger entries in other currencies.\\';
        Text022: Label 'You have created suggested vendor payment lines for all currencies.\\';
        Vend2: Record Vendor;
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        DimSetEntry: Record "Dimension Set Entry";
        GenJnlLine2: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLAcc: Record "G/L Account";
        BankAcc: Record "Bank Account";
        PayableVendLedgEntry: Record "Payable Vendor Ledger Entry" temporary;
        CompanyInformation: Record "Company Information";
        TempPaymentBuffer: Record "Payment Buffer" temporary;
        OldTempPaymentBuffer: Record "Payment Buffer" temporary;
        SelectedDim: Record "Selected Dimension";
        VendorLedgEntryTemp: Record "Vendor Ledger Entry" temporary;
        TempErrorMessage: Record "Error Message" temporary;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        Window: Dialog;
        Window2: Dialog;
        UsePaymentDisc: Boolean;
        PostingDate: Date;
        LastDueDateToPayReq: Date;
        NextDocNo: Code[20];
        AmountAvailable: Decimal;
        OriginalAmtAvailable: Decimal;
        UsePriority: Boolean;
        SummarizePerVend: Boolean;
        SummarizePerDim: Boolean;
        SummarizePerDimText: Text[250];
        LastLineNo: Integer;
        NextEntryNo: Integer;
        DueDateOffset: DateFormula;
        UseDueDateAsPostingDate: Boolean;
        StopPayments: Boolean;
        DocNoPerLine: Boolean;
        BankPmtType: Option;
        BalAccType: Option "G/L Account",Customer,Vendor,"Bank Account";
        BalAccNo: Code[20];
        MessageText: Text;
        GenJnlLineInserted: Boolean;
        SeveralCurrencies: Boolean;
        Text024: Label 'There are one or more entries for which no payment suggestions have been made because the posting dates of the entries are later than the requested posting date. Do you want to see the entries?';
        [InDataSet]
        SummarizePerDimTextEnable: Boolean;
        Text025: Label 'The %1 with the number %2 has a %3 with the number %4.';
        ShowPostingDateWarning: Boolean;
        VendorBalance: Decimal;
        ReplacePostingDateMsg: Label 'For one or more entries, the requested posting date is before the work date.\\These posting dates will use the work date.';
        PmtDiscUnavailableErr: Label 'You cannot use Find Payment Discounts or Summarize per Vendor together with Calculate Posting Date from Applies-to-Doc. Due Date, because the resulting posting date might not match the payment discount date.';
        SkipExportedPayments: Boolean;
        MessageToRecipientMsg: Label 'Payment of %1 %2 ', Comment = '%1 document type, %2 Document No.';
        StartingDocumentNoErr: Label 'The value in the Starting Document No. field must have a number so that we can assign the next number in the series.';
        CheckOtherJournalBatches: Boolean;
        ReviewNotSuggestedLinesQst: Label 'There are payments in other journal batches that are not suggested here. This helps avoid duplicate payments. To add them to this batch, remove the payment from the other batch, and then suggest payments again.\\Do you want to review the payments from the other journal batches now?';
        NotSuggestedPaymentInfoTxt: Label 'There are payments in %1 %2, %3 %4, %5 %6', Comment = 'There are payments in Journal Template Name PAYMENT, Journal Batch Name GENERAL, Applies-to Doc. No. 101321';

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

    procedure InitializeRequest(LastPmtDate: Date; FindPmtDisc: Boolean; NewAvailableAmount: Decimal; NewSkipExportedPayments: Boolean; NewPostingDate: Date; NewStartDocNo: Code[20]; NewSummarizePerVend: Boolean; BalAccType: Option "G/L Account",Customer,Vendor,"Bank Account"; BalAccNo: Code[20]; BankPmtType: Option)
    begin
        LastDueDateToPayReq := LastPmtDate;
        UsePaymentDisc := FindPmtDisc;
        AmountAvailable := NewAvailableAmount;
        SkipExportedPayments := NewSkipExportedPayments;
        PostingDate := NewPostingDate;
        NextDocNo := NewStartDocNo;
        SummarizePerVend := NewSummarizePerVend;
        GenJnlLine2."Bal. Account Type" := BalAccType;
        GenJnlLine2."Bal. Account No." := BalAccNo;
        GenJnlLine2."Bank Payment Type" := BankPmtType;
    end;

    local procedure GetVendLedgEntries(Positive: Boolean; Future: Boolean)
    var
        IsHandled: Boolean;
    begin
        VendLedgEntry.Reset;
        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetRange(Positive, Positive);
        VendLedgEntry.SetRange("Applies-to ID", '');
        if Future then begin
            VendLedgEntry.SetRange("Due Date", LastDueDateToPayReq + 1, DMY2Date(31, 12, 9999));
            VendLedgEntry.SetRange("Pmt. Discount Date", PostingDate, LastDueDateToPayReq);
            VendLedgEntry.SetFilter("Remaining Pmt. Disc. Possible", '<>0');
        end else
            VendLedgEntry.SetRange("Due Date", 0D, LastDueDateToPayReq);
        if SkipExportedPayments then
            VendLedgEntry.SetRange("Exported to Payment File", false);
        VendLedgEntry.SetRange("On Hold", '');
        VendLedgEntry.SetFilter("Currency Code", Vendor.GetFilter("Currency Filter"));
        VendLedgEntry.SetFilter("Global Dimension 1 Code", Vendor.GetFilter("Global Dimension 1 Filter"));
        VendLedgEntry.SetFilter("Global Dimension 2 Code", Vendor.GetFilter("Global Dimension 2 Filter"));

        if VendLedgEntry.FindSet then
            repeat
                IsHandled := false;
                OnGetVendLedgEntriesOnBeforeLoop(VendLedgEntry, PostingDate, LastDueDateToPayReq, Future, IsHandled);
                if not IsHandled then begin
                    SaveAmount;
                    if VendLedgEntry."Accepted Pmt. Disc. Tolerance" or (VendLedgEntry."Accepted Payment Tolerance" <> 0) then begin
                        VendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                        VendLedgEntry."Accepted Payment Tolerance" := 0;
                        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
                    end;
                end;
            until VendLedgEntry.Next = 0;
    end;

    local procedure SaveAmount()
    var
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
    begin
        with GenJnlLine do begin
            Init;
            SetPostingDate(GenJnlLine, VendLedgEntry."Due Date", PostingDate);
            "Document Type" := "Document Type"::Payment;
            "Account Type" := "Account Type"::Vendor;
            Vend2.Get(VendLedgEntry."Vendor No.");
            Vend2.CheckBlockedVendOnJnls(Vend2, "Document Type", false);
            Description := Vend2.Name;
            "Posting Group" := Vend2."Vendor Posting Group";
            "Salespers./Purch. Code" := Vend2."Purchaser Code";
            "Payment Terms Code" := Vend2."Payment Terms Code";
            Validate("Bill-to/Pay-to No.", "Account No.");
            Validate("Sell-to/Buy-from No.", "Account No.");
            "Gen. Posting Type" := 0;
            "Gen. Bus. Posting Group" := '';
            "Gen. Prod. Posting Group" := '';
            "VAT Bus. Posting Group" := '';
            "VAT Prod. Posting Group" := '';
            Validate("Currency Code", VendLedgEntry."Currency Code");
            Validate("Payment Terms Code");
            VendLedgEntry.CalcFields("Remaining Amount");
            if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlVend(GenJnlLine, VendLedgEntry, 0, false) then
                Amount := -(VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible")
            else
                Amount := -VendLedgEntry."Remaining Amount";
            Validate(Amount);
        end;

        if UsePriority then
            PayableVendLedgEntry.Priority := Vendor.Priority
        else
            PayableVendLedgEntry.Priority := 0;
        PayableVendLedgEntry."Vendor No." := VendLedgEntry."Vendor No.";
        PayableVendLedgEntry."Entry No." := NextEntryNo;
        PayableVendLedgEntry."Vendor Ledg. Entry No." := VendLedgEntry."Entry No.";
        PayableVendLedgEntry.Amount := GenJnlLine.Amount;
        PayableVendLedgEntry."Amount (LCY)" := GenJnlLine."Amount (LCY)";
        PayableVendLedgEntry.Positive := (PayableVendLedgEntry.Amount > 0);
        PayableVendLedgEntry.Future := (VendLedgEntry."Due Date" > LastDueDateToPayReq);
        PayableVendLedgEntry."Currency Code" := VendLedgEntry."Currency Code";
        PayableVendLedgEntry.Insert;
        NextEntryNo := NextEntryNo + 1;
    end;

    local procedure CheckAmounts(Future: Boolean)
    var
        CurrencyBalance: Decimal;
        PrevCurrency: Code[10];
    begin
        PayableVendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        PayableVendLedgEntry.SetRange(Future, Future);

        if PayableVendLedgEntry.FindSet then begin
            repeat
                if PayableVendLedgEntry."Currency Code" <> PrevCurrency then begin
                    if CurrencyBalance > 0 then
                        AmountAvailable := AmountAvailable - CurrencyBalance;
                    CurrencyBalance := 0;
                    PrevCurrency := PayableVendLedgEntry."Currency Code";
                end;
                if (OriginalAmtAvailable = 0) or
                   (AmountAvailable >= CurrencyBalance + PayableVendLedgEntry."Amount (LCY)")
                then
                    CurrencyBalance := CurrencyBalance + PayableVendLedgEntry."Amount (LCY)"
                else
                    PayableVendLedgEntry.Delete;
            until PayableVendLedgEntry.Next = 0;
            if OriginalAmtAvailable > 0 then
                AmountAvailable := AmountAvailable - CurrencyBalance;
            if (OriginalAmtAvailable > 0) and (AmountAvailable <= 0) then
                StopPayments := true;
        end;
        PayableVendLedgEntry.Reset;
    end;

    local procedure MakeGenJnlLines()
    var
        GenJnlLine1: Record "Gen. Journal Line";
        DimBuf: Record "Dimension Buffer";
        RemainingAmtAvailable: Decimal;
        HandledEntry: Boolean;
    begin
        TempPaymentBuffer.Reset;
        TempPaymentBuffer.DeleteAll;

        if BalAccType = BalAccType::"Bank Account" then begin
            CheckCurrencies(BalAccType, BalAccNo, PayableVendLedgEntry);
            SetBankAccCurrencyFilter(BalAccType, BalAccNo, PayableVendLedgEntry);
        end;

        if OriginalAmtAvailable <> 0 then begin
            RemainingAmtAvailable := OriginalAmtAvailable;
            RemovePaymentsAboveLimit(PayableVendLedgEntry, RemainingAmtAvailable);
        end;
        if PayableVendLedgEntry.Find('-') then
            repeat
                PayableVendLedgEntry.SetRange("Vendor No.", PayableVendLedgEntry."Vendor No.");
                PayableVendLedgEntry.Find('-');
                repeat
                    VendLedgEntry.Get(PayableVendLedgEntry."Vendor Ledg. Entry No.");
                    SetPostingDate(GenJnlLine1, VendLedgEntry."Due Date", PostingDate);
                    HandledEntry := VendLedgEntry."Posting Date" <= GenJnlLine1."Posting Date";
                    OnBeforeHandledVendLedgEntry(VendLedgEntry, GenJnlLine1, HandledEntry);
                    if HandledEntry then begin
                        TempPaymentBuffer."Vendor No." := VendLedgEntry."Vendor No.";
                        TempPaymentBuffer."Currency Code" := VendLedgEntry."Currency Code";
                        TempPaymentBuffer."Payment Method Code" := VendLedgEntry."Payment Method Code";

                        TempPaymentBuffer.CopyFieldsFromVendorLedgerEntry(VendLedgEntry);

                        OnUpdateTempBufferFromVendorLedgerEntry(TempPaymentBuffer, VendLedgEntry);

                        SetTempPaymentBufferDims(DimBuf);

                        VendLedgEntry.CalcFields("Remaining Amount");

                        if IsNotAppliedEntry(GenJnlLine, VendLedgEntry) then
                            if SummarizePerVend then begin
                                TempPaymentBuffer."Vendor Ledg. Entry No." := 0;
                                if TempPaymentBuffer.Find then begin
                                    TempPaymentBuffer.Amount := TempPaymentBuffer.Amount + PayableVendLedgEntry.Amount;
                                    TempPaymentBuffer.Modify;
                                end else begin
                                    TempPaymentBuffer."Document No." := NextDocNo;
                                    NextDocNo := IncStr(NextDocNo);
                                    TempPaymentBuffer.Amount := PayableVendLedgEntry.Amount;
                                    Window2.Update(1, VendLedgEntry."Vendor No.");
                                    TempPaymentBuffer.Insert;
                                end;
                                VendLedgEntry."Applies-to ID" := TempPaymentBuffer."Document No.";
                            end else begin
                                TempPaymentBuffer."Vendor Ledg. Entry Doc. Type" := VendLedgEntry."Document Type";
                                TempPaymentBuffer."Vendor Ledg. Entry Doc. No." := VendLedgEntry."Document No.";
                                TempPaymentBuffer."Global Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                                TempPaymentBuffer."Global Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                                TempPaymentBuffer."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                                TempPaymentBuffer."Vendor Ledg. Entry No." := VendLedgEntry."Entry No.";
                                TempPaymentBuffer.Amount := PayableVendLedgEntry.Amount;
                                Window2.Update(1, VendLedgEntry."Vendor No.");
                                TempPaymentBuffer.Insert;
                            end;

                        VendLedgEntry."Amount to Apply" := VendLedgEntry."Remaining Amount";
                        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
                    end else begin
                        VendorLedgEntryTemp := VendLedgEntry;
                        VendorLedgEntryTemp.Insert;
                    end;

                    PayableVendLedgEntry.Delete;
                    if OriginalAmtAvailable <> 0 then begin
                        RemainingAmtAvailable := RemainingAmtAvailable - PayableVendLedgEntry."Amount (LCY)";
                        RemovePaymentsAboveLimit(PayableVendLedgEntry, RemainingAmtAvailable);
                    end;

                until not PayableVendLedgEntry.FindSet;
                PayableVendLedgEntry.DeleteAll;
                PayableVendLedgEntry.SetRange("Vendor No.");
            until not PayableVendLedgEntry.Find('-');

        Clear(OldTempPaymentBuffer);
        TempPaymentBuffer.SetCurrentKey("Document No.");
        TempPaymentBuffer.SetFilter(
          "Vendor Ledg. Entry Doc. Type", '<>%1&<>%2', TempPaymentBuffer."Vendor Ledg. Entry Doc. Type"::Refund,
          TempPaymentBuffer."Vendor Ledg. Entry Doc. Type"::Payment);

        if TempPaymentBuffer.Find('-') then
            repeat
                InsertGenJournalLine;
            until TempPaymentBuffer.Next = 0;
    end;

    local procedure InsertGenJournalLine()
    var
        Vendor: Record Vendor;
    begin
        with GenJnlLine do begin
            Init;
            Window2.Update(1, TempPaymentBuffer."Vendor No.");
            LastLineNo := LastLineNo + 10000;
            "Line No." := LastLineNo;
            "Document Type" := "Document Type"::Payment;
            "Posting No. Series" := GenJnlBatch."Posting No. Series";
            if SummarizePerVend then
                "Document No." := TempPaymentBuffer."Document No."
            else
                if DocNoPerLine then begin
                    if TempPaymentBuffer.Amount < 0 then
                        "Document Type" := "Document Type"::Refund;

                    "Document No." := NextDocNo;
                    NextDocNo := IncStr(NextDocNo);
                end else
                    if (TempPaymentBuffer."Vendor No." = OldTempPaymentBuffer."Vendor No.") and
                       (TempPaymentBuffer."Currency Code" = OldTempPaymentBuffer."Currency Code")
                    then
                        "Document No." := OldTempPaymentBuffer."Document No."
                    else begin
                        "Document No." := NextDocNo;
                        NextDocNo := IncStr(NextDocNo);
                        OldTempPaymentBuffer := TempPaymentBuffer;
                        OldTempPaymentBuffer."Document No." := "Document No.";
                    end;
            "Account Type" := "Account Type"::Vendor;
            SetHideValidation(true);
            ShowPostingDateWarning := ShowPostingDateWarning or
              SetPostingDate(GenJnlLine, GetApplDueDate(TempPaymentBuffer."Vendor Ledg. Entry No."), PostingDate);
            Validate("Account No.", TempPaymentBuffer."Vendor No.");
            Vendor.Get(TempPaymentBuffer."Vendor No.");
            if (Vendor."Pay-to Vendor No." <> '') and (Vendor."Pay-to Vendor No." <> "Account No.") then
                Message(Text025, Vendor.TableCaption, Vendor."No.", Vendor.FieldCaption("Pay-to Vendor No."),
                  Vendor."Pay-to Vendor No.");
            "Bal. Account Type" := BalAccType;
            Validate("Bal. Account No.", BalAccNo);
            Validate("Currency Code", TempPaymentBuffer."Currency Code");
            "Message to Recipient" := GetMessageToRecipient(SummarizePerVend);
            "Bank Payment Type" := BankPmtType;
            if SummarizePerVend then
                "Applies-to ID" := "Document No.";
            Description := Vendor.Name;
            "Source Line No." := TempPaymentBuffer."Vendor Ledg. Entry No.";
            "Shortcut Dimension 1 Code" := TempPaymentBuffer."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := TempPaymentBuffer."Global Dimension 2 Code";
            "Dimension Set ID" := TempPaymentBuffer."Dimension Set ID";
            "Source Code" := GenJnlTemplate."Source Code";
            "Reason Code" := GenJnlBatch."Reason Code";
            Validate(Amount, TempPaymentBuffer.Amount);
            "Applies-to Doc. Type" := TempPaymentBuffer."Vendor Ledg. Entry Doc. Type";
            "Applies-to Doc. No." := TempPaymentBuffer."Vendor Ledg. Entry Doc. No.";
            "Payment Method Code" := TempPaymentBuffer."Payment Method Code";

            TempPaymentBuffer.CopyFieldsToGenJournalLine(GenJnlLine);

            OnBeforeUpdateGnlJnlLineDimensionsFromTempBuffer(GenJnlLine, TempPaymentBuffer);
            UpdateDimensions(GenJnlLine);
            Insert;
            GenJnlLineInserted := true;
        end;
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
            if SummarizePerVend then begin
                DimBuf.Reset;
                DimBuf.DeleteAll;
                DimBufMgt.GetDimensions(TempPaymentBuffer."Dimension Entry No.", DimBuf);
                if DimBuf.FindSet then
                    repeat
                        DimVal.Get(DimBuf."Dimension Code", DimBuf."Dimension Value Code");
                        TempDimSetEntry."Dimension Code" := DimBuf."Dimension Code";
                        TempDimSetEntry."Dimension Value Code" := DimBuf."Dimension Value Code";
                        TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
                        TempDimSetEntry.Insert;
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
                DimSetIDArr[1] := "Dimension Set ID";
                DimSetIDArr[2] := NewDimensionID;
                "Dimension Set ID" :=
                  DimMgt.GetCombinedDimensionSetID(DimSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;

            if SummarizePerVend then begin
                DimMgt.GetDimensionSet(TempDimSetEntry, "Dimension Set ID");
                if AdjustAgainstSelectedDim(TempDimSetEntry, TempDimSetEntry2) then
                    "Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry2);
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code",
                  "Shortcut Dimension 2 Code");
            end;
        end;
    end;

    local procedure SetBankAccCurrencyFilter(BalAccType: Option "G/L Account",Customer,Vendor,"Bank Account"; BalAccNo: Code[20]; var TmpPayableVendLedgEntry: Record "Payable Vendor Ledger Entry")
    var
        BankAcc: Record "Bank Account";
    begin
        if BalAccType = BalAccType::"Bank Account" then
            if BalAccNo <> '' then begin
                BankAcc.Get(BalAccNo);
                if BankAcc."Currency Code" <> '' then
                    TmpPayableVendLedgEntry.SetRange("Currency Code", BankAcc."Currency Code");
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

    local procedure CheckCurrencies(BalAccType: Option "G/L Account",Customer,Vendor,"Bank Account"; BalAccNo: Code[20]; var TmpPayableVendLedgEntry: Record "Payable Vendor Ledger Entry")
    var
        BankAcc: Record "Bank Account";
        TmpPayableVendLedgEntry2: Record "Payable Vendor Ledger Entry" temporary;
    begin
        if BalAccType = BalAccType::"Bank Account" then
            if BalAccNo <> '' then begin
                BankAcc.Get(BalAccNo);
                if BankAcc."Currency Code" <> '' then begin
                    TmpPayableVendLedgEntry2.Reset;
                    TmpPayableVendLedgEntry2.DeleteAll;
                    if TmpPayableVendLedgEntry.FindSet then
                        repeat
                            TmpPayableVendLedgEntry2 := TmpPayableVendLedgEntry;
                            TmpPayableVendLedgEntry2.Insert;
                        until TmpPayableVendLedgEntry.Next = 0;

                    TmpPayableVendLedgEntry2.SetFilter("Currency Code", '<>%1', BankAcc."Currency Code");
                    SeveralCurrencies := SeveralCurrencies or TmpPayableVendLedgEntry2.FindFirst;

                    if SeveralCurrencies then
                        MessageText :=
                          StrSubstNo(Text020, BankAcc.FieldCaption("Currency Code"), BankAcc."Currency Code")
                    else
                        MessageText :=
                          StrSubstNo(Text021, BankAcc.FieldCaption("Currency Code"), BankAcc."Currency Code");
                end else
                    MessageText := Text022;
            end;
    end;

    local procedure ClearNegative()
    var
        TempCurrency: Record Currency temporary;
        PayableVendLedgEntry2: Record "Payable Vendor Ledger Entry" temporary;
        CurrencyBalance: Decimal;
    begin
        Clear(PayableVendLedgEntry);
        PayableVendLedgEntry.SetRange("Vendor No.", Vendor."No.");

        while PayableVendLedgEntry.Next <> 0 do begin
            TempCurrency.Code := PayableVendLedgEntry."Currency Code";
            CurrencyBalance := 0;
            if TempCurrency.Insert then begin
                PayableVendLedgEntry2 := PayableVendLedgEntry;
                PayableVendLedgEntry.SetRange("Currency Code", PayableVendLedgEntry."Currency Code");
                repeat
                    CurrencyBalance := CurrencyBalance + PayableVendLedgEntry."Amount (LCY)"
                until PayableVendLedgEntry.Next = 0;
                if CurrencyBalance < 0 then begin
                    PayableVendLedgEntry.DeleteAll;
                    AmountAvailable += CurrencyBalance;
                end;
                PayableVendLedgEntry.SetRange("Currency Code");
                PayableVendLedgEntry := PayableVendLedgEntry2;
            end;
        end;
        PayableVendLedgEntry.Reset;
    end;

    local procedure DimCodeIsInDimBuf(DimCode: Code[20]; DimBuf: Record "Dimension Buffer"): Boolean
    begin
        DimBuf.Reset;
        DimBuf.SetRange("Dimension Code", DimCode);
        exit(not DimBuf.IsEmpty);
    end;

    local procedure RemovePaymentsAboveLimit(var PayableVendLedgEntry: Record "Payable Vendor Ledger Entry"; RemainingAmtAvailable: Decimal)
    begin
        PayableVendLedgEntry.SetFilter("Amount (LCY)", '>%1', RemainingAmtAvailable);
        PayableVendLedgEntry.DeleteAll;
        PayableVendLedgEntry.SetRange("Amount (LCY)");
    end;

    local procedure InsertDimBuf(var DimBuf: Record "Dimension Buffer"; TableID: Integer; EntryNo: Integer; DimCode: Code[20]; DimValue: Code[20])
    begin
        DimBuf.Init;
        DimBuf."Table ID" := TableID;
        DimBuf."Entry No." := EntryNo;
        DimBuf."Dimension Code" := DimCode;
        DimBuf."Dimension Value Code" := DimValue;
        DimBuf.Insert;
    end;

    local procedure GetMessageToRecipient(SummarizePerVend: Boolean): Text[140]
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if SummarizePerVend then
            exit(CompanyInformation.Name);

        VendorLedgerEntry.Get(TempPaymentBuffer."Vendor Ledg. Entry No.");
        if VendorLedgerEntry."Message to Recipient" <> '' then
            exit(VendorLedgerEntry."Message to Recipient");

        exit(
          StrSubstNo(
            MessageToRecipientMsg,
            TempPaymentBuffer."Vendor Ledg. Entry Doc. Type",
            TempPaymentBuffer."Applies-to Ext. Doc. No."));
    end;

    local procedure SetPostingDate(var GenJnlLine: Record "Gen. Journal Line"; DueDate: Date; PostingDate: Date): Boolean
    begin
        if not UseDueDateAsPostingDate then begin
            GenJnlLine.Validate("Posting Date", PostingDate);
            exit(false);
        end;

        if DueDate = 0D then
            DueDate := GenJnlLine.GetAppliesToDocDueDate;
        exit(GenJnlLine.SetPostingDateAsDueDate(DueDate, DueDateOffset));
    end;

    local procedure GetApplDueDate(VendLedgEntryNo: Integer): Date
    var
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if AppliedVendLedgEntry.Get(VendLedgEntryNo) then
            exit(AppliedVendLedgEntry."Due Date");

        exit(PostingDate);
    end;

    local procedure AdjustAgainstSelectedDim(var TempDimSetEntry: Record "Dimension Set Entry" temporary; var TempDimSetEntry2: Record "Dimension Set Entry" temporary): Boolean
    begin
        if SelectedDim.FindSet then begin
            repeat
                TempDimSetEntry.SetRange("Dimension Code", SelectedDim."Dimension Code");
                if TempDimSetEntry.FindFirst then begin
                    TempDimSetEntry2.TransferFields(TempDimSetEntry, true);
                    TempDimSetEntry2.Insert;
                end;
            until SelectedDim.Next = 0;
            exit(true);
        end;
        exit(false);
    end;

    local procedure SetTempPaymentBufferDims(var DimBuf: Record "Dimension Buffer")
    var
        GLSetup: Record "General Ledger Setup";
        EntryNo: Integer;
    begin
        if SummarizePerDim then begin
            DimBuf.Reset;
            DimBuf.DeleteAll;
            if SelectedDim.FindSet then
                repeat
                    if DimSetEntry.Get(VendLedgEntry."Dimension Set ID", SelectedDim."Dimension Code") then
                        InsertDimBuf(DimBuf, DATABASE::"Dimension Buffer", 0, DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                until SelectedDim.Next = 0;
            EntryNo := DimBufMgt.FindDimensions(DimBuf);
            if EntryNo = 0 then
                EntryNo := DimBufMgt.InsertDimensions(DimBuf);
            TempPaymentBuffer."Dimension Entry No." := EntryNo;
            if TempPaymentBuffer."Dimension Entry No." <> 0 then begin
                GLSetup.Get;
                if DimCodeIsInDimBuf(GLSetup."Global Dimension 1 Code", DimBuf) then
                    TempPaymentBuffer."Global Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code"
                else
                    TempPaymentBuffer."Global Dimension 1 Code" := '';
                if DimCodeIsInDimBuf(GLSetup."Global Dimension 2 Code", DimBuf) then
                    TempPaymentBuffer."Global Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code"
                else
                    TempPaymentBuffer."Global Dimension 2 Code" := '';
            end else begin
                TempPaymentBuffer."Global Dimension 1 Code" := '';
                TempPaymentBuffer."Global Dimension 2 Code" := '';
            end;
            TempPaymentBuffer."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
        end else begin
            TempPaymentBuffer."Dimension Entry No." := 0;
            TempPaymentBuffer."Global Dimension 1 Code" := '';
            TempPaymentBuffer."Global Dimension 2 Code" := '';
            TempPaymentBuffer."Dimension Set ID" := 0;
        end;
    end;

    local procedure IsNotAppliedEntry(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    begin
        exit(
          IsNotAppliedToCurrentBatchLine(GenJournalLine, VendorLedgerEntry) and
          IsNotAppliedToOtherBatchLine(GenJournalLine, VendorLedgerEntry));
    end;

    local procedure IsNotAppliedToCurrentBatchLine(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    var
        PaymentGenJournalLine: Record "Gen. Journal Line";
    begin
        with PaymentGenJournalLine do begin
            SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
            SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
            SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
            SetRange("Account No.", VendorLedgerEntry."Vendor No.");
            SetRange("Applies-to Doc. Type", VendorLedgerEntry."Document Type");
            SetRange("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
            exit(IsEmpty);
        end;
    end;

    local procedure IsNotAppliedToOtherBatchLine(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    var
        PaymentGenJournalLine: Record "Gen. Journal Line";
    begin
        if not CheckOtherJournalBatches then
            exit(true);

        with PaymentGenJournalLine do begin
            SetRange("Document Type", "Document Type"::Payment);
            SetRange("Account Type", "Account Type"::Vendor);
            SetRange("Account No.", VendorLedgerEntry."Vendor No.");
            SetRange("Applies-to Doc. Type", VendorLedgerEntry."Document Type");
            SetRange("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
            if IsEmpty then
                exit(true);

            if FindSet then begin
                repeat
                    if ("Journal Batch Name" <> GenJournalLine."Journal Batch Name") or
                       ("Journal Template Name" <> GenJournalLine."Journal Template Name")
                    then
                        LogNotSuggestedPaymentMessage(PaymentGenJournalLine);
                until Next = 0;
                exit(TempErrorMessage.IsEmpty);
            end;
        end;
    end;

    local procedure LogNotSuggestedPaymentMessage(GenJournalLine: Record "Gen. Journal Line")
    begin
        TempErrorMessage.LogMessage(
          GenJournalLine, GenJournalLine.FieldNo("Applies-to ID"),
          TempErrorMessage."Message Type"::Warning,
          StrSubstNo(
            NotSuggestedPaymentInfoTxt,
            GenJournalLine.FieldCaption("Journal Template Name"),
            GenJournalLine."Journal Template Name",
            GenJournalLine.FieldCaption("Journal Batch Name"),
            GenJournalLine."Journal Batch Name",
            GenJournalLine.FieldCaption("Applies-to Doc. No."),
            GenJournalLine."Applies-to Doc. No."));
    end;

    local procedure SetDefaults()
    begin
        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        if GenJnlBatch."Bal. Account No." <> '' then begin
            GenJnlLine2."Bal. Account Type" := GenJnlBatch."Bal. Account Type";
            GenJnlLine2."Bal. Account No." := GenJnlBatch."Bal. Account No.";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTempBufferFromVendorLedgerEntry(var TempPaymentBuffer: Record "Payment Buffer" temporary; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandledVendLedgEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var HandledEntry: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateGnlJnlLineDimensionsFromTempBuffer(var GenJournalLine: Record "Gen. Journal Line"; TempPaymentBuffer: Record "Payment Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVendLedgEntriesOnBeforeLoop(var VendorLedgerEntry: Record "Vendor Ledger Entry"; PostingDate: Date; LastDueDateToPayReq: Date; Future: Boolean; var IsHandled: Boolean)
    begin
    end;
}

