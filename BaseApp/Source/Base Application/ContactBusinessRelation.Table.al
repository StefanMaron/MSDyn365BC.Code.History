table 5054 "Contact Business Relation"
{
    Caption = 'Contact Business Relation';
    DrillDownPageID = "Contact Business Relations";

    fields
    {
        field(1; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            NotBlank = true;
            TableRelation = Contact WHERE(Type = CONST(Company));

            trigger OnValidate()
            begin
                if "Contact No." <> '' then
                    Validate("Business Relation Code");
            end;
        }
        field(2; "Business Relation Code"; Code[10])
        {
            Caption = 'Business Relation Code';
            NotBlank = true;
            TableRelation = "Business Relation";

            trigger OnValidate()
            var
                RMSetup: Record "Marketing Setup";
                Cust: Record Customer;
                Vend: Record Vendor;
                BankAcc: Record "Bank Account";
            begin
                if ("No." = '') and
                   ("Contact No." <> '') and
                   ("Business Relation Code" <> '') and
                   (CurrFieldNo <> 0)
                then begin
                    RMSetup.Get();
                    if "Business Relation Code" = RMSetup."Bus. Rel. Code for Customers" then
                        Error(Text001,
                          FieldCaption("Business Relation Code"), "Business Relation Code",
                          Cont.TableCaption, Cust.TableCaption);
                    if "Business Relation Code" = RMSetup."Bus. Rel. Code for Vendors" then
                        Error(Text001,
                          FieldCaption("Business Relation Code"), "Business Relation Code",
                          Cont.TableCaption, Vend.TableCaption);
                    if "Business Relation Code" = RMSetup."Bus. Rel. Code for Bank Accs." then
                        Error(Text001,
                          FieldCaption("Business Relation Code"), "Business Relation Code",
                          Cont.TableCaption, BankAcc.TableCaption);
                end;
            end;
        }
        field(3; "Link to Table"; Enum "Contact Business Relation Link To Table")
        {
            Caption = 'Link to Table';
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF ("Link to Table" = CONST(Customer)) Customer
            ELSE
            IF ("Link to Table" = CONST(Vendor)) Vendor
            ELSE
            IF ("Link to Table" = CONST("Bank Account")) "Bank Account";
        }
        field(5; "Business Relation Description"; Text[100])
        {
            CalcFormula = Lookup ("Business Relation".Description WHERE(Code = FIELD("Business Relation Code")));
            Caption = 'Business Relation Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Contact Name"; Text[100])
        {
            CalcFormula = Lookup (Contact.Name WHERE("No." = FIELD("Contact No.")));
            Caption = 'Contact Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Contact No.", "Business Relation Code")
        {
            Clustered = true;
        }
        key(Key2; "Link to Table", "No.")
        {
        }
        key(Key3; "Link to Table", "Contact No.")
        {
        }
        key(Key4; "Business Relation Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
    begin
        if "No." <> '' then begin
            if ContBusRel.FindByContact("Link to Table", "Contact No.") then
                Error(
                  Text000,
                  Cont.TableCaption, "Contact No.", TableCaption, "Link to Table", ContBusRel."No.");

            if ContBusRel.FindByRelation("Link to Table", "No.") then
                if GetContactBusinessRelation(ContBusRel) then
                    Error(
                      Text000,
                      "Link to Table", "No.", TableCaption, Cont.TableCaption, ContBusRel."Contact No.");

            ContBusRel.Reset();
            ContBusRel.SetRange("Contact No.", "Contact No.");
            ContBusRel.SetRange("Business Relation Code", "Business Relation Code");
            ContBusRel.SetRange("No.", '');
            ContBusRel.DeleteAll();
        end;
    end;

    var
        Text000: Label '%1 %2 already has a %3 with %4 %5.';
        Text001: Label '%1 %2 is used when a %3 is linked with a %4.';
        Cont: Record Contact;

    local procedure GetContactBusinessRelation(ContactBusinessRelation: Record "Contact Business Relation"): Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        RecordRead: Boolean;
    begin
        case ContactBusinessRelation."Link to Table" of
            ContactBusinessRelation."Link to Table"::"Bank Account":
                RecordRead := BankAccount.Get(ContactBusinessRelation."No.");
            ContactBusinessRelation."Link to Table"::Customer:
                RecordRead := Customer.Get(ContactBusinessRelation."No.");
            ContactBusinessRelation."Link to Table"::Vendor:
                RecordRead := Vendor.Get(ContactBusinessRelation."No.");
        end;
        OnGetContactBusinessRelation(ContactBusinessRelation, RecordRead);
        exit(RecordRead);
    end;

    procedure FindByContact(LinkType: Option; ContactNo: Code[20]): Boolean
    begin
        Reset;
        SetCurrentKey("Link to Table", "Contact No.");
        SetRange("Link to Table", LinkType);
        SetRange("Contact No.", ContactNo);
        exit(FindFirst);
    end;

    procedure FindByRelation(LinkType: Option; LinkNo: Code[20]): Boolean
    begin
        Reset;
        SetCurrentKey("Link to Table", "No.");
        SetRange("Link to Table", LinkType);
        SetRange("No.", LinkNo);
        exit(FindFirst);
    end;

    procedure GetContactNo(LinkType: Option; LinkNo: Code[20]): Code[20]
    begin
        if FindByRelation(LinkType, LinkNo) then
            exit("Contact No.");
        exit('');
    end;

    procedure CreateRelation(ContactNo: Code[20]; LinkNo: Code[20]; LinkToTable: Option)
    begin
        Init;
        "Contact No." := ContactNo;
        "Business Relation Code" := GetBusinessRelationCodeFromSetup(LinkToTable);
        "Link to Table" := LinkToTable;
        "No." := LinkNo;
        Insert(true);
    end;

    procedure FindOrRestoreContactBusinessRelation(var Cont: Record Contact; RecVar: Variant; LinkToTable: Option)
    var
        ContCompany: Record Contact;
        CustContUpdate: Codeunit "CustCont-Update";
        VendContUpdate: Codeunit "VendCont-Update";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(RecVar);
        FieldRef := RecRef.Field(1);

        if not FindByRelation(LinkToTable, Format(FieldRef.Value)) then
            if Cont.Type = Cont.Type::Person then
                if ContCompany.Get(Cont."Company No.") then begin
                    ContCompany.CheckForExistingRelationships(LinkToTable);
                    CreateRelation(ContCompany."No.", Format(FieldRef.Value), LinkToTable);
                end else begin
                    case RecRef.Number of
                        DATABASE::Customer:
                            CustContUpdate.OnInsert(RecVar);
                        DATABASE::Vendor:
                            VendContUpdate.OnInsert(RecVar);
                    end;
                    FindFirst;
                    Cont.Validate("Company No.", "Contact No.");
                    Cont.Modify(true);
                end;
    end;

    local procedure GetBusinessRelationCodeFromSetup(LinkToTable: Option): Code[10]
    var
        MarketingSetup: Record "Marketing Setup";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        MarketingSetup.Get();
        case LinkToTable of
            ContactBusinessRelation."Link to Table"::Customer:
                begin
                    MarketingSetup.TestField("Bus. Rel. Code for Customers");
                    exit(MarketingSetup."Bus. Rel. Code for Customers");
                end;
            ContactBusinessRelation."Link to Table"::Vendor:
                begin
                    MarketingSetup.TestField("Bus. Rel. Code for Vendors");
                    exit(MarketingSetup."Bus. Rel. Code for Vendors");
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateEmptyNoForContact(EntityNo: Code[20]; PrimaryContactNo: Code[20]; LinkToTableOption: Option): Boolean
    var
        PersonContact: Record Contact;
        CompanyContact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        if (EntityNo = '') or (PrimaryContactNo = '') then
            exit(false);

        if not PersonContact.Get(PrimaryContactNo) then
            exit(false);

        if PersonContact.Type <> PersonContact.Type::Person then
            exit(false);

        if CompanyContact.Get(PersonContact."Company No.") then
            if ContactBusinessRelation.FindByContact(LinkToTableOption, CompanyContact."No.") then
                if ContactBusinessRelation."No." = '' then begin
                    ContactBusinessRelation."No." := EntityNo;
                    ContactBusinessRelation.Modify();
                    exit(true);
                end;

        exit(false);
    end;

    procedure FindContactsByRelation(var Contact: Record Contact; LinkType: Option; LinkNo: Code[20]): Boolean
    begin
        if FindByRelation(LinkType, LinkNo) then begin
            Contact.SetRange("Company No.", "Contact No.");
            if Contact.IsEmpty then begin
                Contact.SetRange("Company No.");
                Contact.SetRange("No.", "Contact No.");
            end;
            exit(Contact.FindSet());
        end;
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetContactBusinessRelation(var ContactBusinessRelation: Record "Contact Business Relation"; var RecordRead: Boolean)
    begin
    end;
}

