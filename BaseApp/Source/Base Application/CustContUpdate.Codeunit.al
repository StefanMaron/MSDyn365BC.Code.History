codeunit 5056 "CustCont-Update"
{

    trigger OnRun()
    begin
    end;

    var
        RMSetup: Record "Marketing Setup";
        CustContactUpdateCategoryTxt: Label 'Customer Contact Orphaned Links', Locked = true;
        CustContactUpdateTelemetryMsg: Label 'Contact %1 does not exist. The contact business relation with code %2 which points to it has been deleted', Locked = true;

    procedure OnInsert(var Cust: Record Customer)
    begin
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
        EnvInfoProxy: Codeunit "Env. Info Proxy";
        ContNo: Code[20];
        NoSeries: Code[20];
    begin
        with ContBusRel do begin
            SetCurrentKey("Link to Table", "No.");
            SetRange("Link to Table", "Link to Table"::Customer);
            SetRange("No.", Cust."No.");
            if not FindFirst then
                exit;
            if not Cont.Get("Contact No.") then begin
                Delete();
                SendTraceTag('0000B37', CustContactUpdateCategoryTxt, Verbosity::Normal, StrSubstNo(CustContactUpdateTelemetryMsg, "Contact No.", "Business Relation Code"), DataClassification::EndUserIdentifiableInformation);
                exit;
            end;
            OldCont := Cont;
        end;

        ContNo := Cont."No.";
        NoSeries := Cont."No. Series";
        Cont.Validate("E-Mail", Cust."E-Mail");
        Cont.TransferFields(Cust);
        Cont."No." := ContNo;
        Cont."No. Series" := NoSeries;
        OnAfterTransferFieldsFromCustToCont(Cont, Cust);

        if not EnvInfoProxy.IsInvoicing then
            Cont.Type := OldCont.Type;
        Cont.Validate(Name);
        Cont.DoModify(OldCont);
        Cont.Modify(true);

        Cust.Get(Cust."No.");
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
            Init;
            TransferFields(Cust);
            OnAfterTransferFieldsFromCustToCont(Cont, Cust);
            Validate(Name);
            Validate("E-Mail");
            IsHandled := false;
            OnInsertNewContactOnBeforeAssignNo(Cont, IsHandled);
            if not IsHandled then begin
                "No." := '';
                "No. Series" := '';
                RMSetup.TestField("Contact Nos.");
                NoSeriesMgt.InitSeries(RMSetup."Contact Nos.", '', 0D, "No.", "No. Series");
            end;
            Type := Type::Company;
            TypeChange;
            SetSkipDefault;
            OnBeforeContactInsert(Cont, Cust);
            Insert(true);
        end;

        with ContBusRel do begin
            Init;
            "Contact No." := Cont."No.";
            "Business Relation Code" := RMSetup."Bus. Rel. Code for Customers";
            "Link to Table" := "Link to Table"::Customer;
            "No." := Cust."No.";
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
        if ContBusRel.FindFirst then
            if ContComp.Get(ContBusRel."Contact No.") then
                with Cont do begin
                    Init;
                    "No." := '';
                    Validate(Type, Type::Person);
                    Insert(true);
                    "Company No." := ContComp."No.";
                    Validate(Name, Cust.Contact);
                    InheritCompanyToPersonData(ContComp);
                    OnInsertNewContactPersonOnBeforeContactModify(Cont, Cust);
                    Modify(true);
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
            if FindSet then
                repeat
                    if Contact.Get("Contact No.") then
                        Contact.Delete(true);
                until Next = 0;
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
            if not FindFirst then
                exit(false);
            if not Contact.Get("Contact No.") then
                exit(true);
            exit(Contact.Name = '');
        end;
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
    local procedure OnInsertNewContactPersonOnBeforeContactModify(var Contact: Record Contact; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactOnBeforeAssignNo(var Contact: Record Contact; var IsHandled: Boolean);
    begin
    end;
}

