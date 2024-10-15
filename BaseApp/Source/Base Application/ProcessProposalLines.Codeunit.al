codeunit 11000000 "Process Proposal Lines"
{
    TableNo = "Proposal Line";

    trigger OnRun()
    begin
        ClearAll;
        Prop := Rec;
        Prop.CopyFilters(Rec);
        Prop.SetCurrentKey("Our Bank No.", Process);
        Prop.SetRange(Process, true)
    end;

    var
        Text1000000: Label 'There is nothing to check.';
        Text1000001: Label '%1 %4 have been checked\';
        Text1000002: Label 'This contains:\\';
        Text1000003: Label '  %2 error(s) \';
        Text1000004: Label '  %3 warning(s)';
        Text1000005: Label 'Process proposal lines?';
        Text1000006: Label 'Output cancelled.';
        Text1000007: Label 'There is nothing to process.';
        Text1000008: Label 'The proposal lines were processed.';
        Text1000009: Label 'There are %3 lines processed and %2 lines not processed of %1 lines.';
        Text1000010: Label '%1 is not filled out correctly.';
        Text1000011: Label 'No %1 entered in %2.';
        Text1000012: Label '%1 is not stated correctly %2.';
        Text1000013: Label '%1 in number series must be switched on in number serie %2.';
        Text1000014: Label '%1 %2 must not be in the past.';
        Text1000015: Label '%1 must not be zero.';
        Text1000016: Label '%1 must be negative when %2=%3.';
        Text1000017: Label '%1 must be positive when %2=%3.';
        Text1000018: Label '%1 is not filled out.';
        Text1000019: Label '%1 is already in use, modify %1.';
        Text1000020: Label '%1 is already used more than once in the proposal.';
        Text1000021: Label 'Credit limit for bank %1 will be exceeded.';
        Text1000023: Label '%1 of %2 has not been entered correctly.';
        Text1000024: Label '%1 is not found in table %2.';
        Text1000025: Label '%1 %2 has open credit memo''s.';
        Text1000026: Label '%1 %2 has not been entered correctly.';
        Text1000027: Label '%1 is not entered.';
        Text1000028: Label '%1 is filled in, but %2 is 0.';
        Text1000029: Label '%1 must not be zero in detail line for %2 %3.';
        Text1000030: Label 'No Check ID entered in %1 %2.';
        Prop: Record "Proposal Line";
        PaymHist: Record "Payment History";
        NumberPosted: Integer;
        ErrorNumber: Integer;
        Errortext: Text[125];
        Warningstext: Text[125];
        WarningNumber: Integer;
        TelebankFinancialConnection: Codeunit "Financial Interface Telebank";
        GenJnlLine: Record "Gen. Journal Line" temporary;
        LocalFuncMgt: Codeunit "Local Functionality Mgt.";
        AccountNo: Text[30];
        Text1000035: Label '%1 must not be zero in %2.';

    [Scope('OnPrem')]
    procedure CheckProposallines()
    begin
        ErrorNumber := 0;
        NumberPosted := 0;
        WarningNumber := 0;

        if Prop.Find('-') then
            repeat
                NumberPosted := NumberPosted + 1;
                if not CheckAProposalLine(Prop) then
                    ErrorNumber := ErrorNumber + 1;
                if Warningstext <> '' then
                    WarningNumber := WarningNumber + 1;
                if (Errortext <> Prop."Error Message") or
                   (Warningstext <> Prop.Warning)
                then begin
                    Prop."Error Message" := Errortext;
                    Prop.Warning := Warningstext;
                    Prop.Modify;
                end;
            until Prop.Next = 0;

        if NumberPosted = 0 then
            Message(Text1000000)
        else
            Message(Text1000001 + Text1000002 + Text1000003 + Text1000004, NumberPosted, ErrorNumber, WarningNumber, Prop.TableCaption);
    end;

    [Scope('OnPrem')]
    procedure ProcessProposallines()
    begin
        if not Confirm(Text1000005, false) then
            Error(Text1000006);

        ErrorNumber := 0;
        NumberPosted := 0;
        GenJnlLine.DeleteAll;

        if Prop.Find('-') then begin
            repeat
                NumberPosted := NumberPosted + 1;
                if CheckAProposalLine(Prop) then begin
                    if not PaymentHistoryPresent(Prop, PaymHist) then
                        CreatePaymentHistory(Prop, PaymHist);
                    CreatePaymentHistoryLine(Prop, PaymHist);
                    DeleteProposallines(Prop);
                end else begin
                    if (Errortext <> Prop."Error Message") or
                       (Warningstext <> Prop.Warning)
                    then begin
                        Prop."Error Message" := Errortext;
                        Prop.Warning := Warningstext;
                        Prop.Modify;
                    end;
                    ErrorNumber := ErrorNumber + 1;
                end
            until Prop.Next = 0;
            TelebankFinancialConnection.PostFDBR(GenJnlLine);
            GenJnlLine.DeleteAll;
        end;

        if NumberPosted = 0 then
            Message(Text1000007)
        else
            case ErrorNumber of
                0:
                    Message(Text1000008);
                1:
                    Message(Text1000009, NumberPosted, ErrorNumber, NumberPosted -
                      ErrorNumber);
                else
                    Message(Text1000009, NumberPosted, ErrorNumber, NumberPosted -
                      ErrorNumber);
            end;
    end;

    [Scope('OnPrem')]
    procedure CheckAProposalLine(CheckRecord: Record "Proposal Line") res: Boolean
    var
        TranMode: Record "Transaction Mode";
        ExportProtocol: Record "Export Protocol";
        NoSeries: Record "No. Series";
        OurBnk: Record "Bank Account";
        "Detail line": Record "Detail Line";
        PaymentHistLine: Record "Payment History Line";
        Propline: Record "Proposal Line";
    begin
        Errortext := '';
        Warningstext := '';

        // //////////////////////////////////////////////////////////////////////
        // General information

        if not TranMode.Get(CheckRecord."Account Type", CheckRecord."Transaction Mode") then begin
            Errortext := StrSubstNo(Text1000010, CheckRecord.FieldCaption("Transaction Mode"));
            exit(false);
        end;

        if not ExportProtocol.Get(TranMode."Export Protocol") then begin
            Errortext := StrSubstNo(Text1000011, TranMode.FieldCaption("Export Protocol"), TranMode.TableCaption);
            exit(false);
        end;

        if not NoSeries.Get(TranMode."Run No. Series") then begin
            Errortext := StrSubstNo(Text1000012,
                TranMode.FieldCaption("Run No. Series"), TranMode.TableCaption);
            exit(false);
        end;

        if not NoSeries."Default Nos." then begin
            Errortext := StrSubstNo(Text1000013,
                NoSeries.FieldCaption("Default Nos."), NoSeries.Code);
            exit(false);
        end;

        if CheckRecord."Transaction Date" < Today then begin
            Errortext := StrSubstNo(Text1000014,
                CheckRecord.FieldCaption("Transaction Date"),
                CheckRecord."Transaction Date");
            exit(false);
        end;
        if CheckRecord.Amount = 0 then begin
            Errortext := StrSubstNo(Text1000015, CheckRecord.FieldCaption(Amount));
            exit(false);
        end;

        case CheckRecord.Order of
            CheckRecord.Order::Credit:
                if CheckRecord.Amount > 0 then begin
                    Errortext :=
                      StrSubstNo(Text1000016, CheckRecord.FieldCaption(Amount),
                        CheckRecord.FieldCaption("Transaction Mode"), CheckRecord."Transaction Mode");
                    exit(false);
                end;
            CheckRecord.Order::Debit:
                if CheckRecord.Amount < 0 then begin
                    Errortext :=
                      StrSubstNo(Text1000017, CheckRecord.FieldCaption(Amount),
                        CheckRecord.FieldCaption("Transaction Mode"), CheckRecord."Transaction Mode");
                    exit(false);
                end;
        end;

        // //////////////////////////////////////////////////////////////////////
        // identification

        if CheckRecord.Identification = '' then begin
            Errortext := StrSubstNo(Text1000018,
                CheckRecord.FieldCaption(Identification));
            exit(false);
        end;

        PaymentHistLine.SetCurrentKey("Our Bank", Identification, Status);
        PaymentHistLine.SetRange("Our Bank", CheckRecord."Our Bank No.");
        PaymentHistLine.SetRange(Identification, CheckRecord.Identification);
        PaymentHistLine.SetFilter(Status, '<>%1&<>%2&<>%3',
          PaymentHistLine.Status::Posted,
          PaymentHistLine.Status::Cancelled,
          PaymentHistLine.Status::Rejected);
        if PaymentHistLine.FindFirst then begin
            Errortext := StrSubstNo(Text1000019,
                CheckRecord.FieldCaption(Identification));
            exit(false);
        end;
        Propline.SetCurrentKey("Our Bank No.", Identification);
        Propline.SetRange("Our Bank No.", CheckRecord."Our Bank No.");
        Propline.SetRange(Identification, CheckRecord.Identification);
        Propline.SetFilter("Line No.", '<>%1', CheckRecord."Line No.");
        if Propline.FindFirst then begin
            Errortext := StrSubstNo(Text1000020,
                CheckRecord.FieldCaption(Identification));
            exit(false);
        end;

        // //////////////////////////////////////////////////////////////////////
        // Own account

        if not CheckOurBank(CheckRecord, OurBnk) then
            exit(false);

        // //////////////////////////////////////////////////////////////////////
        // Customer, Vendor and Employee

        if not CheckLedgerEntries(CheckRecord) then
            exit(false);

        if not LocalFuncMgt.CheckBankAccNo(CheckRecord."Bank Account No.", CheckRecord."Bank Country/Region Code", AccountNo) then begin
            Errortext := StrSubstNo(Text1000026, CheckRecord.FieldCaption("Bank Account No."), CheckRecord."Bank Account No.");
            exit(false);
        end;

        if not (CheckRecord."Account Type" = CheckRecord."Account Type"::Employee) then begin
            if CheckRecord."Account Holder Name" = '' then begin
                Errortext := StrSubstNo(Text1000027,
                    CheckRecord.FieldCaption("Account Holder Name"));
                exit(false);
            end;

            if CheckRecord."Account Holder City" = '' then begin
                Errortext := StrSubstNo(Text1000027,
                    CheckRecord.FieldCaption("Account Holder City"));
                exit(false);
            end;
        end;

        if (CheckRecord."Foreign Currency" <> '') and
           (CheckRecord."Foreign Amount" = 0)
        then
            if OurBnk."Currency Code" <> CheckRecord."Foreign Currency" then begin
                Errortext :=
                  StrSubstNo(
                    Text1000028, CheckRecord.FieldCaption("Foreign Currency"), CheckRecord.FieldCaption("Foreign Amount")
                    );
                exit(false);
            end;

        // /////////////////////////////////////////////////////////////////////
        // Per detail line

        "Detail line".SetCurrentKey("Our Bank", Status, "Connect Batches", "Connect Lines");
        "Detail line".SetRange("Our Bank", CheckRecord."Our Bank No.");
        "Detail line".SetRange(Status, "Detail line".Status::Proposal);
        "Detail line".SetRange("Connect Batches", '');
        "Detail line".SetRange("Connect Lines", CheckRecord."Line No.");
        if "Detail line".Find('-') then
            repeat
                if "Detail line".Amount = 0 then begin
                    Errortext :=
                      StrSubstNo(
                        Text1000029,
                        "Detail line".FieldCaption(Amount),
                        "Detail line".FieldCaption("Serial No. (Entry)"),
                        "Detail line"."Serial No. (Entry)");
                    exit(false);
                end;
                if "Detail line"."Serial No. (Entry)" = 0 then begin
                    Errortext :=
                      StrSubstNo(
                        Text1000035,
                        "Detail line".FieldCaption("Serial No. (Entry)"),
                        "Detail line".TableCaption);
                    exit(false);
                end;
            until "Detail line".Next = 0;

        // //////////////////////////////////////////////////////////////////////
        // Protocol specific

        if ExportProtocol."Check ID" <> 0 then begin
            CheckRecord."Error Message" := '';
            CheckRecord.Warning := '';
            CODEUNIT.Run(ExportProtocol."Check ID", CheckRecord);
            if CheckRecord.Warning <> '' then
                Warningstext := CheckRecord.Warning;
            if CheckRecord."Error Message" <> '' then begin
                Errortext := CheckRecord."Error Message";
                exit(false)
            end;
        end else begin
            Errortext := StrSubstNo(Text1000030, ExportProtocol.TableCaption, ExportProtocol.Code);
            exit(false);
        end;

        exit(true);
    end;

    local procedure CheckOurBank(var ProposalLine: Record "Proposal Line"; var BankAccount: Record "Bank Account"): Boolean
    begin
        if not BankAccount.Get(ProposalLine."Our Bank No.") then begin
            Errortext := StrSubstNo(Text1000010, ProposalLine.FieldCaption("Our Bank No."));
            exit(false);
        end;

        if BankAccount."Credit limit" < 0 then begin
            Errortext := StrSubstNo(Text1000021, ProposalLine."Our Bank No.");
            exit(false);
        end;

        if BankAccount."Account Holder Name" = '' then begin
            Errortext := StrSubstNo(Text1000023,
                BankAccount.FieldCaption("Account Holder Name"), ProposalLine."Our Bank No.");
            exit(false);
        end;

        if BankAccount."Account Holder Address" = '' then begin
            Errortext := StrSubstNo(Text1000023,
                BankAccount.FieldCaption("Account Holder Address"), ProposalLine."Our Bank No.");
            exit(false);
        end;

        if BankAccount."Account Holder Post Code" = '' then begin
            Errortext := StrSubstNo(Text1000023,
                BankAccount.FieldCaption("Account Holder Post Code"), ProposalLine."Our Bank No.");
            exit(false);
        end;

        if BankAccount."Account Holder City" = '' then begin
            Errortext := StrSubstNo(Text1000023,
                BankAccount.FieldCaption("Account Holder City"), ProposalLine."Our Bank No.");
            exit(false);
        end;

        exit(true);
    end;

    local procedure CheckLedgerEntries(var ProposalLine: Record "Proposal Line") Result: Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        Customer: Record Customer;
        Employee: Record Employee;
        Vendor: Record Vendor;
    begin
        case ProposalLine."Account Type" of
            ProposalLine."Account Type"::Customer:
                begin
                    if not Customer.Get(ProposalLine."Account No.") then begin
                        Errortext := StrSubstNo(Text1000024, ProposalLine.FieldCaption("Account No."), Customer.TableCaption);
                        exit(false);
                    end;
                    CustLedgerEntry.SetCurrentKey("Document Type", "Customer No.");
                    CustLedgerEntry.SetRange("Customer No.", ProposalLine."Account No.");
                    CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
                    CustLedgerEntry.SetRange(Open, true);
                    if CustLedgerEntry.FindFirst then
                        Warningstext := StrSubstNo(Text1000025, Customer.TableCaption, ProposalLine."Account No.");
                end;
            ProposalLine."Account Type"::Vendor:
                begin
                    if not Vendor.Get(ProposalLine."Account No.") then begin
                        Errortext := StrSubstNo(Text1000024, ProposalLine.FieldCaption("Account No."), Vendor.TableCaption);
                        exit(false);
                    end;
                    VendorLedgerEntry.SetCurrentKey("Document Type", "Vendor No.");
                    VendorLedgerEntry.SetRange("Vendor No.", ProposalLine."Account No.");
                    VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
                    VendorLedgerEntry.SetRange(Open, true);
                    if VendorLedgerEntry.FindFirst then
                        Warningstext := StrSubstNo(Text1000025, Vendor.TableCaption, ProposalLine."Account No.");
                end;
            ProposalLine."Account Type"::Employee:
                begin
                    if not Employee.Get(ProposalLine."Account No.") then begin
                        Errortext := StrSubstNo(Text1000024, ProposalLine.FieldCaption("Account No."), Employee.TableCaption);
                        exit(false);
                    end;
                    EmployeeLedgerEntry.SetCurrentKey("Document Type", "Employee No.");
                    EmployeeLedgerEntry.SetRange("Employee No.", ProposalLine."Account No.");
                    EmployeeLedgerEntry.SetRange("Document Type", EmployeeLedgerEntry."Document Type"::"Credit Memo");
                    EmployeeLedgerEntry.SetRange(Open, true);
                    if EmployeeLedgerEntry.FindFirst then
                        Warningstext := StrSubstNo(Text1000025, Employee.TableCaption, ProposalLine."Account No.");
                end;
        end;

        Result := true;
        OnAfterCheckLedgerEntries(ProposalLine, Warningstext, Errortext, Result);
    end;

    [Scope('OnPrem')]
    procedure PaymentHistoryPresent(var Prop: Record "Proposal Line"; var PaymHist: Record "Payment History") Present: Boolean
    var
        TranMode: Record "Transaction Mode";
    begin
        TranMode.Get(Prop."Account Type", Prop."Transaction Mode");

        PaymHist.SetCurrentKey("Our Bank", "Export Protocol", Status, "User ID");
        PaymHist.SetRange("Our Bank", Prop."Our Bank No.");
        PaymHist.SetRange("Export Protocol", TranMode."Export Protocol");
        PaymHist.SetRange(Status, PaymHist.Status::New);
        PaymHist.SetRange("User ID", UserId);

        exit(PaymHist.Find('-'));
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentHistory(var ProposalLine: Record "Proposal Line"; var PaymHist: Record "Payment History")
    var
        TranMode: Record "Transaction Mode";
        OurBnk: Record "Bank Account";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        DimManagement: Codeunit DimensionManagement;
    begin
        Clear(PaymHist);
        TranMode.Get(Prop."Account Type", Prop."Transaction Mode");
        TranMode.TestField("Run No. Series");

        PaymHist."Our Bank" := Prop."Our Bank No.";
        NoSeriesManagement.InitSeries(TranMode."Run No. Series", '', Today, PaymHist."Run No.", PaymHist."No. Series");
        PaymHist.Init;

        PaymHist.Status := PaymHist.Status::New;
        PaymHist."Creation Date" := Today;
        PaymHist."User ID" := UserId;

        TranMode.Get(Prop."Account Type", Prop."Transaction Mode");
        PaymHist."Export Protocol" := TranMode."Export Protocol";

        OurBnk.Get(Prop."Our Bank No.");

        PaymHist."Account No." := OurBnk."Bank Account No.";
        PaymHist."Account Holder Name" := OurBnk."Account Holder Name";
        PaymHist."Account Holder Address" := OurBnk."Account Holder Address";
        PaymHist."Account Holder Post Code" := OurBnk."Account Holder Post Code";
        PaymHist."Account Holder City" := OurBnk."Account Holder City";
        PaymHist."Acc. Hold. Country/Region Code" := OurBnk."Acc. Hold. Country/Region Code";

        PaymHist."Dimension Set ID" := ProposalLine."Header Dimension Set ID";

        DimManagement.UpdateGlobalDimFromDimSetID(PaymHist."Dimension Set ID",
          PaymHist."Global Dimension 1 Code", PaymHist."Global Dimension 2 Code");

        PaymHist.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentHistoryLine(var ProposalLine: Record "Proposal Line"; var PaymHist: Record "Payment History")
    var
        PaymentHistLine: Record "Payment History Line";
        "Detail line": Record "Detail Line";
    begin
        PaymHist."No. of Transactions" := PaymHist."No. of Transactions" + 1;
        if ProposalLine.Docket then
            PaymHist."Print Docket" := true;
        PaymHist.Modify(true);

        PaymentHistLine."Our Bank" := PaymHist."Our Bank";
        PaymentHistLine."Run No." := PaymHist."Run No.";
        PaymentHistLine."Line No." := PaymHist."No. of Transactions";
        PaymentHistLine.Status := PaymentHistLine.Status::New;

        PaymentHistLine."Account Type" := ProposalLine."Account Type";
        PaymentHistLine."Account No." := ProposalLine."Account No.";
        PaymentHistLine.Date := ProposalLine."Transaction Date";
        PaymentHistLine.Amount := ProposalLine.Amount;
        PaymentHistLine.Bank := ProposalLine.Bank;
        PaymentHistLine."Bank Account No." := ProposalLine."Bank Account No.";

        PaymentHistLine."Description 1" := ProposalLine."Description 1";
        PaymentHistLine."Description 2" := ProposalLine."Description 2";
        PaymentHistLine."Description 3" := ProposalLine."Description 3";
        PaymentHistLine."Description 4" := ProposalLine."Description 4";
        PaymentHistLine.Identification := ProposalLine.Identification;

        PaymentHistLine."Account Holder Name" := ProposalLine."Account Holder Name";
        PaymentHistLine."Account Holder Address" := ProposalLine."Account Holder Address";
        PaymentHistLine."Account Holder Post Code" := ProposalLine."Account Holder Post Code";
        PaymentHistLine."Account Holder City" := ProposalLine."Account Holder City";
        PaymentHistLine."Acc. Hold. Country/Region Code" := ProposalLine."Acc. Hold. Country/Region Code";
        PaymentHistLine."National Bank Code" := ProposalLine."National Bank Code";
        PaymentHistLine."SWIFT Code" := ProposalLine."SWIFT Code";
        PaymentHistLine.IBAN := ProposalLine.IBAN;
        PaymentHistLine."Direct Debit Mandate ID" := ProposalLine."Direct Debit Mandate ID";
        PaymentHistLine."Abbrev. National Bank Code" := ProposalLine."Abbrev. National Bank Code";
        PaymentHistLine."Bank Name" := ProposalLine."Bank Name";
        PaymentHistLine."Bank Address" := ProposalLine."Bank Address";
        PaymentHistLine."Bank City" := ProposalLine."Bank City";
        PaymentHistLine."Bank Country/Region" := ProposalLine."Bank Country/Region Code";
        PaymentHistLine."Transfer Cost Domestic" := ProposalLine."Transfer Cost Domestic";
        PaymentHistLine."Transfer Cost Foreign" := ProposalLine."Transfer Cost Foreign";

        PaymentHistLine."Currency Code" := ProposalLine."Currency Code";
        PaymentHistLine.Order := ProposalLine.Order;
        PaymentHistLine."Transaction Mode" := ProposalLine."Transaction Mode";
        PaymentHistLine.Docket := ProposalLine.Docket;

        PaymentHistLine."Nature of the Payment" := ProposalLine."Nature of the Payment";
        PaymentHistLine."Registration No. DNB" := ProposalLine."Registration No. DNB";
        PaymentHistLine."Description Payment" := ProposalLine."Description Payment";
        PaymentHistLine."Item No." := ProposalLine."Item No.";
        PaymentHistLine."Traders No." := ProposalLine."Traders No.";
        PaymentHistLine.Urgent := ProposalLine.Urgent;

        if ((PaymentHistLine.Order = PaymentHistLine.Order::Credit) and
            (PaymentHistLine."Account Type" = PaymentHistLine."Account Type"::Vendor)) or
           ((PaymentHistLine.Order = PaymentHistLine.Order::Credit) and
            (PaymentHistLine."Account Type" = PaymentHistLine."Account Type"::Customer)) or
           ((PaymentHistLine.Order = PaymentHistLine.Order::Credit) and
            (PaymentHistLine."Account Type" = PaymentHistLine."Account Type"::Employee))
        then
            PaymentHistLine."Payment/Receipt" := PaymentHistLine."Payment/Receipt"::Receipt
        else
            PaymentHistLine."Payment/Receipt" := PaymentHistLine."Payment/Receipt"::Payment;

        PaymentHistLine."Foreign Currency" := ProposalLine."Foreign Currency";
        PaymentHistLine."Foreign Amount" := ProposalLine."Foreign Amount";

        PaymentHistLine."Global Dimension 1 Code" := ProposalLine."Shortcut Dimension 1 Code";
        PaymentHistLine."Global Dimension 2 Code" := ProposalLine."Shortcut Dimension 2 Code";
        PaymentHistLine."Dimension Set ID" := ProposalLine."Dimension Set ID";
        if ((PaymentHistLine.Order = PaymentHistLine.Order::Credit) and
            (PaymentHistLine."Account Type" = PaymentHistLine."Account Type"::Customer))
        then
            UpdateDirectDebitMandate(PaymentHistLine);
        PaymentHistLine.Insert(true);

        "Detail line".SetCurrentKey("Our Bank", Status, "Connect Batches", "Connect Lines");
        "Detail line".SetRange("Our Bank", ProposalLine."Our Bank No.");
        "Detail line".SetRange(Status, "Detail line".Status::Proposal);
        "Detail line".SetRange("Connect Batches", '');
        "Detail line".SetRange("Connect Lines", ProposalLine."Line No.");
        while "Detail line".FindFirst do begin
            "Detail line".Status := "Detail line".Status::"In process";
            "Detail line"."Connect Batches" := PaymentHistLine."Run No.";
            "Detail line"."Connect Lines" := PaymentHistLine."Line No.";
            "Detail line".Modify(true);
        end;
        TelebankFinancialConnection.PostPaymReceived(GenJnlLine, PaymentHistLine, PaymHist);
    end;

    [Scope('OnPrem')]
    procedure DeleteProposallines(var Prop: Record "Proposal Line")
    begin
        Prop.Delete(true);
    end;

    [Scope('OnPrem')]
    procedure FinalError() Res: Text[125]
    begin
        exit(Errortext);
    end;

    [Scope('OnPrem')]
    procedure FinalWarning() Res: Text[125]
    begin
        exit(Warningstext);
    end;

    [Scope('OnPrem')]
    procedure GetAccountnumber() Acc: Text[30]
    begin
        exit(AccountNo);
    end;

    local procedure UpdateDirectDebitMandate(var PaymentHistoryLine: Record "Payment History Line")
    var
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        if DirectDebitMandate.Get(PaymentHistoryLine."Direct Debit Mandate ID") then begin
            DirectDebitMandate.Validate("Debit Counter", DirectDebitMandate."Debit Counter" + 1);

            OnUpdateDirectDebitMandateOnBeforeModify(DirectDebitMandate, PaymentHistoryLine);
            DirectDebitMandate.Modify(true);

            PaymentHistoryLine.Validate("Direct Debit Mandate Counter", DirectDebitMandate."Debit Counter");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckLedgerEntries(ProposalLine: Record "Proposal Line"; var WarningsText: Text[125]; var ErrorText: Text[125]; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDirectDebitMandateOnBeforeModify(var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate"; PaymentHistoryLine: Record "Payment History Line")
    begin
    end;
}

