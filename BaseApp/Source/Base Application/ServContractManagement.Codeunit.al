codeunit 5940 ServContractManagement
{
    Permissions = TableData "Service Ledger Entry" = rimd,
                  TableData "Warranty Ledger Entry" = rimd,
                  TableData "Service Register" = rimd,
                  TableData "Contract Change Log" = rimd,
                  TableData "Contract Gain/Loss Entry" = rimd;
    TableNo = "Service Contract Header";

    trigger OnRun()
    begin
    end;

    var
        Text000: Label '%1 cannot be created for service contract  %2, because %3 and %4 are not equal.';
        Text002: Label 'Service Contract: %1';
        Text003: Label 'Service contract line(s) included in:';
        Text004: Label 'A credit memo cannot be created, because the %1 %2 is after the work date.';
        Text005: Label '%1 %2 removed';
        Text006: Label 'Do you want to create a service invoice for the period %1 .. %2 ?';
        GLAcc: Record "G/L Account";
        ServMgtSetup: Record "Service Mgt. Setup";
        ServLedgEntry: Record "Service Ledger Entry";
        ServLedgEntry2: Record "Service Ledger Entry";
        TempServLedgEntry: Record "Service Ledger Entry" temporary;
        ServLine: Record "Service Line";
        ServHeader: Record "Service Header";
        ServiceRegister: Record "Service Register";
        Salesperson: Record "Salesperson/Purchaser";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        NextLine: Integer;
        PostingDate: Date;
        WDate: Date;
        ServLineNo: Integer;
        NextEntry: Integer;
        AppliedEntry: Integer;
        Text007: Label 'Invoice cannot be created because amount to invoice for this invoice period is zero.';
        Text008: Label 'The combination of dimensions used in %1 %2 is blocked. %3';
        Text009: Label 'The dimensions used in %1 %2 are invalid. %3';
        InvoicingStartingPeriod: Boolean;
        Text010: Label 'You cannot create an invoice for contract %1 before the service under this contract is completed because the %2 check box is selected.';
        Text012: Label 'You must fill in the New Customer No. field.';
        Text013: Label '%1 cannot be created because the %2 is too long. Please shorten the %3 %4 %5 by removing %6 character(s).';
        TempServLineDescription: Text[250];
        Text014: Label 'A %1 cannot be created because %2 %3 has at least one unposted %4 linked to it.';
        Text015: Label '%1 %2 for the existing %3 %4 for %5 %6 differs from the newly calculated %1 %7. Do you want to use the existing %1?', Comment = 'Location Code SILVER for the existing Service Credit Memo 1001 for Service Contract 1002 differs from the newly calculated Location Code BLUE. Do you want to use the existing Location Code?';
        AppliedGLAccount: Code[20];
        CheckMParts: Boolean;
        CombinedCurrenciesErr1: Label 'Customer %1 has service contracts with different currency codes %2 and %3, which cannot be combined on one invoice.';
        CombinedCurrenciesErr2: Label 'Limit the Create Contract Invoices batch job to certain currency codes or clear the Combine Invoices field on the involved service contracts.';
        BlankTxt: Label '<blank>';
        ErrorSplitErr: Label '%1\\%2.';
        AmountType: Option ,Amount,DiscAmount,UnitPrice,UnitCost;
        TempServLedgEntriesIsSet: Boolean;

    procedure CreateInvoice(ServiceContractHeader: Record "Service Contract Header") InvNo: Code[20]
    var
        InvoicedAmount: Decimal;
        InvoiceFromDate: Date;
        InvoiceToDate: Date;
    begin
        OnBeforeCreateInvoice(ServiceContractHeader);
        ServiceContractHeader.TestField("Change Status", ServiceContractHeader."Change Status"::Locked);
        GetNextInvoicePeriod(ServiceContractHeader, InvoiceFromDate, InvoiceToDate);
        CreateInvoiceSetPostingDate(ServiceContractHeader, InvoiceFromDate, InvoiceToDate, PostingDate);

        InvoicedAmount := CalcContractAmount(ServiceContractHeader, InvoiceFromDate, InvoiceToDate);
        if InvoicedAmount = 0 then
            Error(Text007);

        InvNo := CreateRemainingPeriodInvoice(ServiceContractHeader);

        if InvNo = '' then
            InvNo := CreateServHeader(ServiceContractHeader, PostingDate, false);

        if InvoicingStartingPeriod then begin
            GetNextInvoicePeriod(ServiceContractHeader, InvoiceFromDate, InvoiceToDate);
            PostingDate := InvoiceFromDate;
            InvoicedAmount := CalcContractAmount(ServiceContractHeader, InvoiceFromDate, InvoiceToDate);
        end;

        if not CheckIfServiceExist(ServiceContractHeader) then
            Error(
              Text010,
              ServiceContractHeader."Contract No.",
              ServiceContractHeader.FieldCaption("Invoice after Service"));

        OnCreateInvoiceOnBeforeCreateAllServLines(ServiceContractHeader, InvoiceFromDate, InvoiceToDate, InvoicedAmount, PostingDate, InvoicingStartingPeriod, InvNo);

        CreateAllServLines(InvNo, ServiceContractHeader);

        OnAfterCreateInvoice(ServiceContractHeader, PostingDate);
    end;

    local procedure CreateInvoiceSetPostingDate(ServiceContractHeader: Record "Service Contract Header"; InvoiceFromDate: Date; InvoiceToDate: Date; var PostingDate: Date)
    begin
        if ServiceContractHeader.Prepaid then
            PostingDate := InvoiceFromDate
        else
            PostingDate := InvoiceToDate;

        OnAfterCreateInvoiceSetPostingDate(ServiceContractHeader, InvoiceFromDate, InvoiceToDate, PostingDate);
    end;

#if not CLEAN19
    [Obsolete('Replaced by CreateServiceLedgEntry()', '19.0')]
    procedure CreateServiceLedgerEntry(ServHeader2: Record "Service Header"; ContractType: Integer; ContractNo: Code[20]; InvFrom: Date; InvTo: Date; SigningContract: Boolean; AddingNewLines: Boolean; LineNo: Integer) ReturnLedgerEntry: Integer
    begin
        exit(
            CreateServiceLedgEntry(
                ServHeader2, "Service Contract Type".FromInteger(ContractType), ContractNo, InvFrom, InvTo,
                SigningContract, AddingNewLines, LineNo));
    end;
#endif

    procedure CreateServiceLedgEntry(ServHeader2: Record "Service Header"; ContractType: Enum "Service Contract Type"; ContractNo: Code[20]; InvFromDate: Date; InvToDate: Date; SigningContract: Boolean; AddingNewLines: Boolean; LineNo: Integer) ReturnLedgerEntry: Integer
    var
        ServContractLine: Record "Service Contract Line";
        ServContractHeader: Record "Service Contract Header";
        Currency: Record Currency;
        LastEntry: Integer;
        FirstLineEntry: Integer;
        NoOfPayments: Integer;
        DueDate: Date;
        Days: Integer;
        InvToDate2: Date;
        LineInvFrom: Date;
        PartInvFrom: Date;
        PartInvTo: Date;
        NewInvFrom: Date;
        NextInvDate: Date;
        ProcessSigningSLECreation: Boolean;
        NonDistrAmount: array[4] of Decimal;
        InvAmount: array[4] of Decimal;
        InvRoundedAmount: array[4] of Decimal;
        CountOfEntryLoop: Integer;
        YearContractCorrection: Boolean;
        ServiceContractHeaderFound: Boolean;
        DateExpression: Text;
    begin
        ServiceContractHeaderFound := ServContractHeader.Get(ContractType, ContractNo);
        if not ServiceContractHeaderFound or (ServContractHeader."Invoice Period" = ServContractHeader."Invoice Period"::None) then
            exit;

        ServContractHeader.CalcFields("Calcd. Annual Amount");
        CheckServiceContractHeaderAmts(ServContractHeader);
        Currency.InitRoundingPrecision;
        ReturnLedgerEntry := NextEntry;
        Clear(ServLedgEntry);
        InitServLedgEntry(ServLedgEntry, ServContractHeader, ServHeader2."No.");
        OnCreateServiceLedgerEntryOnAfterInitServLedgEntry(
            ServLedgEntry, ServContractHeader, ContractType.AsInteger(), ContractNo, LineNo);
        Clear(NonDistrAmount);
        Clear(InvAmount);
        Clear(InvRoundedAmount);

        if ServContractHeader.Prepaid and not SigningContract then begin
            ServLedgEntry."Moved from Prepaid Acc." := false;
            FirstLineEntry := NextEntry;
            FilterServiceContractLine(
              ServContractLine, ServContractHeader."Contract No.", ServContractHeader."Contract Type", LineNo);
            if AddingNewLines then
                ServContractLine.SetRange("New Line", true)
            else
                ServContractLine.SetFilter("Starting Date", '<=%1|%2..%3', ServContractHeader."Next Invoice Date",
                  ServContractHeader."Next Invoice Period Start", ServContractHeader."Next Invoice Period End");
            if ServContractLine.Find('-') then begin
                repeat
                    YearContractCorrection := false;
                    Days := 0;
                    WDate := CalcDate('<-CM>', InvFromDate);
                    DateExpression := '<1M>';
                    OnCreateServiceLedgerEntryOnBeforeLoopPeriods(
                        ServContractHeader, ServContractLine, InvFromDate, WDate, DateExpression);
                    if (InvFromDate <= ServContractLine."Contract Expiration Date") or
                       (ServContractLine."Contract Expiration Date" = 0D)
                    then begin
                        NoOfPayments := 0;
                        repeat
                            NoOfPayments := NoOfPayments + 1;
                            WDate := CalcDate(DateExpression, WDate);
                        until (WDate >= InvToDate) or
                              ((WDate > ServContractLine."Contract Expiration Date") and
                               (ServContractLine."Contract Expiration Date" <> 0D));
                        CountOfEntryLoop := NoOfPayments;

                        OnCreateServiceLedgerEntryOnBeforeCheckServContractLineStartingDate(ServContractHeader, CountOfEntryLoop);

                        // Partial period ranged by "Starting Date" and end of month. Full period is shifted by one month
                        if ServContractLine."Starting Date" > InvFromDate then begin
                            Days := CalcDate('<CM>', InvFromDate) - ServContractLine."Starting Date";
                            PartInvFrom := ServContractLine."Starting Date";
                            PartInvTo := CalcDate('<CM>', InvFromDate);
                            InvFromDate := PartInvFrom;
                            NewInvFrom := CalcDate('<CM+1D>', InvFromDate);
                            CountOfEntryLoop := CountOfEntryLoop - 1;
                            NoOfPayments := NoOfPayments - 1;
                        end;

                        if ServContractLine."Contract Expiration Date" <> 0D then
                            if CalcDate('<1D>', ServContractLine."Contract Expiration Date") < WDate then
                                if Days = 0 then begin
                                    Days := Date2DMY(ServContractLine."Contract Expiration Date", 1);
                                    CountOfEntryLoop := CountOfEntryLoop - 1;
                                    PartInvFrom := CalcDate('<-CM>', ServContractLine."Contract Expiration Date");
                                    PartInvTo := ServContractLine."Contract Expiration Date";
                                end else
                                    if ServContractLine."Contract Expiration Date" < PartInvTo then begin
                                        // partial period ranged by "Starting Date" from the beginning and "Contract Expiration Date" from the end
                                        PartInvTo := ServContractLine."Contract Expiration Date";
                                        Days := PartInvTo - PartInvFrom;
                                        CountOfEntryLoop := 0;
                                    end else begin
                                        // Post previous partial period before new one with Contract Expiration Date
                                        PostPartialServLedgEntry(
                                          InvRoundedAmount, ServContractLine, ServHeader2, PartInvFrom, PartInvTo,
                                          ServContractHeader."Next Invoice Date", Currency."Amount Rounding Precision");
                                        Days := Date2DMY(ServContractLine."Contract Expiration Date", 1);
                                        CountOfEntryLoop := CountOfEntryLoop - 1;
                                        NoOfPayments := NoOfPayments - 1;
                                        PartInvFrom := CalcDate('<-CM>', ServContractLine."Contract Expiration Date");
                                        PartInvTo := ServContractLine."Contract Expiration Date";
                                    end;

                        WDate := InvToDate;
                        if (WDate > ServContractLine."Contract Expiration Date") and
                           (ServContractLine."Contract Expiration Date" <> 0D)
                        then
                            WDate := ServContractLine."Contract Expiration Date";

                        DueDate := WDate;
                        // Calculate invoice amount for initial period and go ahead with shifted InvFrom
                        CalcInvAmounts(InvAmount, ServContractLine, InvFromDate, WDate);
                        if NewInvFrom = 0D then
                            NextInvDate := ServContractHeader."Next Invoice Date"
                        else begin
                            InvFromDate := NewInvFrom;
                            NextInvDate := CalcDate('<1M>', ServContractHeader."Next Invoice Date");
                        end;

                        OnCreateServiceLedgerEntryOnBeforeInsertMultipleServLedgEntries(NextInvDate, ServContractHeader, ServContractLine);
                        InsertMultipleServLedgEntries(
                          NoOfPayments, DueDate, NonDistrAmount, InvRoundedAmount, ServHeader2, InvFromDate, NextInvDate,
                          AddingNewLines, CountOfEntryLoop, ServContractLine, Currency."Amount Rounding Precision");
                        if Days = 0 then
                            YearContractCorrection := false
                        else
                            YearContractCorrection :=
                              PostPartialServLedgEntry(
                                InvRoundedAmount, ServContractLine, ServHeader2,
                                PartInvFrom, PartInvTo, PartInvFrom, Currency."Amount Rounding Precision");
                        LastEntry := ServLedgEntry."Entry No.";
                        CalcInvoicedToDate(ServContractLine, InvFromDate, InvToDate);
                        ServContractLine.Modify();
                    end else begin
                        YearContractCorrection := false;
                        ReturnLedgerEntry := 0;
                    end;
                until ServContractLine.Next() = 0;
                UpdateApplyUntilEntryNoInServLedgEntry(ReturnLedgerEntry, FirstLineEntry, LastEntry);
            end;
        end else begin
            YearContractCorrection := false;
            ServLedgEntry."Moved from Prepaid Acc." := true;
            ServLedgEntry."Posting Date" := ServHeader2."Posting Date";
            FilterServiceContractLine(
              ServContractLine, ServContractHeader."Contract No.", ServContractHeader."Contract Type", LineNo);
            if AddingNewLines then
                ServContractLine.SetRange("New Line", true)
            else
                if not SigningContract then begin
                    if ServContractHeader."Last Invoice Date" <> 0D then
                        ServContractLine.SetFilter("Invoiced to Date", '%1|%2', ServContractHeader."Last Invoice Date", 0D)
                    else
                        ServContractLine.SetRange("Invoiced to Date", 0D);
                    ServContractLine.SetFilter("Starting Date", '<=%1|%2..%3', InvFromDate,
                      ServContractHeader."Next Invoice Period Start", ServContractHeader."Next Invoice Period End");
                end else
                    ServContractLine.SetFilter("Starting Date", '<=%1', InvToDate);
            FirstLineEntry := NextEntry;
            InvToDate2 := InvToDate;
            if ServContractLine.Find('-') then begin
                repeat
                    if SigningContract then begin
                        if ServContractLine."Invoiced to Date" = 0D then
                            ProcessSigningSLECreation := true
                        else
                            if (ServContractLine."Invoiced to Date" <> 0D) and
                               (ServContractLine."Invoiced to Date" <> CalcDate('<CM>', ServContractLine."Invoiced to Date"))
                            then
                                ProcessSigningSLECreation := true
                    end else
                        ProcessSigningSLECreation := true;
                    if ((InvFromDate <= ServContractLine."Contract Expiration Date") or
                        (ServContractLine."Contract Expiration Date" = 0D)) and ProcessSigningSLECreation
                    then begin
                        if (ServContractLine."Contract Expiration Date" >= InvFromDate) and
                           (ServContractLine."Contract Expiration Date" < InvToDate)
                        then
                            InvToDate := ServContractLine."Contract Expiration Date";
                        ServLedgEntry."Service Item No. (Serviced)" := ServContractLine."Service Item No.";
                        ServLedgEntry."Item No. (Serviced)" := ServContractLine."Item No.";
                        ServLedgEntry."Serial No. (Serviced)" := ServContractLine."Serial No.";
                        OnCreateServiceLedgerEntryBeforeCountLineInvFrom(ServLedgEntry, ServContractLine);
                        LineInvFrom := CountLineInvFrom(SigningContract, ServContractLine, InvFromDate);
                        if (LineInvFrom <> 0D) and (LineInvFrom <= InvToDate) then begin
                            UpdateServLedgEntryAmounts(ServContractLine, Currency, InvRoundedAmount, LineInvFrom, InvToDate);
                            ServLedgEntry."Cost Amount" := ServLedgEntry."Unit Cost" * ServLedgEntry."Charged Qty.";
                            UpdateServLedgEntryAmount(ServLedgEntry, ServHeader2);
                            ServLedgEntry."Entry No." := NextEntry;
                            CalcInvAmounts(InvAmount, ServContractLine, LineInvFrom, InvToDate);
                            OnCreateServiceLedgerEntryOnBeforeServLedgEntryInsert(ServLedgEntry, ServContractHeader, ServContractLine);
                            ServLedgEntry.Insert();

                            LastEntry := ServLedgEntry."Entry No.";
                            NextEntry := NextEntry + 1;
                            InvToDate := InvToDate2;
                        end else
                            ReturnLedgerEntry := 0;
                        CalcInvoicedToDate(ServContractLine, InvFromDate, InvToDate);
                        ServContractLine.Modify();
                    end else
                        ReturnLedgerEntry := 0;
                until ServContractLine.Next() = 0;
                UpdateApplyUntilEntryNoInServLedgEntry(ReturnLedgerEntry, FirstLineEntry, LastEntry);
            end;
        end;
        if ServLedgEntry.Get(LastEntry) and (not YearContractCorrection)
        then begin
            ServLedgEntry."Amount (LCY)" := ServLedgEntry."Amount (LCY)" + InvRoundedAmount[AmountType::Amount] -
              Round(InvAmount[AmountType::Amount], Currency."Amount Rounding Precision");
            ServLedgEntry."Unit Price" := ServLedgEntry."Unit Price" + InvRoundedAmount[AmountType::UnitPrice] -
              Round(InvAmount[AmountType::UnitPrice], Currency."Unit-Amount Rounding Precision");
            ServLedgEntry."Cost Amount" := ServLedgEntry."Cost Amount" + InvRoundedAmount[AmountType::UnitCost] -
              Round(InvAmount[AmountType::UnitCost], Currency."Amount Rounding Precision");
            SetServiceLedgerEntryUnitCost(ServLedgEntry);
            ServLedgEntry."Contract Disc. Amount" :=
              ServLedgEntry."Contract Disc. Amount" - InvRoundedAmount[AmountType::DiscAmount] +
              Round(InvAmount[AmountType::DiscAmount], Currency."Amount Rounding Precision");
            ServLedgEntry."Discount Amount" := ServLedgEntry."Contract Disc. Amount";
            CalcServLedgEntryDiscountPct(ServLedgEntry);
            UpdateServLedgEntryAmount(ServLedgEntry, ServHeader2);
            ServLedgEntry.Modify();
        end;
    end;

    procedure UpdateServLedgEntryAmounts(var ServContractLine: Record "Service Contract Line"; var Currency: Record Currency; var InvRoundedAmount: array[4] of Decimal; LineInvFrom: Date; InvTo: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateServLedgEntryAmounts(ServContractLine, ServLedgEntry, InvRoundedAmount, LineInvFrom, InvTo, IsHandled);
        if IsHandled then
            exit;

        SetServLedgEntryAmounts(
          ServLedgEntry, InvRoundedAmount,
          -CalcContractLineAmount(ServContractLine."Line Amount", LineInvFrom, InvTo),
          -CalcContractLineAmount(ServContractLine."Line Value", LineInvFrom, InvTo),
          CalcContractLineAmount(ServContractLine."Line Cost", LineInvFrom, InvTo),
          CalcContractLineAmount(ServContractLine."Line Discount Amount", LineInvFrom, InvTo),
          Currency."Amount Rounding Precision");
    end;

    procedure CalcServLedgEntryDiscountPct(var ServiceLedgerEntry: Record "Service Ledger Entry")
    begin
        ServiceLedgerEntry."Discount %" := 0;
        if ServiceLedgerEntry."Unit Price" <> 0 then
            ServiceLedgerEntry."Discount %" :=
              -Round(ServiceLedgerEntry."Discount Amount" / ServiceLedgerEntry."Unit Price" * 100, 0.00001);
    end;

    procedure CreateServHeader(ServContract2: Record "Service Contract Header"; PostDate: Date; ContractExists: Boolean) ServInvNo: Code[20]
    var
        ServHeader2: Record "Service Header";
        Cust: Record Customer;
        ServDocReg: Record "Service Document Register";
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        Cust2: Record Customer;
        UserMgt: Codeunit "User Setup Management";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        if ServContract2."Invoice Period" = ServContract2."Invoice Period"::None then
            exit;

        if PostDate = 0D then
            PostDate := WorkDate;

        Clear(ServHeader2);
        ServHeader2.Init();
        ServHeader2.SetHideValidationDialog(true);
        ServHeader2."Document Type" := ServHeader2."Document Type"::Invoice;
        ServMgtSetup.Get();
        ServMgtSetup.TestField("Contract Invoice Nos.");
        OnCreateServHeaderOnBeforeInitSeries(ServHeader2, ServMgtSetup, ServContract2);
        NoSeriesMgt.InitSeries(
          ServMgtSetup."Contract Invoice Nos.", '',
          PostDate, ServHeader2."No.", ServHeader2."No. Series");
        InsertServiceHeader(ServHeader2, ServContract2);
        ServInvNo := ServHeader2."No.";

        ServHeader2."Order Date" := WorkDate;
        ServHeader2."Posting Description" :=
          Format(ServHeader2."Document Type") + ' ' + ServHeader2."No.";
        ServHeader2.Validate("Bill-to Customer No.", ServContract2."Bill-to Customer No.");
        ServHeader2."Prices Including VAT" := false;
        ServHeader2."Customer No." := ServContract2."Customer No.";
        ServHeader2.Validate("Ship-to Code", ServContract2."Ship-to Code");
        Cust.Get(ServHeader2."Customer No.");
        ServHeader2."Responsibility Center" := ServContract2."Responsibility Center";

        Cust.CheckBlockedCustOnDocs(Cust, ServHeader2."Document Type", false, false);

        if not ApplicationAreaMgmt.IsSalesTaxEnabled then
            Cust.TestField("Gen. Bus. Posting Group");
        ServHeader2.Name := Cust.Name;
        ServHeader2."Name 2" := Cust."Name 2";
        ServHeader2.Address := Cust.Address;
        ServHeader2."Address 2" := Cust."Address 2";
        ServHeader2.City := Cust.City;
        ServHeader2."Post Code" := Cust."Post Code";
        ServHeader2.County := Cust.County;
        ServHeader2."Country/Region Code" := Cust."Country/Region Code";
        ServHeader2."Contact Name" := ServContract2."Contact Name";
        ServHeader2."Contact No." := ServContract2."Contact No.";
        ServHeader2."Bill-to Contact No." := ServContract2."Bill-to Contact No.";
        ServHeader2."Bill-to Contact" := ServContract2."Bill-to Contact";
        ServHeader2."Tax Area Code" := Cust."Tax Area Code";
        ServHeader2."Tax Liable" := Cust."Tax Liable";

        if not ContractExists then
            if ServHeader2."Customer No." = ServContract2."Customer No." then
                ServHeader2.Validate("Ship-to Code", ServContract2."Ship-to Code");
        ServHeader2.Validate("Posting Date", PostDate);
        ServHeader2.Validate("Document Date", PostDate);
        ServHeader2."Contract No." := ServContract2."Contract No.";
        GLSetup.Get();
        if GLSetup."Bill-to/Sell-to VAT Calc." = GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No." then begin
            Cust2.Get(ServContract2."Bill-to Customer No.");
            ServHeader2."VAT Bus. Posting Group" := Cust2."VAT Bus. Posting Group";
            ServHeader2."VAT Registration No." := Cust2."VAT Registration No.";
            ServHeader2."VAT Country/Region Code" := Cust2."Country/Region Code";
            ServHeader2."Gen. Bus. Posting Group" := Cust2."Gen. Bus. Posting Group";
        end else begin
            ServHeader2."VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
            ServHeader2."VAT Registration No." := Cust."VAT Registration No.";
            ServHeader2."VAT Country/Region Code" := Cust."Country/Region Code";
            ServHeader2."Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
        end;
        ServHeader2."Currency Code" := ServContract2."Currency Code";
        OnCreateServHeaderOnBeforeCalcCurrencyFactor(ServHeader2, CurrExchRate);
        ServHeader2."Currency Factor" :=
          CurrExchRate.ExchangeRate(
            ServHeader2."Posting Date", ServHeader2."Currency Code");
        ServHeader2.Validate("Payment Terms Code", ServContract2."Payment Terms Code");
        ServHeader2.Validate("Payment Method Code", ServContract2."Payment Method Code");
        ServHeader2.Validate("Direct Debit Mandate ID", ServContract2."Direct Debit Mandate ID");

        ServHeader2."Your Reference" := ServContract2."Your Reference";
        SetSalespersonCode(ServContract2."Salesperson Code", ServHeader2."Salesperson Code");
        ServHeader2."Shortcut Dimension 1 Code" := ServContract2."Shortcut Dimension 1 Code";
        ServHeader2."Shortcut Dimension 2 Code" := ServContract2."Shortcut Dimension 2 Code";
        ServHeader2."Dimension Set ID" := ServContract2."Dimension Set ID";
        ServHeader2.Validate("Location Code",
          UserMgt.GetLocation(2, Cust."Location Code", ServContract2."Responsibility Center"));
        OnBeforeServHeaderModify(ServHeader2, ServContract2);
        ServHeader2.Modify();
        RecordLinkManagement.CopyLinks(ServContract2, ServHeader2);

        Clear(ServDocReg);
        ServDocReg.InsertServiceSalesDocument(
          ServDocReg."Source Document Type"::Contract, ServContract2."Contract No.",
          ServDocReg."Destination Document Type"::Invoice, ServHeader2."No.");

        OnAfterCreateServHeader(ServHeader2, ServContract2);
    end;

    local procedure InsertServiceHeader(var ServiceHeader: Record "Service Header"; var ServiceContractHeader: Record "Service Contract Header")
    begin
        OnBeforeInsertServiceHeader(ServiceHeader, ServiceContractHeader);
        ServiceHeader.Insert(true);
        OnAfterInsertServiceHeader(ServiceHeader, ServiceContractHeader);
    end;

#if not CLEAN19
    [Obsolete('Replaced by CreateServiceLine()', '19.0')]
    procedure CreateServLine(ServHeader: Record "Service Header"; ContractType: Integer; ContractNo: Code[20]; InvFrom: Date; InvTo: Date; ServiceApplyEntry: Integer; SignningContract: Boolean)
    begin
        CreateServiceLine(
            ServHeader, "Service Contract Type".FromInteger(ContractType), ContractNo, InvFrom, InvTo, ServiceApplyEntry, SignningContract);
    end;
#endif

    procedure CreateServiceLine(ServHeader: Record "Service Header"; ContractType: Enum "Service Contract Type"; ContractNo: Code[20]; InvFromDate: Date; InvToDate: Date; ServiceApplyEntry: Integer; SignningContract: Boolean)
    var
        ServContractHeader: Record "Service Contract Header";
        ServDocReg: Record "Service Document Register";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        TotalServLine: Record "Service Line";
        TotalServLineLCY: Record "Service Line";
        ServContractAccGr: Record "Service Contract Account Group";
    begin
        ServContractHeader.Get(ContractType, ContractNo);
        if ServContractHeader."Invoice Period" = ServContractHeader."Invoice Period"::None then
            exit;
        ServLineNo := 0;
        ServLine.Reset();
        ServLine.SetRange("Document Type", ServLine."Document Type"::Invoice);
        ServLine.SetRange("Document No.", ServHeader."No.");
        if ServLine.FindLast then
            ServLineNo := ServLine."Line No.";

        if ServContractHeader.Prepaid and not SignningContract then begin
            ServContractHeader.TestField("Serv. Contract Acc. Gr. Code");
            ServContractAccGr.Get(ServContractHeader."Serv. Contract Acc. Gr. Code");
            ServContractAccGr.TestField("Prepaid Contract Acc.");
            GLAcc.Get(ServContractAccGr."Prepaid Contract Acc.");
            GLAcc.TestField("Direct Posting");
        end else begin
            ServContractHeader.TestField("Serv. Contract Acc. Gr. Code");
            ServContractAccGr.Get(ServContractHeader."Serv. Contract Acc. Gr. Code");
            ServContractAccGr.TestField("Non-Prepaid Contract Acc.");
            GLAcc.Get(ServContractAccGr."Non-Prepaid Contract Acc.");
            GLAcc.TestField("Direct Posting");
        end;
        AppliedGLAccount := GLAcc."No.";

        if ServiceLedgerEntry.Get(ServiceApplyEntry) then begin
            ServiceLedgerEntry.SetRange("Entry No.", ServiceApplyEntry, ServiceLedgerEntry."Apply Until Entry No.");
            if ServiceLedgerEntry.FindSet then
                repeat
                    if ServiceLedgerEntry.Prepaid then begin
                        InvFromDate := ServiceLedgerEntry."Posting Date";
                        InvToDate := CalcDate('<CM>', InvFromDate);
                    end;
                    ServLedgEntryToServiceLine(
                      TotalServLine,
                      TotalServLineLCY,
                      ServHeader,
                      ServiceLedgerEntry,
                      ContractNo,
                      InvFromDate,
                      InvToDate);
                until ServiceLedgerEntry.Next() = 0
        end else begin
            Clear(ServiceLedgerEntry);
            ServLedgEntryToServiceLine(
              TotalServLine,
              TotalServLineLCY,
              ServHeader,
              ServiceLedgerEntry,
              ContractNo,
              InvFromDate,
              InvToDate);
        end;

        Clear(ServDocReg);
        ServDocReg.InsertServiceSalesDocument(
          ServDocReg."Source Document Type"::Contract, ContractNo,
          ServDocReg."Destination Document Type"::Invoice, ServLine."Document No.");
    end;

#if not CLEAN19
    [Obsolete('Replaced by CreateDetailedServiceLine()', '19.0')]
    procedure CreateDetailedServLine(ServHeader: Record "Service Header"; ServContractLine: Record "Service Contract Line"; ContractType: Integer; ContractNo: Code[20])
    begin
        CreateDetailedServiceLine(ServHeader, ServContractLine, "Service Contract Type".FromInteger(ContractType), ContractNo);
    end;
#endif

    procedure CreateDetailedServiceLine(ServHeader: Record "Service Header"; ServContractLine: Record "Service Contract Line"; ContractType: Enum "Service Contract Type"; ContractNo: Code[20])
    var
        ServContractHeader: Record "Service Contract Header";
        Cust: Record Customer;
        StdText: Record "Standard Text";
        FirstLine: Boolean;
        NewContract: Boolean;
    begin
        ServContractHeader.Get(ContractType, ContractNo);
        if ServContractHeader."Invoice Period" = ServContractHeader."Invoice Period"::None then
            exit;

        ServLineNo := 0;
        ServLine.SetRange("Document Type", ServLine."Document Type"::Invoice);
        ServLine.SetRange("Document No.", ServHeader."No.");
        if ServLine.FindLast then begin
            ServLineNo := ServLine."Line No.";
            NewContract := ServLine."Contract No." <> ServContractHeader."Contract No.";
            ServLine.Init();
        end else begin
            FirstLine := true;
            NewContract := true;
        end;

        OnCreateDetailedServLineOnAfterSetFirstLineAndNewContract(FirstLine, NewContract, ServContractHeader);

        Cust.Get(ServContractHeader."Bill-to Customer No.");
        ServLine.Reset();

        if FirstLine or NewContract then
            ServMgtSetup.Get();

        if FirstLine then begin
            ServLine.Init();
            ServLineNo := ServLineNo + 10000;
            ServLine."Document Type" := ServHeader."Document Type";
            ServLine."Document No." := ServHeader."No.";
            ServLine."Line No." := ServLineNo;
            ServLine.Type := ServLine.Type::" ";
            if ServMgtSetup."Contract Line Inv. Text Code" <> '' then begin
                StdText.Get(ServMgtSetup."Contract Line Inv. Text Code");
                ServLine.Description := StdText.Description;
            end else
                ServLine.Description := Text003;
            OnCreateDetailedServLineOnBeforeServLineInsertFirstLine(ServLine, ServContractHeader);
            ServLine.Insert();
        end;

        if NewContract then begin
            OnBeforeCreateServLineForNewContract(ServHeader, ServContractHeader, ServLineNo);
            ServLine.Init();
            ServLineNo := ServLineNo + 10000;
            ServLine."Document Type" := ServHeader."Document Type";
            ServLine."Document No." := ServHeader."No.";
            ServLine."Line No." := ServLineNo;
            ServLine.Type := ServLine.Type::" ";
            if ServMgtSetup."Contract Inv. Line Text Code" <> '' then begin
                StdText.Get(ServMgtSetup."Contract Inv. Line Text Code");
                TempServLineDescription := StrSubstNo('%1 %2', StdText.Description, ServContractHeader."Contract No.");
                if StrLen(TempServLineDescription) > MaxStrLen(ServLine.Description) then
                    Error(
                      Text013,
                      ServLine.TableCaption, ServLine.FieldCaption(Description),
                      StdText.TableCaption, StdText.Code, StdText.FieldCaption(Description),
                      Format(StrLen(TempServLineDescription) - MaxStrLen(ServLine.Description)));
                ServLine.Description := CopyStr(TempServLineDescription, 1, MaxStrLen(ServLine.Description));
            end else
                ServLine.Description := StrSubstNo(Text002, ServContractHeader."Contract No.");
            OnCreateDetailedServLineOnBeforeServLineInsertNewContract(ServLine, ServContractHeader);
            ServLine.Insert();
        end;

        OnCreateDetailedServLineOnBeforeCreateDescriptionServiceLines(ServContractHeader, ServContractLine, ServHeader);
        CreateDescriptionServiceLines(ServContractLine."Service Item No.", ServContractLine.Description, ServContractLine."Serial No.");
    end;

#if not CLEAN19
    [Obsolete('CreateLastServiceLines', '19.0')]
    procedure CreateLastServLines(ServHeader: Record "Service Header"; ContractType: Integer; ContractNo: Code[20])
    begin
        CreateLastServiceLines(ServHeader, "Service Contract Type".FromInteger(ContractType), ContractNo);
    end;
#endif

    procedure CreateLastServiceLines(ServHeader: Record "Service Header"; ContractType: Enum "Service Contract Type"; ContractNo: Code[20])
    var
        ServContractHeader: Record "Service Contract Header";
        StdText: Record "Standard Text";
        Cust: Record Customer;
        TransferExtendedText: Codeunit "Transfer Extended Text";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateLastServLines(ServHeader, ContractType.AsInteger(), ContractNo, IsHandled);
        if IsHandled then
            exit;

        ServContractHeader.Get(ContractType, ContractNo);
        if ServContractHeader."Invoice Period" = ServContractHeader."Invoice Period"::None then
            exit;

        Cust.Get(ServContractHeader."Bill-to Customer No.");
        if ServContractHeader."Print Increase Text" then
            if ServContractHeader."Price Inv. Increase Code" <> '' then
                if StdText.Get(ServContractHeader."Price Inv. Increase Code") then begin
                    ServLine.Init();
                    ServLine."Document Type" := ServHeader."Document Type";
                    ServLine."Document No." := ServHeader."No.";
                    ServLine.Type := ServLine.Type::" ";
                    ServLine."No." := ServContractHeader."Price Inv. Increase Code";
                    ServLine."Contract No." := ContractNo;
                    ServLine.Description := StdText.Description;
                    if ServLine.Description <> '' then begin
                        ServLineNo := ServLineNo + 10000;
                        ServLine."Line No." := ServLineNo;
                        ServLine.Insert();
                        if TransferExtendedText.ServCheckIfAnyExtText(ServLine, true) then
                            TransferExtendedText.InsertServExtText(ServLine);
                        if TransferExtendedText.MakeUpdate then;
                        ServLine."No." := '';
                        OnBeforeLastServLineModify(ServLine);
                        ServLine.Modify();
                    end;
                end;
    end;

    local procedure CreateOrGetCreditHeader(ServContract: Record "Service Contract Header"; CrMemoDate: Date) ServInvoiceNo: Code[20]
    var
        GLSetup: Record "General Ledger Setup";
        ServHeader2: Record "Service Header";
        Cust: Record Customer;
        ServDocReg: Record "Service Document Register";
        CurrExchRate: Record "Currency Exchange Rate";
        UserMgt: Codeunit "User Setup Management";
        ConfirmManagement: Codeunit "Confirm Management";
        CreditMemoForm: Page "Service Credit Memo";
        ServContractForm: Page "Service Contract";
        LocationCode: Code[10];
    begin
        Clear(ServHeader2);
        ServDocReg.Reset();
        ServDocReg.SetRange("Source Document Type", ServDocReg."Source Document Type"::Contract);
        ServDocReg.SetRange("Source Document No.", ServContract."Contract No.");
        ServDocReg.SetRange("Destination Document Type", ServDocReg."Destination Document Type"::"Credit Memo");
        ServInvoiceNo := '';
        if ServDocReg.Find('-') then
            repeat
                ServInvoiceNo := ServDocReg."Destination Document No.";
            until (ServDocReg.Next() = 0) or (ServDocReg."Destination Document No." <> '');

        if ServInvoiceNo <> '' then begin
            ServHeader2.Get(ServHeader2."Document Type"::"Credit Memo", ServInvoiceNo);
            Cust.Get(ServHeader2."Bill-to Customer No.");
            LocationCode := UserMgt.GetLocation(2, Cust."Location Code", ServContract."Responsibility Center");
            if ServHeader2."Location Code" <> LocationCode then
                if not ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(
                       Text015,
                       ServHeader2.FieldCaption("Location Code"),
                       ServHeader2."Location Code",
                       CreditMemoForm.Caption,
                       ServInvoiceNo,
                       ServContractForm.Caption,
                       ServContract."Contract No.",
                       LocationCode), true)
                then
                    Error('');
            exit;
        end;

        Clear(ServHeader2);
        ServHeader2.Init();
        ServHeader2.SetHideValidationDialog(true);
        ServHeader2."Document Type" := ServHeader2."Document Type"::"Credit Memo";
        ServMgtSetup.Get();
        ServMgtSetup.TestField("Contract Credit Memo Nos.");
        OnCreateOrGetCreditHeaderOnBeforeInitSeries(ServHeader2, ServMgtSetup);
        NoSeriesMgt.InitSeries(
          ServMgtSetup."Contract Credit Memo Nos.", ServHeader2."No. Series", 0D,
          ServHeader2."No.", ServHeader2."No. Series");
        InsertServiceHeader(ServHeader2, ServContract);
        ServInvoiceNo := ServHeader2."No.";

        GLSetup.Get();
        ServHeader2.Correction := GLSetup."Mark Cr. Memos as Corrections";
        ServHeader2."Posting Description" := Format(ServHeader2."Document Type") + ' ' + ServHeader2."No.";
        ServHeader2.Validate("Bill-to Customer No.", ServContract."Bill-to Customer No.");
        ServHeader2."Prices Including VAT" := false;
        ServHeader2."Customer No." := ServContract."Customer No.";
        ServHeader2."Responsibility Center" := ServContract."Responsibility Center";
        Cust.Get(ServHeader2."Customer No.");
        Cust.CheckBlockedCustOnDocs(Cust, ServHeader2."Document Type", false, false);
        if not ApplicationAreaMgmt.IsSalesTaxEnabled then
            Cust.TestField("Gen. Bus. Posting Group");
        ServHeader2.Name := Cust.Name;
        ServHeader2."Name 2" := Cust."Name 2";
        ServHeader2.Address := Cust.Address;
        ServHeader2."Address 2" := Cust."Address 2";
        ServHeader2.City := Cust.City;
        ServHeader2."Post Code" := Cust."Post Code";
        ServHeader2.County := Cust.County;
        ServHeader2."Country/Region Code" := Cust."Country/Region Code";
        ServHeader2."Contact Name" := ServContract."Contact Name";
        ServHeader2."Contact No." := ServContract."Contact No.";
        ServHeader2."Bill-to Contact No." := ServContract."Bill-to Contact No.";
        ServHeader2."Bill-to Contact" := ServContract."Bill-to Contact";
        ServHeader2."Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
        if GLSetup."Bill-to/Sell-to VAT Calc." = GLSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No." then
            ServHeader2."VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
        ServHeader2.Validate("Ship-to Code", ServContract."Ship-to Code");
        if CrMemoDate <> 0D then
            ServHeader2.Validate("Posting Date", CrMemoDate)
        else
            ServHeader2.Validate("Posting Date", WorkDate);
        ServHeader2."Contract No." := ServContract."Contract No.";
        ServHeader2."Currency Code" := ServContract."Currency Code";
        OnCreateOrGetCreditHeaderOnBeforeCalcCurrencyFactor(ServHeader2, CurrExchRate);
        ServHeader2."Currency Factor" :=
          CurrExchRate.ExchangeRate(
            ServHeader2."Posting Date", ServHeader2."Currency Code");
        ServHeader2."Payment Terms Code" := ServContract."Payment Terms Code";
        ServHeader2."Your Reference" := ServContract."Your Reference";
        ServHeader2."Salesperson Code" := ServContract."Salesperson Code";
        ServHeader2."Shortcut Dimension 1 Code" := ServContract."Shortcut Dimension 1 Code";
        ServHeader2."Shortcut Dimension 2 Code" := ServContract."Shortcut Dimension 2 Code";
        ServHeader2."Dimension Set ID" := ServContract."Dimension Set ID";
        ServHeader2.Validate("Location Code",
          UserMgt.GetLocation(2, Cust."Location Code", ServContract."Responsibility Center"));
        OnBeforeServHeaderModify(ServHeader2, ServContract);
        ServHeader2.Modify();

        Clear(ServDocReg);
        ServDocReg.InsertServiceSalesDocument(
          ServDocReg."Source Document Type"::Contract, ServContract."Contract No.",
          ServDocReg."Destination Document Type"::"Credit Memo", ServHeader2."No.");

        OnAfterCreateOrGetCreditHeader(ServHeader2, ServContract);
    end;

    local procedure CreateCreditLine(CreditNo: Code[20]; AccountNo: Code[20]; CreditAmount: Decimal; PeriodStarts: Date; PeriodEnds: Date; LineDescription: Text[100]; ServItemNo: Code[20]; ServContract: Record "Service Contract Header"; CreditCost: Decimal; CreditUnitPrice: Decimal; DiscAmount: Decimal; ApplyDiscAmt: Boolean; ServLedgEntryNo: Integer)
    var
        ServHeader2: Record "Service Header";
        ServLine2: Record "Service Line";
        Cust: Record Customer;
    begin
        ServHeader2.Get(ServHeader2."Document Type"::"Credit Memo", CreditNo);
        Cust.Get(ServHeader2."Bill-to Customer No.");

        Clear(ServLine2);
        ServLine2.SetRange("Document Type", ServHeader2."Document Type");
        ServLine2.SetRange("Document No.", CreditNo);
        if ServLine2.FindLast then
            NextLine := ServLine2."Line No." + 10000
        else
            NextLine := 10000;
        Clear(ServLine2);
        ServLine2.Init();
        ServLine2."Document Type" := ServHeader2."Document Type";
        ServLine2."Document No." := ServHeader2."No.";
        ServLine2.Type := ServLine2.Type::" ";
        ServLine2.Description := StrSubstNo('%1 - %2', Format(PeriodStarts), Format(PeriodEnds));
        ServLine2."Line No." := NextLine;
        ServLine2."Posting Date" := PeriodStarts;
        ServLine2.Insert();

        NextLine := NextLine + 10000;
        ServLine2."Customer No." := ServHeader2."Customer No.";
        ServLine2."Location Code" := ServHeader2."Location Code";
        ServLine2."Shortcut Dimension 1 Code" := ServHeader2."Shortcut Dimension 1 Code";
        ServLine2."Shortcut Dimension 2 Code" := ServHeader2."Shortcut Dimension 2 Code";
        ServLine2."Dimension Set ID" := ServHeader2."Dimension Set ID";
        ServLine2."Gen. Bus. Posting Group" := ServHeader2."Gen. Bus. Posting Group";
        ServLine2."Transaction Specification" := ServHeader2."Transaction Specification";
        ServLine2."Transport Method" := ServHeader2."Transport Method";
        ServLine2."Exit Point" := ServHeader2."Exit Point";
        ServLine2.Area := ServHeader2.Area;
        ServLine2."Transaction Specification" := ServHeader2."Transaction Specification";
        ServLine2."Line No." := NextLine;
        ServLine2.Type := ServLine.Type::"G/L Account";
        ServLine2.Validate("No.", AccountNo);
        ServLine2.Validate(Quantity, 1);
        if ServHeader2."Currency Code" <> '' then begin
            ServLine2.Validate("Unit Price", AmountToFCY(CreditUnitPrice, ServHeader2));
            ServLine2.Validate("Line Amount", AmountToFCY(CreditAmount, ServHeader2));
        end else begin
            ServLine2.Validate("Unit Price", CreditUnitPrice);
            ServLine2.Validate("Line Amount", CreditAmount);
        end;
        ServLine2.Description := LineDescription;
        ServLine2."Contract No." := ServContract."Contract No.";
        ServLine2."Service Item No." := ServItemNo;
        ServLine2."Appl.-to Service Entry" := ServLedgEntryNo;
        ServLine2."Unit Cost (LCY)" := CreditCost;
        ServLine2."Posting Date" := PeriodStarts;
        if ApplyDiscAmt then
            ServLine2.Validate("Line Discount Amount", DiscAmount);
        ServLine2.CreateDim(
          DimMgt.TypeToTableID5(ServLine2.Type.AsInteger()), ServLine2."No.",
          DATABASE::Job, ServLine2."Job No.",
          DATABASE::"Responsibility Center", ServLine2."Responsibility Center");
        OnBeforeServLineInsert(ServLine2, ServHeader2, ServContract);
        ServLine2.Insert();
    end;

    procedure CreateContractLineCreditMemo(var FromServiceContractLine: Record "Service Contract Line"; Deleting: Boolean) CreditMemoNo: Code[20]
    var
        ServItem: Record "Service Item";
        ServContractHeader: Record "Service Contract Header";
        StdText: Record "Standard Text";
        Currency: Record Currency;
        ServiceContract: Page "Service Contract";
        ServiceCreditMemo: Page "Service Credit Memo";
        ServiceInvoice: Page "Service Invoice";
        CreditAmount: Decimal;
        FirstPrepaidPostingDate: Date;
        LastIncomePostingDate: Date;
        WDate: Date;
        LineDescription: Text[100];
    begin
        OnBeforeCreateContractLineCreditMemo(FromServiceContractLine, Deleting);
        CreditMemoNo := '';
        with FromServiceContractLine do begin
            ServContractHeader.Get("Contract Type", "Contract No.");
            TestField("Contract Expiration Date");
            TestField("Credit Memo Date");
            if "Credit Memo Date" > WorkDate then
                Error(
                  Text004,
                  FieldCaption("Credit Memo Date"), "Credit Memo Date");
            ServContractHeader.CalcFields("No. of Unposted Invoices");
            if ServContractHeader."No. of Unposted Invoices" <> 0 then
                Error(
                  Text014,
                  ServiceCreditMemo.Caption,
                  ServiceContract.Caption,
                  ServContractHeader."Contract No.",
                  ServiceInvoice.Caption);

            CheckContractGroupAccounts(ServContractHeader);

            FillTempServiceLedgerEntries(ServContractHeader);
            Currency.InitRoundingPrecision;

            if "Line Amount" > 0 then begin
                ServMgtSetup.Get();
                if ServMgtSetup."Contract Credit Line Text Code" <> '' then begin
                    StdText.Get(ServMgtSetup."Contract Credit Line Text Code");
                    LineDescription := CopyStr(StrSubstNo('%1 %2', StdText.Description, "Service Item No."), 1, 50);
                end else
                    if "Service Item No." <> '' then
                        LineDescription := CopyStr(StrSubstNo(Text005, ServItem.TableCaption, "Service Item No."), 1, 50)
                    else
                        LineDescription := CopyStr(StrSubstNo(Text005, TableCaption, "Line No."), 1, 50);
                if "Invoiced to Date" >= "Contract Expiration Date" then begin
                    if ServContractHeader.Prepaid then begin
                        FirstPrepaidPostingDate := FindFirstPrepaidTransaction("Contract No.");
                    end else
                        FirstPrepaidPostingDate := 0D;

                    LastIncomePostingDate := "Invoiced to Date";
                    if FirstPrepaidPostingDate <> 0D then
                        LastIncomePostingDate := FirstPrepaidPostingDate - 1;
                    WDate := "Contract Expiration Date";
                    OnCreateContractLineCreditMemoOnBeforeCalcCreditAmount(WDate, ServContractHeader, FromServiceContractLine);
                    CreditAmount :=
                      Round(
                        CalcContractLineAmount("Line Amount",
                          WDate, "Invoiced to Date"),
                        Currency."Amount Rounding Precision");
                    if CreditAmount > 0 then begin
                        CreditMemoNo := CreateOrGetCreditHeader(ServContractHeader, "Credit Memo Date");
                        CreateAllCreditLines(
                            CreditMemoNo, "Line Amount", WDate, "Invoiced to Date", LineDescription, "Service Item No.", "Item No.",
                            ServContractHeader, "Line Cost", "Line Value", LastIncomePostingDate, "Starting Date");
                        OnCreateContractLineCreditMemoOnAfterCreateAllCreditLines(ServContractHeader, FromServiceContractLine, CreditMemoNo);
                    end;
                end;
            end;
            if (CreditMemoNo <> '') and not Deleting then begin
                Credited := true;
                Modify;
            end;
        end;

        OnAfterCreateContractLineCreditMemo(FromServiceContractLine, CreditMemoNo);
    end;

    procedure CheckContractGroupAccounts(ServContractHeader: Record "Service Contract Header")
    var
        GLAcc: Record "G/L Account";
        ServContractAccGr: Record "Service Contract Account Group";
    begin
        ServContractHeader.TestField("Serv. Contract Acc. Gr. Code");
        ServContractAccGr.Get(ServContractHeader."Serv. Contract Acc. Gr. Code");
        ServContractAccGr.TestField("Non-Prepaid Contract Acc.");
        GLAcc.Get(ServContractAccGr."Non-Prepaid Contract Acc.");
        GLAcc.TestField("Direct Posting");
        if ServContractHeader.Prepaid then begin
            ServContractAccGr.TestField("Prepaid Contract Acc.");
            GLAcc.Get(ServContractAccGr."Prepaid Contract Acc.");
            GLAcc.TestField("Direct Posting");
        end;
    end;

    procedure FindFirstPrepaidTransaction(ContractNo: Code[20]): Date
    var
        ServLedgEntry: Record "Service Ledger Entry";
    begin
        Clear(ServLedgEntry);
        ServLedgEntry.SetCurrentKey(Type, "No.", "Entry Type", "Moved from Prepaid Acc.", "Posting Date", Open);
        ServLedgEntry.SetRange(Type, ServLedgEntry.Type::"Service Contract");
        ServLedgEntry.SetRange("No.", ContractNo);
        ServLedgEntry.SetRange("Moved from Prepaid Acc.", false);
        ServLedgEntry.SetRange(Prepaid, true);
        if ServLedgEntry.FindFirst then
            exit(ServLedgEntry."Posting Date");

        exit(0D);
    end;

    local procedure CreateAllCreditLines(CreditNo: Code[20]; ContractLineAmount: Decimal; PeriodStarts: Date; PeriodEnds: Date; LineDescription: Text[100]; ServItemNo: Code[20]; ItemNo: Code[20]; ServContract: Record "Service Contract Header"; ContractLineCost: Decimal; ContractLineUnitPrice: Decimal; LastIncomePostingDate: Date; ContractLineStartingDate: Date)
    var
        Currency: Record Currency;
        ServContractAccGr: Record "Service Contract Account Group";
        AccountNo: Code[20];
        WDate: Date;
        OldWDate: Date;
        i: Integer;
        Days: Integer;
        InvPeriod: Integer;
        AppliedCreditLineAmount: Decimal;
        AppliedCreditLineCost: Decimal;
        AppliedCreditLineUnitCost: Decimal;
        AppliedCreditLineDiscAmount: Decimal;
        ApplyServiceLedgerEntryAmounts: Boolean;
        ServLedgEntryNo: Integer;
    begin
        Days := Date2DMY(ContractLineStartingDate, 1);
        Currency.InitRoundingPrecision;
        if ServContract.Prepaid then
            InvPeriod := 1
        else
            case ServContract."Invoice Period" of
                ServContract."Invoice Period"::Month:
                    InvPeriod := 1;
                ServContract."Invoice Period"::"Two Months":
                    InvPeriod := 2;
                ServContract."Invoice Period"::Quarter:
                    InvPeriod := 3;
                ServContract."Invoice Period"::"Half Year":
                    InvPeriod := 6;
                ServContract."Invoice Period"::Year:
                    InvPeriod := 12;
                ServContract."Invoice Period"::None:
                    InvPeriod := 0;
                else
                    OnCreateAllCreditLinesCaseElse(ServContract, InvPeriod);
            end;
        ServContract.TestField("Serv. Contract Acc. Gr. Code");
        ServContractAccGr.Get(ServContract."Serv. Contract Acc. Gr. Code");
        ServContractAccGr.TestField("Prepaid Contract Acc.");
        WDate := ContractLineStartingDate;
        repeat
            OldWDate := CalcDate('<CM>', WDate);
            if Days <> 1 then
                Days := 1
            else begin
                for i := 1 to InvPeriod do
                    OldWDate := CalcDate('<CM>', OldWDate) + 1;
                OldWDate := OldWDate - 1;
            end;

            OnCreateAllCreditLinesOnAfterDetermineOldWDate(ServContract, InvPeriod, Days, WDate, OldWDate);

            if OldWDate >= PeriodStarts then begin
                if WDate < PeriodStarts then
                    WDate := PeriodStarts;
                if OldWDate > PeriodEnds then
                    OldWDate := PeriodEnds;
                if OldWDate > LastIncomePostingDate then
                    AccountNo := ServContractAccGr."Prepaid Contract Acc."
                else
                    AccountNo := ServContractAccGr."Non-Prepaid Contract Acc.";
                ApplyServiceLedgerEntryAmounts :=
                  LookUpAmountToCredit(
                    ServItemNo,
                    ItemNo,
                    WDate,
                    AppliedCreditLineAmount,
                    AppliedCreditLineCost,
                    AppliedCreditLineUnitCost,
                    AppliedCreditLineDiscAmount,
                    ServLedgEntryNo);
                if not ApplyServiceLedgerEntryAmounts then begin
                    AppliedCreditLineAmount :=
                      Round(CalcContractLineAmount(ContractLineAmount, WDate, OldWDate), Currency."Amount Rounding Precision");
                    AppliedCreditLineCost :=
                      Round(CalcContractLineAmount(ContractLineCost, WDate, OldWDate), Currency."Amount Rounding Precision");
                    AppliedCreditLineUnitCost :=
                      Round(CalcContractLineAmount(ContractLineUnitPrice, WDate, OldWDate), Currency."Amount Rounding Precision");
                end;
                CreateCreditLine(
                  CreditNo,
                  AccountNo,
                  AppliedCreditLineAmount,
                  WDate,
                  OldWDate,
                  LineDescription,
                  ServItemNo,
                  ServContract,
                  AppliedCreditLineCost,
                  AppliedCreditLineUnitCost,
                  AppliedCreditLineDiscAmount,
                  ApplyServiceLedgerEntryAmounts,
                  ServLedgEntryNo);
            end;
            WDate := CalcDate('<CM>', OldWDate) + 1;
        until (OldWDate >= PeriodEnds);
    end;

    procedure GetNextInvoicePeriod(InvoicedServContractHeader: Record "Service Contract Header"; var InvFrom: Date; var InvTo: Date)
    begin
        InvFrom := InvoicedServContractHeader."Next Invoice Period Start";
        InvTo := InvoicedServContractHeader."Next Invoice Period End";
    end;

    procedure NoOfDayInYear(InputDate: Date): Integer
    var
        W1: Date;
        W2: Date;
        YY: Integer;
    begin
        YY := Date2DMY(InputDate, 3);
        W1 := DMY2Date(1, 1, YY);
        W2 := DMY2Date(31, 12, YY);
        exit(W2 - W1 + 1);
    end;

    procedure NoOfMonthsAndDaysInPeriod(Day1: Date; Day2: Date; var NoOfMonthsInPeriod: Integer; var NoOfDaysInPeriod: Integer)
    var
        Wdate: Date;
        FirstDayinCrntMonth: Date;
        LastDayinCrntMonth: Date;
    begin
        NoOfMonthsInPeriod := 0;
        NoOfDaysInPeriod := 0;

        if Day1 > Day2 then
            exit;
        if Day1 = 0D then
            exit;
        if Day2 = 0D then
            exit;

        Wdate := Day1;
        repeat
            FirstDayinCrntMonth := CalcDate('<-CM>', Wdate);
            LastDayinCrntMonth := CalcDate('<CM>', Wdate);
            if (Wdate = FirstDayinCrntMonth) and (LastDayinCrntMonth <= Day2) then begin
                NoOfMonthsInPeriod := NoOfMonthsInPeriod + 1;
                Wdate := LastDayinCrntMonth + 1;
            end else begin
                NoOfDaysInPeriod := NoOfDaysInPeriod + 1;
                Wdate := Wdate + 1;
            end;
        until Wdate > Day2;
    end;

    procedure NoOfMonthsAndMPartsInPeriod(Day1: Date; Day2: Date) MonthsAndMParts: Decimal
    var
        WDate: Date;
        OldWDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNoOfMonthsAndMPartsInPeriod(Day1, Day2, CheckMParts, MonthsAndMParts, IsHandled);
        if IsHandled then
            exit;

        if Day1 > Day2 then
            exit;
        if (Day1 = 0D) or (Day2 = 0D) then
            exit;
        MonthsAndMParts := 0;

        WDate := CalcDate('<-CM>', Day1);
        repeat
            OldWDate := CalcDate('<CM>', WDate);
            if WDate < Day1 then
                WDate := Day1;
            if OldWDate > Day2 then
                OldWDate := Day2;
            if (WDate <> CalcDate('<-CM>', WDate)) or (OldWDate <> CalcDate('<CM>', OldWDate)) then
                MonthsAndMParts := MonthsAndMParts +
                  (OldWDate - WDate + 1) / (CalcDate('<CM>', OldWDate) - CalcDate('<-CM>', WDate) + 1)
            else
                MonthsAndMParts := MonthsAndMParts + 1;
            WDate := CalcDate('<CM>', OldWDate) + 1;
            if MonthsAndMParts <> Round(MonthsAndMParts, 1) then
                CheckMParts := true;
        until WDate > Day2;
    end;

    procedure CalcContractAmount(ServContractHeader: Record "Service Contract Header"; PeriodStarts: Date; PeriodEnds: Date) AmountCalculated: Decimal
    var
        ServContractLine: Record "Service Contract Line";
        Currency: Record Currency;
        LinePeriodStarts: Date;
        LinePeriodEnds: Date;
        ContractLineIncluded: Boolean;
    begin
        OnBeforeCalcContractAmount(ServContractHeader, PeriodStarts, PeriodEnds);
        Currency.InitRoundingPrecision;
        AmountCalculated := 0;

        if ServContractHeader."Expiration Date" <> 0D then begin
            if ServContractHeader."Expiration Date" < PeriodStarts then
                exit;
            if (ServContractHeader."Expiration Date" >= PeriodStarts) and
               (ServContractHeader."Expiration Date" <= PeriodEnds)
            then
                PeriodEnds := ServContractHeader."Expiration Date";
        end;

        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", ServContractHeader."Contract Type");
        ServContractLine.SetRange("Contract No.", ServContractHeader."Contract No.");
        if ServContractHeader.Prepaid then
            ServContractLine.SetFilter("Starting Date", '<=%1', ServContractHeader."Next Invoice Date")
        else
            if ServContractHeader."Last Invoice Date" <> 0D
            then
                ServContractLine.SetFilter("Invoiced to Date", '%1|%2', ServContractHeader."Last Invoice Date", 0D);
        if ServContractLine.Find('-') then begin
            repeat
                ContractLineIncluded := true;
                if ServContractLine."Invoiced to Date" = 0D then
                    LinePeriodStarts := ServContractLine."Starting Date"
                else
                    LinePeriodStarts := PeriodStarts;
                LinePeriodEnds := PeriodEnds;
                if ServContractLine."Contract Expiration Date" <> 0D then begin
                    if ServContractLine."Contract Expiration Date" < PeriodStarts then
                        ContractLineIncluded := false
                    else
                        if (ServContractLine."Contract Expiration Date" >= PeriodStarts) and
                           (ServContractLine."Contract Expiration Date" <= PeriodEnds)
                        then
                            LinePeriodStarts := PeriodStarts;
                end;
                if ContractLineIncluded then
                    AmountCalculated := AmountCalculated +
                      CalcContractLineAmount(ServContractLine."Line Amount", LinePeriodStarts, LinePeriodEnds);

            until ServContractLine.Next() = 0;
            AmountCalculated := Round(AmountCalculated, Currency."Amount Rounding Precision");
        end else begin
            ServContractLine.SetRange("Starting Date");
            ServContractLine.SetRange("Invoiced to Date");
            if ServContractLine.IsEmpty() then
                AmountCalculated :=
                  Round(
                    ServContractHeader."Annual Amount" / 12 * NoOfMonthsAndMPartsInPeriod(PeriodStarts, PeriodEnds),
                    Currency."Amount Rounding Precision");
        end;
    end;

    procedure CalcContractLineAmount(AnnualAmount: Decimal; PeriodStarts: Date; PeriodEnds: Date) AmountCalculated: Decimal
    begin
        AmountCalculated := AnnualAmount / 12 * NoOfMonthsAndMPartsInPeriod(PeriodStarts, PeriodEnds);

        OnAfterCalcContractLineAmount(AnnualAmount, PeriodStarts, PeriodEnds, AmountCalculated);
    end;

    procedure CreateRemainingPeriodInvoice(var CurrServContract: Record "Service Contract Header") InvoiceNo: Code[20]
    var
        ServContractLine: Record "Service Contract Line";
        InvFrom: Date;
        InvTo: Date;
    begin
        OnBeforeCreateRemainingPeriodInvoice(CurrServContract);
        CurrServContract.TestField("Change Status", CurrServContract."Change Status"::Locked);
        if CurrServContract.Prepaid then
            InvTo := CurrServContract."Next Invoice Date" - 1
        else
            InvTo := CurrServContract."Next Invoice Period Start" - 1;
        if (CurrServContract."Last Invoice Date" = 0D) and
           (CurrServContract."Starting Date" < CurrServContract."Next Invoice Period Start")
        then begin
            InvFrom := CurrServContract."Starting Date";
            if (InvFrom = CalcDate('<-CM>', InvFrom)) and CurrServContract.Prepaid then
                exit;
        end else
            if CurrServContract."Last Invoice Period End" <> 0D then begin
                if CurrServContract."Last Invoice Period End" <> CalcDate('<CM>', CurrServContract."Last Invoice Period End") then
                    InvFrom := CalcDate('<+1D>', CurrServContract."Last Invoice Period End");
                ServContractLine.Reset();
                ServContractLine.SetRange("Contract Type", CurrServContract."Contract Type");
                ServContractLine.SetRange("Contract No.", CurrServContract."Contract No.");
                ServContractLine.SetRange("Invoiced to Date", 0D);
                ServContractLine.SetFilter("Starting Date", '<=%1', InvTo);
                OnCreateRemainingPeriodInvoiceOnAfterServContractLineSetFilters(ServContractLine, CurrServContract);
                if ServContractLine.Find('-') then
                    repeat
                        if InvFrom <> 0D then begin
                            if ServContractLine."Starting Date" < InvFrom then
                                InvFrom := ServContractLine."Starting Date"
                        end else
                            InvFrom := ServContractLine."Starting Date";
                    until ServContractLine.Next() = 0;
            end;

        if (InvFrom = 0D) or (InvFrom > InvTo) then
            exit;
        if ConfirmCreateServiceInvoiceForPeriod(CurrServContract, InvFrom, InvTo) then begin
            InvoiceNo := CreateServHeader(CurrServContract, PostingDate, false);
            ServHeader.Get(ServHeader."Document Type"::Invoice, InvoiceNo);
            ServMgtSetup.Get();
            if not CurrServContract.Prepaid then
                CurrServContract.Validate("Last Invoice Date", InvTo)
            else begin
                CurrServContract."Last Invoice Date" := CurrServContract."Starting Date";
                CurrServContract.Validate("Last Invoice Period End", InvTo);
            end;
            if CurrServContract."Contract Lines on Invoice" then begin
                ServContractLine.Reset();
                ServContractLine.SetRange("Contract Type", CurrServContract."Contract Type");
                ServContractLine.SetRange("Contract No.", CurrServContract."Contract No.");
                ServContractLine.SetFilter("Starting Date", '<=%1', InvTo);
                OnCreateRemainingPeriodInvoiceOnAfterServContractLineSetFilters(ServContractLine, CurrServContract);
                if ServContractLine.Find('-') then
                    repeat
                        if ServContractLine."Invoiced to Date" = 0D then
                            CreateDetailedServiceLine(
                              ServHeader, ServContractLine, CurrServContract."Contract Type", CurrServContract."Contract No.");
                        if ServContractLine."Invoiced to Date" <> 0D then
                            if ServContractLine."Invoiced to Date" <> CalcDate('<CM>', ServContractLine."Invoiced to Date") then
                                CreateDetailedServiceLine(
                                  ServHeader, ServContractLine, CurrServContract."Contract Type", CurrServContract."Contract No.");

                        AppliedEntry :=
                          CreateServiceLedgEntry(
                            ServHeader, CurrServContract."Contract Type",
                            CurrServContract."Contract No.", InvFrom, InvTo, true, false, ServContractLine."Line No.");

                        CreateServiceLine(
                          ServHeader, CurrServContract."Contract Type",
                          CurrServContract."Contract No.", InvFrom, InvTo, AppliedEntry, true);
                    until ServContractLine.Next() = 0;
            end else begin
                CreateHeadingServiceLine(
                  ServHeader, CurrServContract."Contract Type", CurrServContract."Contract No.");

                AppliedEntry :=
                  CreateServiceLedgEntry(
                    ServHeader, CurrServContract."Contract Type",
                    CurrServContract."Contract No.", InvFrom, InvTo, true, false, 0);

                CreateServiceLine(
                  ServHeader, CurrServContract."Contract Type",
                  CurrServContract."Contract No.", InvFrom, InvTo, AppliedEntry, true);
            end;

            CurrServContract.Modify();
            InvoicingStartingPeriod := true;

            OnAfterCreateRemainingPeriodInvoice(CurrServContract);
        end;
    end;

    local procedure ConfirmCreateServiceInvoiceForPeriod(var CurrServContract: Record "Service Contract Header"; InvFrom: Date; InvTo: Date) Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmCreateServiceInvoiceForPeriod(CurrServContract, InvFrom, InvTo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text006, InvFrom, InvTo), true));
    end;

    procedure InitCodeUnit()
    var
        ServLedgEntry: Record "Service Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        KeepFromWarrEntryNo: Integer;
        KeepToWarrEntryNo: Integer;
    begin
        with ServLedgEntry do begin
            Reset;
            LockTable();
            if FindLast then begin
                NextEntry := "Entry No." + 1;
            end else
                NextEntry := 1;

            ServiceRegister.Reset();
            ServiceRegister.LockTable();
            if ServiceRegister.FindLast then begin
                ServiceRegister."No." := ServiceRegister."No." + 1;
                KeepFromWarrEntryNo := ServiceRegister."From Warranty Entry No.";
                KeepToWarrEntryNo := ServiceRegister."To Warranty Entry No.";
            end else
                ServiceRegister."No." := 1;

            ServiceRegister.Init();
            ServiceRegister."From Entry No." := NextEntry;
            ServiceRegister."From Warranty Entry No." := KeepFromWarrEntryNo;
            ServiceRegister."To Warranty Entry No." := KeepToWarrEntryNo;
            ServiceRegister."Creation Date" := Today;
            ServiceRegister."Creation Time" := Time;
            SourceCodeSetup.Get();
            ServiceRegister."Source Code" := SourceCodeSetup."Service Management";
            ServiceRegister."User ID" := UserId;
        end;
    end;

    procedure FinishCodeunit()
    begin
        ServiceRegister."To Entry No." := NextEntry - 1;
        ServiceRegister.Insert();

        OnAfterFinishCodeunit(ServiceRegister);
    end;

    procedure CopyCheckSCDimToTempSCDim(ServContract: Record "Service Contract Header")
    begin
        OnBeforeCopyCheckSCDimToTempSCDim(ServContract);

        CheckDimComb(ServContract, 0);
        CheckDimValuePosting(ServContract, 0);
    end;

    local procedure CheckDimComb(ServContract: Record "Service Contract Header"; LineNo: Integer)
    begin
        if not DimMgt.CheckDimIDComb(ServContract."Dimension Set ID") then
            if LineNo = 0 then
                Error(
                  Text008,
                  ServContract."Contract Type", ServContract."Contract No.", DimMgt.GetDimCombErr);
    end;

    local procedure CheckDimValuePosting(ServContract: Record "Service Contract Header"; LineNo: Integer)
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        if LineNo = 0 then begin
            TableIDArr[1] := DATABASE::Customer;
            NumberArr[1] := ServContract."Bill-to Customer No.";
            TableIDArr[2] := DATABASE::"Salesperson/Purchaser";
            NumberArr[2] := ServContract."Salesperson Code";
            TableIDArr[3] := DATABASE::"Responsibility Center";
            NumberArr[3] := ServContract."Responsibility Center";
            TableIDArr[4] := DATABASE::"Service Contract Template";
            NumberArr[4] := ServContract."Template No.";
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, ServContract."Dimension Set ID") then
                Error(
                  Text009,
                  ServContract."Contract Type", ServContract."Contract No.", DimMgt.GetDimValuePostingErr);
        end;
    end;

    procedure CreateAllServLines(InvNo: Code[20]; ServContractToInvoice: Record "Service Contract Header")
    var
        ServContractLine: Record "Service Contract Line";
        ServHeader: Record "Service Header";
        InvoiceFrom: Date;
        InvoiceTo: Date;
        PartInvoiceFrom: Date;
        PartInvoiceTo: Date;
        ServiceApplyEntry: Integer;
    begin
        GetNextInvoicePeriod(ServContractToInvoice, InvoiceFrom, InvoiceTo);
        with ServContractToInvoice do begin
            if ServHeader.Get(ServHeader."Document Type"::Invoice, InvNo) then begin
                ServContractLine.Reset();
                ServContractLine.SetRange("Contract Type", "Contract Type");
                ServContractLine.SetRange("Contract No.", "Contract No.");
                OnCreateAllServLinesOnAfterServContractLineSetFilters(ServContractLine, ServContractToInvoice);
                if not "Contract Lines on Invoice" then
                    CreateHeadingServiceLine(ServHeader, "Contract Type", "Contract No.");
                if ServContractLine.Find('-') then
                    repeat
                        OnCreateAllServLinesOnBeforeServContractLineLoop(InvoiceFrom, ServContractLine, ServContractToInvoice);

                        if "Contract Lines on Invoice" and (ServContractLine."Starting Date" <= InvoiceTo) then
                            if Prepaid and (ServContractLine."Starting Date" <= "Next Invoice Date") or
                               ((not Prepaid) and
                                ((ServContractLine."Invoiced to Date" = "Last Invoice Date") or
                                 (ServContractLine."Invoiced to Date" = 0D)))
                            then
                                if (ServContractLine."Contract Expiration Date" = 0D) or
                                   (ServContractLine."Contract Expiration Date" >= InvoiceFrom)
                                then
                                    CreateDetailedServiceLine(ServHeader, ServContractLine, "Contract Type", "Contract No.");
                        OnCreateAllServLinesOnAfterCreateDetailedServLine(ServContractToInvoice, ServHeader, ServContractLine);

                        if Prepaid then
                            if (ServContractLine."Starting Date" < "Next Invoice Date") and (ServContractLine."Invoiced to Date" = 0D) then begin
                                PartInvoiceFrom := ServContractLine."Starting Date";
                                PartInvoiceTo := "Next Invoice Date" - 1;
                                ServiceApplyEntry :=
                                  CreateServiceLedgEntry(
                                    ServHeader, "Contract Type", "Contract No.", CalcDate('<-CM>', PartInvoiceFrom), PartInvoiceTo,
                                    false, false, ServContractLine."Line No.");
                                if ServiceApplyEntry <> 0 then
                                    CreateServiceLine(ServHeader, "Contract Type", "Contract No.", PartInvoiceFrom, PartInvoiceTo, ServiceApplyEntry, false);
                                ServiceApplyEntry := 0;
                            end;
                        OnCreateAllServLinesOnAfterCreateServiceLedgerEntry(ServContractLine, ServiceApplyEntry);

                        ServiceApplyEntry :=
                          CreateServiceLedgEntry(
                            ServHeader, "Contract Type", "Contract No.", InvoiceFrom, InvoiceTo,
                            false, false, ServContractLine."Line No.");

                        if ServiceApplyEntry <> 0 then
                            CreateServiceLine(
                              ServHeader, "Contract Type", "Contract No.",
                              CountLineInvFrom(false, ServContractLine, InvoiceFrom), InvoiceTo, ServiceApplyEntry, false);
                    until ServContractLine.Next() = 0;
            end;
            CreateLastServiceLines(ServHeader, "Contract Type", "Contract No.");

            Validate("Last Invoice Date", "Next Invoice Date");
            "Print Increase Text" := false;
            Modify();
        end;

        OnAfterCreateAllServLines(ServContractToInvoice, ServContractLine);
    end;

    procedure CheckIfServiceExist(ServContractHeader: Record "Service Contract Header"): Boolean
    var
        ServContractLine: Record "Service Contract Line";
    begin
        with ServContractHeader do
            if "Invoice after Service" then begin
                ServContractLine.Reset();
                ServContractLine.SetRange("Contract Type", "Contract Type");
                ServContractLine.SetRange("Contract No.", "Contract No.");
                ServContractLine.SetFilter("Last Service Date", '<%1 | >%2', "Next Invoice Period Start", "Next Invoice Period End");
                exit(ServContractLine.IsEmpty);
            end;
        exit(true);
    end;

