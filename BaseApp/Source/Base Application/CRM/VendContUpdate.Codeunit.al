codeunit 5057 "VendCont-Update"
{

    trigger OnRun()
    begin
    end;

    var
        RMSetup: Record "Marketing Setup";
        VendContactUpdateCategoryTxt: Label 'Vendor Contact Orphaned Links', Locked = true;
        VendContactUpdateTelemetryMsg: Label 'Contact does not exist. The contact business relation which points to it has been deleted', Locked = true;

    procedure OnInsert(var Vend: Record Vendor)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Vend, IsHandled);
        if IsHandled then
            exit;

        RMSetup.Get();
        if RMSetup."Bus. Rel. Code for Vendors" = '' then
            exit;

        InsertNewContact(Vend, true);
    end;

    procedure OnModify(var Vend: Record Vendor)
    var
        Cont: Record Contact;
        OldCont: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        ContNo: Code[20];
        NoSeries: Code[20];
        SalespersonCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnModify(Vend, ContBusRel, IsHandled);
        if not IsHandled then begin
            with ContBusRel do begin
                SetCurrentKey("Link to Table", "No.");
                SetRange("Link to Table", "Link to Table"::Vendor);
                SetRange("No.", Vend."No.");
                if not FindFirst() then
                    exit;
                if not Cont.Get("Contact No.") then begin
                    Delete();
                    Session.LogMessage('0000B36', VendContactUpdateTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VendContactUpdateCategoryTxt);
                    exit;
                end;
                OldCont := Cont;
            end;

            ContNo := Cont."No.";
            NoSeries := Cont."No. Series";
            SalespersonCode := Cont."Salesperson Code";

            OnBeforeTransferFieldsFromVendToCont(Cont, Vend);
            Cont.Validate("E-Mail", Vend."E-Mail");

            Cont.TransferFields(Vend);
            OnAfterTransferFieldsFromVendToCont(Cont, Vend);

            IsHandled := false;
            OnModifyOnBeforeAssignNo(Cont, IsHandled);
            if not IsHandled then begin
                Cont."No." := ContNo;
                Cont."No. Series" := NoSeries;
            end;
            Cont."Salesperson Code" := SalespersonCode;
            Cont.Validate(Name);
            Cont.DoModify(OldCont);
            Cont.Modify(true);

            Vend.Get(Vend."No.");
        end;
        OnAfterOnModify(Cont, OldCont, Vend);
    end;

    procedure OnDelete(var Vend: Record Vendor)
    var
        ContBusRel: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Vend, ContBusRel, IsHandled);
        if IsHandled then
            exit;

        with ContBusRel do begin
            SetCurrentKey("Link to Table", "No.");
            SetRange("Link to Table", "Link to Table"::Vendor);
            SetRange("No.", Vend."No.");
            DeleteAll(true);
        end;
    end;

    procedure InsertNewContact(var Vend: Record Vendor; LocalCall: Boolean)
    var
        Cont: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertNewContact(Vend, LocalCall, IsHandled);
        if IsHandled then
            exit;

        if not LocalCall then begin
            RMSetup.Get();
            RMSetup.TestField("Bus. Rel. Code for Vendors");
        end;

        if ContBusRel.UpdateEmptyNoForContact(Vend."No.", Vend."Primary Contact No.", ContBusRel."Link to Table"::Vendor) then
            exit;

        with Cont do begin
            Init();
            TransferFields(Vend);
            OnAfterTransferFieldsFromVendToCont(Cont, Vend);
            Validate(Name);
            Validate("E-Mail");
            IsHandled := false;
            OnInsertNewContactOnBeforeAssignNo(Cont, IsHandled, Vend, RMSetup, LocalCall);
            if not IsHandled then begin
                "No." := '';
                "No. Series" := '';
                RMSetup.TestField("Contact Nos.");
                NoSeriesMgt.InitSeries(RMSetup."Contact Nos.", '', 0D, "No.", "No. Series");
            end;
            Type := Type::Company;
            TypeChange();
            SetSkipDefault();
            OnBeforeContactInsert(Cont, Vend);
            Insert(true);
            OnInsertNewContactOnAfterContactInsert(Cont, Vend);
        end;

        with ContBusRel do begin
            Init();
            "Contact No." := Cont."No.";
            "Business Relation Code" := RMSetup."Bus. Rel. Code for Vendors";
            "Link to Table" := "Link to Table"::Vendor;
            "No." := Vend."No.";
            OnInsertNewContactOnBeforeContBusRelInsert(ContBusRel, Cont, Vend);
            Insert(true);
        end;
    end;

    procedure InsertNewContactPerson(var Vend: Record Vendor; LocalCall: Boolean)
    var
        Cont: Record Contact;
        ContComp: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        if not LocalCall then begin
            RMSetup.Get();
            RMSetup.TestField("Bus. Rel. Code for Vendors");
        end;

        ContBusRel.SetCurrentKey("Link to Table", "No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
        ContBusRel.SetRange("No.", Vend."No.");
        if ContBusRel.FindFirst() then
            if ContComp.Get(ContBusRel."Contact No.") then
                with Cont do begin
                    Init();
                    "No." := '';
                    OnInsertNewContactPersonOnBeforeContactInsert(Cont, Vend);
                    Insert(true);
                    "Company No." := ContComp."No.";
                    Type := Type::Person;
                    Validate(Name, Vend.Contact);
                    InheritCompanyToPersonData(ContComp);
                    UpdateBusinessRelation();
                    OnInsertNewContactPersonOnBeforeContactModify(Cont, Vend);
                    Modify(true);
                    Vend."Primary Contact No." := "No.";
                end
    end;

    procedure ContactNameIsBlank(VendorNo: Code[20]): Boolean
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        with ContactBusinessRelation do begin
            SetCurrentKey("Link to Table", "No.");
            SetRange("Link to Table", "Link to Table"::Vendor);
            SetRange("No.", VendorNo);
            if not FindFirst() then
                exit(false);
            if not Contact.Get("Contact No.") then
                exit(true);
            exit(Contact.Name = '');
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFieldsFromVendToCont(var Contact: Record Contact; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnModify(var Contact: Record Contact; var OldContact: Record Contact; var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferFieldsFromVendToCont(var Contact: Record Contact; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeContactInsert(var Contact: Record Contact; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewContact(var Vendor: Record Vendor; LocalCall: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(Vendor: Record Vendor; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModify(Vend: Record Vendor; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactPersonOnBeforeContactInsert(var Contact: Record Contact; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactPersonOnBeforeContactModify(var Contact: Record Contact; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactOnBeforeAssignNo(var Contact: Record Contact; var IsHandled: Boolean; Vendor: Record Vendor; MarketingSetup: Record "Marketing Setup"; LocalCall: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactOnBeforeContBusRelInsert(var ContactBusinessRelation: Record "Contact Business Relation"; Contact: Record Contact; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnBeforeAssignNo(var Contact: Record Contact; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertNewContactOnAfterContactInsert(var Contact: Record "Contact"; var Vendor: Record "Vendor")
    begin
    end;
}

