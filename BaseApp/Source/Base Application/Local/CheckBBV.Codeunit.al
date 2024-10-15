codeunit 11000008 "Check BBV"
{
    // BBV Controle

    TableNo = "Proposal Line";

    trigger OnRun()
    var
        FreelyTransferableMaximum: Record "Freely Transferable Maximum";
    begin
        FreelyTransferableMaximum.Get("Acc. Hold. Country/Region Code", "Currency Code");

        if Amount > FreelyTransferableMaximum.Amount then
            case "Nature of the Payment" of
                "Nature of the Payment"::" ":
                    begin
                        "Error Message" := StrSubstNo(Text1000000,
                            FieldCaption(Amount),
                            FieldCaption("Nature of the Payment"));
                        exit;
                    end;
                "Nature of the Payment"::"Transito Trade":
                    if ("Item No." = '') or ("Traders No." = '') then begin
                        "Error Message" := StrSubstNo(Text1000001,
                            FieldCaption("Nature of the Payment"),
                            FieldCaption("Item No."),
                            FieldCaption("Traders No."));
                        exit;
                    end;
                "Nature of the Payment"::"Invisible- and Capital Transactions":
                    if "Description Payment" = '' then begin
                        "Error Message" := StrSubstNo(Text1000002,
                            FieldCaption("Nature of the Payment"),
                            FieldCaption("Description Payment"));
                        exit;
                    end;
                "Nature of the Payment"::"Transfer to Own Account",
              "Nature of the Payment"::"Other Registrated BFI":
                    if ("Description Payment" = '') or
                       ("Registration No. DNB" = '')
                    then begin
                        "Error Message" :=
                          StrSubstNo(
                            Text1000003,
                            FieldCaption("Nature of the Payment"),
                            FieldCaption("Description Payment"),
                            FieldCaption("Registration No. DNB"));
                        exit;
                    end;
            end;

        if "Transfer Cost Domestic" = "Transfer Cost Domestic"::"Balancing Account Holder" then
            Warning := Text1000005;

        if ("Bank Name" = '') or ("Bank City" = '') then begin
            "Error Message" := StrSubstNo(Text1000004,
                FieldCaption("Bank Name"),
                FieldCaption("Bank City"));
            exit;
        end;

        if "Bank Name" = '' then begin
            "Error Message" := StrSubstNo(Text1000006, FieldCaption("Bank Name"));
            exit;
        end;

        if "Bank City" = '' then begin
            "Error Message" := StrSubstNo(Text1000006, FieldCaption("Bank City"));
            exit;
        end;

        if "Account Holder Address" = '' then begin
            "Error Message" := StrSubstNo(Text1000006, FieldCaption("Account Holder Address"));
            exit;
        end;

        if "Acc. Hold. Country/Region Code" = '' then begin
            "Error Message" := StrSubstNo(Text1000006, FieldCaption("Acc. Hold. Country/Region Code"));
            exit;
        end;

        if "Bank Country/Region Code" = '' then begin
            "Error Message" := StrSubstNo(Text1000006, FieldCaption("Bank Country/Region Code"));
            exit;
        end;
    end;

    var
        Text1000000: Label '%1 exceeds the maximum limit, %2 must be filled in';
        Text1000001: Label '%1 is transito trade, %2 and %3 must be filled in';
        Text1000002: Label '%1 is invisible- and capital transactions, %2 must be filled in';
        Text1000003: Label '%1 is transfer or sundry, %2 and %3 must be filled in';
        Text1000004: Label '%1 and %2  must be filled in';
        Text1000005: Label 'With protocol BBV, the domestic transfer cost always are for the principal';
        Text1000006: Label '%1 must be filled in';
}

