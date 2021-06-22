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
        field(4; "Inbox Type"; Option)
        {
            Caption = 'Inbox Type';
            InitValue = Database;
            OptionCaption = 'File Location,Database,Email,No IC Transfer';
            OptionMembers = "File Location",Database,Email,"No IC Transfer";

            trigger OnValidate()
            var
                Cust: Record Customer;
                Vend: Record Vendor;
            begin
                if "Inbox Type" <> xRec."Inbox Type" then
                    "Inbox Details" := '';
                if "Inbox Type" = "Inbox Type"::Email then begin
                    if "Customer No." <> '' then begin
                        if Cust.Get("Customer No.") then
                            "Inbox Details" := Cust."E-Mail";
                    end else
                        if "Vendor No." <> '' then
                            if Vend.Get("Vendor No.") then
                                "Inbox Details" := Vend."E-Mail";
                end;
            end;
        }
        field(5; "Inbox Details"; Text[250])
        {
            Caption = 'Inbox Details';
            TableRelation = IF ("Inbox Type" = CONST(Database)) Company.Name;

            trigger OnLookup()
            var
                Company: Record Company;
                FileMgt: Codeunit "File Management";
                Companies: Page Companies;
                FileName: Text;
                FileName2: Text;
                Path: Text;
            begin
                case "Inbox Type" of
                    "Inbox Type"::Database:
                        begin
                            Company.SetFilter(Name, '<>%1', CompanyName);
                            Companies.SetTableView(Company);
                            Companies.LookupMode := true;
                            if Companies.RunModal = ACTION::LookupOK then begin
                                Companies.GetRecord(Company);
                                "Inbox Details" := Company.Name;
                            end;
                        end;
                    "Inbox Type"::"File Location":
                        begin
                            if "Inbox Details" = '' then
                                FileName := StrSubstNo('%1.xml', Code)
                            else
                                FileName := "Inbox Details" + StrSubstNo('\%1.xml', Code);

                            FileName2 := FileMgt.SaveFileDialog(Text005, FileName, '');
                            if FileName <> FileName2 then begin
                                Path := FileMgt.GetDirectoryName(FileName2);
                                if Path <> '' then
                                    "Inbox Details" := CopyStr(Path, 1, 250);
                            end;
                        end;
                end;
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
        field(10; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = Exist ("Comment Line" WHERE("Table Name" = CONST("IC Partner"),
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
        field(14; "Outbound Sales Item No. Type"; Option)
        {
            Caption = 'Outbound Sales Item No. Type';
            OptionCaption = 'Internal No.,Common Item No.,Cross Reference';
            OptionMembers = "Internal No.","Common Item No.","Cross Reference";
        }
        field(15; "Outbound Purch. Item No. Type"; Option)
        {
            Caption = 'Outbound Purch. Item No. Type';
            OptionCaption = 'Internal No.,Common Item No.,Cross Reference,Vendor Item No.';
            OptionMembers = "Internal No.","Common Item No.","Cross Reference","Vendor Item No.";
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
        if AccountingPeriod.FindFirst then
            GLEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not GLEntry.IsEmpty then
            Error(Text000, xRec.Code);

        GLSetup.Get();
        if GLSetup."Allow G/L Acc. Deletion Before" <> 0D then begin
            GLEntry.SetFilter("Posting Date", '>=%1', GLSetup."Allow G/L Acc. Deletion Before");
            if not GLEntry.IsEmpty then
                Error(Text001, Code, GLSetup."Allow G/L Acc. Deletion Before");
        end;

        if "Customer No." <> '' then
            if Cust.Get("Customer No.") then
                Error(Text002, Code, Cust.TableCaption, Cust."No.");

        if "Vendor No." <> '' then
            if Vend.Get("Vendor No.") then
                Error(Text002, Code, Vend.TableCaption, Vend."No.");

        ICInbox.SetRange("IC Partner Code", Code);
        if not ICInbox.IsEmpty then
            Error(Text003, Code, ICInbox.TableCaption);

        ICOutbox.SetRange("IC Partner Code", Code);
        if not ICOutbox.IsEmpty then
            Error(Text003, Code, ICOutbox.TableCaption);

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
    end;

    var
        CommentLine: Record "Comment Line";
        Text000: Label 'You cannot delete IC Partner %1 because it has ledger entries in a fiscal year that has not been closed yet.';
        Text001: Label 'You cannot delete IC Partner %1 because it has ledger entries after %2.';
        Text002: Label 'You cannot delete IC Partner %1 because it is used for %2 %3';
        Text003: Label 'You cannot delete IC Partner %1 because it is used in %2';
        Text004: Label '%1 %2 is linked to a blocked IC Partner.';
        Text005: Label 'File Location for IC files';
        DimMgt: Codeunit DimensionManagement;

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
    begin
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
    begin
        if (PreviousVendorNo <> NewVendorNo) and Vendor.Get(PreviousVendorNo) then begin
            Vendor.Validate("IC Partner Code", '');
            Vendor.Modify();
        end;

        if Vendor.Get(NewVendorNo) then begin
            Vendor.Validate("IC Partner Code", ICPartnerCode);
            Vendor.Modify();
        end;
    end;
}

