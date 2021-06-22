codeunit 5058 "BankCont-Update"
{

    trigger OnRun()
    begin
    end;

    var
        RMSetup: Record "Marketing Setup";
        BankContactUpdateCategoryTxt: Label 'Bank Contact Orphaned Links', Locked = true;
        BankContactUpdateTelemetryMsg: Label 'Contact %1 does not exist. The contact business relation with code %2 which points to it has been deleted', Locked = true;

    procedure OnInsert(var BankAcc: Record "Bank Account")
    begin
        RMSetup.Get();
        if RMSetup."Bus. Rel. Code for Bank Accs." = '' then
            exit;

        InsertNewContact(BankAcc, true);
    end;

    procedure OnModify(var BankAcc: Record "Bank Account")
    var
        Cont: Record Contact;
        OldCont: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        ContNo: Code[20];
        NoSeries: Code[20];
        SalespersonCode: Code[20];
    begin
        with ContBusRel do begin
            SetCurrentKey("Link to Table", "No.");
            SetRange("Link to Table", "Link to Table"::"Bank Account");
            SetRange("No.", BankAcc."No.");
            if not FindFirst then
                exit;
            if not Cont.Get("Contact No.") then begin
                Delete();
                SendTraceTag('0000B38', BankContactUpdateCategoryTxt, Verbosity::Normal, StrSubstNo(BankContactUpdateTelemetryMsg, "Contact No.", "Business Relation Code"), DataClassification::EndUserIdentifiableInformation);
                exit;
            end;
            OldCont := Cont;
        end;

        ContNo := Cont."No.";
        NoSeries := Cont."No. Series";
        SalespersonCode := Cont."Salesperson Code";
        Cont.Validate("E-Mail", BankAcc."E-Mail");
        Cont.TransferFields(BankAcc);
        OnAfterTransferFieldsFromBankAccToCont(Cont, BankAcc);
        Cont."No." := ContNo;
        Cont."No. Series" := NoSeries;
        Cont."Salesperson Code" := SalespersonCode;
        Cont.Validate(Name);
        Cont.DoModify(OldCont);
        Cont.Modify(true);

        BankAcc.Get(BankAcc."No.");
    end;

    procedure OnDelete(var BankAcc: Record "Bank Account")
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        with ContBusRel do begin
            SetCurrentKey("Link to Table", "No.");
            SetRange("Link to Table", "Link to Table"::"Bank Account");
            SetRange("No.", BankAcc."No.");
            DeleteAll(true);
        end;
    end;

    procedure InsertNewContact(var BankAcc: Record "Bank Account"; LocalCall: Boolean)
    var
        Cont: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertNewContact(BankAcc, LocalCall, IsHandled);
        if IsHandled then
            exit;

        if not LocalCall then begin
            RMSetup.Get();
            RMSetup.TestField("Bus. Rel. Code for Bank Accs.");
        end;

        with Cont do begin
            Init;
            TransferFields(BankAcc);
            Validate(Name);
            Validate("E-Mail");
            "No." := '';
            "No. Series" := '';
            RMSetup.TestField("Contact Nos.");
            NoSeriesMgt.InitSeries(RMSetup."Contact Nos.", '', 0D, "No.", "No. Series");
            Type := Type::Company;
            TypeChange;
            SetSkipDefault;
            OnBeforeContactInsert(Cont, BankAcc);
            Insert(true);
        end;

        with ContBusRel do begin
            Init;
            "Contact No." := Cont."No.";
            "Business Relation Code" := RMSetup."Bus. Rel. Code for Bank Accs.";
            "Link to Table" := "Link to Table"::"Bank Account";
            "No." := BankAcc."No.";
            Insert(true);
        end;
    end;

    procedure ContactNameIsBlank(BankAccountNo: Code[20]): Boolean
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        with ContactBusinessRelation do begin
            SetCurrentKey("Link to Table", "No.");
            SetRange("Link to Table", "Link to Table"::"Bank Account");
            SetRange("No.", BankAccountNo);
            if not FindFirst then
                exit(false);
            if not Contact.Get("Contact No.") then
                exit(true);
            exit(Contact.Name = '');
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFieldsFromBankAccToCont(var Contact: Record Contact; BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewContact(var BankAccount: Record "Bank Account"; LocalCall: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeContactInsert(var Contact: Record Contact; BankAccount: Record "Bank Account")
    begin
    end;
}

