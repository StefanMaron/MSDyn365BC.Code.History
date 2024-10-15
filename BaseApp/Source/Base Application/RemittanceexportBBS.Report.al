report 15000060 "Remittance - export (BBS)"
{
    Caption = 'Remittance - export (BBS)';
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = SORTING("Journal Template Name", "Journal Batch Name", "Line No.");
            MaxIteration = 1;

            trigger OnPreDataItem()
            var
                StoreJournalRec: Record "Gen. Journal Line";
                RemPmtOrderExport: Report "Rem. Payment Order  - Export";
                RemittJournalCheckLine: Codeunit "Remitt. journal - Check line";
                Done: Boolean;
                NextSelection: Boolean;
                LastLine: Boolean;
                VendBalance: Decimal;
                FirstPaymOrder: Boolean;
            begin
                RemAgreement.LockTable; // Ensure update of RemAgreement."Latest BBS PaymOrderno.".

                DateNow := Today; // Current date and time.
                TimeNow := Time;
                NextLineNo(true);
                VendBalance := 0; // Use to check that vendor balance is not negative.
                NextSelection := true;  // See explanation below...
                RemAgreement.Get(RemAgreementCode); // Check if the code is valid.

                // Select lines from current journals:
                JournalRec.Reset; // Make sure the primary key is active and all the filters are deleted.
                JournalRec.SetCurrentKey(
                  "Journal Template Name", "Journal Batch Name", "Remittance Agreement Code", "Remittance Type", "Remittance Account Code");
                JournalRec.SetRange("Journal Template Name", CurrentJournalLine."Journal Template Name");
                JournalRec.SetRange("Journal Batch Name", CurrentJournalLine."Journal Batch Name");
                JournalRec.SetRange("Remittance Agreement Code", RemAgreementCode); // Only one PaymOrder at the time is processed.

                if not JournalRec.Find('-') then
                    Error(Text000);
                CreatePaymOrderHead;

                RecordType10;
                // Go thorugh the lines:
                // 1. Start with the first one and set the filter to select all related lines.
                // 2. Go over each line.
                // 2. Each line is deleted after being processed.
                // 3. If there are more then 14 lines, then go over them several times.
                // 4. When the selected lines are processed, the filter is deleted and the first of the remaining
                //    journal lines is processed (back to 1.)
                // 5. Done when all the lines are processed.
                JournalRec.Find('-');  // Start with the first line, the new key applied.
                StoreJournalRec.Init;
                StoreJournalRec."Remittance Type" := -1; // "undefined"
                FirstPaymOrder := true;
                repeat
                    if NextSelection then begin  // Continue with next selection:
                                                 // Select journal lines for the payment transaction
                        JournalRec.SetRange("Remittance Type", JournalRec."Remittance Type");
                        JournalRec.SetRange("Remittance Account Code", JournalRec."Remittance Account Code");
                        JournalRec.SetRange("Posting Date", JournalRec."Posting Date");
                        JournalRec.SetRange("Account No.", JournalRec."Account No.");
                        JournalRec.SetRange(Urgent, JournalRec.Urgent);
                        JournalRec.SetRange("Futures Contract No.", JournalRec."Futures Contract No.");
                        JournalRec.SetRange("Futures Contract Exch. Rate", JournalRec."Futures Contract Exch. Rate");
                        JournalRec.SetRange("Currency Code", JournalRec."Currency Code");
                        JournalRec.SetRange("Currency Factor", JournalRec."Currency Factor");
                        JournalRec.SetRange("Agreed Exch. Rate", JournalRec."Agreed Exch. Rate");
                        JournalRec.SetRange("Agreed With", JournalRec."Agreed With");
                        if JournalRec.KID = '' then
                            JournalRec.SetFilter(KID, '=%1', '')
                        else
                            JournalRec.SetFilter(KID, '<>%1', '');
                        JournalRec.Find('-');

                        // The sum of the payments in a transaction must be known before payments are processed.
                        TransAmount := 0;
                        repeat
                            TransAmount := TransAmount + JournalRec."Amount (LCY)";
                        until JournalRec.Next = 0;
                        JournalRec.Find('-');

                        // Init data related to the current account/agreement.
                        // All the selected lines are attached to the same account
                        RemAccount.Get(JournalRec."Remittance Account Code");
                        // Check - should not happen:
                        if RemAccount."Remittance Agreement Code" <> RemAgreement.Code then
                            Error(Text001);
                        if RemAccount.Type = RemAccount.Type::Foreign then begin
                            JournalRec.TestField("Payment Type Code Abroad");
                            JournalRec.TestField("Specification (Norges Bank)");
                        end;
                        RemAccount.TestField("Bank Account No.");

                        // Check if the account is changed. If so, the new PaymOrder is created.
                        // Create Recordtype88 (closed PaymOrder) for previous paymenyt PaymOrder (if any), and the new
                        // Recordtype20 (new PaymOrder) for the new PaymOrder:
                        if StoreJournalRec."Remittance Account Code" <> JournalRec."Remittance Account Code" then begin
                            if not FirstPaymOrder then // Close previous one
                                RecordType88;

                            // Recordtype20 for the first/next PaymOrder
                            RecordType20;
                            FirstPaymOrder := false;
                        end;
                    end;

                    JournalRec.TestField("Account Type", JournalRec."Account Type"::Vendor);
                    JournalRec.TestField("Waiting Journal Reference", 0); // The journal line is a settlement and can not be exported!
                    Vendor.Get(JournalRec."Account No.");

                    RecordType30(JournalRec);
                    RecordType31;
                    if JournalRec.KID = '' then begin
                        // Payment with notice
                        RecordType40;
                        RecordType41;
                    end;

                    repeat
                        RemittJournalCheckLine.CheckUntilFirstError(JournalRec, RemAccount);
                        VendBalance := VendBalance + JournalRec.Amount;  // Counts vendor balance for future checks.
                                                                         // Moved to Waiting journal by PAYFOR23(), since own ref. is used.
                        MoveToWaitingJournal(JournalRec);  // Move journal lines to Waiting journal.

                        if JournalRec.KID = '' then
                            RecordType49(JournalRec) // Payment with notice
                        else
                            RecordType50(JournalRec); // Payment with KID

                        RemTools.MarkEntry(JournalRec, Text002, PaymOrder.ID);  // Mark the posts waiting for remitt. settlement.

                        // Delete the journal lines that were just processed.
                        JournalRec.Delete(true);

                        StoreJournalRec := JournalRec;
                        // Find the first of the remaining lines in the filter. -
                        LastLine := not JournalRec.Find('-');

                        // Stop if all the lines in a transaction are processed, or the number of messages is 21:
                    until LastLine or ((SpecificationCounter mod 21 = 0) and (JournalRec.KID = ''));
                    TransAmount := 0; // Following transaction will be a notice, without amount.

                    // Are all invoices processed?
                    // If so, the next invoice is selected.
                    // Otherwise, the vendor has more then 14 lines. Back to repeat-loop -
                    // - export all invoices.
                    if LastLine then begin
                        // New transaction. Check amount:
                        // Check the balance for closed vendors:
                        if VendBalance < 0 then begin
                            // Notification for vendor with and without currency:
                            if JournalRec."Currency Code" = '' then
                                Error(
                                  Text003,
                                  JournalRec."Posting Date", JournalRec."Account No.", VendBalance);

                            Error(
                              Text004,
                              JournalRec."Posting Date", JournalRec."Account No.",
                              VendBalance, JournalRec."Currency Code", JournalRec."Currency Factor");
                        end;
                        VendBalance := 0;  // Reset for next vendor.
                    end;
                    if LastLine then begin
                        // All selected invoices are processed. Continue with the following selection:
                        // Delete the limitations for vendor. Continue with the vendor following the
                        // one just processed.
                        JournalRec.SetRange("Remittance Type");
                        JournalRec.SetRange("Remittance Account Code");
                        JournalRec.SetRange("Posting Date");
                        JournalRec.SetRange("Account No.");
                        JournalRec.SetRange(Urgent);
                        JournalRec.SetRange("Futures Contract No.");
                        JournalRec.SetRange("Futures Contract Exch. Rate");
                        JournalRec.SetRange("Currency Code");
                        JournalRec.SetRange("Currency Factor");
                        JournalRec.SetRange("Agreed Exch. Rate");
                        JournalRec.SetRange("Agreed With");
                        JournalRec.SetRange(KID);
                        StoreJournalRec := JournalRec;
                        Done := not JournalRec.Find('-');  // Are there more jorunal lines?
                        NextSelection := true;  // All the selected ones are processed. Select next transaction.
                    end else begin  // Not all invoices are processed.
                        Done := false;  // Continue with the next one, among the selected ones.
                        NextSelection := false;  // Not all the selected ones are processed yet. The next transaction is NOT selected.
                    end;
                until Done;  // IF stop=True, all invoices are processed.

                RecordType88;
                RecordType89;

                if RemAgreement."Return File Is Not In Use" then
                    RemTools.SettlePaymOrdWithoutReturnFile(PaymOrder, JournalRec);

                // Export data:
                RemPmtOrderExport.SetPmtOrder(PaymOrder);
                RemPmtOrderExport.SetFilename(CurrentFilename);
                LineRec.Reset;
                LineRec.SetRange("Payment Order No.", PaymOrder.ID);
                RemPmtOrderExport.SetTableView(LineRec);
                RemPmtOrderExport.RunModal;
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
                    field(RemAgreementCode; RemAgreementCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Remittance agreement code';
                        TableRelation = "Remittance Agreement";
                        ToolTip = 'Specifies the remittance agreement code to use for the payment.';

                        trigger OnValidate()
                        begin
                            RemAgreement.Get(RemAgreementCode);
                            CurrentFilename := RemAgreement."Payment File Name"
                        end;
                    }
                    field(CurrentRemark; CurrentRemark)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment order note';
                        ToolTip = 'Specifies a note that is transferred to the remittance.';
                    }
                    field(CurrentFilename; CurrentFilename)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Filename';
                        ToolTip = 'Specifies the name and directory of the payment.';

                        trigger OnAssistEdit()
                        begin
                            CurrentFilename := FileMgt.SaveFileDialog(Text014, CurrentFilename, Text015);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            // Selected the contract specified in the first line of the journal
            RemAgreement.Get(CurrentJournalLine."Remittance Agreement Code");
            RemAgreementCode := RemAgreement.Code;
            CurrentFilename := RemAgreement."Payment File Name"
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GenLedgSetup.Get;
        GenLedgSetup.TestField("LCY Code");
    end;

    var
        Text000: Label 'There are no payments to export.\Export aborted.';
        Text001: Label 'Account and remittance agreement are different.';
        Text002: Label 'REM';
        Text003: Label 'Payment amount cannot be negative.\Balance for vendor %2 %3  is %1.', Comment = 'Parameter 1 - date, 2 - account number, 3 - decimal amount.';
        Text004: Label 'Payment amount cannot be negative.\Balance for vendor %2 %3 is %1, currency %4 exch. rate %5.', Comment = 'Parameter 1 - decimal amount, 2 - account number, 3 - date, 4 - currency code, 5 - decimal amount.';
        Text013: Label 'Line %1 is not 80 chars long.\%2';
        JournalRec: Record "Gen. Journal Line";
        RemAccount: Record "Remittance Account";
        RemAgreement: Record "Remittance Agreement";
        PaymOrder: Record "Remittance Payment Order";
        LineRec: Record "Payment Order Data";
        CurrentJournalLine: Record "Gen. Journal Line";
        WaitingJournal: Record "Waiting Journal";
        Vendor: Record Vendor;
        GenLedgSetup: Record "General Ledger Setup";
        RemTools: Codeunit "Remittance Tools";
        FileMgt: Codeunit "File Management";
        BBSOwnRefNo: Integer;
        SpecificationCounter: Integer;
        SpecificationLineNo: Integer;
        TransNo: Code[7];
        TransType: Text[2];
        TransFirstPayment: Date;
        TransAmount: Decimal;
        PaymOrderNoOfRec: Integer;
        PaymOrderNoOfTrans: Integer;
        PaymOrderAmount: Decimal;
        PaymOrderFirstPayment: Date;
        PaymOrderLastPayment: Date;
        ShipNoOfTrans: Integer;
        ShipNoOfRec: Integer;
        ShipAmount: Decimal;
        DateNow: Date;
        TimeNow: Time;
        StoreNextno: Integer;
        CurrentRemark: Text[50];
        CurrentFilename: Text[250];
        RemAgreementCode: Code[10];
        Text014: Label 'Remittance - export (BBS)';
        Text015: Label 'Text Files (*.txt)|*.txt|All Files (*.*)|*.*';

    [Scope('OnPrem')]
    procedure CreatePaymOrderHead()
    var
        NextID: Integer;
    begin
        // Create PaymOrder for import.
        // Select ID. Find next:
        PaymOrder.LockTable;
        if PaymOrder.FindLast then
            NextID := PaymOrder.ID + 1
        else
            NextID := 1;

        // Insert new PaymOrder. Remaining data are set later:
        PaymOrder.Init;
        PaymOrder.ID := NextID;
        PaymOrder.Date := DateNow;
        PaymOrder.Time := TimeNow;
        PaymOrder.Type := PaymOrder.Type::Export;
        PaymOrder.Comment := CurrentRemark;
        PaymOrder.Insert;
    end;

    [Scope('OnPrem')]
    procedure RecordType10()
    var
        CustomerUnitID: Text[8];
        ShipmentNo: Text[7];
    begin
        // Start record for shipment
        // Initialize new shipment:
        ShipNoOfTrans := 0;
        ShipNoOfRec := 1;
        ShipAmount := 0;
        TransNo := '0000001';

        CustomerUnitID := RemTools.FormatNumStr(RemAgreement."BBS Customer Unit ID", 8);
        ShipmentNo := RemTools.FormatNum(PaymOrder.ID, 7, false);

        InitLine(LineRec);
        LineRec.Data :=
          'NY000010' +
          CustomerUnitID +
          ShipmentNo +
          '00008080' +
          Fill0(49);
        InsertLine(LineRec);
    end;

    [Scope('OnPrem')]
    procedure RecordType20()
    var
        AgreementID: Text[9];
        PaymOrderNo: Text[7];
        PaymOrderAccount: Text[11];
    begin
        // Start record for PaymOrder
        ShipNoOfRec := ShipNoOfRec + 1;
        // Initialize new PaymOrder:
        PaymOrderNoOfTrans := 0;
        PaymOrderNoOfRec := 1;
        PaymOrderFirstPayment := 99991231D;
        PaymOrderLastPayment := 00000101D;
        PaymOrderAmount := 0;

        AgreementID := RemTools.FormatNumStr(RemAccount."BBS Agreement ID", 9);
        PaymOrderNo := RemTools.FormatNum(RemTools.NextBBSPaymOrderNo(RemAgreement), 7, false);
        PaymOrderAccount := RemTools.FormatAccountNo(RemAccount."Bank Account No.");

        InitLine(LineRec);
        LineRec.Data :=
          'NY040020' +
          AgreementID +
          PaymOrderNo +
          PaymOrderAccount +
          Fill0(45);
        InsertLine(LineRec);
    end;

    [Scope('OnPrem')]
    procedure RecordType30(JournalRec: Record "Gen. Journal Line")
    var
        DueDate: Text[6];
        CreditAccount: Text[30];
        SumAmount: Text[17];
    begin
        // Transaction record - payment entry 1
        ShipNoOfRec := ShipNoOfRec + 1;
        ShipNoOfTrans := ShipNoOfTrans + 1;
        PaymOrderNoOfRec := PaymOrderNoOfRec + 1;
        PaymOrderNoOfTrans := PaymOrderNoOfTrans + 1;
        TransFirstPayment := 99991231D;

        // Note: Trans type is used globaly in following records
        if JournalRec.KID = '' then
            TransType := '03' // Transfer with notice to beneficiary
        else
            TransType := '16'; // transfer with KID and bottom specification to beneficiary
        TransNo := IncStr(TransNo); // Used globaly in all underlying records.
        DueDate := FormatDate(JournalRec."Posting Date");

        // Update first/last payment date for recordtype 88:
        if JournalRec."Posting Date" < PaymOrderFirstPayment then
            PaymOrderFirstPayment := JournalRec."Posting Date";
        if JournalRec."Posting Date" > PaymOrderLastPayment then
            PaymOrderLastPayment := JournalRec."Posting Date";
        if JournalRec."Posting Date" < TransFirstPayment then
            TransFirstPayment := JournalRec."Posting Date";

        // Delete everything except 0..9, and set leading zeros for 7-digits post-giro numbers:
        CreditAccount := '00000000000' + RemTools.FormatAccountNo(Vendor."Recipient Bank Account No.");
        CreditAccount := CopyStr(CreditAccount, StrLen(CreditAccount) - 10);  // Last 11 chars.
        // TransAmount is calculated at the begining (when processing of the PaymOrder started):
        SumAmount := RemTools.FormatNum(TransAmount, 17, true);
        // Update info to Recordtype 88 and 89:
        PaymOrderAmount := PaymOrderAmount + TransAmount;
        ShipAmount := ShipAmount + TransAmount;

        InitLine(LineRec);
        LineRec.Data :=
          'NY04' + TransType + '30' +
          TransNo +
          DueDate +
          CreditAccount +
          SumAmount +
          Fill(25) + // KID: allways specified in bottom specification
          Fill0(6);
        InsertLine(LineRec);
    end;

    [Scope('OnPrem')]
    procedure RecordType31()
    var
        ShortName: Text[10];
        BBSOwnRef: Text[25];
    begin
        // Transaction record - Amount entry 2
        ShipNoOfRec := ShipNoOfRec + 1;
        PaymOrderNoOfRec := PaymOrderNoOfRec + 1;

        ShortName := PadStr(Vendor.Name, 10);
        // Own ref. is the first Waiting journal line in the transaction - the reference field:
        BBSOwnRefNo := NextWaitingJournalRef;
        BBSOwnRef := RemTools.FormatNum(BBSOwnRefNo, 25, false);

        InitLine(LineRec);
        LineRec.Data :=
          'NY04' + TransType + '31' +
          TransNo +
          ShortName +
          BBSOwnRef +
          Fill(25) +
          Fill0(5);
        InsertLine(LineRec);
    end;

    [Scope('OnPrem')]
    procedure RecordType40()
    var
        RecipientName: Text[30];
        RecipientPostNo: Text[4];
        RecipientPlace: Text[25];
    begin
        // Name/Adress record - Adress entry 1
        ShipNoOfRec := ShipNoOfRec + 1;
        PaymOrderNoOfRec := PaymOrderNoOfRec + 1;
        SpecificationCounter := 0;
        SpecificationLineNo := 0;

        // Note: Transtype is in this case always '03'.
        RecipientName := PadStr(Vendor.Name, 30);
        RecipientPostNo := PadStr(Vendor."Post Code", 4);
        RecipientPlace := PadStr(Vendor.City, 25);

        InitLine(LineRec);
        LineRec.Data :=
          'NY04' + TransType + '40' +
          TransNo +
          RecipientName +
          RecipientPostNo +
          Fill(3) +
          RecipientPlace +
          Fill0(3);
        InsertLine(LineRec);
    end;

    [Scope('OnPrem')]
    procedure RecordType41()
    var
        RecipientAdr1: Text[30];
        RecipientAdr2: Text[30];
        RecipientCountryCode: Text[3];
    begin
        // Name /Adress record - Adress entry 2
        ShipNoOfRec := ShipNoOfRec + 1;
        PaymOrderNoOfRec := PaymOrderNoOfRec + 1;

        RecipientAdr1 := PadStr(Vendor.Address, 30);
        RecipientAdr2 := PadStr(Vendor."Address 2", 30);
        RecipientCountryCode := PadStr(RecipientCountryCode, 3);

        InitLine(LineRec);
        LineRec.Data :=
          'NY04' + TransType + '41' +
          TransNo +
          RecipientAdr1 +
          RecipientAdr2 +
          RecipientCountryCode +
          Fill0(2);
        InsertLine(LineRec);
    end;

    [Scope('OnPrem')]
    procedure RecordType49(JournalRec: Record "Gen. Journal Line")
    var
        LineNo: Integer;
        MessageLineNo: Text[3];
        Message: Text[80];
        Message1: Text[40];
        Message2: Text[40];
        Message2Check: Code[40];
    begin
        // Specification record.
        // Note: Transtype id in this case always '03'.
        // Save to specification record for every recipient ref. that is specified.
        for LineNo := 1 to 3 do begin
            case LineNo of
                1:
                    Message := JournalRec."Recipient Ref. 1";
                2:
                    Message := JournalRec."Recipient Ref. 2";
                3:
                    Message := JournalRec."Recipient Ref. 3";
            end;
            if Message <> '' then begin
                SpecificationCounter := SpecificationCounter + 1;
                SpecificationLineNo := SpecificationLineNo + 1;

                Message := PadStr(Message, 80, ' ');
                Message1 := CopyStr(Message, 1, 40);
                Message2 := CopyStr(Message, 41, 40);
                MessageLineNo := RemTools.FormatNum(SpecificationLineNo, 3, false);

                // Column 1. Holds only text.
                ShipNoOfRec := ShipNoOfRec + 1;
                PaymOrderNoOfRec := PaymOrderNoOfRec + 1;
                InitLine(LineRec);
                LineRec.Data :=
                  'NY04' + TransType + '49' +
                  TransNo +
                  MessageLineNo +
                  '1' +
                  Message1 +
                  Fill(21);
                InsertLine(LineRec);

                // Column 2. Text only if the message is more then 40 chars. long.
                Message2Check := Message2; // Message2Check is code 40. it is empty if message2 is SP's only.
                if Message2Check <> '' then begin
                    ShipNoOfRec := ShipNoOfRec + 1;
                    PaymOrderNoOfRec := PaymOrderNoOfRec + 1;
                    InitLine(LineRec);
                    LineRec.Data :=
                      'NY04' + TransType + '49' +
                      TransNo +
                      MessageLineNo +
                      '2' +
                      Message2 +
                      Fill0(21);
                    InsertLine(LineRec);
                end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure RecordType50(JournalRec: Record "Gen. Journal Line")
    var
        UnderSpecTransType: Text[2];
        KID: Text[100];
        PaymentAmount: Text[17];
    begin
        // Bottom specification of combined shipments and credit memo
        ShipNoOfRec := ShipNoOfRec + 1;
        PaymOrderNoOfRec := PaymOrderNoOfRec + 1;

        if JournalRec.Amount < 0 then // Credit memo payment
            UnderSpecTransType := '17'
        else
            UnderSpecTransType := '16';
        // Format KID with leading zeros:
        KID := Fill(25) + JournalRec.KID;
        KID := CopyStr(KID, StrLen(KID) - 24, 25); // Last 25 chars.
        PaymentAmount := RemTools.FormatNum(JournalRec.Amount, 17, true);

        InitLine(LineRec);
        LineRec.Data :=
          'NY04' + UnderSpecTransType + '50' +
          TransNo +
          KID +
          PaymentAmount +
          Fill0(23);
        InsertLine(LineRec);
    end;

    [Scope('OnPrem')]
    procedure RecordType88()
    var
        NumberOfTrans: Text[8];
        NumberOfRec: Text[8];
        FirstPayment: Text[6];
        LastPayment: Text[6];
        SumAmount: Text[17];
    begin
        // End record for PaymOrder
        ShipNoOfRec := ShipNoOfRec + 1;
        PaymOrderNoOfRec := PaymOrderNoOfRec + 1;

        // Note: Field 7: Sum Amount is already calculated for Recordtype 30.
        NumberOfTrans := RemTools.FormatNum(PaymOrderNoOfTrans, 8, false);
        NumberOfRec := RemTools.FormatNum(PaymOrderNoOfRec, 8, false);
        FirstPayment := FormatDate(PaymOrderFirstPayment);
        LastPayment := FormatDate(PaymOrderLastPayment);
        SumAmount := RemTools.FormatNum(PaymOrderAmount, 17, true);

        InitLine(LineRec);
        LineRec.Data :=
          'NY040088' +
          NumberOfTrans +
          NumberOfRec +
          SumAmount +
          FirstPayment +
          LastPayment +
          Fill0(27);
        InsertLine(LineRec);
    end;

    [Scope('OnPrem')]
    procedure RecordType89()
    var
        SumAmount: Text[17];
        NumberOfTrans: Text[8];
        NumberOfRec: Text[8];
        FirstPayment: Text[6];
    begin
        // End record for shipment
        ShipNoOfRec := ShipNoOfRec + 1;

        SumAmount := RemTools.FormatNum(ShipAmount, 17, true);
        NumberOfTrans := RemTools.FormatNum(ShipNoOfTrans, 8, false);
        NumberOfRec := RemTools.FormatNum(ShipNoOfRec, 8, false);
        FirstPayment := FormatDate(TransFirstPayment);

        InitLine(LineRec);
        LineRec.Data :=
          'NY040089' +
          NumberOfTrans +
          NumberOfRec +
          SumAmount +
          FirstPayment +
          Fill0(33);
        InsertLine(LineRec);
    end;

    [Scope('OnPrem')]
    procedure MoveToWaitingJournal(JournalLine: Record "Gen. Journal Line")
    begin
        WaitingJournal.Init;
        WaitingJournal.TransferFields(JournalLine);
        WaitingJournal."Payment Order ID - Sent" := PaymOrder.ID;
        WaitingJournal."Remittance Status" := WaitingJournal."Remittance Status"::Sent;
        WaitingJournal.Reference := NextWaitingJournalRef;
        WaitingJournal."BBS Referance" := BBSOwnRefNo;
        WaitingJournal.Validate("Remittance Account Code", RemAccount.Code);
        WaitingJournal.Insert(true);
        WaitingJournal.CopyLineDimensions(JournalLine);
    end;

    [Scope('OnPrem')]
    procedure Fill(NumberOfChars: Integer): Text[250]
    begin
        // Return string with SpaceCount space.
        exit(PadStr('', NumberOfChars, ' '));
    end;

    [Scope('OnPrem')]
    procedure Fill0(NumberOfChars: Integer): Text[250]
    begin
        // Return string with SpaceCount zeros.
        exit(PadStr('', NumberOfChars, '0'));
    end;

    [Scope('OnPrem')]
    procedure NextLineNo(Init: Boolean): Integer
    begin
        // Select and return next line no.
        // PARAMETERS:
        // init=True. LineNo. (starts with 1), starting with the next call made with False as parameter.
        // init=False. Returns next line no.
        // RETURNS: Next lineno., =0 if init=True.

        if Init then
            StoreNextno := 0 // This no. is not in use.
        else
            StoreNextno := StoreNextno + 1;
        exit(StoreNextno);
    end;

    [Scope('OnPrem')]
    procedure Check(LineNo: Integer; Data: Text[100])
    begin
        // Additional check. This error should not occur in a customer-system
        if StrLen(Data) <> 80 then
            Message(Text013, LineNo, Data);
    end;

    [Scope('OnPrem')]
    procedure InitLine(var LineRec: Record "Payment Order Data")
    begin
        // prepare (data) line for use.
        LineRec.Init;
        LineRec."Payment Order No." := PaymOrder.ID;
        LineRec."Line No" := NextLineNo(false);
    end;

    [Scope('OnPrem')]
    procedure InsertLine(LineRec: Record "Payment Order Data")
    begin
        // Insert line into the file.
        Check(LineRec."Line No", LineRec.Data);  // My own check, just in case...!
        LineRec.Data := UpperCase(LineRec.Data);
        LineRec.Insert;
    end;

    [Scope('OnPrem')]
    procedure SetJournalLine(JournalLine: Record "Gen. Journal Line")
    begin
        // Transfer current lines from journal routine (for ex. journal window):
        CurrentJournalLine := JournalLine;
    end;

    local procedure NextWaitingJournalRef(): Integer
    var
        WaitingJournal: Record "Waiting Journal";
    begin
        WaitingJournal.LockTable;  // Serial no. depends on the existing Waiting journal.
        WaitingJournal.Init;
        if WaitingJournal.FindLast then
            exit(WaitingJournal.Reference + 1);

        exit(1);
    end;

    [Scope('OnPrem')]
    procedure FormatDate(Date: Date): Text[6]
    begin
        exit(Format(Date, 0, '<Day,2><Month,2><Year,2>'));
    end;
}

