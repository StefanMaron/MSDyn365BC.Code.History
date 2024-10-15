codeunit 10090 "Export Payments (ACH)"
{

    trigger OnRun()
    begin
    end;

    var
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
        RBMgt: Codeunit "File Management";
        ExportFile: File;
        TotalFileDebit: Decimal;
        TotalFileCredit: Decimal;
        TotalBatchDebit: Decimal;
        TotalBatchCredit: Decimal;
        RecordLength: Integer;
        BlockingFactor: Integer;
        BlockCount: Integer;
        EntryAddendaCount: Integer;
        FileEntryAddendaCount: Integer;
        NoOfRec: Integer;
        Justification: Option Left,Right;
        BatchNo: Integer;
        BatchCount: Integer;
        FileHashTotal: Decimal;
        BatchHashTotal: Decimal;
        FileName: Text;
        FileIsInProcess: Boolean;
        BatchIsInProcess: Boolean;
        FileDate: Date;
        FileTime: Time;
        ModifierValues: array[26] of Code[1];
        TraceNo: Integer;
        ExportInProcessErr: Label 'Cannot start new Export File while %1 is in process.', Comment = '%1 = the filename that is already being processed.';
        ExportFilePathErr: Label '%1 in %2 %3 is invalid.', Comment = '%1 = the export file path, %2 the field in the table, ie, bank, customer etc, %3 = the identifier for the record, ie, bankaccount number etc. ';
        FileAlreadyExistsErr: Label 'File %1 already exists. Check the %2 in %3 %4.', Comment = '%1 = file name, %2 file patch, the bank account table, the identifier in the bank account table, ie the .No';
        ExportFileNotStartedErr: Label 'Cannot start export batch until an export file is started.';
        ExportFileNotCompletedErr: Label 'Cannot start new export batch until previous batch is completed.';
        ExportDetailsFileNotStartedErr: Label 'Cannot export details until an export file is started.';
        ExportDetailsFileNotCompletedErr: Label 'Cannot export details until an export batch is started.';
        CustBankAccErr: Label 'Customer No. %1 has no bank account setup for electronic payments.', Comment = '%1 the Customer No.';
        CustMoreThanOneBankAccErr: Label 'Customer No. %1 has more than one bank account setup for electronic payments.', Comment = '%1 the customer No.';
        ExportBatchFileNotStartedErr: Label 'Cannot end export batch until an export file is started.';
        ExportBatchNotStartedErr: Label 'Cannot end export batch until an export batch is started.';
        ExportFileNotEndedFileNotStartedErr: Label 'Cannot end export file until an export file is started.';
        ExportFileNotEndedFileNotEndedErr: Label 'Cannot end export file until export batch is ended.';
        FileDoesNoteExistErr: Label 'File %1 does not exist.', Comment = '%1 = the file name.';
        DidTransmissionWorkQst: Label 'Did the transmission work properly?';
        InvalidPaymentSpecErr: Label 'Either %1 or %2 must refer to either a %3 or a %4 for an electronic payment.', Comment = '%1 = Account Type, %2 = the account,%3 = Vendor table, %4 = Customer table';
        CustomerBlockedErr: Label '%1 is blocked for %2 processing.', Comment = '%1 = account type, %2 = customer.blocked';
        PrivacyBlockedErr: Label '%1 is blocked for privacy.', Comment = '%1 = account type';
        ConfirmTransmissioinQst: Label 'You must now run the program that transmits the payments file to the bank. Transmit the file named %1 located at %2 to %3 (%4 %5 %6).  After the transmission is completed, you will be asked if it worked correctly.  Are you ready to transmit (answer No to cancel the transmission process)?', Comment = '%1 = full  filename, %2 = file path, %3 = file name, %4 = bank account table, %5 = bank account no.caption, %6 = bank account no. ';
        VendorBankAccErr: Label 'Vendor%1  has no bank account setup for electronic payments.', Comment = 'The Vendor No';
        VendorMoreThanOneBankAccErr: Label 'Vendor%1  has more than one bank account setup for electronic payments.', Comment = '%1 = The Vendor No.';
        VendorTransitNumNotValidErr: Label 'The specified transit number %1 for vendor %2  is not valid.', Comment = '%1 the transit number, %2 The Vendor No.';
        CustTransitNumNotValidErr: Label 'The specified transit number %1 for customer %2  is not valid.', Comment = '%1 the transit number, %2 The customer  No.';
        BankTransitNumNotValidErr: Label 'The specified transit number %1 for bank %2  is not valid.', Comment = '%1 the transit number, %2 The bank  No.';

    procedure StartExportFile(BankAccountNo: Code[20]; ReferenceCode: Code[10])
    var
        FileHeaderRec: Text[250];
        i: Integer;
    begin
        BuildIDModifier;
        if FileIsInProcess then
            Error(ExportInProcessErr, FileName);

        CompanyInformation.Get();
        CompanyInformation.TestField("Federal ID No.");

        with BankAccount do begin
            LockTable();
            Get(BankAccountNo);
            TestField("Export Format", "Export Format"::US);
            TestField("Transit No.");
            if not CheckDigit("Transit No.") then
                FieldError("Transit No.", StrSubstNo(BankTransitNumNotValidErr, "Transit No.", "No."));
            TestField("E-Pay Export File Path");
            if "E-Pay Export File Path"[StrLen("E-Pay Export File Path")] <> '\' then
                Error(ExportFilePathErr,
                  FieldCaption("E-Pay Export File Path"),
                  TableCaption,
                  "No.");
            TestField("Last E-Pay Export File Name");
            TestField("Bank Acc. Posting Group");
            TestField(Blocked, false);
            "Last E-Pay Export File Name" := IncStr("Last E-Pay Export File Name");
            FileName := RBMgt.ServerTempFileName('');
            if "Last ACH File ID Modifier" = '' then
                "Last ACH File ID Modifier" := '1'
            else begin
                i := 1;
                while (i < ArrayLen(ModifierValues)) and
                      ("Last ACH File ID Modifier" <> ModifierValues[i])
                do
                    i := i + 1;
                if i = ArrayLen(ModifierValues) then
                    i := 1
                else
                    i := i + 1;
                "Last ACH File ID Modifier" := ModifierValues[i];
            end;
            Modify;

            if Exists(FileName) then
                Error(FileAlreadyExistsErr,
                  FileName,
                  FieldCaption("Last E-Pay Export File Name"),
                  TableCaption,
                  "No.");
            ExportFile.TextMode(true);
            ExportFile.WriteMode(true);
            ExportFile.Create(FileName);

            FileIsInProcess := true;
            FileDate := Today;
            FileTime := Time;
            NoOfRec := 0;
            FileHashTotal := 0;
            TotalFileDebit := 0;
            TotalFileCredit := 0;
            FileEntryAddendaCount := 0;
            BatchCount := 0;
            BlockingFactor := 10;
            RecordLength := 94;
            BatchNo := 0;

            FileHeaderRec := '';
            AddNumToPrnString(FileHeaderRec, 1, 1, 1);                                    // Record Type Code
            AddNumToPrnString(FileHeaderRec, 1, 2, 2);                                    // Priority Code
            AddToPrnString(FileHeaderRec, "Transit No.", 4, 10, Justification::Right, ' '); // Immediate Destination
            AddFedIDToPrnString(FileHeaderRec, CompanyInformation."Federal ID No.", 14, 10);                              // Immediate Origin
            AddToPrnString(FileHeaderRec, Format(FileDate, 0, '<Year,2><Month,2><Day,2>'), 24, 6, Justification::Right, '0');
            // File Creation Date
            AddToPrnString(FileHeaderRec, Format(FileTime, 0, '<Hours24,2><Minutes,2>'), 30, 4, Justification::Right, '0');
            // File Creation Time
            AddToPrnString(FileHeaderRec, "Last ACH File ID Modifier", 34, 1, Justification::Right, '0');                   // File ID Modifier
            AddNumToPrnString(FileHeaderRec, RecordLength, 35, 3);                        // Record Size
            AddNumToPrnString(FileHeaderRec, BlockingFactor, 38, 2);                      // Blocking Factor
            AddNumToPrnString(FileHeaderRec, 1, 40, 1);                                   // Format Code
            AddToPrnString(FileHeaderRec, Name, 41, 23, Justification::Left, ' ');          // Immediate Destimation Name
            AddToPrnString(FileHeaderRec, CompanyInformation.Name, 64, 23, Justification::Left, ' ');
            // Immediate Origin Name
            AddToPrnString(FileHeaderRec, ReferenceCode, 87, 8, Justification::Left, ' ');  // Reference Code
            ExportPrnString(FileHeaderRec);
        end;
    end;

    procedure StartExportBatch(ServiceClassCode: Code[10]; EntryClassCode: Code[10]; SourceCode: Code[10]; SettleDate: Date)
    var
        BatchHeaderRec: Text[250];
    begin
        if not FileIsInProcess then
            Error(ExportFileNotStartedErr);
        if BatchIsInProcess then
            Error(ExportFileNotCompletedErr);

        BatchIsInProcess := true;
        BatchNo := BatchNo + 1;
        BatchHashTotal := 0;
        TotalBatchDebit := 0;
        TotalBatchCredit := 0;
        EntryAddendaCount := 0;
        TraceNo := 0;
        BatchHeaderRec := '';

        AddNumToPrnString(BatchHeaderRec, 5, 1, 1);                                               // Record Type
        AddToPrnString(BatchHeaderRec, ServiceClassCode, 2, 3, Justification::Right, '0');          // Service Class Code
        AddToPrnString(BatchHeaderRec, CompanyInformation.Name, 5, 36, Justification::Left, ' ');   // Company Name (+ Discretionary Data)
        AddFedIDToPrnString(BatchHeaderRec, CompanyInformation."Federal ID No.", 41, 10);         // Company ID
        AddToPrnString(BatchHeaderRec, EntryClassCode, 51, 3, Justification::Left, ' ');            // Entry Class Code
        AddToPrnString(BatchHeaderRec, SourceCode, 54, 10, Justification::Left, ' ');               // Entry Description
        AddToPrnString(BatchHeaderRec, Format(WorkDate, 0, '<Year><Month,2><Day,2>'), 64, 6, Justification::Left, ' ');   // Descriptive Date
        AddToPrnString(BatchHeaderRec, Format(SettleDate, 0, '<Year><Month,2><Day,2>'), 70, 6, Justification::Left, ' ');
        // Effective Entry Date
        AddNumToPrnString(BatchHeaderRec, 1, 79, 1);                                              // Originator Status Code
        AddToPrnString(BatchHeaderRec, BankAccount."Transit No.", 80, 8, Justification::Left, ' '); // Originating DFI ID
        AddNumToPrnString(BatchHeaderRec, BatchNo, 88, 7);                                        // Batch Number
        ExportPrnString(BatchHeaderRec);
    end;

    procedure ExportOffSettingDebit(): Code[30]
    var
        DetailRec: Text[250];
    begin
        if not FileIsInProcess then
            Error(ExportDetailsFileNotStartedErr);
        if not BatchIsInProcess then
            Error(ExportDetailsFileNotCompletedErr);

        TraceNo := TraceNo + 1;
        DetailRec := '';

        AddNumToPrnString(DetailRec, 6, 1, 1);          // Record Type Code
        AddNumToPrnString(DetailRec, 27, 2, 2);     // Demand Debit: Balancing record

        AddToPrnString(DetailRec, BankAccount."Transit No.", 4, 9, Justification::Right, ' ');           // Receiving DFI ID
        AddToPrnString(DetailRec, DelChr(BankAccount."Bank Account No.", '=', ' '), 13, 17, Justification::Left, ' '); // DFI Account Number
        AddAmtToPrnString(DetailRec, TotalBatchCredit, 30, 10); // Total Credit Entry
        AddToPrnString(DetailRec, CompanyInformation."Federal ID No.", 40, 15, Justification::Left, ' ');  // Company ID Number
        AddToPrnString(DetailRec, CompanyInformation.Name, 55, 22, Justification::Left, ' ');     // Company Name
        AddNumToPrnString(DetailRec, 0, 79, 1);         // Addenda Record Indicator
        AddToPrnString(DetailRec, GenerateTraceNoCode(TraceNo), 80, 15, Justification::Left, ' ');       // Trace Number

        ExportPrnString(DetailRec);

        EntryAddendaCount := EntryAddendaCount + 1;

        IncrementHashTotal(BatchHashTotal, MakeHash(CopyStr(BankAccount."Transit No.", 1, 8)));
        TotalBatchDebit := TotalBatchCredit;

        exit(GenerateFullTraceNoCode(TraceNo));
    end;

    procedure ExportElectronicPayment(GenJnlLine: Record "Gen. Journal Line"; PaymentAmount: Decimal): Code[30]
    var
        Vendor: Record Vendor;
        VendorBankAcct: Record "Vendor Bank Account";
        Customer: Record Customer;
        CustBankAcct: Record "Customer Bank Account";
        AcctType: Text[1];
        AcctNo: Code[20];
        AcctName: Text[16];
        BankAcctNo: Text[30];
        TransitNo: Text[20];
        DetailRec: Text[250];
        DemandCredit: Boolean;
    begin
        if not FileIsInProcess then
            Error(ExportDetailsFileNotStartedErr);
        if not BatchIsInProcess then
            Error(ExportDetailsFileNotCompletedErr);

        // NOTE:  If PaymentAmount is Positive, then we are Receiving money.
        // If PaymentAmount is Negative, then we are Sending money.
        if PaymentAmount = 0 then
            exit('');
        DemandCredit := (PaymentAmount < 0);
        PaymentAmount := Abs(PaymentAmount);

        with GenJnlLine do begin
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
                            Error(InvalidPaymentSpecErr,
                              FieldCaption("Account Type"), FieldCaption("Bal. Account Type"), Vendor.TableCaption, Customer.TableCaption);

            if AcctType = 'V' then begin
                CheckVendorTransitNum(AcctNo, Vendor, VendorBankAcct, true);
                AcctName := CopyStr(Vendor.Name, 1, MaxStrLen(AcctName));

                VendorBankAcct.TestField("Bank Account No.");
                TransitNo := VendorBankAcct."Transit No.";
                BankAcctNo := VendorBankAcct."Bank Account No.";
            end else
                if AcctType = 'C' then begin
                    Customer.Get(AcctNo);
                    if Customer."Privacy Blocked" then
                        Error(PrivacyBlockedErr, "Account Type");

                    if Customer.Blocked = Customer.Blocked::All then
                        Error(CustomerBlockedErr, "Account Type", Customer.Blocked);

                    AcctName := CopyStr(Customer.Name, 1, MaxStrLen(AcctName));

                    CustBankAcct.SetRange("Customer No.", AcctNo);
                    CustBankAcct.SetRange("Use for Electronic Payments", true);
                    CustBankAcct.FindFirst;

                    if CustBankAcct.Count < 1 then
                        Error(CustBankAccErr, AcctNo);
                    if CustBankAcct.Count > 1 then
                        Error(CustMoreThanOneBankAccErr, AcctNo);

                    if not CheckDigit(CustBankAcct."Transit No.") then
                        CustBankAcct.FieldError("Transit No.", StrSubstNo(CustTransitNumNotValidErr, CustBankAcct."Transit No.", Customer."No."));
                    CustBankAcct.TestField("Bank Account No.");
                    TransitNo := CustBankAcct."Transit No.";
                    BankAcctNo := CustBankAcct."Bank Account No.";
                end;

            TraceNo := TraceNo + 1;
            DetailRec := '';

            AddNumToPrnString(DetailRec, 6, 1, 1);            // Record Type Code
            if DemandCredit then
                AddNumToPrnString(DetailRec, 22, 2, 2) // Transaction Code -> Demand Credit: Automated Deposit
            else
                AddNumToPrnString(DetailRec, 27, 2, 2);         // Transaction Code -> Demand Debit: Automated Payment
            AddToPrnString(DetailRec, TransitNo, 4, 9, Justification::Right, ' ');                      // Receiving DFI ID
            AddToPrnString(DetailRec, DelChr(BankAcctNo, '=', ' '), 13, 17, Justification::Left, ' ');    // DFI Account Number
            AddAmtToPrnString(DetailRec, PaymentAmount, 30, 10);                                      // Amount
            AddToPrnString(DetailRec, AcctNo, 40, 15, Justification::Left, ' ');                        // Cust/Vendor ID Number
            AddNumToPrnString(DetailRec, 0, 55, 4);                                                   // Addenda Record Indicator
            AddToPrnString(DetailRec, AcctName, 59, 16, Justification::Left, ' ');                      // Cust/Vendor Name
            AddToPrnString(DetailRec, '  ', 75, 2, Justification::Left, ' ');                           // Reserved
            AddToPrnString(DetailRec, AcctType, 77, 2, Justification::Left, ' ');                       // Account Type (C or V)
            AddNumToPrnString(DetailRec, 0, 79, 1);                                                   // Addenda Record Indicator
            AddToPrnString(DetailRec, GenerateTraceNoCode(TraceNo), 80, 15, Justification::Left, ' ');  // Trace Number

            ExportPrnString(DetailRec);
            EntryAddendaCount := EntryAddendaCount + 1;
            if DemandCredit then
                TotalBatchCredit := TotalBatchCredit + PaymentAmount
            else
                TotalBatchDebit := TotalBatchDebit + PaymentAmount;
            IncrementHashTotal(BatchHashTotal, MakeHash(CopyStr(TransitNo, 1, 8)));
        end;

        exit(GenerateFullTraceNoCode(TraceNo));
    end;

    procedure EndExportBatch(ServiceClassCode: Code[10])
    var
        BatchControlRec: Text[250];
    begin
        if not FileIsInProcess then
            Error(ExportBatchFileNotStartedErr);
        if not BatchIsInProcess then
            Error(ExportBatchNotStartedErr);

        BatchIsInProcess := false;
        BatchControlRec := '';

        AddNumToPrnString(BatchControlRec, 8, 1, 1);                  // Record Type
        AddToPrnString(BatchControlRec, ServiceClassCode, 2, 3, Justification::Right, '0');                     // Service Class Code
        AddNumToPrnString(BatchControlRec, EntryAddendaCount, 5, 6);  // Entry/Addenda Count
        AddToPrnString(BatchControlRec, Format(BatchHashTotal, 0, 2), 11, 10, Justification::Right, '0');         // Entry Hash
        AddAmtToPrnString(BatchControlRec, TotalBatchDebit, 21, 12);  // Total Debit Entry Dollar Amount
        AddAmtToPrnString(BatchControlRec, TotalBatchCredit, 33, 12); // Total Credit Entry Dollar Amount
        AddFedIDToPrnString(BatchControlRec, CompanyInformation."Federal ID No.", 45, 10);                    // Company ID
        AddToPrnString(BatchControlRec, BankAccount."Transit No.", 80, 8, Justification::Left, ' ');            // Originating DFI ID
        AddNumToPrnString(BatchControlRec, BatchNo, 88, 7);           // Batch Number
        ExportPrnString(BatchControlRec);

        BatchCount := BatchCount + 1;
        IncrementHashTotal(FileHashTotal, BatchHashTotal);
        TotalFileDebit := TotalFileDebit + TotalBatchDebit;
        TotalFileCredit := TotalFileCredit + TotalBatchCredit;
        FileEntryAddendaCount := FileEntryAddendaCount + EntryAddendaCount;
    end;

    procedure EndExportFile(): Boolean
    var
        FileControlRec: Text[250];
        ClientFile: Text;
    begin
        if not FileIsInProcess then
            Error(ExportFileNotEndedFileNotStartedErr);
        if BatchIsInProcess then
            Error(ExportFileNotEndedFileNotEndedErr);

        FileIsInProcess := false;
        FileControlRec := '';
        BlockCount := (NoOfRec + 1) div BlockingFactor;
        if (NoOfRec + 1) mod BlockingFactor <> 0 then
            BlockCount := BlockCount + 1;

        AddNumToPrnString(FileControlRec, 9, 1, 1);                  // Record Type
        AddNumToPrnString(FileControlRec, BatchCount, 2, 6);         // Batch Count
        AddNumToPrnString(FileControlRec, BlockCount, 8, 6);         // Block Count
        AddNumToPrnString(FileControlRec, FileEntryAddendaCount, 14, 8);                        // Entry/Addenda Count
        AddToPrnString(FileControlRec, Format(FileHashTotal, 0, 2), 22, 10, Justification::Right, '0'); // Entry Hash
        AddAmtToPrnString(FileControlRec, TotalFileDebit, 32, 12);  // Total Debit Entry Dollar Amount
        AddAmtToPrnString(FileControlRec, TotalFileCredit, 44, 12); // Total Credit Entry Dollar Amount
        ExportPrnString(FileControlRec);

        while NoOfRec mod BlockingFactor <> 0 do begin
            FileControlRec := PadStr('', RecordLength, '9');
            ExportPrnString(FileControlRec);
        end;
        ExportFile.Close;

        ClientFile := BankAccount."E-Pay Export File Path" + BankAccount."Last E-Pay Export File Name";
        RBMgt.DownloadToFile(FileName, ClientFile);
        Erase(FileName);
        exit(true);
    end;

    local procedure GenerateFullTraceNoCode(TraceNo: Integer): Code[30]
    var
        TraceCode: Text[250];
    begin
        TraceCode := '';
        AddToPrnString(TraceCode, Format(FileDate, 0, '<Year,2><Month,2><Day,2>'), 1, 6, Justification::Left, ' ');
        AddToPrnString(TraceCode, BankAccount."Last ACH File ID Modifier", 7, 1, Justification::Right, '0');
        AddNumToPrnString(TraceCode, BatchNo, 8, 7);
        AddToPrnString(TraceCode, GenerateTraceNoCode(TraceNo), 15, 15, Justification::Left, ' ');
        exit(TraceCode);
    end;

    local procedure GenerateTraceNoCode(TraceNo: Integer): Code[15]
    var
        TraceCode: Text[250];
    begin
        TraceCode := '';
        AddToPrnString(TraceCode, BankAccount."Transit No.", 1, 8, Justification::Left, ' ');
        AddNumToPrnString(TraceCode, TraceNo, 9, 7);
        exit(TraceCode);
    end;

    local procedure AddNumToPrnString(var PrnString: Text[250]; Number: Integer; StartPos: Integer; Length: Integer)
    var
        TmpString: Text[250];
    begin
        TmpString := DelChr(Format(Number), '=', '.,-');
        AddToPrnString(PrnString, TmpString, StartPos, Length, Justification::Right, '0');
    end;

    local procedure AddAmtToPrnString(var PrnString: Text[250]; Amount: Decimal; StartPos: Integer; Length: Integer)
    var
        TmpString: Text[250];
        I: Integer;
    begin
        TmpString := Format(Amount);
        I := StrPos(TmpString, '.');
        case true of
            I = 0:
                TmpString := TmpString + '.00';
            I = StrLen(TmpString) - 1:
                TmpString := TmpString + '0';
        end;
        TmpString := DelChr(TmpString, '=', '.,-');
        AddToPrnString(PrnString, TmpString, StartPos, Length, Justification::Right, '0');
    end;

    procedure AddFedIDToPrnString(var PrnString: Text[250]; FedID: Text[30]; StartPos: Integer; Length: Integer)
    begin
        AddToPrnString(PrnString, '1' + DelChr(FedID, '=', ' .,-'), StartPos, Length, Justification::Left, ' ');
    end;

    local procedure AddToPrnString(var PrnString: Text[251]; SubString: Text[250]; StartPos: Integer; Length: Integer; Justification: Option Left,Right; Filler: Text[1])
    var
        I: Integer;
        SubStrLen: Integer;
    begin
        SubString := UpperCase(DelChr(SubString, '<>', ' '));
        SubStrLen := StrLen(SubString);

        if SubStrLen > Length then begin
            SubString := CopyStr(SubString, 1, Length);
            SubStrLen := Length;
        end;

        if Justification = Justification::Right then
            for I := 1 to (Length - SubStrLen) do
                SubString := Filler + SubString
        else
            for I := SubStrLen + 1 to Length do
                SubString := SubString + Filler;

        if StrLen(PrnString) >= StartPos then
            if StartPos > 1 then
                PrnString := CopyStr(PrnString, 1, StartPos - 1) + SubString + CopyStr(PrnString, StartPos)
            else
                PrnString := SubString + PrnString
        else begin
            for I := StrLen(PrnString) + 1 to StartPos - 1 do
                PrnString := PrnString + ' ';
            PrnString := PrnString + SubString;
        end;
    end;

    local procedure ExportPrnString(var PrnString: Text[250])
    begin
        PrnString := PadStr(PrnString, RecordLength, ' ');
        ExportFile.Write(PrnString);
        NoOfRec := NoOfRec + 1;
        PrnString := '';
    end;

    procedure CheckDigit(DigitString: Code[20]): Boolean
    var
        Weight: Code[8];
        Digit: Integer;
        I: Integer;
        Digit1: Integer;
        Digit2: Integer;
        CheckChar: Code[1];
    begin
        Weight := '37137137';
        Digit := 0;

        if StrLen(DigitString) <= StrLen(Weight) then
            exit(false);

        for I := 1 to StrLen(Weight) do begin
            Evaluate(Digit1, CopyStr(DigitString, I, 1));
            Evaluate(Digit2, CopyStr(Weight, I, 1));
            Digit := Digit + Digit1 * Digit2;
        end;

        Digit := 10 - Digit mod 10;
        if Digit = 10 then
            CheckChar := '0'
        else
            CheckChar := Format(Digit);
        exit(DigitString[StrLen(Weight) + 1] = CheckChar[1]);
    end;

    local procedure IncrementHashTotal(var HashTotal: Decimal; HashIncrement: Decimal)
    var
        SubTotal: Decimal;
    begin
        SubTotal := HashTotal + HashIncrement;
        if SubTotal < 10000000000.0 then
            HashTotal := SubTotal
        else
            HashTotal := SubTotal - 10000000000.0;
    end;

    local procedure MakeHash(InputString: Text[30]): Decimal
    var
        HashAmt: Decimal;
    begin
        InputString := DelChr(InputString, '=', '.,- ');
        if Evaluate(HashAmt, InputString) then
            exit(HashAmt);

        exit(0);
    end;

    local procedure BuildIDModifier()
    begin
        ModifierValues[1] := 'A';
        ModifierValues[2] := 'B';
        ModifierValues[3] := 'C';
        ModifierValues[4] := 'D';
        ModifierValues[5] := 'E';
        ModifierValues[6] := 'F';
        ModifierValues[7] := 'G';
        ModifierValues[8] := 'H';
        ModifierValues[9] := 'I';
        ModifierValues[10] := 'J';
        ModifierValues[11] := 'K';
        ModifierValues[12] := 'L';
        ModifierValues[13] := 'M';
        ModifierValues[14] := 'N';
        ModifierValues[15] := 'O';
        ModifierValues[16] := 'P';
        ModifierValues[17] := 'Q';
        ModifierValues[18] := 'R';
        ModifierValues[19] := 'S';
        ModifierValues[20] := 'T';
        ModifierValues[21] := 'U';
        ModifierValues[22] := 'V';
        ModifierValues[23] := 'W';
        ModifierValues[24] := 'X';
        ModifierValues[25] := 'Y';
        ModifierValues[26] := 'Z';
    end;

    procedure TransmitExportedFile(BankAccountNo: Code[20]; FName: Text)
    var
        ExportFullPathName: Text;
        TransmitFullPathName: Text;
    begin
        with BankAccount do begin
            Get(BankAccountNo);
            TestField("E-Pay Export File Path");
            if "E-Pay Export File Path"[StrLen("E-Pay Export File Path")] <> '\' then
                Error(ExportFilePathErr,
                  FieldCaption("E-Pay Export File Path"),
                  TableCaption,
                  "No.");
            TestField("E-Pay Trans. Program Path");
            if "E-Pay Trans. Program Path"[StrLen("E-Pay Trans. Program Path")] <> '\' then
                Error(ExportFilePathErr,
                  FieldCaption("E-Pay Trans. Program Path"),
                  TableCaption,
                  "No.");
            ExportFullPathName := "E-Pay Export File Path" + FName;
            TransmitFullPathName := "E-Pay Trans. Program Path" + FName;

            if not RBMgt.ClientFileExists(ExportFullPathName) then
                Error(FileDoesNoteExistErr, FName);
            RBMgt.CopyClientFile(ExportFullPathName, TransmitFullPathName, true);

            if Confirm(ConfirmTransmissioinQst, true, FName, "E-Pay Trans. Program Path", Name, TableCaption, FieldCaption("No."), "No.") then
                if Confirm(DidTransmissionWorkQst) then
                    RBMgt.DeleteClientFile(ExportFullPathName);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckVendorTransitNum(AccountNo: Code[20]; var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account"; CheckTheCheckDigit: Boolean)
    var
        ExportPaymentsACH: Codeunit "Export Payments (ACH)";
    begin
        Vendor.Get(AccountNo);
        Vendor.TestField(Blocked, Vendor.Blocked::" ");
        Vendor.TestField("Privacy Blocked", false);

        VendorBankAccount.SetRange("Vendor No.", AccountNo);
        VendorBankAccount.SetRange("Use for Electronic Payments", true);
        VendorBankAccount.FindFirst;

        if VendorBankAccount.Count < 1 then
            Error(StrSubstNo(VendorBankAccErr, Vendor."No."));
        if VendorBankAccount.Count > 1 then
            Error(StrSubstNo(VendorMoreThanOneBankAccErr, Vendor."No."));

        if CheckTheCheckDigit and (VendorBankAccount."Country/Region Code" = 'US') then
            if not ExportPaymentsACH.CheckDigit(VendorBankAccount."Transit No.") then
                Error(StrSubstNo(VendorTransitNumNotValidErr, VendorBankAccount."Transit No.", Vendor."No."));
    end;
}

