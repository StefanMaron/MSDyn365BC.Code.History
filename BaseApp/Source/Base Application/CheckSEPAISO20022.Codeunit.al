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

        if "SWIFT Code" = '' then begin
            "Error Message" := StrSubstNo(Text001, FieldCaption("SWIFT Code"), TableCaption);
            exit;
        end;

        if StrLen("SWIFT Code") > 11 then begin
            "Error Message" := StrSubstNo(Text002, FieldCaption("SWIFT Code"), TableCaption);
            exit;
        end;

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

        if BankAcc."SWIFT Code" = '' then begin
            "Error Message" := StrSubstNo(Text004, BankAcc.FieldCaption("SWIFT Code"), FieldCaption("Our Bank No."), "Our Bank No.");
            exit;
        end;

        if Country.Code <> BankAcc."Country/Region Code" then
            Country.Get(BankAcc."Country/Region Code");

        if not Country."SEPA Allowed" then begin
            "Error Message" := StrSubstNo(Text003, Country.FieldCaption("SEPA Allowed"), Country."SEPA Allowed",
                BankAcc.FieldCaption("Country/Region Code"), BankAcc."Country/Region Code",
                FieldCaption("Our Bank No."), "Our Bank No.");
            exit;
        end;

        // Check Company Information
        CompanyInfo.Get();
        if CompanyInfo."VAT Registration No." = '' then begin
            "Error Message" := StrSubstNo(Text001, CompanyInfo.FieldCaption("VAT Registration No."), CompanyInfo.TableCaption);
            exit;
        end;

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