#if not CLEAN19
    [Obsolete('Relaced by GetAffectedItemsOnContractChange()', '19.0')]
    procedure GetAffectedItemsOnCustChange(ContractNoToBeChanged: Code[20]; var TempServContract: Record "Service Contract Header"; var TempServItem: Record "Service Item"; Recursive: Boolean; ContractTypeToBeChanged: Integer)
    begin
        GetAffectedItemsOnContractChange(
            ContractNoToBeChanged, TempServContract, TempServItem, Recursive, "Service Contract Type".FromInteger(ContractTypeToBeChanged));
    end;
#endif

    procedure GetAffectedItemsOnContractChange(ContractNoToBeChanged: Code[20]; var TempServContract: Record "Service Contract Header"; var TempServItem: Record "Service Item"; Recursive: Boolean; ContractTypeToBeChanged: Enum "Service Contract Type")
    var
        ServContract: Record "Service Contract Header";
        ServItem: Record "Service Item";
        ServContractLine: Record "Service Contract Line";
        ServContractLine2: Record "Service Contract Line";
    begin
        if not Recursive then begin
            TempServContract.DeleteAll();
            TempServItem.DeleteAll();
        end;
        if TempServContract.Get(ContractTypeToBeChanged, ContractNoToBeChanged) then
            exit;
        ServContract.Get(ContractTypeToBeChanged, ContractNoToBeChanged);
        if (ServContract.Status = ServContract.Status::Canceled) and
           (ServContract."Contract Type" = ServContract."Contract Type"::Contract)
        then
            exit;
        TempServContract := ServContract;
        TempServContract.Insert();

        ServContractLine.SetRange("Contract Type", ContractTypeToBeChanged);
        ServContractLine.SetRange("Contract No.", ServContract."Contract No.");
        ServContractLine.SetFilter("Contract Status", '<>%1', ServContractLine."Contract Status"::Cancelled);
        ServContractLine.SetFilter("Service Item No.", '<>%1', '');
        if ServContractLine.Find('-') then
            repeat
                if not TempServItem.Get(ServContractLine."Service Item No.") then begin
                    ServItem.Get(ServContractLine."Service Item No.");
                    TempServItem := ServItem;
                    TempServItem.Insert();
                end;

                ServContractLine2.Reset();
                ServContractLine2.SetCurrentKey("Service Item No.", "Contract Status");
                ServContractLine2.SetRange("Service Item No.", ServContractLine."Service Item No.");
                ServContractLine2.SetFilter("Contract Status", '<>%1', ServContractLine."Contract Status"::Cancelled);
                ServContractLine2.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                ServContractLine2.SetFilter("Contract No.", '<>%1', ServContractLine."Contract No.");
                if ServContractLine2.Find('-') then
                    repeat
                        GetAffectedItemsOnContractChange(
                          ServContractLine2."Contract No.", TempServContract, TempServItem,
                          true, ServContractLine."Contract Type"::Contract);
                    until ServContractLine2.Next() = 0;

                ServContractLine2.Reset();
                ServContractLine2.SetCurrentKey("Service Item No.");
                ServContractLine2.SetRange("Service Item No.", ServContractLine."Service Item No.");
                ServContractLine2.SetRange("Contract Type", ServContractLine."Contract Type"::Quote);
                if ServContractLine2.Find('-') then
                    repeat
                        GetAffectedItemsOnContractChange(
                          ServContractLine2."Contract No.", TempServContract, TempServItem,
                          true, ServContractLine."Contract Type"::Quote);
                    until ServContractLine2.Next() = 0;

            until ServContractLine.Next() = 0;
    end;

    procedure ChangeCustNoOnServContract(NewCustomertNo: Code[20]; NewShipToCode: Code[10]; ServContractHeader: Record "Service Contract Header")
    var
        ServContractLine: Record "Service Contract Line";
        Cust: Record Customer;
        ContractChangeLog: Record "Contract Change Log";
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
        UserMgt: Codeunit "User Setup Management";
        OldSalespersonCode: Code[20];
        OldCurrencyCode: Code[10];
    begin
        if NewCustomertNo = '' then
            Error(Text012);

        ServMgtSetup.Get();

        with ServContractHeader do begin
            OldSalespersonCode := "Salesperson Code";
            OldCurrencyCode := "Currency Code";

            if "Customer No." <> NewCustomertNo then begin
                if ServMgtSetup."Register Contract Changes" then
                    ContractChangeLog.LogContractChange(
                      "Contract No.", 0, FieldCaption("Customer No."), 0, "Customer No.", NewCustomertNo, '', 0);
                "Customer No." := NewCustomertNo;
                CustCheckCrLimit.OnNewCheckRemoveCustomerNotifications(RecordId, true);

                Cust.Get(NewCustomertNo);
                SetHideValidationDialog(true);
                if Cust."Bill-to Customer No." <> '' then
                    Validate("Bill-to Customer No.", Cust."Bill-to Customer No.")
                else
                    Validate("Bill-to Customer No.", Cust."No.");
                "Responsibility Center" := UserMgt.GetRespCenter(2, Cust."Responsibility Center");
                UpdateShiptoCode;
                CalcFields(
                  Name, "Name 2", Address, "Address 2",
                  "Post Code", City, County, "Country/Region Code");
                CustCheckCrLimit.ServiceContractHeaderCheck(ServContractHeader);
            end;

            if "Ship-to Code" <> NewShipToCode then begin
                if ServMgtSetup."Register Contract Changes" then
                    ContractChangeLog.LogContractChange(
                      "Contract No.", 0, FieldCaption("Ship-to Code"), 0, "Ship-to Code", NewShipToCode, '', 0);
                "Ship-to Code" := NewShipToCode;
                if NewShipToCode = '' then
                    UpdateShiptoCode
                else
                    CalcFields(
                      "Ship-to Name", "Ship-to Name 2", "Ship-to Address", "Ship-to Address 2",
                      "Ship-to Post Code", "Ship-to City", "Ship-to County", "Ship-to Country/Region Code");
            end;

            UpdateServZone;
            UpdateCont("Customer No.");
            UpdateCust("Contact No.");
            "Salesperson Code" := OldSalespersonCode;
            "Currency Code" := OldCurrencyCode;

            CreateDim(
              DATABASE::Customer, "Bill-to Customer No.",
              DATABASE::"Salesperson/Purchaser", "Salesperson Code",
              DATABASE::"Responsibility Center", "Responsibility Center",
              DATABASE::"Service Contract Template", "Template No.",
              DATABASE::"Service Order Type", "Service Order Type");

            ServContractLine.Reset();
            ServContractLine.SetRange("Contract Type", "Contract Type");
            ServContractLine.SetRange("Contract No.", "Contract No.");
            if ServContractLine.Find('-') then
                repeat
                    ServContractLine."Customer No." := NewCustomertNo;
                    ServContractLine."Ship-to Code" := NewShipToCode;
                    ServContractLine.Modify();
                until ServContractLine.Next() = 0;
        end;

        OnBeforeServContractHeaderModify(ServContractHeader);
        ServContractHeader.Modify();
    end;

    procedure ChangeCustNoOnServItem(NewCustomertNo: Code[20]; NewShipToCode: Code[10]; ServItem: Record "Service Item")
    var
        OldServItem: Record "Service Item";
        ServLogMgt: Codeunit ServLogManagement;
    begin
        OnBeforeChangeCustNoOnServItem(ServItem, NewCustomertNo);
        OldServItem := ServItem;
        ServItem."Customer No." := NewCustomertNo;
        ServItem."Ship-to Code" := NewShipToCode;
        if OldServItem."Customer No." <> NewCustomertNo then begin
            ServLogMgt.ServItemCustChange(ServItem, OldServItem);
            ServLogMgt.ServItemShipToCodeChange(ServItem, OldServItem);
        end else
            if OldServItem."Ship-to Code" <> NewShipToCode then
                ServLogMgt.ServItemShipToCodeChange(ServItem, OldServItem);
        ServItem.Modify();
    end;

