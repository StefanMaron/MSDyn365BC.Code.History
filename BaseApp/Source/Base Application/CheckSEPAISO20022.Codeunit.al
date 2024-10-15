codeunit 11000010 "Check SEPA ISO20022"
{
    TableNo = "Proposal Line";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec);

        // Check Vendor/Customer Bank Account
        if IBAN = '' then begin
            "Error Message" := StrSubstNo(Text001, FieldCaption(IBAN), TableCaption);
            exit;
        end;

        if not CheckSWIFTCode(Rec) then
            exit;

        if "Bank Country/Region Code" = '' then begin
            "Error Message" := StrSubstNo(Text001, FieldCaption("Bank Country/Region Code"), TableCaption);
            exit;
        end;

        Country.Get("Bank Country/Region Code");

        if not Country."SEPA Allowed" then begin
            "Error Message" := StrSubstNo(Text009, Country.FieldCaption("SEPA Allowed"), Country."SEPA Allowed",
                FieldCaption("Bank Country/Region Code"), "Bank Country/Region Code");
            exit;
        end;

        if "Acc. Hold. Country/Region Code" = '' then begin
            "Error Message" := StrSubstNo(Text001, FieldCaption("Acc. Hold. Country/Region Code"), TableCaption);
            exit;
        end;

        // Check Our Bank Account
        BankAcc.Get("Our Bank No.");
        OnAfterBankAccGet(BankAcc);

        if BankAcc."Country/Region Code" = '' then begin
            "Error Message" := StrSubstNo(Text004, BankAcc.FieldCaption("Country/Region Code"), FieldCaption("Our Bank No."), "Our Bank No.");
            exit;
        end;

        if BankAcc.IBAN = '' then begin
            "Error Message" := StrSubstNo(Text004, BankAcc.FieldCaption(IBAN), FieldCaption("Our Bank No."), "Our Bank No.");
            exit;
        end;

        if not CheckBankSWIFTCode(Rec) then
            exit;

        if Country.Code <> BankAcc."Country/Region Code" then
            Country.Get(BankAcc."Country/Region Code");

        if not Country."SEPA Allowed" then begin
            "Error Message" := StrSubstNo(Text003, Country.FieldCaption("SEPA Allowed"), Country."SEPA Allowed",
                BankAcc.FieldCaption("Country/Region Code"), BankAcc."Country/Region Code",
                FieldCaption("Our Bank No."), "Our Bank No.");
            exit;
        end;

        // Check Company Information
        if not CheckCompanyInfoVATRegistrationNo(Rec) then
            exit;

        // Check Freely Tranferable Maximum
        FreelyTransferableMaximum.Get("Bank Country/Region Code", "Currency Code");


        if Amount > FreelyTransferableMaximum.Amount then
            case "Nature of the Payment" of
                "Nature of the Payment"::" ":
                    begin
                        "Error Message" := StrSubstNo(Text005, FieldCaption(Amount), FieldCaption("Nature of the Payment"));
                        exit;
                    end;
                "Nature of the Payment"::"Transito Trade":
                    if ("Item No." = '') or ("Traders No." = '') then begin
                        "Error Message" :=
                          StrSubstNo(
                            Text006,
                            FieldCaption("Nature of the Payment"),
                            FieldCaption("Item No."),
                            FieldCaption("Traders No."));
                        exit;
                    end;
                "Nature of the Payment"::"Invisible- and Capital Transactions":
                    if "Description Payment" = '' then begin
                        "Error Message" := StrSubstNo(Text007, FieldCaption("Nature of the Payment"), FieldCaption("Description Payment"));
                        exit;
                    end;
                "Nature of the Payment"::"Transfer to Own Account", "Nature of the Payment"::"Other Registrated BFI":
                    if ("Description Payment" = '') or ("Registration No. DNB" = '') then begin
                        "Error Message" :=
                          StrSubstNo(
                            Text008,
                            FieldCaption("Nature of the Payment"),
                            FieldCaption("Description Payment"),
                            FieldCaption("Registration No. DNB"));
                        exit;
                    end;
            end;

        OnAfterOnRun(Rec);
    end;

    var
        Text001: Label '%1 must be entered in %2.';
        Text002: Label '%1 must not exceed 11 characters.';
        Country: Record "Country/Region";
        Text003: Label '%1 cannot be %2 for %3:%4 of %5:%6.';
        BankAcc: Record "Bank Account";
        Text004: Label '%1 must be entered for %2:%3.';
        CompanyInfo: Record "Company Information";
        FreelyTransferableMaximum: Record "Freely Transferable Maximum";
        Text005: Label '%1 exceeds the maximum limit, %2 must be entered. The default value is ''goods''.';
        Text006: Label '%1 is transito trade, %2 and %3 must be filled in.';
        Text007: Label '%1 is invisible- and capital transactions, %2 must be filled in.';
        Text008: Label '%1 is transfer or sundry, %2 and %3 must be filled in.';
        Text009: Label '%1 cannot be %2 for %3:%4.';

    local procedure CheckCompanyInfoVATRegistrationNo(var ProposalLine: Record "Proposal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCompanyInfoVATRegistrationNo(ProposalLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        CompanyInfo.Get();
        if CompanyInfo."VAT Registration No." = '' then begin
            ProposalLine."Error Message" := StrSubstNo(Text001, CompanyInfo.FieldCaption("VAT Registration No."), CompanyInfo.TableCaption);
            exit(false);
        end;

        exit(true);
    end;

    local procedure CheckBankSWIFTCode(var ProposalLine: Record "Proposal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBankSWIFTCode(ProposalLine, BankAcc, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if BankAcc."SWIFT Code" = '' then begin
            ProposalLine."Error Message" := StrSubstNo(Text004, BankAcc.FieldCaption("SWIFT Code"), ProposalLine.FieldCaption("Our Bank No."), ProposalLine."Our Bank No.");
            exit(false);
        end;

        exit(true);
    end;

    local procedure CheckSWIFTCode(var ProposalLine: Record "Proposal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSWIFTCode(ProposalLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ProposalLine."SWIFT Code" = '' then begin
            ProposalLine."Error Message" := StrSubstNo(Text001, ProposalLine.FieldCaption("SWIFT Code"), ProposalLine.TableCaption);
            exit(false);
        end;

        if StrLen(ProposalLine."SWIFT Code") > 11 then begin
            ProposalLine."Error Message" := StrSubstNo(Text002, ProposalLine.FieldCaption("SWIFT Code"), ProposalLine.TableCaption);
            exit;
        end;

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBankSWIFTCode(var ProposalLine: Record "Proposal Line"; BankAcc: Record "Bank Account"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCompanyInfoVATRegistrationNo(var ProposalLine: Record "Proposal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSWIFTCode(var ProposalLine: Record "Proposal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ProposalLine: Record "Proposal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var ProposalLine: Record "Proposal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBankAccGet(var BankAcc: Record "Bank Account")
    begin
    end;
}

