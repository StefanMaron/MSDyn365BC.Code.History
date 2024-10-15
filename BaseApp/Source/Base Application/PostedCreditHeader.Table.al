table 31057 "Posted Credit Header"
{
    Caption = 'Posted Credit Header';
    DataCaptionFields = "No.", Description;
#if CLEAN18
    ObsoleteState = Removed;
#else
    LookupPageID = "Posted Credits List";
    ObsoleteState = Pending;
#endif
    ObsoleteReason = 'Moved to Compensation Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    fields
    {
        field(5; "No."; Code[20])
        {
            Caption = 'No.';
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
            IF (Type = CONST(Vendor)) Vendor;
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
            ValidateTableRelation = false;
        }
        field(45; "Company Contact"; Text[100])
        {
            Caption = 'Company Contact';
        }
        field(46; "Company County"; Text[30])
        {
            Caption = 'Company County';
            CaptionClass = '5,1,' + "Company Country/Region Code";
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
            ValidateTableRelation = false;
        }
        field(55; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(65; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(70; "Document Date"; Date)
        {
            Caption = 'Document Date';
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
#if not CLEAN18
        field(90; "Balance (LCY)"; Decimal)
        {
            CalcFormula = Sum("Posted Credit Line"."Ledg. Entry Rem. Amt. (LCY)" WHERE("Credit No." = FIELD("No.")));
            Caption = 'Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
#endif
        field(100; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Customer,Vendor,Contact';
            OptionMembers = Customer,Vendor,Contact;
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
#if not CLEAN18

    trigger OnDelete()
    var
        PostedCreditLine: Record "Posted Credit Line";
    begin
        LockTable();

        PostedCreditLine.SetRange("Credit No.", "No.");
        PostedCreditLine.DeleteAll(true);
    end;

    var
        PstdCreditHeader: Record "Posted Credit Header";

    [Scope('OnPrem')]
    [Obsolete('Moved to Compensation Localization Pack for Czech.', '18.0')]
    procedure Navigate()
    var
        NavigateForm: Page Navigate;
    begin
        NavigateForm.SetDoc("Posting Date", "No.");
        NavigateForm.Run;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Compensation Localization Pack for Czech.', '18.0')]
    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        CreditReportSelections: Record "Credit Report Selections";
    begin
        with PstdCreditHeader do begin
            Copy(Rec);
            FindFirst;
            CreditReportSelections.SetRange(Usage, CreditReportSelections.Usage::"Posted Credit");
            CreditReportSelections.SetFilter("Report ID", '<>0');
            CreditReportSelections.Find('-');
            repeat
                REPORT.RunModal(CreditReportSelections."Report ID", ShowRequestForm, false, PstdCreditHeader);
            until CreditReportSelections.Next() = 0;
        end;
    end;
#endif
}

