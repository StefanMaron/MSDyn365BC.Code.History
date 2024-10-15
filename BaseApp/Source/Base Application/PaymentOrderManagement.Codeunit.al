codeunit 11709 "Payment Order Management"
{
    Permissions = TableData "Issued Payment Order Header" = rm;

    trigger OnRun()
    begin
    end;

    var
        TempErrorMessage: Record "Error Message" temporary;
        MustBeSpecifiedErr: Label '''%1'' or ''%2'' in ''%3'' must be specified.', Comment = '%1 = fieldcaption of Account No.; %2 = fieldcaption of IBAN; %3 = recordid';
        BankOperationsFunctions: Codeunit "Bank Operations Functions";
        CustVendBlockedErr: Label '%1 %2 in ''%3'' is Blocked.', Comment = '%1 = table caption; %2 = No.; %3 = recordid';
        PrivacyBlockedErr: Label '%1 %2 in ''%3'' is blocked for privacy.', Comment = '%1 = table caption; %2 = No.; %3 = recordid';
        CustVendLedgEntryAlreadyAppliedErr: Label '''%1'' %2 in ''%3'' is already applied on other payment order.', Comment = '%1 = fieldcaption of Applies-to C/V Entry No; %2 = Applies-to C/V Entry No; %3 = recordid';
        AdvanceAlreadyAppliedErr: Label '''%1'' %2 in ''%3'' is already applied on other payment order.', Comment = '%1 = fieldcaption of Letter No.; %2 = Letter No.; %3 = recordid';
        AdvanceLineAlreadyAppliedErr: Label '''%1'' and ''%2'' %3 %4 in ''%5'' is already applied on other payment order.', Comment = '%1 = fieldcaption of Letter No.; %2 = fieldcaption of Letter Line No.; %3 = Letter No.; %4 = Letter Line No.; %5 = recordid';
        AccountNoMalformedErr: Label '''%1'' %2 in ''%3 is malformed.', Comment = '%1 = fieldcaption of Account No.; %2 = Account No.; %3 = recordid';
        ContinueQst: Label 'Do you want to continue?';
        ErrorMessageLogSuspended: Boolean;

    [Scope('OnPrem')]
    procedure PaymentOrderSelection(var PmtOrdHdr: Record "Payment Order Header"; var BankSelected: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
        BankAcc: Record "Bank Account";
        UserSetupLine: Record "User Setup Line";
        UserSetupAdvMgt: Codeunit "User Setup Adv. Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePaymentOrderSelection(PmtOrdHdr, BankSelected, IsHandled);
        if IsHandled then
            exit;

        BankSelected := true;

        BankAcc.Reset();

        case BankAcc.Count of
            0:
                BankAcc.FindFirst;
            1:
                BankAcc.FindFirst;
            else
                BankSelected := PAGE.RunModal(PAGE::"Bank List", BankAcc) = ACTION::LookupOK;
        end;

        if BankSelected then begin
            GLSetup.Get();
            if GLSetup."User Checks Allowed" then
                UserSetupAdvMgt.CheckBankAccountNo(UserSetupLine.Type::"Paym. Order", BankAcc."No.");
            PmtOrdHdr.FilterGroup := 2;
            PmtOrdHdr.SetRange("Bank Account No.", BankAcc."No.");
            PmtOrdHdr.FilterGroup := 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure IssuedPaymentOrderSelection(var IssuedPmtOrdHdr: Record "Issued Payment Order Header"; var BankSelected: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
        BankAcc: Record "Bank Account";
        UserSetupLine: Record "User Setup Line";
        UserSetupAdvMgt: Codeunit "User Setup Adv. Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIssuedPaymentOrderSelection(IssuedPmtOrdHdr, BankSelected, IsHandled);
        if IsHandled then
            exit;

        BankSelected := true;

        BankAcc.Reset();

        case BankAcc.Count of
            0:
                BankAcc.FindFirst;
            1:
                BankAcc.FindFirst;
            else
                BankSelected := PAGE.RunModal(PAGE::"Bank List", BankAcc) = ACTION::LookupOK;
        end;

        if BankSelected then begin
            GLSetup.Get();
            if GLSetup."User Checks Allowed" then
                UserSetupAdvMgt.CheckBankAccountNo(UserSetupLine.Type::"Paym. Order", BankAcc."No.");
            IssuedPmtOrdHdr.FilterGroup := 2;
            IssuedPmtOrdHdr.SetRange("Bank Account No.", BankAcc."No.");
            IssuedPmtOrdHdr.FilterGroup := 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckPaymentOrderLineFormat(PmtOrdLn: Record "Payment Order Line"; ShowErrorMessages: Boolean): Boolean
    var
        TempErrorMessage2: Record "Error Message" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPaymentOrderLineFormat(PmtOrdLn, ShowErrorMessages, TempErrorMessage2, IsHandled);
        if not IsHandled then
            with PmtOrdLn do begin
                TempErrorMessage2.LogIfEqualTo(
                    PmtOrdLn, FieldNo("Amount Must Be Checked"), TempErrorMessage2."Message Type"::Error, true);
                TempErrorMessage2.LogIfEmpty(
                    PmtOrdLn, FieldNo("Amount to Pay"), TempErrorMessage2."Message Type"::Error);
                TempErrorMessage2.LogIfLessThan(
                    PmtOrdLn, FieldNo("Amount to Pay"), TempErrorMessage2."Message Type"::Error, 0);
                TempErrorMessage2.LogIfEmpty(
                    PmtOrdLn, FieldNo("Due Date"), TempErrorMessage2."Message Type"::Error);
                TempErrorMessage2.LogIfEmpty(
                    PmtOrdLn, FieldNo("Variable Symbol"), TempErrorMessage2."Message Type"::Error);
                TempErrorMessage2.LogIfInvalidCharacters(
                    PmtOrdLn, FieldNo("Variable Symbol"), TempErrorMessage2."Message Type"::Error,
                    BankOperationsFunctions.GetValidCharactersForVariableSymbol());
                TempErrorMessage2.LogIfInvalidCharacters(
                    PmtOrdLn, FieldNo("Constant Symbol"), TempErrorMessage2."Message Type"::Error,
                    BankOperationsFunctions.GetValidCharactersForConstantSymbol());
                TempErrorMessage2.LogIfInvalidCharacters(
                    PmtOrdLn, FieldNo("Specific Symbol"), TempErrorMessage2."Message Type"::Error,
                    BankOperationsFunctions.GetValidCharactersForSpecificSymbol());
                if ("Account No." = '') and (IBAN = '') then
                    TempErrorMessage2.LogMessage(
                        PmtOrdLn, 0, TempErrorMessage2."Message Type"::Error,
                        StrSubstNo(MustBeSpecifiedErr, FieldCaption("Account No."), FieldCaption(IBAN), RecordId));
            end;

        SaveErrorMessage(TempErrorMessage2);
        exit(not HasErrorMessages(TempErrorMessage2, ShowErrorMessages));
    end;

    [Scope('OnPrem')]
    procedure CheckPaymentOrderLineBankAccountNo(PmtOrdLn: Record "Payment Order Line"; ShowErrorMessages: Boolean): Boolean
    var
        PmtOrdHdr: Record "Payment Order Header";
        BankAccount: Record "Bank Account";
        TempErrorMessage2: Record "Error Message" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPaymentOrderLineBankAccountNo(PmtOrdLn, ShowErrorMessages, TempErrorMessage2, IsHandled);
        if not IsHandled then
            with PmtOrdLn do begin
                PmtOrdHdr.Get("Payment Order No.");
                BankAccount.Get(PmtOrdHdr."Bank Account No.");

                if not BankAccount."Check Czech Format on Issue" or
                    PmtOrdHdr."Foreign Payment Order"
                then
                    exit(true);

                TempErrorMessage2.LogIfInvalidCharacters(
                    PmtOrdLn, FieldNo("Account No."), TempErrorMessage2."Message Type"::Error,
                    BankOperationsFunctions.GetValidCharactersForBankAccountNo());
                if not BankOperationsFunctions.CheckBankAccountNo("Account No.", false) then
                    TempErrorMessage2.LogMessage(
                        PmtOrdLn, FieldNo("Account No."), TempErrorMessage2."Message Type"::Error,
                        StrSubstNo(AccountNoMalformedErr, FieldCaption("Account No."), "Account No.", RecordId));
            end;

        SaveErrorMessage(TempErrorMessage2);
        exit(not HasErrorMessages(TempErrorMessage2, ShowErrorMessages));
    end;

    [Scope('OnPrem')]
    procedure CheckPaymentOrderLineCustVendBlocked(PmtOrdLn: Record "Payment Order Line"; ShowErrorMessages: Boolean): Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        TempErrorMessage2: Record "Error Message" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPaymentOrderLineCustVendBlocked(PmtOrdLn, ShowErrorMessages, TempErrorMessage2, IsHandled);
        if not IsHandled then
            with PmtOrdLn do
                case Type of
                    Type::Customer:
                        begin
                            Customer.Get("No.");
                            if Customer."Privacy Blocked" then
                                TempErrorMessage2.LogMessage(
                                    PmtOrdLn, FieldNo("No."), TempErrorMessage2."Message Type"::Warning,
                                    StrSubstNo(PrivacyBlockedErr, Customer.TableCaption, Customer."No.", RecordId));

                            if Customer.Blocked in [Customer.Blocked::All] then
                                TempErrorMessage2.LogMessage(
                                    PmtOrdLn, FieldNo("No."), TempErrorMessage2."Message Type"::Warning,
                                    StrSubstNo(CustVendBlockedErr, Customer.TableCaption, Customer."No.", RecordId));
                        end;
                    Type::Vendor:
                        begin
                            Vendor.Get("No.");
                            if Vendor."Privacy Blocked" then
                                TempErrorMessage2.LogMessage(
                                    PmtOrdLn, FieldNo("No."), TempErrorMessage2."Message Type"::Warning,
                                    StrSubstNo(PrivacyBlockedErr, Vendor.TableCaption, Vendor."No.", RecordId));

                            if Vendor.Blocked in [Vendor.Blocked::All] then
                                TempErrorMessage2.LogMessage(
                                    PmtOrdLn, FieldNo("No."), TempErrorMessage2."Message Type"::Warning,
                                    StrSubstNo(CustVendBlockedErr, Vendor.TableCaption, Vendor."No.", RecordId));
                        end;
                end;

        SaveErrorMessage(TempErrorMessage2);
        exit(not HasErrorMessages(TempErrorMessage2, ShowErrorMessages));
    end;

    [Scope('OnPrem')]
    procedure CheckPaymentOrderLineApply(PmtOrdLn: Record "Payment Order Line"; ShowErrorMessages: Boolean): Boolean
    var
        TempErrorMessage2: Record "Error Message" temporary;
        ErrorMessageID: Integer;
        TempErrorMessageLogSuspended: Boolean;
    begin
        TempErrorMessage.Reset();
        if TempErrorMessage.FindLast then
            ErrorMessageID := TempErrorMessage.ID;

        TempErrorMessageLogSuspended := ErrorMessageLogSuspended;
        ErrorMessageLogSuspended := false;

        CheckPaymentOrderLineApplyToOtherEntries(PmtOrdLn, false);
        CheckPaymentOrderLineApplyToAdvanceLetter(PmtOrdLn, false);

        ErrorMessageLogSuspended := TempErrorMessageLogSuspended;

        TempErrorMessage.Reset();
        TempErrorMessage.SetFilter(ID, '%1..', ErrorMessageID + 1);
        TempErrorMessage.CopyToTemp(TempErrorMessage2);

        if ErrorMessageLogSuspended then
            TempErrorMessage.DeleteAll(true);

        exit(not HasErrorMessages(TempErrorMessage2, ShowErrorMessages))
    end;

    procedure CheckPaymentOrderLineCustom(PmtOrdLn: Record "Payment Order Line"; ShowErrorMessages: Boolean): Boolean
    var
        TempErrorMessage2: Record "Error Message" temporary;
    begin
        OnCheckPaymentOrderLineCustom(PmtOrdLn, ShowErrorMessages, TempErrorMessage2);

        SaveErrorMessage(TempErrorMessage2);
        exit(not HasErrorMessages(TempErrorMessage2, ShowErrorMessages))
    end;

    local procedure CheckPaymentOrderLineApplyToOtherEntries(PmtOrdLn: Record "Payment Order Line"; ShowErrorMessages: Boolean): Boolean
    var
        TempErrorMessage2: Record "Error Message" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPaymentOrderLineApplyToOtherEntries(PmtOrdLn, ShowErrorMessages, TempErrorMessage2, IsHandled);
        if not IsHandled then
            with PmtOrdLn do begin
                if not IsLedgerEntryApplied(PmtOrdLn) then
                    exit;

                TempErrorMessage2.LogMessage(
                    PmtOrdLn, FieldNo("Applies-to C/V/E Entry No."), TempErrorMessage2."Message Type"::Warning,
                    StrSubstNo(
                        CustVendLedgEntryAlreadyAppliedErr,
                        FieldCaption("Applies-to C/V/E Entry No."), "Applies-to C/V/E Entry No.", RecordId));
            end;

        SaveErrorMessage(TempErrorMessage2);
        exit(not HasErrorMessages(TempErrorMessage2, ShowErrorMessages));
    end;

    local procedure CheckPaymentOrderLineApplyToAdvanceLetter(PmtOrdLn: Record "Payment Order Line"; ShowErrorMessages: Boolean): Boolean
    var
        TempErrorMessage2: Record "Error Message" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPaymentOrderLineApplyToAdvanceLetter(PmtOrdLn, ShowErrorMessages, TempErrorMessage2, IsHandled);
        if not IsHandled then
            with PmtOrdLn do begin
                if not IsAdvanceLetterApplied(PmtOrdLn) then
                    exit(true);

                if ("Letter No." <> '') and ("Letter Line No." <> 0) then
                    TempErrorMessage2.LogMessage(
                        PmtOrdLn, FieldNo("Letter Line No."), TempErrorMessage2."Message Type"::Warning,
                        StrSubstNo(
                            AdvanceLineAlreadyAppliedErr,
                            FieldCaption("Letter No."), "Letter No.",
                            FieldCaption("Letter Line No."), "Letter Line No.", RecordId));

                if ("Letter No." <> '') and ("Letter Line No." = 0) then
                    TempErrorMessage2.LogMessage(
                        PmtOrdLn, FieldNo("Letter No."), TempErrorMessage2."Message Type"::Warning,
                        StrSubstNo(
                            AdvanceAlreadyAppliedErr,
                            FieldCaption("Letter No."), "Letter No.", RecordId));
            end;

        SaveErrorMessage(TempErrorMessage2);
        exit(not HasErrorMessages(TempErrorMessage2, ShowErrorMessages));
    end;

    local procedure IsLedgerEntryApplied(PmtOrdLn: Record "Payment Order Line"): Boolean
    var
        PmtOrdLn2: Record "Payment Order Line";
        IssuedPmtOrdLn: Record "Issued Payment Order Line";
    begin
        with PmtOrdLn do begin
            if "Applies-to C/V/E Entry No." = 0 then
                exit(false);

            IssuedPmtOrdLn.SetFilter(Type, '%1|%2|%3',
              IssuedPmtOrdLn.Type::Customer, IssuedPmtOrdLn.Type::Vendor, IssuedPmtOrdLn.Type::Employee);
            IssuedPmtOrdLn.SetRange("Applies-to C/V/E Entry No.", "Applies-to C/V/E Entry No.");
            IssuedPmtOrdLn.SetRange(Status, IssuedPmtOrdLn.Status::" ");
            if not IssuedPmtOrdLn.IsEmpty then
                exit(true);

            PmtOrdLn2.SetRange("Applies-to C/V/E Entry No.", "Applies-to C/V/E Entry No.");
            PmtOrdLn2.SetFilter("Payment Order No.", '<>%1', "Payment Order No.");
            if not PmtOrdLn2.IsEmpty then
                exit(true);

            PmtOrdLn2.SetRange("Payment Order No.", "Payment Order No.");
            PmtOrdLn2.SetFilter("Line No.", '<>%1', "Line No.");
            if not PmtOrdLn2.IsEmpty then
                exit(true);
        end;
    end;

    local procedure IsAdvanceLetterApplied(PmtOrdLn: Record "Payment Order Line"): Boolean
    var
        PmtOrdLn2: Record "Payment Order Line";
        IssuedPmtOrdLn: Record "Issued Payment Order Line";
    begin
        with PmtOrdLn do begin
            if "Letter No." = '' then
                exit(false);

            IssuedPmtOrdLn.SetRange("Letter Type", "Letter Type");
            IssuedPmtOrdLn.SetRange("Letter No.", "Letter No.");
            IssuedPmtOrdLn.SetRange("Letter Line No.", "Letter Line No.");
            IssuedPmtOrdLn.SetRange(Status, IssuedPmtOrdLn.Status::" ");
            if not IssuedPmtOrdLn.IsEmpty then
                exit(true);

            PmtOrdLn2.SetRange("Letter Type", "Letter Type");
            PmtOrdLn2.SetRange("Letter No.", "Letter No.");
            PmtOrdLn2.SetRange("Letter Line No.", "Letter Line No.");
            PmtOrdLn2.SetFilter("Payment Order No.", '<>%1', "Payment Order No.");
            if not PmtOrdLn2.IsEmpty then
                exit(true);

            PmtOrdLn2.SetRange("Payment Order No.", "Payment Order No.");
            PmtOrdLn2.SetFilter("Line No.", '<>%1', "Line No.");
            if not PmtOrdLn2.IsEmpty then
                exit(true);
        end;
    end;

    local procedure HasErrorMessages(var TempErrorMessage2: Record "Error Message" temporary; ShowErrorMessages: Boolean): Boolean
    var
        HasMessages: Boolean;
    begin
        HasMessages := TempErrorMessage2.ErrorMessageCount(TempErrorMessage2."Message Type"::Information) > 0;
        TempErrorMessage2.HasErrors(ShowErrorMessages);
        if ShowErrorMessages then
            TempErrorMessage2.ShowErrorMessages(true);

        exit(HasMessages);
    end;

    local procedure SaveErrorMessage(var TempErrorMessage2: Record "Error Message" temporary)
    begin
        if ErrorMessageLogSuspended then
            exit;

        TempErrorMessage2.Reset();
        TempErrorMessage2.CopyToTemp(TempErrorMessage);
    end;

    [Scope('OnPrem')]
    procedure CopyErrorMessageToTemp(var TempErrorMessage2: Record "Error Message" temporary)
    begin
        TempErrorMessage.Reset();
        TempErrorMessage.CopyToTemp(TempErrorMessage2);
    end;

    [Scope('OnPrem')]
    procedure ClearErrorMessageLog()
    begin
        TempErrorMessage.ClearLog;
    end;

    [Scope('OnPrem')]
    procedure SuspendErrorMessageLog(NewErrorMessageLogSuspended: Boolean)
    begin
        ErrorMessageLogSuspended := NewErrorMessageLogSuspended;
    end;

    [Scope('OnPrem')]
    procedure ProcessErrorMessages(ShowMessage: Boolean; RollBackOnError: Boolean)
    var
        PmtOrdLn: Record "Payment Order Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessErrorMessages(TempErrorMessage, ShowMessage, RollBackOnError, IsHandled);
        if IsHandled then
            exit;

        if TempErrorMessage.HasErrors(ShowMessage) then
            TempErrorMessage.ShowErrorMessages(RollBackOnError);

        TempErrorMessage.Reset();
        TempErrorMessage.SetRange("Message Type", TempErrorMessage."Message Type"::Warning);
        TempErrorMessage.SetFilter("Field Number", '%1|%2|%3',
            PmtOrdLn.FieldNo("Applies-to C/V/E Entry No."),
            PmtOrdLn.FieldNo("Letter No."),
            PmtOrdLn.FieldNo("Letter Line No."));
        if TempErrorMessage.FindSet then
            repeat
                if not Confirm(StrSubstNo('%1\\%2', TempErrorMessage.Description, ContinueQst)) then
                    Error('');
            until TempErrorMessage.Next = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePaymentOrderSelection(var PmtOrdHdr: Record "Payment Order Header"; var BankSelected: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuedPaymentOrderSelection(var IssuedPmtOrdHdr: Record "Issued Payment Order Header"; var BankSelected: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPaymentOrderLineFormat(var PmtOrdLn: Record "Payment Order Line"; var ShowErrorMessages: Boolean; var TempErrorMessage: Record "Error Message" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPaymentOrderLineBankAccountNo(var PmtOrdLn: Record "Payment Order Line"; var ShowErrorMessages: Boolean; var TempErrorMessage: Record "Error Message" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPaymentOrderLineCustVendBlocked(var PmtOrdLn: Record "Payment Order Line"; var ShowErrorMessages: Boolean; var TempErrorMessage: Record "Error Message" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPaymentOrderLineApplyToOtherEntries(var PmtOrdLn: Record "Payment Order Line"; var ShowErrorMessages: Boolean; var TempErrorMessage: Record "Error Message" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPaymentOrderLineApplyToAdvanceLetter(var PmtOrdLn: Record "Payment Order Line"; var ShowErrorMessages: Boolean; var TempErrorMessage: Record "Error Message" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPaymentOrderLineCustom(var PmtOrdLn: Record "Payment Order Line"; var ShowErrorMessages: Boolean; var TempErrorMessage: Record "Error Message" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessErrorMessages(var TempErrorMessage: Record "Error Message" temporary; var ShowMessage: Boolean; var RollBackOnError: Boolean; var IsHandled: Boolean)
    begin
    end;
}

