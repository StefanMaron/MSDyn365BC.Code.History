codeunit 5055 "CustVendBank-Update"
{
    TableNo = Contact;

    trigger OnRun()
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        ContBusRel.SetRange("Contact No.", "No.");
        ContBusRel.SetFilter("Link to Table", '<>''''');

        if ContBusRel.Find('-') then
            repeat
                case ContBusRel."Link to Table" of
                    ContBusRel."Link to Table"::Customer:
                        UpdateCustomer(Rec, ContBusRel);
                    ContBusRel."Link to Table"::Vendor:
                        UpdateVendor(Rec, ContBusRel);
                    ContBusRel."Link to Table"::"Bank Account":
                        UpdateBankAccount(Rec, ContBusRel);
                    else
                        OnRunCustVendBankUpdateCaseElse(Rec, ContBusRel);
                end;
            until ContBusRel.Next = 0;
    end;

    var
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        NoSeries: Code[20];
        PurchaserCode: Code[20];
        OurContactCode: Code[20];

    procedure UpdateCustomer(var Cont: Record Contact; var ContBusRel: Record "Contact Business Relation")
    var
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        VATRegNo: Text[20];
    begin
        with Cust do begin
            Get(ContBusRel."No.");
            NoSeries := "No. Series";
            VATRegNo := "VAT Registration No.";
            TransferFields(Cont);
            "No." := ContBusRel."No.";
            "No. Series" := NoSeries;
            OnAfterUpdateCustomer(Cust, Cont);
            Modify;
            if ("VAT Registration No." <> '') and ("VAT Registration No." <> VATRegNo) then
                VATRegistrationLogMgt.LogCustomer(Cust);
        end;
    end;

    procedure UpdateVendor(var Cont: Record Contact; var ContBusRel: Record "Contact Business Relation")
    var
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        VATRegNo: Text[20];
    begin
        with Vend do begin
            Get(ContBusRel."No.");
            NoSeries := "No. Series";
            PurchaserCode := "Purchaser Code";
            VATRegNo := "VAT Registration No.";
            TransferFields(Cont);
            "No." := ContBusRel."No.";
            "No. Series" := NoSeries;
            "Purchaser Code" := PurchaserCode;
            OnAfterUpdateVendor(Vend, Cont);
            Modify;
            if ("VAT Registration No." <> '') and ("VAT Registration No." <> VATRegNo) then
                VATRegistrationLogMgt.LogVendor(Vend);
        end;
    end;

    procedure UpdateBankAccount(var Cont: Record Contact; var ContBusRel: Record "Contact Business Relation")
    begin
        with BankAcc do begin
            Get(ContBusRel."No.");
            NoSeries := "No. Series";
            OurContactCode := "Our Contact Code";
            Validate("Currency Code", Cont."Currency Code");
            TransferFields(Cont);
            "No." := ContBusRel."No.";
            "No. Series" := NoSeries;
            "Our Contact Code" := OurContactCode;
            OnAfterUpdateBankAccount(BankAcc, Cont);
            Modify;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCustomer(var Customer: Record Customer; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVendor(var Vendor: Record Vendor; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBankAccount(var BankAccount: Record "Bank Account"; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCustVendBankUpdateCaseElse(var Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation")
    begin
    end;
}

