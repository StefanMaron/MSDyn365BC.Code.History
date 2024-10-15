codeunit 11000011 "Check SEPA Pain 008.001.02"
{
    TableNo = "Proposal Line";

    trigger OnRun()
    var
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        TransactionMode: Record "Transaction Mode";
        CheckSEPA: Codeunit "Check SEPA ISO20022";
    begin
        if "Account Type" = "Account Type"::Customer then begin
            TransactionMode.Get(TransactionMode."Account Type"::Customer, "Transaction Mode");
            if TransactionMode."Partner Type" = TransactionMode."Partner Type"::" " then begin
                "Error Message" := MissingPartnerTypeErr;
                exit;
            end;

            Customer.Get("Account No.");
            if TransactionMode."Partner Type" <> Customer."Partner Type" then begin
                "Error Message" := PartnerTypeMismatchErr;
                exit;
            end;

            BankAcc.Get("Our Bank No.");
            if BankAcc."Creditor Identifier" = '' then begin
                "Error Message" := MissingCrIdentifierErr;
                exit;
            end;

            if "Direct Debit Mandate ID" = '' then begin
                "Error Message" := MissingMandateErr;
                exit;
            end;

            DirectDebitMandate.Get("Direct Debit Mandate ID");
            if not DirectDebitMandate.IsMandateActive("Transaction Date") then begin
                "Error Message" := InvalidMandateDatesErr;
                exit;
            end;

            if DirectDebitMandate."Date of Signature" = 0D then begin
                "Error Message" := MissingDateOfSignatureErr;
                exit;
            end;

            if DirectDebitMandate."Expected Number of Debits" = DirectDebitMandate."Debit Counter" then begin
                "Error Message" := ClosedMandateErr;
                exit;
            end;

            if (DirectDebitMandate."Type of Payment" = DirectDebitMandate."Type of Payment"::OneOff) and
               (DirectDebitMandate."Debit Counter" >= 1)
            then begin
                "Error Message" := ClosedMandateErr;
                exit;
            end;

            if not CheckProposalPartnerType(Rec) then
                exit;
        end;

        CheckSEPA.Run(Rec);
    end;

    var
        ClosedMandateErr: Label 'The Mandate is already used for specified number of direct debit transactions and cannot be used anymore.';
        InvalidMandateDatesErr: Label 'The Transaction Date is not within the date interval specified in the mandate or the mandate is closed.';
        MissingMandateErr: Label 'The Mandate ID must be entered on the Customer Bank Account card.';
        MissingPartnerTypeErr: Label 'The Partner Type must be entered in the Transaction Mode field.';
        MissingCrIdentifierErr: Label 'The Creditor Identifier must be entered on the Bank Account card.';
        MissingDateOfSignatureErr: Label 'The Date of Signature must be entered in the Mandate List window.';
        PropLinesPartnerTypeErr: Label 'All transactions must have the same value for Partner Type.';
        PartnerTypeMismatchErr: Label 'The Partner Type must be the same for the selected Transaction Mode and the Customer.';
        BankAcc: Record "Bank Account";

    [Scope('OnPrem')]
    procedure CheckProposalPartnerType(var ProposalLine: Record "Proposal Line"): Boolean
    var
        CountPartnerTypes: Query CountPartnerTypes;
    begin
        CountPartnerTypes.SetRange(Our_Bank_No, ProposalLine."Our Bank No.");
        CountPartnerTypes.Open;

        CountPartnerTypes.Read;
        if CountPartnerTypes.Read then begin
            ProposalLine."Error Message" := PropLinesPartnerTypeErr;
            exit(false);
        end;

        exit(true);
    end;
}

