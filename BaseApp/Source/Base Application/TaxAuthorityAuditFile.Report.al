report 11412 "Tax Authority - Audit File"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tax Authority - Audit File';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = SORTING("No.") WHERE("Account Type" = CONST(Posting));

            trigger OnAfterGetRecord()
            begin
                CalcFields("Balance at Date");
                if ("Balance at Date" <> 0) and not ExcludeBeginBalance then
                    WriteAccountBeginBalance;
            end;

            trigger OnPreDataItem()
            begin
                SetFilter("Date Filter", '..%1', ClosingDate(StartDate - 1));
            end;
        }
        dataitem("Accounting Period"; "Accounting Period")
        {
            DataItemTableView = SORTING("Starting Date");
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemTableView = SORTING("G/L Account No.", "Posting Date");

                trigger OnAfterGetRecord()
                begin
                    if ("Debit Amount" <> 0) or ("Credit Amount" <> 0) then begin
                        BufferGLAccount("G/L Account No.");
                        BufferCustomerVendor;
                        BufferTransactions;

                        TotalEntries := TotalEntries + 1;
                        TotalDebit := TotalDebit + "Debit Amount";
                        TotalCredit := TotalCredit + "Credit Amount";
                    end;

                    UpdateWindow(1);
                end;

                trigger OnPreDataItem()
                var
                    UseStartDate: Date;
                    UseStopDate: Date;
                begin
                    if "Accounting Period"."Starting Date" < StartDate then
                        UseStartDate := StartDate
                    else
                        UseStartDate := "Accounting Period"."Starting Date";
                    if EndPeriodDate > EndDate then
                        UseStopDate := EndDate
                    else
                        UseStopDate := EndPeriodDate;
                    SetRange("Posting Date", UseStartDate, ClosingDate(UseStopDate));
                end;
            }

            trigger OnAfterGetRecord()
            var
                NextAcctPeriod: Record "Accounting Period";
            begin
                FindPeriodNo("Accounting Period");
                NextAcctPeriod.Get("Starting Date");

                if NextAcctPeriod.Next = 0 then
                    EndPeriodDate := CalcDate('<+1M-1D>', NextAcctPeriod."Starting Date")
                else
                    EndPeriodDate := CalcDate('<-1D>', NextAcctPeriod."Starting Date");
            end;

            trigger OnPreDataItem()
            begin
                PeriodNumber := 0;
                CopyFilters(AccountingPeriod);
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
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';

                        trigger OnValidate()
                        begin
                            StartDateOnAfterValidate;
                        end;
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'End Date';
                        ToolTip = 'Specifies the last date for which data is included in the file.';
                    }
                    field(ExcludeBalance; ExcludeBeginBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Exclude Begin Balance';
                        Enabled = ExcludeBalanceEnable;
                        ToolTip = 'Specifies if the starting balance is included in the file. This option is available when the start date is equal to the first date of a fiscal year.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            ExcludeBalanceEnable := true;
        end;

        trigger OnOpenPage()
        begin
            EnableBeginBalance;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        TempAuditFileBuffer.Reset;
        GLSetup.Get;
        GLSetup.TestField("LCY Code");
        CompanyInfo.Get;
        if StrLen(CompanyInfo."VAT Registration No.") > 15 then
            Error(Text007, CompanyInfo.FieldCaption("VAT Registration No."), CompanyInfo.TableCaption);
    end;

    trigger OnPostReport()
    var
        FileMgmt: Codeunit "File Management";
        Encoding: DotNet Encoding;
        XmlWriterSettings: DotNet XmlWriterSettings;
        ServerFileName: Text;
    begin
        ServerFileName := FileMgmt.ServerTempFileName('.xaf');

        TotalCount := TempAuditFileBuffer.Count;
        StepEntries := Round(TotalCount / 1000, 1, '>');
        NextStep := StepEntries;
        CountEntries := 0;

        XmlWriterSettings := XmlWriterSettings.XmlWriterSettings;
        XmlWriterSettings.Encoding := Encoding.GetEncoding('windows-1252');
        XmlWriterSettings.OmitXmlDeclaration := false;
        XmlWriterSettings.Indent := true;

        XmlWriter := XmlWriter.Create(ServerFileName, XmlWriterSettings);

        XmlWriter.WriteStartDocument;
        StartElement('auditfile');
        FlushOutput;

        WriteHeader;
        WriteGLAccounts;
        WriteCustomersVendors;
        WriteTransactions;

        EndElement('auditfile');
        XmlWriter.WriteEndDocument;
        FlushOutput;

        Clear(XmlWriter);

        if FileName = '' then
            FileMgmt.DownloadHandler(ServerFileName, '', '', Text015, ClientFileTxt)
        else
            FileMgmt.CopyServerFile(ServerFileName, FileName, true);

        Window.Close;
    end;

    trigger OnPreReport()
    var
        LocGLEntry: Record "G/L Entry";
        FilterStartDate: Date;
        FilterEndDate: Date;
        FirstRecord: Boolean;
    begin
        // Check User input
        if StartDate = 0D then
            Error(Text010);
        if EndDate = 0D then
            Error(Text011);
        if StartDate > EndDate then
            Error(Text004);
        if EndDate > Today then
            Error(Text005);

        // Filter Accounting Period
        AccountingPeriod.Reset;
        AccountingPeriod."Starting Date" := StartDate;
        if not AccountingPeriod.Find('=<') then
            Error(Text012);
        FilterStartDate := AccountingPeriod."Starting Date";
        AccountingPeriod."Starting Date" := EndDate;
        AccountingPeriod.Find('=<');
        FilterEndDate := AccountingPeriod."Starting Date";
        AccountingPeriod.SetFilter("Starting Date", '%1..%2', FilterStartDate, FilterEndDate);

        // Check Fiscal Year
        FirstRecord := true;
        if AccountingPeriod.Find('-') then
            repeat
                if AccountingPeriod."New Fiscal Year" and not FirstRecord then
                    Error(Text006);
                FirstRecord := false;
            until AccountingPeriod.Next = 0;

        Window.Open(Text009);
        LocGLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
        LocGLEntry.SetRange("Posting Date", StartDate, ClosingDate(EndDate));
        TotalCount := LocGLEntry.Count;
        StepEntries := Round(TotalCount / 1000, 1, '>');
        NextStep := StepEntries;
        CountEntries := 0;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        TempAuditFileBuffer: Record "Audit File Buffer" temporary;
        AccountingPeriod: Record "Accounting Period";
        Window: Dialog;
        XmlWriter: DotNet XmlWriter;
        StartDate: Date;
        EndDate: Date;
        EndPeriodDate: Date;
        PeriodNumber: Integer;
        TotalEntries: BigInteger;
        TotalCount: BigInteger;
        CountEntries: BigInteger;
        StepEntries: BigInteger;
        NextStep: BigInteger;
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        CustSupID: Code[35];
        ExcludeBeginBalance: Boolean;
        Text004: Label 'Start Date cannot be higher than End Date.';
        Text005: Label 'End Date cannot be higher than today.';
        Text006: Label 'Start/End Date must be within one fiscal year.';
        Text007: Label 'Length of %1 in %2  must not exceed 15 characters.';
        Text008: Label 'Length of %1 in %2 %3 must not exceed 15 characters.';
        Text009: Label 'Processing Data @1@@@@@@@@@@@@@\\Exporting Data  @2@@@@@@@@@@@@@ ';
        Text010: Label 'Start Date cannot be blank.';
        Text011: Label 'End Date cannot be blank.';
        Text012: Label 'Start Date should be within one of the setup accounting periods. ';
        Text015: Label 'Audit File (*.xaf)|*.xaf|All Files|*.*';
        [InDataSet]
        ExcludeBalanceEnable: Boolean;
        ClientFileTxt: Label 'Audit.xaf', Locked = true;
        FileName: Text;

    local procedure BufferGLAccount(AcctNo: Code[20])
    begin
        Clear(TempAuditFileBuffer);
        TempAuditFileBuffer.Rectype := TempAuditFileBuffer.Rectype::"G/L Account";
        TempAuditFileBuffer.Code := AcctNo;
        if not TempAuditFileBuffer.Get(TempAuditFileBuffer.Rectype, TempAuditFileBuffer.Code) then
            TempAuditFileBuffer.Insert;
    end;

    local procedure BufferCustomerVendor()
    begin
        Clear(CustSupID);
        Clear(TempAuditFileBuffer);

        if "G/L Entry"."Source Type" = "G/L Entry"."Source Type"::Customer then
            TempAuditFileBuffer.Rectype := TempAuditFileBuffer.Rectype::Customer
        else
            if "G/L Entry"."Source Type" = "G/L Entry"."Source Type"::Vendor then
                TempAuditFileBuffer.Rectype := TempAuditFileBuffer.Rectype::Vendor
            else
                if "G/L Entry"."Source Type" = "G/L Entry"."Source Type"::"Bank Account" then
                    TempAuditFileBuffer.Rectype := TempAuditFileBuffer.Rectype::"Bank Account";

        if TempAuditFileBuffer.Rectype <> TempAuditFileBuffer.Rectype::" " then begin
            TempAuditFileBuffer.Code := "G/L Entry"."Source No.";
            CustSupID := GetFormatedCustSupID(TempAuditFileBuffer.Rectype, TempAuditFileBuffer.Code);
            if not TempAuditFileBuffer.Get(TempAuditFileBuffer.Rectype, TempAuditFileBuffer.Code) then
                TempAuditFileBuffer.Insert;
        end;
    end;

    local procedure BufferTransactions()
    var
        SourceCode: Record "Source Code";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Clear(TempAuditFileBuffer);
        TempAuditFileBuffer.Rectype := TempAuditFileBuffer.Rectype::Transaction;

        // Journal data
        TempAuditFileBuffer.JournalID := "G/L Entry"."Source Code";
        if SourceCode.Get("G/L Entry"."Source Code") then
            TempAuditFileBuffer.JournalDescription := SourceCode.Description;

        // Transaction data
        TempAuditFileBuffer.TransactionID := Format("G/L Entry"."Transaction No.", 20);
        TempAuditFileBuffer.TransactionDate := "G/L Entry"."Posting Date";
        TempAuditFileBuffer.TransactionDescription := "G/L Entry".Description;
        TempAuditFileBuffer.Period := Format(PeriodNumber, 5);

        // Line data
        TempAuditFileBuffer.RecordID := Format("G/L Entry"."Entry No.", 20);
        TempAuditFileBuffer."Account ID" :=
          CopyStr("G/L Entry"."G/L Account No.", 1, MaxStrLen(TempAuditFileBuffer."Account ID"));
        TempAuditFileBuffer."Source ID" :=
          CopyStr(CustSupID, 1, MaxStrLen(TempAuditFileBuffer."Source ID"));
        TempAuditFileBuffer."Document ID" :=
          CopyStr("G/L Entry"."Document No.", 1, MaxStrLen(TempAuditFileBuffer."Document ID"));
        TempAuditFileBuffer.EffectiveDate := "G/L Entry"."Document Date";
        TempAuditFileBuffer.LineDescription := "G/L Entry".Description;
        TempAuditFileBuffer.DebitAmount := "G/L Entry"."Debit Amount";
        TempAuditFileBuffer.CreditAmount := "G/L Entry"."Credit Amount";
        TempAuditFileBuffer.CostDescription := "G/L Entry"."Global Dimension 1 Code";
        TempAuditFileBuffer.ProductDescription := "G/L Entry"."Global Dimension 2 Code";
        if "G/L Entry"."VAT Amount" <> 0 then begin
            TempAuditFileBuffer.VATCode := "G/L Entry"."VAT Prod. Posting Group";
            if VATPostingSetup.Get("G/L Entry"."VAT Bus. Posting Group", "G/L Entry"."VAT Prod. Posting Group") then
                TempAuditFileBuffer."VAT %" := VATPostingSetup."VAT %";
            TempAuditFileBuffer.VATAmount := "G/L Entry"."VAT Amount";
        end;
        TempAuditFileBuffer.Insert;
    end;

    local procedure StartElement(QualifiedName: Text[80])
    var
        NamespaceURI: Text[80];
        LocalName: Text[80];
    begin
        XmlWriter.WriteStartElement(LocalName, QualifiedName, NamespaceURI);
    end;

    local procedure EndElement(QualifiedName: Text[80])
    begin
        XmlWriter.WriteEndElement;
    end;

    local procedure WriteElement(QualifiedName: Text[80]; Value: Text[1024])
    begin
        XmlWriter.WriteElementString(QualifiedName, Value);
    end;

    local procedure WriteHeader()
    var
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        StartElement('header');
        WriteElement('auditfileVersion', 'CLAIR2.00.00');
        WriteElement('companyID', CopyStr(CompanyName, 1, 20));
        WriteElement('taxRegistrationNr', CompanyInfo."VAT Registration No.");
        WriteElement('companyName', ConvertStr(CompanyInfo.Name, '.,', '  '));
        WriteElement('companyAddress', CompanyInfo.Address);
        WriteElement('companyCity', CompanyInfo.City);
        WriteElement('companyPostalCode', CopyStr(CompanyInfo."Post Code", 1, 10));
        WriteElement('fiscalYear', Format(StartDate, 0, '<YEAR4>'));
        WriteElement('startDate', FormatDate(StartDate));
        WriteElement('endDate', FormatDate(EndDate));
        WriteElement('currencyCode', CopyStr(GLSetup."LCY Code", 1, 3));
        WriteElement('dateCreated', FormatDate(Today));
        WriteElement('productID', 'Microsoft Dynamics NAV');
        WriteElement('productVersion', CopyStr(ApplicationSystemConstants.ApplicationVersion, 1, 20));
        EndElement('header');
        FlushOutput;
    end;

    local procedure WriteGLAccounts()
    var
        GLAcc: Record "G/L Account";
    begin
        TempAuditFileBuffer.Reset;
        TempAuditFileBuffer.SetRange(Rectype, TempAuditFileBuffer.Rectype::"G/L Account");
        StartElement('generalLedger');
        WriteElement('taxonomy', '');

        if TempAuditFileBuffer.Find('-') then
            repeat
                StartElement('ledgerAccount');
                if GLAcc.Get(TempAuditFileBuffer.Code) then begin
                    WriteElement('accountID', CopyStr(TempAuditFileBuffer.Code, 1, 15));
                    WriteElement('accountDesc', GLAcc.Name);
                    case GLAcc."Income/Balance" of
                        GLAcc."Income/Balance"::"Income Statement":
                            WriteElement('accountType', 'Winst en Verlies');
                        GLAcc."Income/Balance"::"Balance Sheet":
                            WriteElement('accountType', 'Balans');
                    end;
                    WriteElement('leadCode', GLAcc."No.");
                    WriteElement('leadDescription', GLAcc.Name);
                end;
                EndElement('ledgerAccount');
                UpdateWindow(2);
                FlushOutput;
            until TempAuditFileBuffer.Next = 0;

        EndElement('generalLedger');
    end;

    local procedure WriteCustomersVendors()
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        Country: Record "Country/Region";
    begin
        TempAuditFileBuffer.Reset;
        TempAuditFileBuffer.SetFilter(Rectype, '%1|%2|%3', TempAuditFileBuffer.Rectype::Customer,
          TempAuditFileBuffer.Rectype::Vendor, TempAuditFileBuffer.Rectype::"Bank Account");
        StartElement('customersSuppliers');

        if TempAuditFileBuffer.Find('-') then
            repeat
                StartElement('customerSupplier');
                WriteElement('custSupID', CopyStr(GetFormatedCustSupID(TempAuditFileBuffer.Rectype, TempAuditFileBuffer.Code), 1, 15));
                case TempAuditFileBuffer.Rectype of
                    TempAuditFileBuffer.Rectype::Customer:
                        if Cust.Get(TempAuditFileBuffer.Code) then begin
                            if StrLen(Cust."VAT Registration No.") > 15 then
                                Error(Text008, Cust.FieldCaption("VAT Registration No."), Cust.TableCaption, Cust."No.");
                            WriteElement('type', 'Debiteur');
                            WriteElement('taxRegistrationNr', Cust."VAT Registration No.");
                            WriteElement('companyName', Cust.Name);
                            WriteElement('contact', Cust.Contact);
                            StartElement('streetAddress');
                            WriteElement('address', Cust.Address);
                            WriteElement('city', Cust.City);
                            WriteElement('postalCode', CopyStr(Cust."Post Code", 1, 10));
                            if Country.Get(Cust."Country/Region Code") then
                                WriteElement('country', Country.Name)
                            else
                                WriteElement('country', '');
                            EndElement('streetAddress');
                            WriteElement('telephone', Cust."Phone No.");
                            WriteElement('fax', Cust."Fax No.");
                            WriteElement('eMail', DelChr(Cust."E-Mail"));
                            WriteElement('website', DelChr(Cust."Home Page", '<>', ' '));
                        end;
                    TempAuditFileBuffer.Rectype::Vendor:
                        if Vend.Get(TempAuditFileBuffer.Code) then begin
                            if StrLen(Vend."VAT Registration No.") > 15 then
                                Error(Text008, Vend.FieldCaption("VAT Registration No."), Vend.TableCaption, Vend."No.");
                            WriteElement('type', 'Crediteur');
                            WriteElement('taxRegistrationNr', Vend."VAT Registration No.");
                            WriteElement('companyName', Vend.Name);
                            WriteElement('contact', Vend.Contact);
                            StartElement('streetAddress');
                            WriteElement('address', Vend.Address);
                            WriteElement('city', Vend.City);
                            WriteElement('postalCode', CopyStr(Vend."Post Code", 1, 10));
                            if Country.Get(Vend."Country/Region Code") then
                                WriteElement('country', Country.Name)
                            else
                                WriteElement('country', '');
                            EndElement('streetAddress');
                            WriteElement('telephone', Vend."Phone No.");
                            WriteElement('fax', Vend."Fax No.");
                            WriteElement('eMail', DelChr(Vend."E-Mail"));
                            WriteElement('website', DelChr(Vend."Home Page", '<>', ' '));
                        end;
                    TempAuditFileBuffer.Rectype::"Bank Account":
                        if BankAcc.Get(TempAuditFileBuffer.Code) then begin
                            WriteElement('type', 'Filiaal');
                            WriteElement('taxRegistrationNr', '');
                            WriteElement('companyName', BankAcc.Name);
                            WriteElement('contact', BankAcc.Contact);
                            StartElement('streetAddress');
                            WriteElement('address', BankAcc.Address);
                            WriteElement('city', BankAcc.City);
                            WriteElement('postalCode', CopyStr(BankAcc."Post Code", 1, 10));
                            if Country.Get(BankAcc."Country/Region Code") then
                                WriteElement('country', Country.Name)
                            else
                                WriteElement('country', '');
                            EndElement('streetAddress');
                            WriteElement('telephone', BankAcc."Phone No.");
                            WriteElement('fax', BankAcc."Fax No.");
                            WriteElement('eMail', DelChr(BankAcc."E-Mail"));
                            WriteElement('website', DelChr(BankAcc."Home Page", '<>', ' '));
                        end;
                end;
                EndElement('customerSupplier');
                UpdateWindow(2);
                FlushOutput;
            until TempAuditFileBuffer.Next = 0;
        EndElement('customersSuppliers');
    end;

    local procedure WriteTransactions()
    var
        OldJournalID: Text[20];
        OldTransactionID: Text[20];
        FirstLoop: Boolean;
        JournalElementStarted: Boolean;
        TransactionElementStarted: Boolean;
    begin
        OldJournalID := '';
        FirstLoop := true;
        TempAuditFileBuffer.Reset;
        TempAuditFileBuffer.SetRange(Rectype, TempAuditFileBuffer.Rectype::Transaction);

        StartElement('transactions');
        WriteElement('numberEntries', Format(TotalEntries));
        WriteElement('totalDebit', FormatAmount(TotalDebit));
        WriteElement('totalCredit', FormatAmount(TotalCredit));

        if TempAuditFileBuffer.Find('-') then
            repeat
                if FirstLoop or (OldJournalID <> TempAuditFileBuffer.JournalID) then begin
                    FirstLoop := false;
                    OldJournalID := TempAuditFileBuffer.JournalID;
                    OldTransactionID := '';
                    if TransactionElementStarted then begin
                        EndElement('transaction');
                        TransactionElementStarted := false;
                    end;
                    if JournalElementStarted then
                        EndElement('journal');
                    StartElement('journal');
                    JournalElementStarted := true;
                    WriteElement('journalID', TempAuditFileBuffer.JournalID);
                    WriteElement('description', TempAuditFileBuffer.JournalDescription);
                end;
                if OldTransactionID <> TempAuditFileBuffer.TransactionID then begin
                    OldTransactionID := TempAuditFileBuffer.TransactionID;
                    if TransactionElementStarted then
                        EndElement('transaction');
                    StartElement('transaction');
                    TransactionElementStarted := true;
                    WriteElement('transactionID', TempAuditFileBuffer.TransactionID);
                    WriteElement('description', TempAuditFileBuffer.TransactionDescription);
                    WriteElement('period', TempAuditFileBuffer.Period);
                    WriteElement('transactionDate', FormatDate(TempAuditFileBuffer.TransactionDate));
                end;
                StartElement('line');
                WriteElement('recordID', TempAuditFileBuffer.RecordID);
                WriteElement('accountID', TempAuditFileBuffer."Account ID");
                if TempAuditFileBuffer."Source ID" <> '' then
                    WriteElement('custSupID', TempAuditFileBuffer."Source ID");
                WriteElement('documentID', TempAuditFileBuffer."Document ID");
                WriteElement('effectiveDate', FormatDate(TempAuditFileBuffer.EffectiveDate));
                WriteElement('description', TempAuditFileBuffer.LineDescription);
                if TempAuditFileBuffer.DebitAmount <> 0 then
                    WriteElement('debitAmount', FormatAmount(TempAuditFileBuffer.DebitAmount));
                if TempAuditFileBuffer.CreditAmount <> 0 then
                    WriteElement('creditAmount', FormatAmount(TempAuditFileBuffer.CreditAmount));
                if TempAuditFileBuffer.CostDescription <> '' then
                    WriteElement('costDesc', TempAuditFileBuffer.CostDescription);
                if TempAuditFileBuffer.ProductDescription <> '' then
                    WriteElement('productDesc', TempAuditFileBuffer.ProductDescription);
                if TempAuditFileBuffer.VATAmount <> 0 then begin
                    StartElement('vat');
                    WriteElement('vatCode', TempAuditFileBuffer.VATCode);
                    WriteElement('vatAmount', FormatAmount(TempAuditFileBuffer.VATAmount));
                    EndElement('vat');
                end;
                EndElement('line');
                UpdateWindow(2);
                FlushOutput;
            until TempAuditFileBuffer.Next = 0;

        if TransactionElementStarted then
            EndElement('transaction');
        if JournalElementStarted then
            EndElement('journal');
        EndElement('transactions');
    end;

    local procedure FormatDate(Date: Date): Text[30]
    begin
        exit(Format(Date, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    local procedure FormatAmount(InAmount: Decimal): Text[30]
    begin
        exit(ConvertStr(Format(InAmount, 0, '<sign><integer><decimal,3>'), ',', '.'));
    end;

    local procedure WriteAccountBeginBalance()
    begin
        BufferGLAccount("G/L Account"."No.");

        Clear(TempAuditFileBuffer);
        TempAuditFileBuffer.Rectype := TempAuditFileBuffer.Rectype::Transaction;

        // Journal data
        TempAuditFileBuffer.JournalID := 'BEGINBALANS';
        TempAuditFileBuffer.JournalDescription := 'Begin balans';

        // Transaction data
        TempAuditFileBuffer.TransactionID := '0';
        TempAuditFileBuffer.TransactionDate := StartDate;
        TempAuditFileBuffer.TransactionDescription := 'Begin balans grootboekrekeningen';
        TempAuditFileBuffer.Period := '0';

        // Line data
        TempAuditFileBuffer.RecordID := Format(FindBeginBalanceEntryNo("G/L Account"."No."), 20);
        TempAuditFileBuffer."Account ID" :=
          CopyStr("G/L Account"."No.", 1, MaxStrLen(TempAuditFileBuffer."Account ID"));
        TempAuditFileBuffer.EffectiveDate := StartDate;
        TempAuditFileBuffer.LineDescription := 'Transactie beginbalans';
        if "G/L Account"."Balance at Date" > 0 then
            TempAuditFileBuffer.DebitAmount := "G/L Account"."Balance at Date"
        else
            TempAuditFileBuffer.CreditAmount := Abs("G/L Account"."Balance at Date");

        TempAuditFileBuffer.Insert;

        TotalEntries := TotalEntries + 1;
        TotalDebit := TotalDebit + TempAuditFileBuffer.DebitAmount;
        TotalCredit := TotalCredit + TempAuditFileBuffer.CreditAmount;
    end;

    local procedure EnableBeginBalance()
    begin
        PageEnableBeginBalance;
    end;

    local procedure UpdateWindow(ProgressBarNo: Integer)
    begin
        CountEntries := CountEntries + 1;
        if CountEntries >= NextStep then begin
            Window.Update(ProgressBarNo, Round(10000 * (CountEntries / TotalCount), 1));
            NextStep := NextStep + StepEntries;
        end;
    end;

    local procedure FlushOutput()
    begin
        XmlWriter.Flush;
    end;

    local procedure FindPeriodNo(ParamAccountingPeriod: Record "Accounting Period")
    var
        FoundFiscalYear: Boolean;
    begin
        if PeriodNumber <> 0 then
            PeriodNumber := PeriodNumber + 1
        else begin
            PeriodNumber := 1;
            FoundFiscalYear := false;
            if not ParamAccountingPeriod."New Fiscal Year" then
                while (ParamAccountingPeriod.Next(-1) <> 0) and not FoundFiscalYear do begin
                    PeriodNumber := PeriodNumber + 1;
                    if ParamAccountingPeriod."New Fiscal Year" then
                        FoundFiscalYear := true;
                end;
        end;
    end;

    local procedure FindBeginBalanceEntryNo(GLAccountNo: Code[20]): Integer
    var
        LocGLEntry: Record "G/L Entry";
    begin
        LocGLEntry.Reset;
        LocGLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
        LocGLEntry.SetRange("G/L Account No.", GLAccountNo);
        LocGLEntry.SetFilter("Posting Date", '..%1', ClosingDate(StartDate - 1));
        LocGLEntry.FindLast;
        exit(LocGLEntry."Entry No.");
    end;

    local procedure StartDateOnAfterValidate()
    begin
        EnableBeginBalance;
    end;

    local procedure PageEnableBeginBalance()
    var
        LocAccountingPeriod: Record "Accounting Period";
    begin
        ExcludeBeginBalance := true;
        ExcludeBalanceEnable := false;
        if LocAccountingPeriod.Get(StartDate) then
            if LocAccountingPeriod."New Fiscal Year" then begin
                ExcludeBeginBalance := false;
                ExcludeBalanceEnable := true;
            end;
    end;

    [Scope('OnPrem')]
    procedure SetFileName(ServerFileName: Text)
    begin
        FileName := ServerFileName;
    end;

    local procedure GetFormatedCustSupID(Rectype: Option; CustomerSupID: Code[20]): Code[35]
    var
        AuditFileBuffer: Record "Audit File Buffer";
    begin
        if Rectype = AuditFileBuffer.Rectype::" " then
            exit(CustomerSupID);
        exit(StrSubstNo('%1%2', Format(Rectype, 0, 2), CustomerSupID));
    end;
}

