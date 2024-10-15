table 31050 "Credit Header"
{
    Caption = 'Credit Header';
    DataCaptionFields = "No.", Description;
    LookupPageID = "Credits List";

    fields
    {
        field(5; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            var
                CreditsSetup: Record "Credits Setup";
                NoSeriesMgt: Codeunit NoSeriesManagement;
            begin
                if "No." <> xRec."No." then begin
                    CreditsSetup.Get;
                    NoSeriesMgt.TestManual(CreditsSetup."Credit Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(15; "Company No."; Code[20])
        {
            Caption = 'Company No.';
            TableRelation = IF (Type = CONST(Customer)) Customer
            ELSE
            IF (Type = CONST(Vendor)) Vendor
            ELSE
            IF (Type = CONST(Contact)) Contact."No." WHERE(Type = CONST(Company));

            trigger OnValidate()
            var
                Cust: Record Customer;
                Vend: Record Vendor;
                Contact: Record Contact;
            begin
                TestField(Status, Status::Open);
                case Type of
                    Type::Customer:
                        begin
                            if not Cust.Get("Company No.") then
                                Clear(Cust);

                            InitCompanyInformation(
                              Cust.Name,
                              Cust."Name 2",
                              Cust.Address,
                              Cust."Address 2",
                              Cust.City,
                              Cust.Contact,
                              Cust."Post Code",
                              Cust."Country/Region Code",
                              Cust.County);
                        end;
                    Type::Vendor:
                        begin
                            if not Vend.Get("Company No.") then
                                Clear(Vend);

                            InitCompanyInformation(
                              Vend.Name,
                              Vend."Name 2",
                              Vend.Address,
                              Vend."Address 2",
                              Vend.City,
                              Vend.Contact,
                              Vend."Post Code",
                              Vend."Country/Region Code",
                              Vend.County);
                        end;
                    Type::Contact:
                        begin
                            if not Contact.Get("Company No.") then
                                Clear(Contact);

                            InitCompanyInformation(
                              Contact.Name,
                              Contact."Name 2",
                              Contact.Address,
                              Contact."Address 2",
                              Contact.City,
                              '',
                              Contact."Post Code",
                              Contact."Country/Region Code",
                              Contact.County);
                        end;
                end;
            end;
        }
        field(20; "Company Name"; Text[100])
        {
            Caption = 'Company Name';
        }
        field(25; "Company Name 2"; Text[50])
        {
            Caption = 'Company Name 2';
        }
        field(30; "Company Address"; Text[100])
        {
            Caption = 'Company Address';
        }
        field(35; "Company Address 2"; Text[50])
        {
            Caption = 'Company Address 2';
        }
        field(40; "Company City"; Text[30])
        {
            Caption = 'Company City';
            TableRelation = "Post Code".City;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Company City", "Company Post Code", "Company County", "Company Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(45; "Company Contact"; Text[100])
        {
            Caption = 'Company Contact';
        }
        field(46; "Company County"; Text[30])
        {
            Caption = 'Company County';
        }
        field(47; "Company Country/Region Code"; Code[10])
        {
            Caption = 'Company Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(50; "Company Post Code"; Code[20])
        {
            Caption = 'Company Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Company City", "Company Post Code", "Company County", "Company Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(55; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(60; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released,Pending Approval';
            OptionMembers = Open,Released,"Pending Approval";
        }
        field(65; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(70; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                Validate("Posting Date", "Document Date");
            end;
        }
        field(75; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(80; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(90; "Balance (LCY)"; Decimal)
        {
            CalcFormula = Sum ("Credit Line"."Ledg. Entry Rem. Amt. (LCY)" WHERE("Credit No." = FIELD("No.")));
            Caption = 'Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(95; "Credit Balance (LCY)"; Decimal)
        {
            CalcFormula = Sum ("Credit Line"."Amount (LCY)" WHERE("Credit No." = FIELD("No.")));
            Caption = 'Credit Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(100; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Customer,Vendor,Contact';
            OptionMembers = Customer,Vendor,Contact;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if Type <> xRec.Type then
                    Validate("Company No.", '');
            end;
        }
        field(165; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";

            trigger OnValidate()
            var
                IncomingDocument: Record "Incoming Document";
            begin
                if "Incoming Document Entry No." = xRec."Incoming Document Entry No." then
                    exit;
                if "Incoming Document Entry No." = 0 then
                    IncomingDocument.RemoveReferenceToWorkingDocument(xRec."Incoming Document Entry No.")
                else
                    IncomingDocument.SetCreditDoc(Rec);
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        CreditLine: Record "Credit Line";
    begin
        TestField(Status, Status::Open);

        Validate("Incoming Document Entry No.", 0);

        ApprovalsMgmt.DeleteApprovalEntryForRecord(Rec);

        CreditLine.SetRange("Credit No.", "No.");
        CreditLine.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        CreditsSetup: Record "Credits Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        CreditsSetup.Get;
        if "No." = '' then begin
            CreditsSetup.TestField("Credit Nos.");
            NoSeriesMgt.InitSeries(CreditsSetup."Credit Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;
        "User ID" := UserId;
    end;

    trigger OnRename()
    begin
        Error(RenameErr, TableCaption);
    end;

    var
        PostCode: Record "Post Code";
        RenameErr: Label 'You cannot rename a %1.', Comment = '%1 = TABLECAPTION';
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ApprovalProcessPrintErr: Label 'This document can only be printed when the approval process is complete.';

    [Scope('OnPrem')]
    procedure AssistEdit(OldCreditHeader: Record "Credit Header"): Boolean
    var
        CreditHeader: Record "Credit Header";
        CreditsSetup: Record "Credits Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        with CreditHeader do begin
            Copy(Rec);
            CreditsSetup.Get;
            CreditsSetup.TestField("Credit Nos.");
            if NoSeriesMgt.SelectSeries(CreditsSetup."Credit Nos.", OldCreditHeader."No. Series", "No. Series") then begin
                CreditsSetup.Get;
                CreditsSetup.TestField("Credit Nos.");
                NoSeriesMgt.SetSeries("No.");
                Rec := CreditHeader;
                exit(true);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        CreditReportSelections: Record "Credit Report Selections";
        CreditHeader: Record "Credit Header";
    begin
        with CreditHeader do begin
            Copy(Rec);
            OnCheckCreditPrintRestrictions;
            FindFirst;
            CreditReportSelections.SetRange(Usage, CreditReportSelections.Usage::Credit);
            CreditReportSelections.SetFilter("Report ID", '<>0');
            CreditReportSelections.Find('-');
            repeat
                REPORT.RunModal(CreditReportSelections."Report ID", ShowRequestForm, false, CreditHeader);
            until CreditReportSelections.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformManualPrintRecords(ShowRequestForm: Boolean)
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if ApprovalsMgmt.IsCreditApprovalsWorkflowEnabled(Rec) and (Status = Status::Open) then
            Error(ApprovalProcessPrintErr);

        PrintRecords(ShowRequestForm);
    end;

    [Scope('OnPrem')]
    procedure SendToPosting(PostingCodeunitID: Integer)
    begin
        if not IsApprovedPosting then
            exit;

        CODEUNIT.Run(PostingCodeunitID, Rec);
    end;

    local procedure IsApprovedPosting(): Boolean
    begin
        if ApprovalsMgmt.PrePostApprovalCheckCredit(Rec) then
            exit(true);
    end;

    local procedure InitCompanyInformation(CompanyName: Text[100]; CompanyName2: Text[50]; CompanyAddress: Text[100]; CompanyAddress2: Text[50]; CompanyCity: Text[30]; CompanyContact: Text[100]; CompanyPostCode: Code[20]; CompanyCountryRegionCode: Code[10]; CompanyCounty: Text[30])
    begin
        "Company Name" := CompanyName;
        "Company Name 2" := CompanyName2;
        "Company Address" := CompanyAddress;
        "Company Address 2" := CompanyAddress2;
        "Company City" := CompanyCity;
        "Company Contact" := CompanyContact;
        "Company Post Code" := CompanyPostCode;
        "Company Country/Region Code" := CompanyCountryRegionCode;
        "Company County" := CompanyCounty;
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('OnPrem')]
    procedure OnCheckCreditReleaseRestrictions()
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('OnPrem')]
    procedure OnCheckCreditPostRestrictions()
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('OnPrem')]
    procedure OnCheckCreditPrintRestrictions()
    begin
    end;
}