#if not CLEAN19
    [Obsolete('Replaced by CreateHeadingServiceLine()', '19.0')]
    procedure CreateHeadingServLine(ServHeader: Record "Service Header"; ContractType: Integer; ContractNo: Code[20])
    begin
        CreateHeadingServiceLine(ServHeader, "Service Contract Type".FromInteger(ContractType), ContractNo);
    end;
#endif

    procedure CreateHeadingServiceLine(ServHeader: Record "Service Header"; ContractType: Enum "Service Contract Type"; ContractNo: Code[20])
    var
        ServContractHeader: Record "Service Contract Header";
        Cust: Record Customer;
        StdText: Record "Standard Text";
    begin
        ServContractHeader.Get(ContractType, ContractNo);
        if ServContractHeader."Invoice Period" = ServContractHeader."Invoice Period"::None then
            exit;

        ServLineNo := 0;
        ServLine.SetRange("Document Type", ServLine."Document Type"::Invoice);
        ServLine.SetRange("Document No.", ServHeader."No.");
        if ServLine.FindLast() then
            ServLineNo := ServLine."Line No.";
        Cust.Get(ServContractHeader."Bill-to Customer No.");
        ServMgtSetup.Get();
        ServLine.Reset();
        ServLine.Init();
        ServLineNo := ServLineNo + 10000;
        ServLine."Document Type" := ServHeader."Document Type";
        ServLine."Document No." := ServHeader."No.";
        ServLine."Line No." := ServLineNo;
        ServLine.Type := ServLine.Type::" ";
        if ServMgtSetup."Contract Inv. Line Text Code" <> '' then begin
            StdText.Get(ServMgtSetup."Contract Inv. Line Text Code");
            TempServLineDescription := StrSubstNo('%1 %2', StdText.Description, ServContractHeader."Contract No.");
            if StrLen(TempServLineDescription) > MaxStrLen(ServLine.Description) then
                Error(Text013, ServLine.TableCaption, ServLine.FieldCaption(Description),
                  StdText.TableCaption, StdText.Code, StdText.FieldCaption(Description),
                  Format(StrLen(TempServLineDescription) - MaxStrLen(ServLine.Description)));
            ServLine.Description := CopyStr(TempServLineDescription, 1, MaxStrLen(ServLine.Description));
        end else
            ServLine.Description := StrSubstNo(Text002, ServContractHeader."Contract No.");
        OnCreateHeadingServLineOnBeforeServLineInsert(ServLine, ServContractHeader, ServHeader);
        ServLine.Insert();
    end;

    procedure LookupServItemNo(var ServiceContractLine: Record "Service Contract Line")
    var
        ServContractHeader: Record "Service Contract Header";
        ServItem: Record "Service Item";
        ServItemList: Page "Service Item List";
        IsHandled: Boolean;
    begin
        Clear(ServItemList);
        if ServItem.Get(ServiceContractLine."Service Item No.") then
            ServItemList.SetRecord(ServItem);
        ServItem.Reset();
        ServItem.SetCurrentKey("Customer No.", "Ship-to Code");
        ServItem.FilterGroup(2);
        IsHandled := false;
        OnLookupServItemNoOnBeforeFilterByCustomerNo(ServItem, ServiceContractLine, IsHandled);
        if not IsHandled then
            if ServiceContractLine."Customer No." <> '' then
                ServItem.SetRange("Customer No.", ServiceContractLine."Customer No.");

        ServItem.FilterGroup(0);
        if ServContractHeader.Get(ServiceContractLine."Contract Type", ServiceContractLine."Contract No.") and
           (ServiceContractLine."Ship-to Code" = ServContractHeader."Ship-to Code")
        then
            ServItem.SetRange("Ship-to Code", ServiceContractLine."Ship-to Code");
        ServItemList.SetTableView(ServItem);
        ServItemList.LookupMode(true);
        if ServItemList.RunModal = ACTION::LookupOK then begin
            ServItemList.GetRecord(ServItem);
            ServiceContractLine.Validate("Service Item No.", ServItem."No.");
        end;
    end;

    procedure AmountToFCY(AmountLCY: Decimal; var ServHeader3: Record "Service Header"): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
    begin
        Currency.Get(ServHeader3."Currency Code");
        Currency.TestField("Unit-Amount Rounding Precision");
        exit(
          Round(
            CurrExchRate.ExchangeAmtLCYToFCY(
              ServHeader3."Posting Date", ServHeader3."Currency Code",
              AmountLCY, ServHeader3."Currency Factor"),
            Currency."Unit-Amount Rounding Precision"));
    end;

