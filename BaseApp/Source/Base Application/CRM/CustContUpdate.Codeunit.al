codeunit 5056 "CustCont-Update"
{

    trigger OnRun()
    begin
    end;

    var
        RMSetup: Record "Marketing Setup";
        CustContactUpdateCategoryTxt: Label 'Customer Contact Orphaned Links', Locked = true;
        CustContactUpdateTelemetryMsg: Label 'Contact does not exist. The contact business relation which points to it has been deleted', Locked = true;

    procedure OnInsert(var Cust: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Cust, IsHandled);
        if IsHandled then
            exit;

        RMSetup.Get();
        if RMSetup."Bus. Rel. Code for Customers" = '' then
            exit;

        InsertNewContact(Cust, true);
    end;

    procedure OnModify(var Cust: Record Customer)
    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
        OldCont: Record Contact;
        ContNo: Code[20];
        NoSeries: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnModify(Cust, ContBusRel, IsHandled);
        if not IsHandled then begin
            with ContBusRel do begin
                SetCurrentKey("Link to Table", "No.");
                SetRange("Link to Table", "Link to Table"::Customer);
                SetRange("No.", Cust."No.");
                if not FindFirst() then
                    exit;
                if not Cont.Get("Contact No.") then begin
                    Delete();
                    Session.LogMessage('0000B37', CustContactUpdateTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CustContactUpdateCategoryTxt);
                    exit;
                end;
                OldCont := Cont;
            end;

            ContNo := Cont."No.";
            NoSeries := Cont."No. Series";
            Cont.Validate("E-Mail", Cust."E-Mail");
            if (Cont."VAT Registration No." <> Cust."VAT Registration No.") and CustVATLogExist(Cust) then begin
                Cont.Validate("Country/Region Code", Cust."Country/Region Code");
                Cont.Validate("VAT Registration No.", Cust."VAT Registration No.");
            end;
            Cont.TransferFields(Cust);
            Cont."No." := ContNo;
            Cont."No. Series" := NoSeries;
            OnAfterTransferFieldsFromCustToCont(Cont, Cust);

            Cont.Type := OldCont.Type;
            Cont.Validate(Name);
            Cont.DoModify(OldCont);
            Cont.Modify(true);

            Cust.Get(Cust."No.");
        end;

        OnAfterOnModify(Cont, OldCont, Cust);
    end;

    procedure OnDelete(var Cust: Record Customer)
    var
        ContBusRel: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Cust, ContBusRel, IsHandled);
        if IsHandled then
            exit;

        with ContBusRel do begin
            SetCurrentKey("Link to Table", "No.");
            SetRange("Link to Table", "Link to Table"::Customer);
            SetRange("No.", Cust."No.");
            DeleteAll(true);
        end;
    end;

    procedure InsertNewContact(var Cust: Record Customer; LocalCall: Boolean)
    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertNewContact(Cust, LocalCall, IsHandled);
        if IsHandled then
            exit;

        if not LocalCall then begin
            RMSetup.Get();
            RMSetup.TestField("Bus. Rel. Code for Customers");
        end;

        if ContBusRel.UpdateEmptyNoForContact(Cust."No.", Cust."Primary Contact No.", ContBusRel."Link to Table"::Customer) then
            exit;

        with Cont do begin
            Init();
            TransferFields(Cust);
            OnAfterTransferFieldsFromCustToCont(Cont, Cust);
            Validate(Name);
            Validate("E-Mail");
            IsHandled := false;
            OnInsertNewContactOnBeforeAssignNo(Cont, IsHandled, Cust);
            if not IsHandled then begin
                "No." := '';
                "No. Series" := '';
                RMSetup.TestField("Contact Nos.");
                NoSeriesMgt.InitSeries(RMSetup."Contact Nos.", '', 0D, "No.", "No. Series");
            end;
            Type := Cust."Contact Type";
            SetSkipDefault();
            OnBeforeContactInsert(Cont, Cust);
            Insert(true);
        end;

        OnInsertNewContactOnAfterContInsert(Cont, Cust);

        with ContBusRel do begin
            Init();
            "Contact No." := Cont."No.";
            "Business Relation Code" := RMSetup."Bus. Rel. Code for Customers";
            "Link to Table" := "Link to Table"::Customer;
            "No." := Cust."No.";
            OnInsertNewContactOnBeforeContBusRelInsert(ContBusRel, Cont, Cust);
            Insert(true);
        end;
    end;

    procedure InsertNewContactPerson(var Cust: Record Customer; LocalCall: Boolean)
    var
        ContComp: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
    begin
        if not LocalCall then begin
            RMSetup.Get();
            RMSetup.TestField("Bus. Rel. Code for Customers");
        end;

        ContBusRel.SetCurrentKey("Link to Table", "No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
        ContBusRel.SetRange("No.", Cust."No.");
        if ContBusRel.FindFirst() then
            if ContComp.Get(ContBusRel."Contact No.") then
                with Cont do begin
                    Init();
                    "No." := '';
                    OnInsertNewContactPersonOnBeforeValidateType(Cont, Cust, ContComp);
                    Validate(Type, Type::Person);
                    Insert(true);
                    "Company No." := ContComp."No.";
                    Validate(Name, Cust.Contact);
                    InheritCompanyToPersonData(ContComp);
                    UpdateBusinessRelation();
                    OnInsertNewContactPersonOnBeforeContactModify(Cont, Cust);
                    Modify(true);
                    OnInsertNewContactPersonOnAfterContactModify(Cont, Cust);
                    Cust."Primary Contact No." := "No.";
                end
    end;

    procedure DeleteCustomerContacts(var Customer: Record Customer)
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        with ContactBusinessRelation do begin
            SetCurrentKey("Link to Table", "No.");
            SetRange("Link to Table", "Link to Table"::Customer);
            SetRange("No.", Customer."No.");
            if FindSet() then
                repeat
                    if Contact.Get("Contact No.") then
                        Contact.Delete(true);
                until Next() = 0;
        end;
    end;

    procedure ContactNameIsBlank(CustomerNo: Code[20]): Boolean
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        with ContactBusinessRelation do begin
            SetCurrentKey("Link to Table", "No.");
            SetRange("Link to Table", "Link to Table"::Customer);
            SetRange("No.", CustomerNo);
            if not FindFirst() then
                exit(false);
            if not Contact.Get("Contact No.") then
                exit(true);
            exit(Contact.Name = '');
        end;
    end;

    local procedure CustVATLogExist(Customer: Record Customer): Boolean
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        if Customer."VAT Registration No." = '' then
            exit(false);
        if not VATRegNoSrvConfig.VATRegNoSrvIsEnabled() then
            exit(false);

        VATRegistrationLog.SetRange("Account Type", VATRegistrationLog."Account Type"::Customer);
        VATRegistrationLog.SetRange("Account No.", Customer."No.");
        VATRegistrationLog.SetRange("VAT Registration No.", Customer."VAT Registration No.");
        if not VATRegistrationLog.IsEmpty() then
            exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnModify(var Contact: Record Contact; var OldContact: Record Contact; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFieldsFromCustToCont(var Contact: Record Contact; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeContactInsert(var Contact: Record Contact; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewContact(var Customer: Record Customer; LocalCall: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(Customer: Record Customer; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModify(Customer: Record Customer; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactOnAfterContInsert(var Contact: Record Contact; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactPersonOnAfterContactModify(var Contact: Record Contact; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactPersonOnBeforeValidateType(var Contact: Record Contact; Customer: Record Customer; ContComp: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactPersonOnBeforeContactModify(var Contact: Record Contact; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactOnBeforeContBusRelInsert(var ContactBusinessRelation: Record "Contact Business Relation"; Contact: Record Contact; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactOnBeforeAssignNo(var Contact: Record Contact; var IsHandled: Boolean; Customer: Record Customer);
    begin
    end;
}

