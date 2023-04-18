table 413 "IC Partner"
{
    Caption = 'IC Partner';
    LookupPageID = "IC Partner List";
    Permissions = TableData "G/L Entry" = rm;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        field(4; "Inbox Type"; Enum "IC Partner Inbox Type")
        {
            Caption = 'Inbox Type';
            InitValue = Database;

            trigger OnValidate()
            var
                Cust: Record Customer;
                Vend: Record Vendor;
            begin
                if "Inbox Type" <> xRec."Inbox Type" then
                    "Inbox Details" := '';
                if "Inbox Type" = "Inbox Type"::Email then
                    if "Customer No." <> '' then begin
                        if Cust.Get("Customer No.") then
                            "Inbox Details" := Cust."E-Mail";
                    end else
                        if "Vendor No." <> '' then
                            if Vend.Get("Vendor No.") then
                                "Inbox Details" := Vend."E-Mail";
            end;
        }
        field(5; "Inbox Details"; Text[250])
        {
            Caption = 'Inbox Details';
            TableRelation = IF ("Inbox Type" = CONST(Database)) Company.Name;

            trigger OnLookup()
            var
                Company: Record Company;
                Companies: Page Companies;
                FileName: Text;
            begin
                case "Inbox Type" of
                    "Inbox Type"::Database:
                        begin
                            Company.SetFilter(Name, '<>%1', CompanyName);
                            Companies.SetTableView(Company);
                            Companies.LookupMode := true;
                            if Companies.RunModal() = ACTION::LookupOK then begin
                                Companies.GetRecord(Company);
                                "Inbox Details" := Company.Name;
                            end;
                        end;
                    "Inbox Type"::"File Location":
                        if "Inbox Details" = '' then
                            FileName := StrSubstNo('%1.xml', Code)
                        else
                            FileName := "Inbox Details" + StrSubstNo('\%1.xml', Code);
                end;
                AutosetICPartnerDetails();
            end;
        }
        field(6; "Receivables Account"; Code[20])
        {
            Caption = 'Receivables Account';
            TableRelation = "G/L Account"."No.";
        }
        field(7; "Payables Account"; Code[20])
        {
            Caption = 'Payables Account';
            TableRelation = "G/L Account"."No.";
        }
        field(8; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(10; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = Exist("Comment Line" WHERE("Table Name" = CONST("IC Partner"),
                                                      "No." = FIELD(Code)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(13; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(14; "Outbound Sales Item No. Type"; Enum "IC Outb. Sales Item No. Type")
        {
            Caption = 'Outbound Sales Item No. Type';
        }
        field(15; "Outbound Purch. Item No. Type"; Enum "IC Outb. Purch. Item No. Type")
        {
            Caption = 'Outbound Purch. Item No. Type';
        }
        field(16; "Cost Distribution in LCY"; Boolean)
        {
            Caption = 'Cost Distribution in LCY';
        }
        field(17; "Auto. Accept Transactions"; Boolean)
        {
            Caption = 'Auto. Accept Transactions';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        GLEntry: Record "G/L Entry";
        GLSetup: Record "General Ledger Setup";
        AccountingPeriod: Record "Accounting Period";
        Cust: Record Customer;
        Vend: Record Vendor;
        ICInbox: Record "IC Inbox Transaction";
        ICOutbox: Record "IC Outbox Transaction";
    begin
        GLEntry.SetRange("IC Partner Code", Code);
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            GLEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not GLEntry.IsEmpty() then
            Error(Text000, xRec.Code);

        GLSetup.Get();
        if GLSetup."Allow G/L Acc. Deletion Before" <> 0D then begin
            GLEntry.SetFilter("Posting Date", '>=%1', GLSetup."Allow G/L Acc. Deletion Before");
            if not GLEntry.IsEmpty() then
                Error(Text001, Code, GLSetup."Allow G/L Acc. Deletion Before");
        end;

        if "Customer No." <> '' then
            if Cust.Get("Customer No.") then
                Error(Text002, Code, Cust.TableCaption(), Cust."No.");

        if "Vendor No." <> '' then
            if Vend.Get("Vendor No.") then
                Error(Text002, Code, Vend.TableCaption(), Vend."No.");

        ICInbox.SetRange("IC Partner Code", Code);
        if not ICInbox.IsEmpty() then
            Error(Text003, Code, ICInbox.TableCaption());

        ICOutbox.SetRange("IC Partner Code", Code);
        if not ICOutbox.IsEmpty() then
            Error(Text003, Code, ICOutbox.TableCaption());

        GLEntry.Reset();
        GLEntry.SetCurrentKey("IC Partner Code");
        GLEntry.SetRange("IC Partner Code", Code);
        GLEntry.ModifyAll("IC Partner Code", '');

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::"IC Partner");
        CommentLine.SetRange("No.", Code);
        CommentLine.DeleteAll();

        DimMgt.DeleteDefaultDim(DATABASE::"IC Partner", Code);
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::"IC Partner", xRec.Code, Code);
        CommentLine.RenameCommentLine(CommentLine."Table Name"::"IC Partner", xRec.Code, Code);
    end;

    var
        CommentLine: Record "Comment Line";
        DimMgt: Codeunit DimensionManagement;
        Text000: Label 'You cannot delete IC Partner %1 because it has ledger entries in a fiscal year that has not been closed yet.';
        Text001: Label 'You cannot delete IC Partner %1 because it has ledger entries after %2.';
        Text002: Label 'You cannot delete IC Partner %1 because it is used for %2 %3';
        Text003: Label 'You cannot delete IC Partner %1 because it is used in %2';
        Text004: Label '%1 %2 is linked to a blocked IC Partner.';
        CantFindCompanyErr: Label 'The selected company cannot be found.';
        CompanyNotICConfiguredErr: Label 'The selected company has not been configured for using intercompany.';
        PartnerCompanySameICSetupCodeErr: Label 'The partner company has been configured with the same Intercompany code as this company. This can cause issues when using intercompany features.';

    procedure CheckICPartner()
    begin
        TestField(Blocked, false);
    end;

    procedure CheckICPartnerIndirect(AccountType: Text[250]; AccountNo: Code[20])
    begin
        if Blocked then
            Error(Text004, AccountType, AccountNo);
    end;

    procedure PropagateCustomerICPartner(PreviousCustomerNo: Code[20]; NewCustomerNo: Code[20]; ICPartnerCode: Code[20])
    var
        Customer: Record Customer;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IJ0', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUsage('0000IJ2', ICMapping.GetFeatureTelemetryName(), 'Propagate Customer IC Partner');

        if (PreviousCustomerNo <> NewCustomerNo) and Customer.Get(PreviousCustomerNo) then begin
            Customer.Validate("IC Partner Code", '');
            Customer.Modify();
        end;

        if Customer.Get(NewCustomerNo) then begin
            Customer.Validate("IC Partner Code", ICPartnerCode);
            Customer.Modify();
        end;
    end;

    procedure PropagateVendorICPartner(PreviousVendorNo: Code[20]; NewVendorNo: Code[20]; ICPartnerCode: Code[20])
    var
        Vendor: Record Vendor;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IJ1', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUsage('0000IJ3', ICMapping.GetFeatureTelemetryName(), 'Propagate Vendor IC Partner');

        if (PreviousVendorNo <> NewVendorNo) and Vendor.Get(PreviousVendorNo) then begin
            Vendor.Validate("IC Partner Code", '');
            Vendor.Modify();
        end;

        if Vendor.Get(NewVendorNo) then begin
            Vendor.Validate("IC Partner Code", ICPartnerCode);
            Vendor.Modify();
        end;
    end;

    local procedure AutosetICPartnerDetails()
    var
        Company: Record Company;
    begin
        if Rec."Inbox Type" <> Rec."Inbox Type"::Database then
            exit;
        if not Company.Get(Rec."Inbox Details") then
            Error(CantFindCompanyErr);

        AutosetICPartnerName(Company);
        AutosetICPartnerCurrency(Company);
        AutosetICPartnerCountry(Company);
    end;

    local procedure AutosetICPartnerName(Company: Record Company)
    var
        MyICSetup: Record "IC Setup";
        OtherICSetup: Record "IC Setup";
    begin
        if not MyICSetup.Get() then begin
            MyICSetup.Init();
            MyICSetup.Insert();
        end;

        if not OtherICSetup.ChangeCompany(Company.Name) then
            Error(CantFindCompanyErr);

        if not OtherICSetup.ReadPermission() then
            exit;
        if not OtherICSetup.Get() then begin
            if System.GuiAllowed() then
                Message(CompanyNotICConfiguredErr);
            exit;
        end;
        if OtherICSetup."IC Partner Code" = '' then begin
            if System.GuiAllowed() then
                Message(CompanyNotICConfiguredErr);
            exit;
        end;
        if OtherICSetup."IC Partner Code" = MyICSetup."IC Partner Code" then
            if System.GuiAllowed() then
                Message(PartnerCompanySameICSetupCodeErr);
        Rec.Code := OtherICSetup."IC Partner Code";
        Rec.Name := CopyStr(Company."Display Name", 1, MaxStrLen(Rec.Name));
        if Rec.Name = '' then
            Rec.Name := Company.Name;
    end;

    local procedure AutosetICPartnerCurrency(Company: Record Company)
    var
        PartnerGeneralLedgerSetup: Record "General Ledger Setup";
        CurrentCompanyGeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not PartnerGeneralLedgerSetup.ChangeCompany(Company.Name) then
            Error(CantFindCompanyErr);
        if not PartnerGeneralLedgerSetup.ReadPermission() then
            exit;
        if not PartnerGeneralLedgerSetup.Get() then
            exit;
        if not CurrentCompanyGeneralLedgerSetup.Get() then
            exit;

        if CurrentCompanyGeneralLedgerSetup."LCY Code" <> PartnerGeneralLedgerSetup."LCY Code" then
            Rec."Currency Code" := PartnerGeneralLedgerSetup."LCY Code";
    end;

    local procedure AutosetICPartnerCountry(Company: Record Company)
    var
        CompanyInformation: Record "Company Information";
    begin
        if not CompanyInformation.ChangeCompany(Company.Name) then
            Error(CantFindCompanyErr);
        if not CompanyInformation.ReadPermission() then
            exit;
        if not CompanyInformation.Get() then
            exit;
        Rec."Country/Region Code" := CompanyInformation."Country/Region Code";
    end; 

}