#if not CLEAN19
    [Obsolete('Replaced by IsYearContract', '19.0')]
    procedure YearContract(ContrType: Integer; ContrNo: Code[20]): Boolean
    begin
        exit(IsYearContract("Service Contract Type".FromInteger(ContrType), ContrNo));
    end;
#endif

    procedure IsYearContract(ContractType: Enum "Service Contract Type"; ContrNo: Code[20]): Boolean
    var
        ServContrHeader: Record "Service Contract Header";
    begin
        if not ServContrHeader.Get(ContractType, ContrNo) then
            exit(false);

        exit(ServContrHeader."Expiration Date" = CalcDate('<1Y-1D>', ServContrHeader."Starting Date"));
    end;

    local procedure FillTempServiceLedgerEntries(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        if TempServLedgEntriesIsSet then
            exit;
        TempServLedgEntry.DeleteAll();
        with ServiceLedgerEntry do begin
            SetRange("Service Contract No.", ServiceContractHeader."Contract No.");
            SetRange("Entry Type", "Entry Type"::Sale);
            if not FindSet then
                exit;
            repeat
                TempServLedgEntry := ServiceLedgerEntry;
                TempServLedgEntry.Insert();
            until Next() = 0;
            TempServLedgEntriesIsSet := true;
        end;
    end;

    local procedure LookUpAmountToCredit(ServItemNo: Code[20]; ItemNo: Code[20]; PostingDate: Date; var LineAmount: Decimal; var CostAmount: Decimal; var UnitPrice: Decimal; var DiscountAmt: Decimal; var ServLedgEntryNo: Integer): Boolean
    begin
        LineAmount := 0;
        CostAmount := 0;
        UnitPrice := 0;
        DiscountAmt := 0;
        ServLedgEntryNo := 0;

        TempServLedgEntry.Reset();
        if ServItemNo <> '' then
            TempServLedgEntry.SetRange("Service Item No. (Serviced)", ServItemNo);
        if ItemNo <> '' then
            TempServLedgEntry.SetRange("Item No. (Serviced)", ItemNo);
        TempServLedgEntry.SetRange("Posting Date", PostingDate);

        if not TempServLedgEntry.FindFirst then
            exit(false);

        LineAmount := -TempServLedgEntry."Amount (LCY)";
        CostAmount := TempServLedgEntry."Cost Amount";
        UnitPrice := -TempServLedgEntry."Unit Price";
        DiscountAmt := TempServLedgEntry."Discount Amount";
        ServLedgEntryNo := TempServLedgEntry."Entry No.";
        TempServLedgEntry.Delete();

        exit(true);
    end;

    procedure CheckServiceContractHeaderAmts(ServiceContractHeader: Record "Service Contract Header")
    begin
        if ServiceContractHeader."Calcd. Annual Amount" <> ServiceContractHeader."Annual Amount" then
            Error(
              Text000,
              ServLedgEntry2.TableCaption,
              ServiceContractHeader."Contract No.",
              ServiceContractHeader.FieldCaption("Calcd. Annual Amount"),
              ServiceContractHeader.FieldCaption("Annual Amount"));
    end;

    procedure SetServiceLedgerEntryUnitCost(var ServiceLedgerEntry: Record "Service Ledger Entry")
    begin
        with ServiceLedgerEntry do
            if "Charged Qty." = 0 then
                "Unit Cost" := -"Cost Amount"
            else
                "Unit Cost" := "Cost Amount" / "Charged Qty.";
    end;

    local procedure ServLedgEntryToServiceLine(var TotalServLine: Record "Service Line"; var TotalServLineLCY: Record "Service Line"; ServHeader: Record "Service Header"; ServiceLedgerEntry: Record "Service Ledger Entry"; ContractNo: Code[20]; InvFrom: Date; InvTo: Date)
    var
        StdText: Record "Standard Text";
        IsHandled: Boolean;
    begin
        OnBeforeServLedgEntryToServiceLine(TotalServLine, TotalServLineLCY, ServHeader, ServLedgEntry, IsHandled, ServiceLedgerEntry, InvFrom, InvTo);
        if IsHandled then
            exit;

        ServLineNo := ServLineNo + 10000;
        with ServLine do begin
            Reset;
            Init;
            "Document Type" := ServHeader."Document Type";
            "Document No." := ServHeader."No.";
            "Line No." := ServLineNo;
            "Customer No." := ServHeader."Customer No.";
            "Location Code" := ServHeader."Location Code";
            "Gen. Bus. Posting Group" := ServHeader."Gen. Bus. Posting Group";
            "Transaction Specification" := ServHeader."Transaction Specification";
            "Transport Method" := ServHeader."Transport Method";
            "Exit Point" := ServHeader."Exit Point";
            Area := ServHeader.Area;
            "Transaction Specification" := ServHeader."Transaction Specification";
            InitServiceLineAppliedGLAccount();
            Validate(Quantity, 1);
            if ServMgtSetup."Contract Inv. Period Text Code" <> '' then begin
                StdText.Get(ServMgtSetup."Contract Inv. Period Text Code");
                TempServLineDescription := StrSubstNo('%1 %2 - %3', StdText.Description, Format(InvFrom), Format(InvTo));
                if StrLen(TempServLineDescription) > MaxStrLen(Description) then
                    Error(
                      Text013,
                      TableCaption, FieldCaption(Description),
                      StdText.TableCaption, StdText.Code, StdText.FieldCaption(Description),
                      Format(StrLen(TempServLineDescription) - MaxStrLen(Description)));
                Description := CopyStr(TempServLineDescription, 1, MaxStrLen(Description));
            end else
                Description :=
                  StrSubstNo('%1 - %2', Format(InvFrom), Format(InvTo));
            "Contract No." := ContractNo;
            "Appl.-to Service Entry" := ServiceLedgerEntry."Entry No.";
            "Service Item No." := ServiceLedgerEntry."Service Item No. (Serviced)";
            "Unit Cost (LCY)" := ServiceLedgerEntry."Unit Cost";
            "Unit Price" := -ServiceLedgerEntry."Unit Price";

            TotalServLine."Unit Price" += "Unit Price";
            TotalServLine."Line Amount" += -ServiceLedgerEntry."Amount (LCY)";
            if (ServiceLedgerEntry."Amount (LCY)" <> 0) or (ServiceLedgerEntry."Discount %" > 0) then
                if ServHeader."Currency Code" <> '' then begin
                    Validate("Unit Price",
                      AmountToFCY(TotalServLine."Unit Price", ServHeader) - TotalServLineLCY."Unit Price");
                    Validate("Line Amount",
                      AmountToFCY(TotalServLine."Line Amount", ServHeader) - TotalServLineLCY."Line Amount");
                end else begin
                    Validate("Unit Price");
                    Validate("Line Amount", -ServiceLedgerEntry."Amount (LCY)");
                end;
            TotalServLineLCY."Unit Price" += "Unit Price";
            TotalServLineLCY."Line Amount" += "Line Amount";

            "Shortcut Dimension 1 Code" := ServiceLedgerEntry."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := ServiceLedgerEntry."Global Dimension 2 Code";
            "Dimension Set ID" := ServiceLedgerEntry."Dimension Set ID";

            IsHandled := false;
            OnServLedgEntryToServiceLineOnBeforeServLineInsert(ServLine, TotalServLine, TotalServLineLCY, ServHeader, ServLedgEntry, ServiceLedgerEntry, IsHandled, InvFrom, InvTo);
            if IsHandled then
                exit;

            Insert;
            CreateDim(
              DimMgt.TypeToTableID5(Type.AsInteger()), "No.",
              DATABASE::Job, "Job No.",
              DATABASE::"Responsibility Center", "Responsibility Center");
        end;
    end;

    local procedure InitServiceLineAppliedGLAccount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitServiceLineAppliedGLAccount(ServLine, AppliedGLAccount, IsHandled);
        if IsHandled then
            exit;

        with ServLine do begin
            Type := Type::"G/L Account";
            Validate("No.", AppliedGLAccount);
        end;
    end;

    procedure CheckMultipleCurrenciesForCustomers(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractHeader2: Record "Service Contract Header";
        PrevCustNo: Code[20];
    begin
        with ServiceContractHeader2 do begin
            Copy(ServiceContractHeader);
            SetCurrentKey("Bill-to Customer No.", "Contract Type", "Combine Invoices", "Next Invoice Date");
            SetRange("Combine Invoices", true);
            if FindSet then
                repeat
                    if PrevCustNo <> "Bill-to Customer No." then begin
                        CheckCustomerCurrencyCombination(ServiceContractHeader2);
                        PrevCustNo := "Bill-to Customer No.";
                    end;
                until Next() = 0;
        end;
    end;

    local procedure CheckCustomerCurrencyCombination(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractHeader2: Record "Service Contract Header";
    begin
        with ServiceContractHeader2 do begin
            Copy(ServiceContractHeader);
            SetRange("Bill-to Customer No.", ServiceContractHeader."Bill-to Customer No.");
            SetFilter("Currency Code", '<>%1', ServiceContractHeader."Currency Code");
            if FindFirst then
                Error(ErrorSplitErr,
                  StrSubstNo(CombinedCurrenciesErr1,
                    "Bill-to Customer No.",
                    ShownCurrencyText("Currency Code"),
                    ShownCurrencyText(ServiceContractHeader."Currency Code")),
                  CombinedCurrenciesErr2);
        end;
    end;

    local procedure ShownCurrencyText(CurrCode: Code[10]): Text
    begin
        if CurrCode = '' then
            exit(BlankTxt);
        exit(CurrCode);
    end;

    procedure InitServLedgEntry(var ServLedgEntry: Record "Service Ledger Entry"; ServContractHeader: Record "Service Contract Header"; DocNo: Code[20])
    begin
        with ServLedgEntry do begin
            Init();
            Type := Type::"Service Contract";
            "No." := ServContractHeader."Contract No.";
            "Service Contract No." := ServContractHeader."Contract No.";
            "Document Type" := "Document Type"::" ";
            "Document No." := DocNo;
            "Serv. Contract Acc. Gr. Code" := ServContractHeader."Serv. Contract Acc. Gr. Code";
            "Bill-to Customer No." := ServContractHeader."Bill-to Customer No.";
            "Customer No." := ServContractHeader."Customer No.";
            "Ship-to Code" := ServContractHeader."Ship-to Code";
            "Global Dimension 1 Code" := ServContractHeader."Shortcut Dimension 1 Code";
            "Global Dimension 2 Code" := ServContractHeader."Shortcut Dimension 2 Code";
            "Dimension Set ID" := ServContractHeader."Dimension Set ID";
            "Entry Type" := "Entry Type"::Sale;
            "User ID" := UserId;
            "Contract Invoice Period" := Format(ServContractHeader."Invoice Period");
            "Contract Group Code" := ServContractHeader."Contract Group Code";
            "Responsibility Center" := ServContractHeader."Responsibility Center";
            Open := true;
            Quantity := -1;
            "Charged Qty." := -1;
        end;
    end;

    procedure GetInvoicePeriodText(InvoicePeriod: Enum "Service Contract Header Invoice Period"): Text[4]
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        case InvoicePeriod of
            ServiceContractHeader."Invoice Period"::Month:
                exit('<1M>');
            ServiceContractHeader."Invoice Period"::"Two Months":
                exit('<2M>');
            ServiceContractHeader."Invoice Period"::Quarter:
                exit('<3M>');
            ServiceContractHeader."Invoice Period"::"Half Year":
                exit('<6M>');
            ServiceContractHeader."Invoice Period"::Year:
                exit('<1Y>');
        end;
    end;

#if not CLEAN19
    [Obsolete('Replaced by FilterServiceContractLine()', '19.0')]
    procedure FilterServContractLine(var ServContractLine: Record "Service Contract Line"; ContractNo: Code[20]; ContractType: Option; LineNo: Integer)
    begin
        FilterServiceContractLine(ServContractLine, ContractNo, "Service Contract Type".FromInteger(ContractType), LineNo);
    end;
#endif

    procedure FilterServiceContractLine(var ServContractLine: Record "Service Contract Line"; ContractNo: Code[20]; ContractType: Enum "Service Contract Type"; LineNo: Integer)
    begin
        ServContractLine.Reset();
        ServContractLine.SetRange("Contract No.", ContractNo);
        ServContractLine.SetRange("Contract Type", ContractType);
        if LineNo <> 0 then
            ServContractLine.SetRange("Line No.", LineNo);

        OnAfterFilterServContractLine(ServContractLine, ContractNo, ContractType.AsInteger());
    end;

    local procedure CountLineInvFrom(SigningContract: Boolean; ServContractLine: Record "Service Contract Line"; InvFrom: Date) LineInvFrom: Date
    begin
        if ServContractLine."Invoiced to Date" = 0D then
            LineInvFrom := ServContractLine."Starting Date"
        else
            if SigningContract then begin
                if ServContractLine."Invoiced to Date" <> CalcDate('<CM>', ServContractLine."Invoiced to Date") then
                    LineInvFrom := ServContractLine."Invoiced to Date" + 1
            end else
                LineInvFrom := InvFrom;
    end;

    local procedure CalcServLedgEntryAmounts(var ServContractLine: Record "Service Contract Line"; var InvAmountRounded: array[4] of Decimal)
    var
        ServLedgEntry2: Record "Service Ledger Entry";
        AccumulatedAmts: array[4] of Decimal;
        i: Integer;
    begin
        ServLedgEntry2.SetCurrentKey("Service Contract No.");
        ServLedgEntry2.SetRange("Service Contract No.", ServContractLine."Contract No.");
        ServLedgEntry2.SetRange("Service Item No. (Serviced)", ServContractLine."Service Item No.");
        ServLedgEntry2.SetRange("Entry Type", ServLedgEntry2."Entry Type"::Sale);
        for i := 1 to 4 do
            AccumulatedAmts[i] := 0;
        if ServLedgEntry2.FindSet then
            repeat
                AccumulatedAmts[AmountType::UnitCost] :=
                  AccumulatedAmts[AmountType::UnitCost] + ServLedgEntry2."Cost Amount";
                AccumulatedAmts[AmountType::Amount] :=
                  AccumulatedAmts[AmountType::Amount] - ServLedgEntry2."Amount (LCY)";
                AccumulatedAmts[AmountType::DiscAmount] :=
                  AccumulatedAmts[AmountType::DiscAmount] + ServLedgEntry2."Discount Amount";
                AccumulatedAmts[AmountType::UnitPrice] :=
                  AccumulatedAmts[AmountType::UnitPrice] - ServLedgEntry2."Unit Price";
            until ServLedgEntry2.Next() = 0;
        ServLedgEntry."Cost Amount" := -Round(ServContractLine."Line Cost" + AccumulatedAmts[AmountType::UnitCost]);
        SetServiceLedgerEntryUnitCost(ServLedgEntry);
        ServLedgEntry."Amount (LCY)" := AccumulatedAmts[AmountType::Amount] - ServContractLine."Line Amount";
        ServLedgEntry."Discount Amount" := ServContractLine."Line Discount Amount" - AccumulatedAmts[AmountType::DiscAmount];
        ServLedgEntry."Contract Disc. Amount" := ServLedgEntry."Discount Amount";
        ServLedgEntry."Unit Price" := AccumulatedAmts[AmountType::UnitPrice] - ServContractLine."Line Value";
        CalcServLedgEntryDiscountPct(ServLedgEntry);
        InvAmountRounded[AmountType::Amount] -= ServLedgEntry."Amount (LCY)";
        InvAmountRounded[AmountType::UnitPrice] -= ServLedgEntry."Unit Price";
        InvAmountRounded[AmountType::UnitCost] += ServLedgEntry."Unit Cost";
        InvAmountRounded[AmountType::DiscAmount] += ServLedgEntry."Contract Disc. Amount";
    end;

    procedure UpdateServLedgEntryAmount(var ServLedgEntry: Record "Service Ledger Entry"; var ServHeader: Record "Service Header")
    begin
        if ServHeader."Currency Code" <> '' then
            ServLedgEntry.Amount := AmountToFCY(ServLedgEntry."Amount (LCY)", ServHeader)
        else
            ServLedgEntry.Amount := ServLedgEntry."Amount (LCY)";
    end;

    procedure CalcInvoicedToDate(var ServContractLine: Record "Service Contract Line"; InvFrom: Date; InvTo: Date)
    begin
        if ServContractLine."Contract Expiration Date" <> 0D then begin
            if (ServContractLine."Contract Expiration Date" >= InvFrom) and
               (ServContractLine."Contract Expiration Date" <= InvTo)
            then
                ServContractLine."Invoiced to Date" := ServContractLine."Contract Expiration Date"
            else
                if ServContractLine."Contract Expiration Date" > InvTo then
                    ServContractLine."Invoiced to Date" := InvTo;
        end else
            ServContractLine."Invoiced to Date" := InvTo;
    end;

    local procedure CreateDescriptionServiceLines(ServContractLineItemNo: Code[20]; ServContractLineDesc: Text[100]; ServContractLineItemSerialNo: Code[50])
    var
        ServLineDescription: Text;
        RequiredLength: Integer;
    begin
        if ServContractLineItemNo <> '' then begin
            ServLineDescription := StrSubstNo('%1 %2 %3', ServContractLineItemNo, ServContractLineDesc, ServContractLineItemSerialNo);
            RequiredLength := MaxStrLen(ServLine.Description);
            InsertDescriptionServiceLine(CopyStr(ServLineDescription, 1, RequiredLength));
            if StrLen(ServLineDescription) > RequiredLength then
                InsertDescriptionServiceLine(CopyStr(ServLineDescription, RequiredLength + 1, RequiredLength))
        end else
            InsertDescriptionServiceLine(ServContractLineDesc);
    end;

    local procedure InsertDescriptionServiceLine(Description: Text[100])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertDescriptionServiceLine(ServLine, Description, IsHandled);
        if IsHandled then
            exit;

        ServLine.Init();
        ServLine."Line No." := ServLine.GetLineNo();
        ServLine.Description := Description;
        OnInsertDescriptionServiceLineOnBeforeServiceLineInsert(ServLine);
        ServLine.Insert();
    end;

    local procedure UpdateApplyUntilEntryNoInServLedgEntry(ReturnLedgerEntry: Integer; FirstLineEntry: Integer; LastEntry: Integer)
    var
        ServLedgEntry: Record "Service Ledger Entry";
    begin
        if ReturnLedgerEntry <> 0 then begin
            ServLedgEntry.Get(FirstLineEntry);
            ServLedgEntry."Apply Until Entry No." := LastEntry;
            ServLedgEntry.Modify();
        end;
    end;

    local procedure PostPartialServLedgEntry(var InvAmountRounded: array[4] of Decimal; ServContractLine: Record "Service Contract Line"; ServHeader: Record "Service Header"; InvFrom: Date; InvTo: Date; DueDate: Date; AmtRoundingPrecision: Decimal) YearContractCorrection: Boolean
    begin
        OnBeforePostPartialServLedgEntry(ServLedgEntry, ServContractLine);
        ServLedgEntry."Service Item No. (Serviced)" := ServContractLine."Service Item No.";
        ServLedgEntry."Item No. (Serviced)" := ServContractLine."Item No.";
        ServLedgEntry."Serial No. (Serviced)" := ServContractLine."Serial No.";
        if IsYearContract(ServContractLine."Contract Type", ServContractLine."Contract No.") then begin
            YearContractCorrection := true;
            CalcServLedgEntryAmounts(ServContractLine, InvAmountRounded);
            ServLedgEntry."Entry No." := NextEntry;
            UpdateServLedgEntryAmount(ServLedgEntry, ServHeader);
        end else begin
            YearContractCorrection := false;
            SetServLedgEntryAmounts(
              ServLedgEntry, InvAmountRounded,
              -CalcContractLineAmount(ServContractLine."Line Amount", InvFrom, InvTo),
              -CalcContractLineAmount(ServContractLine."Line Value", InvFrom, InvTo),
              -CalcContractLineAmount(ServContractLine."Line Cost", InvFrom, InvTo),
              -CalcContractLineAmount(ServContractLine."Line Discount Amount", InvFrom, InvTo),
              AmtRoundingPrecision);
            ServLedgEntry."Entry No." := NextEntry;
            UpdateServLedgEntryAmount(ServLedgEntry, ServHeader);
        end;
        ServLedgEntry."Posting Date" := DueDate;
        ServLedgEntry.Prepaid := true;
        OnPostPartialServLedgEntryOnBeforeServLedgEntryInsert(ServLedgEntry, ServContractLine);
        ServLedgEntry.Insert();
        NextEntry := NextEntry + 1;
        exit(YearContractCorrection);
    end;

    procedure SetServLedgEntryAmounts(var ServLedgEntry: Record "Service Ledger Entry"; var EntryAmount: array[4] of Decimal; Amount: Decimal; UnitPrice: Decimal; CostAmount: Decimal; DiscAmount: Decimal; AmtRoundingPrecision: Decimal)
    begin
        ServLedgEntry."Amount (LCY)" := Round(Amount, AmtRoundingPrecision);
        ServLedgEntry."Unit Price" := Round(UnitPrice, AmtRoundingPrecision);
        ServLedgEntry."Unit Cost" := Round(CostAmount, AmtRoundingPrecision);
        ServLedgEntry."Contract Disc. Amount" := Round(DiscAmount, AmtRoundingPrecision);
        ServLedgEntry."Discount Amount" := ServLedgEntry."Contract Disc. Amount";
        CalcServLedgEntryDiscountPct(ServLedgEntry);
        EntryAmount[AmountType::Amount] -= ServLedgEntry."Amount (LCY)";
        EntryAmount[AmountType::UnitPrice] -= ServLedgEntry."Unit Price";
        EntryAmount[AmountType::UnitCost] += ServLedgEntry."Unit Cost";
        EntryAmount[AmountType::DiscAmount] += ServLedgEntry."Contract Disc. Amount";
    end;

    procedure CalcInvAmounts(var InvAmount: array[4] of Decimal; ServContractLine: Record "Service Contract Line"; InvFrom: Date; InvTo: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcInvAmounts(InvAmount, ServContractLine, InvFrom, InvTo, IsHandled);
        if IsHandled then
            exit;

        InvAmount[AmountType::Amount] +=
          CalcContractLineAmount(ServContractLine."Line Amount", InvFrom, InvTo);
        InvAmount[AmountType::UnitPrice] +=
          CalcContractLineAmount(ServContractLine."Line Value", InvFrom, InvTo);
        InvAmount[AmountType::UnitCost] +=
          CalcContractLineAmount(ServContractLine."Line Cost", InvFrom, InvTo);
        InvAmount[AmountType::DiscAmount] +=
          CalcContractLineAmount(ServContractLine."Line Discount Amount", InvFrom, InvTo);
    end;

    procedure InsertMultipleServLedgEntries(var NoOfPayments: Integer; var DueDate: Date; var NonDistrAmount: array[4] of Decimal; var InvRoundedAmount: array[4] of Decimal; var ServHeader: Record "Service Header"; InvFrom: Date; NextInvDate: Date; AddingNewLines: Boolean; CountOfEntryLoop: Integer; ServContractLine: Record "Service Contract Line"; AmountRoundingPrecision: Decimal)
    var
        ServContractHeader: Record "Service Contract Header";
        Index: Integer;
        IsHandled: Boolean;
    begin
        if CountOfEntryLoop = 0 then
            exit;

        OnBeforeInsertMultipleServLedgEntries(ServLedgEntry, ServContractLine);

        CheckMParts := false;
        if DueDate <> CalcDate('<CM>', DueDate) then begin
            DueDate := CalcDate('<-CM-1D>', DueDate);
            ServContractHeader.Get(ServContractLine."Contract Type", ServContractLine."Contract No.");
            if ServContractHeader."Contract Lines on Invoice" then
                CheckMParts := true;
        end;
        NonDistrAmount[AmountType::Amount] :=
          -CalcContractLineAmount(ServContractLine."Line Amount", InvFrom, DueDate);
        NonDistrAmount[AmountType::UnitPrice] :=
          -CalcContractLineAmount(ServContractLine."Line Value", InvFrom, DueDate);
        NonDistrAmount[AmountType::UnitCost] :=
          CalcContractLineAmount(ServContractLine."Line Cost", InvFrom, DueDate);
        NonDistrAmount[AmountType::DiscAmount] :=
          CalcContractLineAmount(ServContractLine."Line Discount Amount", InvFrom, DueDate);
        ServLedgEntry."Service Item No. (Serviced)" := ServContractLine."Service Item No.";
        ServLedgEntry."Item No. (Serviced)" := ServContractLine."Item No.";
        ServLedgEntry."Serial No. (Serviced)" := ServContractLine."Serial No.";
        DueDate := NextInvDate;
        if CheckMParts and (NoOfPayments > 1) then begin
            NoOfPayments := NoOfPayments - 1;
            // the count of invoice lines should never exceed the count of payments
            if CountOfEntryLoop > NoOfPayments then
                CountOfEntryLoop := NoOfPayments;
        end;

        if AddingNewLines then
            DueDate := InvFrom;
        for Index := 1 to CountOfEntryLoop do begin
            SetServLedgEntryAmounts(
              ServLedgEntry, InvRoundedAmount,
              NonDistrAmount[AmountType::Amount] / (NoOfPayments + 1 - Index),
              NonDistrAmount[AmountType::UnitPrice] / (NoOfPayments + 1 - Index),
              NonDistrAmount[AmountType::UnitCost] / (NoOfPayments + 1 - Index),
              NonDistrAmount[AmountType::DiscAmount] / (NoOfPayments + 1 - Index),
              AmountRoundingPrecision);
            ServLedgEntry."Cost Amount" := ServLedgEntry."Charged Qty." * ServLedgEntry."Unit Cost";

            NonDistrAmount[AmountType::Amount] -= ServLedgEntry."Amount (LCY)";
            NonDistrAmount[AmountType::UnitPrice] -= ServLedgEntry."Unit Price";
            NonDistrAmount[AmountType::UnitCost] -= ServLedgEntry."Unit Cost";
            NonDistrAmount[AmountType::DiscAmount] -= ServLedgEntry."Contract Disc. Amount";

            ServLedgEntry."Entry No." := NextEntry;
            UpdateServLedgEntryAmount(ServLedgEntry, ServHeader);
            ServLedgEntry."Posting Date" := DueDate;
            ServLedgEntry.Prepaid := true;
            IsHandled := false;
            OnInsertMultipleServLedgEntriesOnBeforeServLedgEntryInsert(ServLedgEntry, ServContractHeader, ServContractLine, NonDistrAmount, IsHandled);
            if IsHandled then
                exit;
            ServLedgEntry.Insert();
            NextEntry += 1;
            DueDate := CalcDate('<1M>', DueDate);
        end;
    end;

    local procedure SetSalespersonCode(SalesPersonCodeToCheck: Code[20]; var SalesPersonCodeToAssign: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSalespersonCode(SalesPersonCodeToCheck, SalesPersonCodeToAssign, IsHandled);
        if IsHandled then
            exit;

        if SalesPersonCodeToCheck <> '' then
            if Salesperson.Get(SalesPersonCodeToCheck) then
                if Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then
                    SalesPersonCodeToAssign := ''
                else
                    SalesPersonCodeToAssign := SalesPersonCodeToCheck;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcContractLineAmount(AnnualAmount: Decimal; PeriodStarts: Date; PeriodEnds: Date; var AmountCalculated: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateAllServLines(ServiceContractHeader: Record "Service Contract Header"; var ServContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInvoice(var ServiceContractHeader: Record "Service Contract Header"; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInvoiceSetPostingDate(ServiceContractHeader: Record "Service Contract Header"; InvoiceFromDate: Date; InvoiceToDate: Date; var PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateServHeader(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertServiceHeader(var ServiceHeader: Record "Service Header"; var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvAmounts(var InvAmount: array[4] of Decimal; var ServiceContractLine: Record "Service Contract Line"; InvFrom: Date; InvTo: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeCustNoOnServItem(var ServiceItem: Record "Service Item"; NewCustomerNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateServLineForNewContract(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header"; var ServLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitServiceLineAppliedGLAccount(var ServLine: Record "Service Line"; AppliedGLAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDescriptionServiceLine(var ServLine: Record "Service Line"; Description: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertMultipleServLedgEntries(var ServLedgEntry: Record "Service Ledger Entry"; ServContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServContractHeaderModify(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLastServLineModify(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServHeaderModify(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServLineInsert(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateServLedgEntryAmounts(var ServiceContractLine: Record "Service Contract Line"; var ServLedgEntry: Record "Service Ledger Entry"; InvRoundedAmount: array[4] of Decimal; LineInvoiceFrom: Date; InvoiceTo: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDetailedServLineOnBeforeServLineInsertFirstLine(var ServiceLine: Record "Service Line"; var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDetailedServLineOnBeforeServLineInsertNewContract(var ServiceLine: Record "Service Line"; var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDetailedServLineOnBeforeCreateDescriptionServiceLines(ServContractHeader: Record "Service Contract Header"; var ServContractLine: Record "Service Contract Line"; ServHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateHeadingServLineOnBeforeServLineInsert(var ServiceLine: Record "Service Line"; ServiceContractHeader: Record "Service Contract Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOrGetCreditHeaderOnBeforeCalcCurrencyFactor(ServiceHeader: Record "Service Header"; var CurrExchRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOrGetCreditHeaderOnBeforeInitSeries(var ServiceHeader: Record "Service Header"; ServMgtSetup: Record "Service Mgt. Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServHeaderOnBeforeInitSeries(var ServiceHeader: Record "Service Header"; var ServMgtSetup: Record "Service Mgt. Setup"; ServContract2: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServHeaderOnBeforeCalcCurrencyFactor(ServiceHeader: Record "Service Header"; var CurrExchRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateContractLineCreditMemo(var ServiceContractLine: Record "Service Contract Line"; Deleting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateInvoice(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateRemainingPeriodInvoice(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateLastServLines(ServiceHeader: Record "Service Header"; ContractType: Integer; ContractNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcContractAmount(var ServiceContractHeader: Record "Service Contract Header"; PeriodStarts: Date; PeriodEnds: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServiceHeader(var ServiceHeader: Record "Service Header"; var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServiceLedgerEntryOnBeforeServLedgEntryInsert(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServiceLedgerEntryBeforeCountLineInvFrom(var ServLedgEntry: Record "Service Ledger Entry"; ServContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertMultipleServLedgEntriesOnBeforeServLedgEntryInsert(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line"; var NonDistrAmount: array[4] of Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateContractLineCreditMemoOnBeforeCalcCreditAmount(var WDate: Date; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateContractLineCreditMemo(var ServiceContractLine: Record "Service Contract Line"; ServiceCreditMemoNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterServContractLine(var ServContractLine: Record "Service Contract Line"; ContractNo: Code[20]; ContractType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinishCodeunit(ServiceRegister: Record "Service Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNoOfMonthsAndMPartsInPeriod(Day1: Date; Day2: Date; var CheckMParts: Boolean; var MonthsAndMParts: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyCheckSCDimToTempSCDim(var ServContract: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmCreateServiceInvoiceForPeriod(var CurrServContract: Record "Service Contract Header"; InvFrom: Date; InvTo: Date; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPartialServLedgEntry(var ServLedgEntry: Record "Service Ledger Entry"; ServContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServLedgEntryToServiceLine(var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceLedgerEntry: Record "Service Ledger Entry"; var IsHandled: Boolean; ServiceLedgerEntryParm: Record "Service Ledger Entry"; InvFrom: Date; InvTo: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDescriptionServiceLineOnBeforeServiceLineInsert(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServLedgEntryToServiceLineOnBeforeServLineInsert(var ServiceLine: Record "Service Line"; TotalServiceLine: Record "Service Line"; TotalServiceLineLCY: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceLedgerEntryParm: Record "Service Ledger Entry"; var IsHandled: Boolean; InvFrom: Date; InvTo: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateContractLineCreditMemoOnAfterCreateAllCreditLines(ServContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line"; CreditMemoNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateOrGetCreditHeader(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateRemainingPeriodInvoiceOnAfterServContractLineSetFilters(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateAllServLinesOnAfterServContractLineSetFilters(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateAllServLinesOnAfterCreateDetailedServLine(ServiceContractHeader: Record "Service Contract Header"; ServHeader: Record "Service Header"; ServContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateAllServLinesOnAfterCreateServiceLedgerEntry(var ServContractLine: Record "Service Contract Line"; var ServiceApplyEntry: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateAllServLinesOnBeforeServContractLineLoop(var InvoiceFrom: Date; ServContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateAllCreditLinesCaseElse(ServiceContractHeader: Record "Service Contract Header"; var InvPeriod: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateAllCreditLinesOnAfterDetermineOldWDate(ServiceContractHeader: Record "Service Contract Header"; InvPeriod: Integer; Days: Integer; WDate: Date; var OldWDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDetailedServLineOnAfterSetFirstLineAndNewContract(var FirstLine: Boolean; var NewContract: Boolean; ServContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvoiceOnBeforeCreateAllServLines(var ServiceContractHeader: Record "Service Contract Header"; InvoiceFromDate: Date; InvoiceToDate: Date; var InvoicedAmount: Decimal; var PostingDate: Date; InvoicingStartingPeriod: Boolean; InvNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupServItemNoOnBeforeFilterByCustomerNo(var ServItem: Record "Service Item"; var ServiceContractLine: Record "Service Contract Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPartialServLedgEntryOnBeforeServLedgEntryInsert(var ServLedgEntry: Record "Service Ledger Entry"; ServContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateRemainingPeriodInvoice(var CurrServContract: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalespersonCode(SalesPersonCodeToCheck: Code[20]; var SalesPersonCodeToAssign: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServiceLedgerEntryOnAfterInitServLedgEntry(var ServLedgEntry: Record "Service Ledger Entry"; var ServContractHeader: Record "Service Contract Header"; ContractType: Integer; ContractNo: Code[20]; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServiceLedgerEntryOnBeforeCheckServContractLineStartingDate(ServContractHeader: Record "Service Contract Header"; var CountOfEntryLoop: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServiceLedgerEntryOnBeforeLoopPeriods(ServContractHeader: Record "Service Contract Header"; ServContractLine: Record "Service Contract Line"; var InvFrom: Date; var WDate: Date; var DateExpression: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServiceLedgerEntryOnBeforeInsertMultipleServLedgEntries(var NextInvDate: Date; ServContractHeader: Record "Service Contract Header"; ServContractLine: Record "Service Contract Line")
    begin
    end;
}

