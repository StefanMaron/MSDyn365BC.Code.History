codeunit 10095 "Export EFT (RB)"
{

    trigger OnRun()
    begin
    end;

    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
        FileManagement: Codeunit "File Management";
        FileName: Text;
        FileDate: Date;
        DummyModifierValues: array[26] of Code[1];
        PaymentsThisAcct: Integer;
        CurrencyType: Code[10];
        AcctNo: Code[20];
        AcctName: Text[30];
        AcctLanguage: Option "E  English","F  French";
        RecipientAddress: Text[80];
        RecipientCity: Text[30];
        RecipientCountryCode: Text[30];
        RecipientCounty: Text[30];
        RecipientPostCode: Code[20];
        RecipientBankAcctNo: Text[30];
        RecipientTransitNo: Text[20];
        RecipientBankNo: Text[20];
        RecipientBankAcctCurrencyCode: Code[10];
        RecipientBankAcctCountryCode: Code[10];
        AlreadyExistsErr: Label 'The file already exists. Check the "Last E-Pay Export File Name" field in the bank account.';
        ReferErr: Label 'Either Account type or balance account type must refer to either a vendor or a customer for an electronic payment.';
        VendorBankAccountErr: Label 'The vendor has no bank account setup for electronic payments.';
        VendorMoreThanOneBankAccErr: Label 'The vendor has more than one bank account setup for electronic payments.';
        CustomerBankAccountErr: Label 'The customer has no bank account setup for electronic payments.';
        CustomerMoreThanOneBankAccountErr: Label 'The customer has more than one bank account setup for electronic payments.';
        IsBlockedErr: Label 'Account type is blocked for processing.';
        PrivacyBlockedErr: Label 'Account type is blocked for privacy.';

    [Scope('OnPrem')]
    procedure StartExportFile(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; BankAccountNo: Code[20]; DataExchEntryNo: Integer; var EFTValues: Codeunit "EFT Values")
    var
        ACHRBHeader: Record "ACH RB Header";
        GLSetup: Record "General Ledger Setup";
        DataExchColumnDef: Record "Data Exch. Column Def";
        ExportEFTACH: Codeunit "Export EFT (ACH)";
        i: Integer;
        FedID: Text[30];
        DateInteger: Integer;
    begin
        ExportEFTACH.BuildIDModifier(DummyModifierValues);

        CompanyInformation.Get;
        CompanyInformation.TestField("Federal ID No.");

        with BankAccount do begin
            LockTable;
            Get(BankAccountNo);
            TestField("Export Format", "Export Format"::CA);
            TestField("Transit No.");
            TestField("Last E-Pay Export File Name");
            TestField("Bank Acc. Posting Group");
            TestField(Blocked, false);
            TestField("Client No.");
            TestField("Client Name");

            if TempEFTExportWorkset."Bank Payment Type" =
               TempEFTExportWorkset."Bank Payment Type"::"Electronic Payment-IAT"
            then begin
                TempEFTExportWorkset.TestField("Transaction Code");
                TempEFTExportWorkset.TestField("Company Entry Description");
            end;

            FileName := FileManagement.ServerTempFileName('');

            if "Last ACH File ID Modifier" = '' then
                "Last ACH File ID Modifier" := '1'
            else begin
                i := 1;
                while (i < ArrayLen(DummyModifierValues)) and
                      ("Last ACH File ID Modifier" <> DummyModifierValues[i])
                do
                    i := i + 1;
                if i = ArrayLen(DummyModifierValues) then
                    i := 1
                else
                    i := i + 1;

                "Last ACH File ID Modifier" := DummyModifierValues[i];
            end;
            "Last E-Pay File Creation No." := "Last E-Pay File Creation No." + 1;
            Modify;

            if Exists(FileName) then
                Error(AlreadyExistsErr);

            FileDate := Today;
            EFTValues.SetNoOfRec(1);
            EFTValues.SetNoOfCustInfoRec(0);
            EFTValues.SetTotalFileDebit(0);
            EFTValues.SetTotalFileCredit(0);
            EFTValues.SetTransactions(0);
            FedID := CompanyInformation."Federal ID No.";

            if TempEFTExportWorkset."Currency Code" = '' then begin
                GLSetup.Get;
                CurrencyType := GLSetup."LCY Code";
            end else
                CurrencyType := TempEFTExportWorkset."Currency Code";

            ACHRBHeader.Get(DataExchEntryNo);
            ACHRBHeader."Record Count" := EFTValues.GetNoOfRec;
            ACHRBHeader."Record Type" := 'A';
            ACHRBHeader."Transaction Code" := 'HDR';
            ACHRBHeader."Client Number" := "Client No.";
            ACHRBHeader."Client Name" := "Client Name";
            ACHRBHeader."Federal ID No." := DelChr(FedID, '=', ' .,-');
            ACHRBHeader."File Creation Number" := "Last E-Pay File Creation No.";
            ACHRBHeader."File Creation Date" := JulianDate(FileDate);

            // if can find the column definition, get the value of the Data Format and assign it to DateFormat variable
            FindDataExchColumnDef(DataExchColumnDef, DataExchEntryNo, ACHRBHeader.FieldName("File Creation Date"));
            if DataExchColumnDef."Data Format" <> '' then begin
                Evaluate(DateInteger, Format(FileDate, DataExchColumnDef.Length, DataExchColumnDef."Data Format"));
                ACHRBHeader."File Creation Date" := DateInteger;
            end;

            ACHRBHeader."Currency Type" := CurrencyType;
            ACHRBHeader."Input Type" := '1';
            ACHRBHeader."Input Qualifier" := "Input Qualifier";
            OnBeforeACHRBHeaderModify(ACHRBHeader, BankAccount);
            ACHRBHeader.Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure ExportElectronicPayment(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; PaymentAmount: Decimal; SettleDate: Date; DataExchEntryNo: Integer; DataExchLineDefCode: Code[20]; var EFTValues: Codeunit "EFT Values"): Code[30]
    var
        DemandCredit: Boolean;
    begin
        // NOTE:  If PaymentAmount is Positive, then we are Receiving money.
        // If PaymentAmount is Negative, then we are Sending money.
        if PaymentAmount = 0 then
            exit('');
        DemandCredit := (PaymentAmount < 0);
        PaymentAmount := Abs(PaymentAmount);

        if EFTValues.GetParentBoolean then
            if DemandCredit then
                EFTValues.SetTotalFileCredit(EFTValues.GetTotalFileCredit + PaymentAmount)
            else
                EFTValues.SetTotalFileDebit(EFTValues.GetTotalFileDebit + PaymentAmount);

        GetRecipientData(TempEFTExportWorkset);
        WriteRecord(TempEFTExportWorkset, PaymentAmount, SettleDate, DataExchEntryNo, DataExchLineDefCode,
          EFTValues.GetParentBoolean, EFTValues);

        exit(GenerateFullTraceNoCode(EFTValues.GetTraceNo));
    end;

    [Scope('OnPrem')]
    procedure EndExportFile(DataExchEntryNo: Integer; var EFTValues: Codeunit "EFT Values"): Boolean
    var
        ACHRBFooter: Record "ACH RB Footer";
    begin
        ACHRBFooter.Get(DataExchEntryNo);
        ACHRBFooter."Record Type" := 'Z';
        ACHRBFooter."Transaction Code" := 'TRL';
        ACHRBFooter."Client Number" := BankAccount."Client No.";
        EFTValues.SetNoOfRec(EFTValues.GetNoOfRec + 1);
        ACHRBFooter."Record Count" := EFTValues.GetNoOfRec;
        ACHRBFooter."Credit Payment Transactions" := EFTValues.GetTransactions;
        ACHRBFooter."Total File Credit" := EFTValues.GetTotalFileCredit;
        ACHRBFooter."Zero Fill" := 0;
        ACHRBFooter."Number of Cust Info Records" := EFTValues.GetNoOfCustInfoRec;
        OnBeforeACHRBFooterModify(ACHRBFooter, BankAccount."No.");
        ACHRBFooter.Modify;

        exit(true);
    end;

    local procedure GenerateFullTraceNoCode(TraceNo: Integer): Code[30]
    var
        TraceCode: Text;
    begin
        TraceCode := '';
        TraceCode := Format(BankAccount."Last E-Pay File Creation No." + TraceNo);
        exit(TraceCode);
    end;

    local procedure GetRecipientData(var TempEFTExportWorkset: Record "EFT Export Workset" temporary)
    var
        AcctType: Text[1];
    begin
        with TempEFTExportWorkset do begin
            if "Account Type" = "Account Type"::Vendor then begin
                AcctType := 'V';
                AcctNo := "Account No.";
            end else
                if "Account Type" = "Account Type"::Customer then begin
                    AcctType := 'C';
                    AcctNo := "Account No.";
                end else
                    if "Bal. Account Type" = "Bal. Account Type"::Vendor then begin
                        AcctType := 'V';
                        AcctNo := "Bal. Account No.";
                    end else
                        if "Bal. Account Type" = "Bal. Account Type"::Customer then begin
                            AcctType := 'C';
                            AcctNo := "Bal. Account No.";
                        end else
                            Error(ReferErr);

            if AcctType = 'V' then
                GetRecipientDataFromVendor
            else
                if AcctType = 'C' then
                    GetRecipientDataFromCustomer;
        end;
    end;

    local procedure GetRecipientDataFromVendor()
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        if AcctNo <> Vendor."No." then begin
            Vendor.Get(AcctNo);
            Vendor.TestField(Blocked, Vendor.Blocked::" ");
            Vendor.TestField("Privacy Blocked", false);
            PaymentsThisAcct := 0;
        end else
            PaymentsThisAcct := PaymentsThisAcct + 1;
        AcctName := CopyStr(Vendor.Name, 1, 30);
        AcctLanguage := Vendor."Bank Communication";
        RecipientAddress := CopyStr(Vendor.Address, 1, 35) + ' ' + CopyStr(Vendor."Address 2", 1, 35);
        RecipientCity := Vendor.City;
        RecipientCountryCode := Vendor."Country/Region Code";
        RecipientCounty := Vendor.County;
        RecipientPostCode := Vendor."Post Code";
        VendorBankAccount.SetRange("Vendor No.", AcctNo);
        VendorBankAccount.SetRange("Use for Electronic Payments", true);
        if VendorBankAccount.Count < 1 then
            Error(VendorBankAccountErr);
        if VendorBankAccount.Count > 1 then
            Error(VendorMoreThanOneBankAccErr);
        VendorBankAccount.FindFirst;

        VendorBankAccount.TestField("Bank Account No.");
        RecipientBankNo := VendorBankAccount."Bank Branch No.";
        RecipientTransitNo := VendorBankAccount."Transit No.";
        RecipientBankAcctNo := VendorBankAccount."Bank Account No.";
        RecipientBankAcctCurrencyCode := VendorBankAccount."Currency Code";
        RecipientBankAcctCountryCode := VendorBankAccount."Country/Region Code";
    end;

    local procedure GetRecipientDataFromCustomer()
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        if AcctNo <> Customer."No." then begin
            Customer.Get(AcctNo);
            if Customer."Privacy Blocked" then
                Error(PrivacyBlockedErr);
            if Customer.Blocked in [Customer.Blocked::All] then
                Error(IsBlockedErr);

            PaymentsThisAcct := 0;
        end else
            PaymentsThisAcct := PaymentsThisAcct + 1;
        AcctName := CopyStr(Customer.Name, 1, 30);
        AcctLanguage := Customer."Bank Communication";
        RecipientAddress := CopyStr(Customer.Address, 1, 35) + ' ' + CopyStr(Customer."Address 2", 1, 35);
        RecipientCity := Customer.City;
        RecipientCountryCode := Customer."Country/Region Code";
        RecipientCounty := Customer.County;
        RecipientPostCode := Customer."Post Code";
        CustomerBankAccount.SetRange("Customer No.", AcctNo);
        CustomerBankAccount.SetRange("Use for Electronic Payments", true);
        if CustomerBankAccount.Count < 1 then
            Error(CustomerBankAccountErr);

        if CustomerBankAccount.Count > 1 then
            Error(CustomerMoreThanOneBankAccountErr);

        CustomerBankAccount.FindFirst;

        CustomerBankAccount.TestField("Bank Account No.");
        RecipientBankNo := CustomerBankAccount."Bank Branch No.";
        RecipientTransitNo := CustomerBankAccount."Transit No.";
        RecipientBankAcctNo := CustomerBankAccount."Bank Account No.";
        RecipientBankAcctCurrencyCode := CustomerBankAccount."Currency Code";
        RecipientBankAcctCountryCode := CustomerBankAccount."Country/Region Code"
    end;

    [Scope('OnPrem')]
    procedure JulianDate(NormalDate: Date): Integer
    var
        Year: Integer;
        Days: Integer;
    begin
        Year := Date2DMY(NormalDate, 3);
        Days := (NormalDate - DMY2Date(1, 1, Year)) + 1;
        exit(Year * 1000 + Days);
    end;

    local procedure WriteRecord(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; PaymentAmount: Decimal; SettleDate: Date; DataExchEntryNo: Integer; DataExchLineDefCode: Code[20]; IsParent: Boolean; var EFTValues: Codeunit "EFT Values")
    var
        ACHRBDetail: Record "ACH RB Detail";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DateInteger: Integer;
    begin
        with TempEFTExportWorkset do begin
            if IsParent then
                EFTValues.SetTransactions(EFTValues.GetTransactions + 1);
            EFTValues.SetNoOfRec(EFTValues.GetNoOfRec + 1);
            EFTValues.SetTraceNo(EFTValues.GetNoOfRec);
            EFTValues.SetDataExchEntryNo(DataExchEntryNo);

            ACHRBDetail.Get(DataExchEntryNo, DataExchLineDefCode);
            ACHRBDetail."Record Count" := EFTValues.GetNoOfRec;
            ACHRBDetail."Transaction Code" := "Transaction Code";
            ACHRBDetail."Client Number" := BankAccount."Client No.";
            ACHRBDetail."Customer/Vendor Number" := AcctNo;
            ACHRBDetail."Vendor/Customer Name" := AcctName;
            ACHRBDetail."Payment Number" := PaymentsThisAcct;

            if RecipientBankAcctCountryCode = 'CA' then begin
                ACHRBDetail."Bank No." := RecipientBankNo;
                ACHRBDetail."Transit Routing No." := RecipientTransitNo;
            end else
                if RecipientBankAcctCountryCode = 'US' then
                    ACHRBDetail."Transit Routing No." := RecipientTransitNo;

            ACHRBDetail."Recipient Bank No." := RecipientBankAcctNo;
            ACHRBDetail."Payment Amount" := PaymentAmount;
            ACHRBDetail."Payment Date" := JulianDate(SettleDate);

            // if can find the column definition, get the value of the Data Format and assign it to DateFormat variable
            FindDataExchColumnDef(DataExchColumnDef, DataExchEntryNo, ACHRBDetail.FieldName("Payment Date"));
            if DataExchColumnDef."Data Format" <> '' then begin
                Evaluate(DateInteger, Format(SettleDate, DataExchColumnDef.Length, DataExchColumnDef."Data Format"));
                ACHRBDetail."Payment Date" := DateInteger;
            end;

            ACHRBDetail."Language Code" := Format(AcctLanguage);
            ACHRBDetail."Client Name" := BankAccount."Client Name";

            if RecipientBankAcctCurrencyCode = '' then
                ACHRBDetail."Currency Code" := CurrencyType
            else
                ACHRBDetail."Currency Code" := RecipientBankAcctCurrencyCode;

            if RecipientCountryCode = 'CA' then
                ACHRBDetail.Country := 'CAN'
            else
                if RecipientCountryCode = 'US' then
                    ACHRBDetail.Country := 'USA';

            if IsParent then
                EFTValues.SetNoOfCustInfoRec(EFTValues.GetNoOfCustInfoRec + 1);
            ACHRBDetail.AD1NoOfRec := EFTValues.GetNoOfRec;
            ACHRBDetail."AD1Client No" := BankAccount."Client No.";
            ACHRBDetail."AD1Company Name" := CompanyInformation.Name;
            ACHRBDetail.AD1Address := CopyStr(CompanyInformation.Address, 1, 35) + ' ' +
              CopyStr(CompanyInformation."Address 2", 1, 35);
            ACHRBDetail."AD1City State" := CompanyInformation.City + '*' + CompanyInformation.County + '\';
            ACHRBDetail."AD1Region Code/Post Code" := CompanyInformation."Country/Region Code" + '*' +
              CompanyInformation."Post Code" + '\';

            if IsParent then
                EFTValues.SetNoOfCustInfoRec(EFTValues.GetNoOfCustInfoRec + 1);
            ACHRBDetail.AD2NoOfRec := EFTValues.GetNoOfRec;
            ACHRBDetail."AD2Client No" := BankAccount."Client No.";
            ACHRBDetail."AD2Recipient Address" := RecipientAddress;
            ACHRBDetail."AD2Recipient City/County" := RecipientCity + '*' + RecipientCounty + '\';
            ACHRBDetail."AD2Region Code/Post Code" := RecipientCountryCode + '*' + RecipientPostCode + '\';
            ACHRBDetail."AD2Transaction Type Code" := Format("Transaction Type Code");
            ACHRBDetail."AD2Company Entry Description" := "Company Entry Description";

            if ("Payment Related Information 1" <> '') or ("Payment Related Information 2" <> '') then begin
                ACHRBDetail."Client Number" := BankAccount."Client No.";
                ACHRBDetail.RRNoOfRec := EFTValues.GetNoOfRec;
                ACHRBDetail."RRClient No" := BankAccount."Client No.";
                ACHRBDetail."RRPayment Related Info1" := "Payment Related Information 1";
                ACHRBDetail."RRPayment Related Info2" := "Payment Related Information 2";
                OnBeforeACHRBDetailModify(ACHRBDetail, TempEFTExportWorkset, BankAccount."No.", SettleDate);
                ACHRBDetail.Modify;
                EFTValues.SetNoOfCustInfoRec(EFTValues.GetNoOfCustInfoRec + 1);
            end else begin
                OnBeforeACHRBDetailModify(ACHRBDetail, TempEFTExportWorkset, BankAccount."No.", SettleDate);
                ACHRBDetail.Modify;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDateFormatString(DataExchEntryNo: Integer; FieldName: Text[250]): Text[100]
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        FindDataExchColumnDef(DataExchColumnDef, DataExchEntryNo, FieldName);
        exit(DataExchColumnDef."Data Format");
    end;

    [Scope('OnPrem')]
    procedure FindDataExchColumnDef(var DataExchColumnDef: Record "Data Exch. Column Def"; DataExchEntryNo: Integer; FieldName: Text[250])
    var
        DataExch: Record "Data Exch.";
    begin
        Clear(DataExchColumnDef);

        if not DataExch.Get(DataExchEntryNo) then
            exit;

        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExch."Data Exch. Line Def Code");
        DataExchColumnDef.SetRange(Name, FieldName);
        if DataExchColumnDef.FindFirst then;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeACHRBHeaderModify(var ACHRBHeader: Record "ACH RB Header"; BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeACHRBDetailModify(var ACHRBDetail: Record "ACH RB Detail"; var TempEFTExportWorkset: Record "EFT Export Workset" temporary; BankAccNo: Code[20]; SettleDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeACHRBFooterModify(var ACHRBFooter: Record "ACH RB Footer"; BankAccNo: Code[20])
    begin
    end;
}

