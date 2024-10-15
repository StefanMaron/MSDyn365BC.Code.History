#if not CLEAN19
report 11700 "Suggest Payments"
{
    Caption = 'Suggest Payments (Obsolete)';
    Permissions = TableData "Bank Statement Line" = im;
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    dataset
    {
        dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
        {
            DataItemTableView = SORTING(Open, "Due Date") WHERE(Open = CONST(true), "On Hold" = CONST(''));

            trigger OnAfterGetRecord()
            begin
                if TypeCustomer = TypeCustomer::OnlyBalance then
                    if CustomerBalanceTest("Customer No.") then
                        CurrReport.Skip();
                if SkipBlocked and CustomerBlockedTest("Customer No.") then begin
                    IsSkippedBlockedCustomer := true;
                    CurrReport.Skip();
                end;

                AddCustLedgEntry("Cust. Ledger Entry");
                if StopPayments then
                    CurrReport.Break();

                Window.Update(1, "Entry No.");
            end;

            trigger OnPostDataItem()
            begin
                if DialogOpen then begin
                    Clear(DialogOpen);
                    Window.Close();
                end;
            end;

            trigger OnPreDataItem()
            begin
                if TypeCustomer = TypeCustomer::Nothing then
                    CurrReport.Break();

                if TypeCustomer <> TypeCustomer::All then
                    SetRange("Document Type", "Document Type"::"Credit Memo");
                SetRange("Due Date", 0D, LastDueDateToPayReq);

                if KeepCurrency then
                    case Currency of
                        Currency::"Payment Order":
                            SetRange("Currency Code", PmtOrdHdr."Payment Order Currency Code");
                        Currency::"Bank Account":
                            SetRange("Currency Code", PmtOrdHdr."Currency Code");
                    end;

                Window.Open(CustEntriesMsg);
                DialogOpen := true;
            end;
        }
        dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
        {
            DataItemTableView = SORTING(Open, "Due Date") WHERE(Open = CONST(true), "On Hold" = CONST(''));

            trigger OnAfterGetRecord()
            begin
                if TypeVendor = TypeVendor::OnlyBalance then
                    if VendorBalanceTest("Vendor No.") then
                        CurrReport.Skip();
                if SkipBlocked and VendorBlockedTest("Vendor No.") then begin
                    IsSkippedBlockedVendor := true;
                    CurrReport.Skip();
                end;

                AddVendLedgEntry("Vendor Ledger Entry");
                if StopPayments then
                    CurrReport.Break();

                Window.Update(1, "Entry No.");
            end;

            trigger OnPostDataItem()
            begin
                if DialogOpen then begin
                    Clear(DialogOpen);
                    Window.Close();
                end;
            end;

            trigger OnPreDataItem()
            begin
                if TypeVendor = TypeVendor::Nothing then
                    CurrReport.Break();
                if StopPayments then
                    CurrReport.Break();

                if TypeVendor <> TypeVendor::All then
                    SetRange("Document Type", "Document Type"::Invoice);
                SetRange("Due Date", 0D, LastDueDateToPayReq);

                if KeepCurrency then
                    case Currency of
                        Currency::"Payment Order":
                            SetRange("Currency Code", PmtOrdHdr."Payment Order Currency Code");
                        Currency::"Bank Account":
                            SetRange("Currency Code", PmtOrdHdr."Currency Code");
                    end;

                Window.Open(VendEntriesMsg);
                DialogOpen := true;
            end;
        }
        dataitem("Vendor Ledger Entry Disc"; "Vendor Ledger Entry")
        {
            DataItemTableView = SORTING(Open, "Due Date") WHERE(Open = CONST(true), "On Hold" = CONST(''));

            trigger OnAfterGetRecord()
            begin
                if TypeVendor = TypeVendor::OnlyBalance then
                    if VendorBalanceTest("Vendor No.") then
                        CurrReport.Skip();
                if SkipBlocked and VendorBlockedTest("Vendor No.") then begin
                    IsSkippedBlockedVendor := true;
                    CurrReport.Skip();
                end;

                AddVendLedgEntry("Vendor Ledger Entry Disc");
                if StopPayments then
                    CurrReport.Break();

                Window.Update(1, "Entry No.");
            end;

            trigger OnPostDataItem()
            begin
                if DialogOpen then begin
                    Clear(DialogOpen);
                    Window.Close();
                end;
            end;

            trigger OnPreDataItem()
            begin
                if TypeVendor = TypeVendor::Nothing then
                    CurrReport.Break();
                if not UsePaymentDisc then
                    CurrReport.Break();
                if StopPayments then
                    CurrReport.Break();

                if TypeVendor <> TypeVendor::All then
                    SetRange("Document Type", "Document Type"::Invoice);
                SetRange("Due Date", LastDueDateToPayReq + 1, DMY2Date(31, 12, 9999));
                SetRange("Pmt. Discount Date", PmtOrdHdr."Document Date", LastDueDateToPayReq);
                SetFilter("Remaining Pmt. Disc. Possible", '<0');

                if KeepCurrency then
                    case Currency of
                        Currency::"Payment Order":
                            SetRange("Currency Code", PmtOrdHdr."Payment Order Currency Code");
                        Currency::"Bank Account":
                            SetRange("Currency Code", PmtOrdHdr."Currency Code");
                    end;

                Window.Open(VendDiscEntriesMsg);
                DialogOpen := true;
            end;
        }
        dataitem("Employee Ledger Entry"; "Employee Ledger Entry")
        {
            DataItemTableView = SORTING("Entry No.") WHERE(Open = CONST(true));

            trigger OnAfterGetRecord()
            begin
                AddEmplLedgEntry("Employee Ledger Entry");
                if StopPayments then
                    CurrReport.Break();

                Window.Update(1, "Entry No.");
            end;

            trigger OnPostDataItem()
            begin
                if DialogOpen then begin
                    Clear(DialogOpen);
                    Window.Close();
                end;
            end;

            trigger OnPreDataItem()
            begin
                if TypeEmployee = TypeEmployee::Nothing then
                    CurrReport.Break();
                if StopPayments then
                    CurrReport.Break();
                if PmtOrdHdr."Currency Code" <> '' then
                    CurrReport.Break();

                SetRange("Posting Date", 0D, LastDueDateToPayReq);

                Window.Open(EmpEntriesMsg);
                DialogOpen := true;
            end;
        }
        dataitem("Purch. Advance Letter Header"; "Purch. Advance Letter Header")
        {
            CalcFields = "Amount on Payment Order (LCY)", "Amount Including VAT";
            DataItemTableView = SORTING("No.") WHERE(Status = FILTER("Pending Payment" .. "Pending Payment"), "On Hold" = CONST(''));

            trigger OnAfterGetRecord()
            var
                RemAmount: Decimal;
            begin
                if TypeVendor = TypeVendor::OnlyBalance then
                    if VendorBalanceTest("Pay-to Vendor No.") then
                        CurrReport.Skip();
                if SkipBlocked and VendorBlockedTest("Pay-to Vendor No.") then begin
                    IsSkippedBlockedVendor := true;
                    CurrReport.Skip();
                end;

                RemAmount := GetRemAmount();
                if RemAmount <> 0 then
                    AddPurchaseLetter("Purch. Advance Letter Header");

                if StopPayments then
                    CurrReport.Break();

                Window.Update(1, "No.");
            end;

            trigger OnPostDataItem()
            begin
                if DialogOpen then begin
                    Clear(DialogOpen);
                    Window.Close();
                end;
            end;

            trigger OnPreDataItem()
            begin
                if TypeVendor = TypeVendor::Nothing then
                    CurrReport.Break();
                if StopPayments then
                    CurrReport.Break();

                SetRange("Advance Due Date", 0D, LastDueDateToPayReq);
                SetRange("Due Date from Line", false);

                if KeepCurrency then
                    case Currency of
                        Currency::"Payment Order":
                            SetRange("Currency Code", PmtOrdHdr."Payment Order Currency Code");
                        Currency::"Bank Account":
                            SetRange("Currency Code", PmtOrdHdr."Currency Code");
                    end;

                Window.Open(VendAdvancesMsg);
                DialogOpen := true;
            end;
        }
        dataitem(PurchAdvLetterHdrPerLine; "Purch. Advance Letter Header")
        {
            CalcFields = "Amount on Payment Order (LCY)", "Amount Including VAT";
            DataItemTableView = SORTING("No.") WHERE(Status = FILTER("Pending Payment" .. "Pending Payment"), "On Hold" = CONST(''));
            dataitem(PurchAdvLetterLinePerLine; "Purch. Advance Letter Line")
            {
                CalcFields = "Amount on Payment Order (LCY)";
                DataItemLink = "Letter No." = FIELD("No.");
                DataItemTableView = SORTING("Letter No.", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    if "Amount To Link" > 0 then
                        AddPurchaseLetterLine(PurchAdvLetterLinePerLine);

                    if StopPayments then
                        CurrReport.Break();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Advance Due Date", 0D, LastDueDateToPayReq);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if TypeVendor = TypeVendor::OnlyBalance then
                    if VendorBalanceTest("Pay-to Vendor No.") then
                        CurrReport.Skip();
                if SkipBlocked and VendorBlockedTest("Pay-to Vendor No.") then begin
                    IsSkippedBlockedVendor := true;
                    CurrReport.Skip();
                end;

                Window.Update(1, "No.");
            end;

            trigger OnPostDataItem()
            begin
                if DialogOpen then begin
                    Clear(DialogOpen);
                    Window.Close();
                end;
            end;

            trigger OnPreDataItem()
            begin
                if TypeVendor = TypeVendor::Nothing then
                    CurrReport.Break();
                if StopPayments then
                    CurrReport.Break();

                CopyFilters("Purch. Advance Letter Header");
                SetRange("Advance Due Date");
                SetRange("Due Date from Line", true);

                if KeepCurrency then
                    case Currency of
                        Currency::"Payment Order":
                            SetRange("Currency Code", PmtOrdHdr."Payment Order Currency Code");
                        Currency::"Bank Account":
                            SetRange("Currency Code", PmtOrdHdr."Currency Code");
                    end;

                Window.Open(VendAdvLinesMsg);
                DialogOpen := true;
            end;
        }
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
                    field(LastDueDateToPayReq; LastDueDateToPayReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Last Payment Date';
                        ToolTip = 'Specifies the system goes through entries to this date.';
                    }
                    field(UsePaymentDisc; UsePaymentDisc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Find Payment Discounts';
                        MultiLine = true;
                        ToolTip = 'Specifies placing a check mark in the check box if you want the batch job to include vendor ledger entries for which you can receive a payment discount.';
                    }
                    field(AmountAvailable; AmountAvailable)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Available Amount (LCY)';
                        ToolTip = 'Specifies the max. amount. The amount is in the local currency.';
                    }
                    field(TypeVendor; TypeVendor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Payables';
                        OptionCaption = 'Only Payable Balance,Only Payables,All Entries,No Sugest';
                        ToolTip = 'Specifies vendor payables';
                    }
                    field(TypeCustomer; TypeCustomer)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Payables';
                        OptionCaption = 'Only Payable Balance,Only Payables,All Entries,No Sugest';
                        ToolTip = 'Specifies customers payables.';
                    }
                    field(TypeEmployee; TypeEmployee)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Employee Payables';
                        OptionCaption = 'All Entries,No Suggest';
                        ToolTip = 'Specifies employee payables.';
                    }
                    field(Currency; Currency)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Keep Currency';
                        OptionCaption = 'Entry,Payment Order,Bank Account';
                        ToolTip = 'Specifies Payment Order or Bank Account';

                        trigger OnValidate()
                        begin
                            if Currency = Currency::"Bank Account" then
                                BankAccountCurrencyOnValida();
                            if Currency = Currency::"Payment Order" then
                                PaymentOrderCurrencyOnValid();
                            if Currency = Currency::Entry then
                                EntryCurrencyOnValidate();
                        end;
                    }
                    field(KeepCurrency; KeepCurrency)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only Entries in Currency';
                        Enabled = KeepCurrencyEnable;
                        ToolTip = 'Specifies entries will be in the same currency (by payment order header or by bank account).';
                    }
                    field(KeepBank; KeepBank)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only Entries with same Bank Code';
                        ToolTip = 'Specifies whether entries will be in the same bank account.';
                    }
                    field(SkipNonWork; SkipNonWork)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Modify nonworking days';
                        ToolTip = 'Specifies if the nonworking days will be modified';
                    }
                    field(SkipBlocked; SkipBlocked)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Skip blocked';
                        ToolTip = 'Specifies whether the entries of blocked customers/vendors will be skipped.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            KeepCurrencyEnable := true;
        end;

        trigger OnOpenPage()
        begin
            case Currency of
                Currency::Entry:
                    KeepCurrencyEnable := false
                else
                    KeepCurrencyEnable := true;
            end;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if IsSkippedBlockedCustomer or IsSkippedBlockedVendor then
            Message(SkipBlockedVendorCustomerMsg);
    end;

    trigger OnPreReport()
    begin
        PmtOrdHdr.Get(PmtOrdHdr."No.");

        if UsePaymentDisc and (LastDueDateToPayReq < WorkDate()) then
            if not Confirm(EarlierDateQst, false, WorkDate()) then
                Error(InterruptedBatchErr);

        if LastDueDateToPayReq = 0D then
            Error(EnterLastDateErr);

        BankAccount.Get(PmtOrdHdr."Bank Account No.");
        if SkipNonWork then
            BankAccount.TestField("Base Calendar Code");

        PmtOrdLn.SetRange("Payment Order No.", PmtOrdHdr."No.");
        if PmtOrdLn.FindLast() then
            LineNo := PmtOrdLn."Line No." + 10000
        else
            LineNo := 10000;

        if KeepBank then begin
            if PmtOrdHdr."Account No." <> '' then
                BankCode := CopyStr(BankOperationsFunctions.GetBankCode(PmtOrdHdr."Account No."), 1, 10);
            if (PmtOrdHdr.IBAN <> '') and (BankCode = '') then
                BankCode := BankOperationsFunctions.IBANBankCode(PmtOrdHdr.IBAN);
            SWIFTCode := PmtOrdHdr."SWIFT Code";
            if (BankCode = '') and (SWIFTCode = '') then
                Error(NotRecognizedBankCodeErr);
        end;

        IsSkippedBlockedCustomer := false;
        IsSkippedBlockedVendor := false;
    end;

    var
        PmtOrdHdr: Record "Payment Order Header";
        PmtOrdLn: Record "Payment Order Line";
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        PaymentOrderManagement: Codeunit "Payment Order Management";
        BankOperationsFunctions: Codeunit "Bank Operations Functions";
        Window: Dialog;
        BankCode: Code[10];
        SWIFTCode: Code[20];
        AmountAvailable: Decimal;
        AppliedAmount: Decimal;
        LineNo: Integer;
        TypeCustomer: Option OnlyBalance,OnlyPayables,All,Nothing;
        TypeVendor: Option OnlyBalance,OnlyPayables,All,Nothing;
        TypeEmployee: Option All,Nothing;
        Currency: Option Entry,"Payment Order","Bank Account";
        LastDueDateToPayReq: Date;
        UsePaymentDisc: Boolean;
        StopPayments: Boolean;
        KeepCurrency: Boolean;
        SkipNonWork: Boolean;
        KeepBank: Boolean;
        [InDataSet]
        KeepCurrencyEnable: Boolean;
        DialogOpen: Boolean;
        CustEntriesMsg: Label 'Processing customer entries #1##########', Comment = 'Progress bar';
        VendEntriesMsg: Label 'Processing vendors entries #1##########', Comment = 'Progress bar';
        EmpEntriesMsg: Label 'Processing employee entries #1##########', Comment = 'Progress bar';
        VendDiscEntriesMsg: Label 'Processing vendors for payment discounts #1##########', Comment = 'Progress bar';
        VendAdvancesMsg: Label 'Processing vendors advanced payment #1##########', Comment = 'Progress bar';
        VendAdvLinesMsg: Label 'Processing vendors advanced payment lines #1##########', Comment = 'Progress bar';
        EnterLastDateErr: Label 'Please enter the last payment date.';
        EarlierDateQst: Label 'The payment date is earlier than %1.\\Do you still want to run the batch job?', Comment = '%1=WORKDATE';
        InterruptedBatchErr: Label 'The batch job was interrupted.';
        NotRecognizedBankCodeErr: Label 'Bank Code does not recognized.';
        SkipBlocked: Boolean;
        IsSkippedBlockedVendor: Boolean;
        IsSkippedBlockedCustomer: Boolean;
        SkipBlockedVendorCustomerMsg: Label 'During the suggesting payments were skipped blocked vendor/customer.';

    [Scope('OnPrem')]
    procedure SetPaymentOrder(PmtOrdHdr1: Record "Payment Order Header")
    begin
        PmtOrdHdr := PmtOrdHdr1;
    end;

    [Scope('OnPrem')]
    procedure AddCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        with PmtOrdLn do begin
            Init();
            Validate("Payment Order No.", PmtOrdHdr."No.");
            "Line No." := LineNo;
            LineNo += 10000;
            Type := Type::Customer;
            case Currency of
                Currency::Entry:
                    if "Payment Order Currency Code" <> CustLedgEntry."Currency Code" then
                        Validate("Payment Order Currency Code", CustLedgEntry."Currency Code");
                Currency::"Payment Order":
                    if "Payment Order Currency Code" <> PmtOrdHdr."Payment Order Currency Code" then
                        Validate("Payment Order Currency Code", PmtOrdHdr."Payment Order Currency Code");
                Currency::"Bank Account":
                    if "Payment Order Currency Code" <> PmtOrdHdr."Currency Code" then
                        Validate("Payment Order Currency Code", PmtOrdHdr."Currency Code");
            end;
            Validate("Applies-to C/V/E Entry No.", CustLedgEntry."Entry No.");
            if not UsePaymentDisc and "Pmt. Discount Possible" then begin
                "Pmt. Discount Possible" := false;
                "Pmt. Discount Date" := 0D;
                "Amount(Pay.Order Curr.) to Pay" += "Remaining Pmt. Disc. Possible";
                "Remaining Pmt. Disc. Possible" := 0;
                Validate("Amount(Pay.Order Curr.) to Pay");
                "Original Amount" := "Amount to Pay";
                "Original Amount (LCY)" := "Amount (LCY) to Pay";
                "Orig. Amount(Pay.Order Curr.)" := "Amount(Pay.Order Curr.) to Pay";
            end;
            AddPaymentLine();
        end;
    end;

    [Scope('OnPrem')]
    procedure AddVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        with PmtOrdLn do begin
            Init();
            Validate("Payment Order No.", PmtOrdHdr."No.");
            "Line No." := LineNo;
            LineNo += 10000;
            Type := Type::Vendor;
            case Currency of
                Currency::Entry:
                    if "Payment Order Currency Code" <> VendLedgEntry."Currency Code" then
                        Validate("Payment Order Currency Code", VendLedgEntry."Currency Code");
                Currency::"Payment Order":
                    if "Payment Order Currency Code" <> PmtOrdHdr."Payment Order Currency Code" then
                        Validate("Payment Order Currency Code", PmtOrdHdr."Payment Order Currency Code");
                Currency::"Bank Account":
                    if "Payment Order Currency Code" <> PmtOrdHdr."Currency Code" then
                        Validate("Payment Order Currency Code", PmtOrdHdr."Currency Code");
            end;
            Validate("Applies-to C/V/E Entry No.", VendLedgEntry."Entry No.");
            if not UsePaymentDisc and "Pmt. Discount Possible" then begin
                "Pmt. Discount Possible" := false;
                "Pmt. Discount Date" := 0D;
                "Amount(Pay.Order Curr.) to Pay" -= "Remaining Pmt. Disc. Possible";
                "Remaining Pmt. Disc. Possible" := 0;
                Validate("Amount(Pay.Order Curr.) to Pay");
                "Original Amount" := "Amount to Pay";
                "Original Amount (LCY)" := "Amount (LCY) to Pay";
                "Orig. Amount(Pay.Order Curr.)" := "Amount(Pay.Order Curr.) to Pay";
                "Due Date" := VendLedgEntry."Due Date";
            end;
            AddPaymentLine();
        end;
    end;

    [Scope('OnPrem')]
    procedure AddEmplLedgEntry(EmplLedgEntry: Record "Employee Ledger Entry")
    begin
        with PmtOrdLn do begin
            Init();
            Validate("Payment Order No.", PmtOrdHdr."No.");
            "Line No." := LineNo;
            LineNo += 10000;
            Type := Type::Employee;
            if "Payment Order Currency Code" <> EmplLedgEntry."Currency Code" then
                Validate("Payment Order Currency Code", EmplLedgEntry."Currency Code");
            Validate("Applies-to C/V/E Entry No.", EmplLedgEntry."Entry No.");
            AddPaymentLine();
        end;
    end;

    [Scope('OnPrem')]
    procedure AddPurchaseLetter(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        with PmtOrdLn do begin
            Init();
            Validate("Payment Order No.", PmtOrdHdr."No.");
            "Line No." := LineNo;
            LineNo += 10000;
            Type := Type::Vendor;
            case Currency of
                Currency::Entry:
                    if "Payment Order Currency Code" <> PurchAdvanceLetterHeader."Currency Code" then
                        Validate("Payment Order Currency Code", PurchAdvanceLetterHeader."Currency Code");
                Currency::"Payment Order":
                    if "Payment Order Currency Code" <> PmtOrdHdr."Payment Order Currency Code" then
                        Validate("Payment Order Currency Code", PmtOrdHdr."Payment Order Currency Code");
                Currency::"Bank Account":
                    if "Payment Order Currency Code" <> PmtOrdHdr."Currency Code" then
                        Validate("Payment Order Currency Code", PmtOrdHdr."Currency Code");
            end;
            "Letter Type" := "Letter Type"::Purchase;

            Validate("Letter No.", PurchAdvanceLetterHeader."No.");
            AddPaymentLine();
        end;
    end;

    [Scope('OnPrem')]
    procedure AddPaymentLine()
    var
        Cal: Record "Customized Calendar Change";
        CalMgt: Codeunit "Calendar Management";
        BankCodeLoc: Code[10];
    begin
        if KeepBank then begin
            if PmtOrdLn."Account No." <> '' then
                BankCodeLoc := CopyStr(BankOperationsFunctions.GetBankCode(PmtOrdLn."Account No."), 1, 10);
            if (BankCodeLoc = '') and (PmtOrdLn.IBAN <> '') then
                BankCodeLoc := BankOperationsFunctions.IBANBankCode(PmtOrdLn.IBAN);

            if (SWIFTCode <> '') and (PmtOrdLn."SWIFT Code" <> '') then
                if SWIFTCode <> PmtOrdLn."SWIFT Code" then
                    exit;
            if BankCodeLoc <> BankCode then
                exit;
        end;
        if PaymentOrderManagement.CheckPaymentOrderLineCustVendBlocked(PmtOrdLn, false) and
           PaymentOrderManagement.CheckPaymentOrderLineApply(PmtOrdLn, false)
        then begin
            StopPayments := ((AppliedAmount + PmtOrdLn."Amount to Pay") > AmountAvailable) and
              (AmountAvailable <> 0);
            if not StopPayments then begin
                if SkipNonWork then begin
                    CalMgt.SetSource(BankAccount, Cal);
                    while CalMgt.IsNonworkingDay(PmtOrdLn."Due Date", Cal) do
                        PmtOrdLn."Due Date" := CalcDate('<-1D>', PmtOrdLn."Due Date");
                end;
                PmtOrdLn.Insert();
                AppliedAmount := AppliedAmount + PmtOrdLn."Amount to Pay";
            end;
        end else
            if BankAccount."Payment Partial Suggestion" then begin
                StopPayments := ((AppliedAmount + PmtOrdLn."Amount to Pay") > AmountAvailable) and
                  (AmountAvailable <> 0);
                if not StopPayments then begin
                    if SkipNonWork then begin
                        CalMgt.SetSource(BankAccount, Cal);
                        while CalMgt.IsNonworkingDay(PmtOrdLn."Due Date", Cal) do
                            PmtOrdLn."Due Date" := CalcDate('<-1D>', PmtOrdLn."Due Date");
                    end;
                    PmtOrdLn."Amount Must Be Checked" := true;
                    PmtOrdLn.Insert();
                    AppliedAmount := AppliedAmount + PmtOrdLn."Amount to Pay";
                end;
            end;
    end;

    [Scope('OnPrem')]
    procedure CustomerBalanceTest(No: Code[20]): Boolean
    begin
        GetCustomer(No);
        with Customer do begin
            CalcFields("Balance (LCY)");
            exit("Balance (LCY)" > 0);
        end;
    end;

    local procedure CustomerBlockedTest(No: Code[20]): Boolean
    begin
        GetCustomer(No);
        exit(Customer.Blocked <> Customer.Blocked::" ");
    end;

    [Scope('OnPrem')]
    procedure VendorBalanceTest(No: Code[20]): Boolean
    begin
        GetVendor(No);
        with Vendor do begin
            CalcFields("Balance (LCY)");
            exit("Balance (LCY)" < 0);
        end;
    end;

    local procedure VendorBlockedTest(No: Code[20]): Boolean
    begin
        GetVendor(No);
        exit(Vendor.Blocked <> Vendor.Blocked::" ");
    end;

    local procedure EntryCurrencyOnValidate()
    begin
        KeepCurrency := false;
        KeepCurrencyEnable := false;
    end;

    local procedure PaymentOrderCurrencyOnValid()
    begin
        KeepCurrencyEnable := true;
    end;

    local procedure BankAccountCurrencyOnValida()
    begin
        KeepCurrencyEnable := true;
    end;

    [Scope('OnPrem')]
    procedure AddPurchaseLetterLine(PurchAdvLetterLine: Record "Purch. Advance Letter Line")
    begin
        with PmtOrdLn do begin
            Init();
            Validate("Payment Order No.", PmtOrdHdr."No.");
            "Line No." := LineNo;
            LineNo += 10000;
            Type := Type::Vendor;
            case Currency of
                Currency::Entry:
                    if "Payment Order Currency Code" <> PurchAdvLetterLine."Currency Code" then
                        Validate("Payment Order Currency Code", PurchAdvLetterLine."Currency Code");
                Currency::"Payment Order":
                    if "Payment Order Currency Code" <> PmtOrdHdr."Payment Order Currency Code" then
                        Validate("Payment Order Currency Code", PmtOrdHdr."Payment Order Currency Code");
                Currency::"Bank Account":
                    if "Payment Order Currency Code" <> PmtOrdHdr."Currency Code" then
                        Validate("Payment Order Currency Code", PmtOrdHdr."Currency Code");
            end;
            "Letter Type" := "Letter Type"::Purchase;
            "Letter No." := PurchAdvLetterLine."Letter No.";
            Validate("Letter Line No.", PurchAdvLetterLine."Line No.");
            AddPaymentLine();
        end;
    end;

    local procedure GetCustomer(CustomerNo: Code[20])
    begin
        if Customer."No." <> CustomerNo then
            Customer.Get(CustomerNo);
    end;

    local procedure GetVendor(VendorNo: Code[20])
    begin
        if Vendor."No." <> VendorNo then
            Vendor.Get(VendorNo);
    end;
}
#endif