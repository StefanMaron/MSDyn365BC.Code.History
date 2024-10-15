table 11735 "Posted Cash Document Header"
{
    Caption = 'Posted Cash Document Header';
    DataCaptionFields = "Cash Desk No.", "Cash Document Type", "No.", "Pay-to/Receive-from Name";
#if CLEAN17
    ObsoleteState = Removed;
#else
    DrillDownPageID = "Posted Cash Document List";
    LookupPageID = "Posted Cash Document List";
    Permissions = TableData "Posted Cash Document Line" = rd;
    ObsoleteState = Pending;
#endif
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "Cash Desk No."; Code[20])
        {
            Caption = 'Cash Desk No.';
#if not CLEAN17
            TableRelation = "Bank Account" WHERE("Account Type" = CONST("Cash Desk"));

            trigger OnLookup()
            var
                CashDesk: Record "Bank Account";
            begin
                if not CashDesk.Get("Cash Desk No.") then
                    CashDesk."Account Type" := CashDesk."Account Type"::"Cash Desk";
                CashDesk.Lookup;
            end;
#endif
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Pay-to/Receive-from Name"; Text[100])
        {
            Caption = 'Pay-to/Receive-from Name';
        }
        field(4; "Pay-to/Receive-from Name 2"; Text[50])
        {
            Caption = 'Pay-to/Receive-from Name 2';
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
#if not CLEAN17
        field(7; Amount; Decimal)
        {
            CalcFormula = Sum("Posted Cash Document Line".Amount WHERE("Cash Desk No." = FIELD("Cash Desk No."),
                                                                        "Cash Document No." = FIELD("No.")));
            Caption = 'Amount';
            FieldClass = FlowField;
        }
        field(8; "Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum("Posted Cash Document Line"."Amount (LCY)" WHERE("Cash Desk No." = FIELD("Cash Desk No."),
                                                                                "Cash Document No." = FIELD("No.")));
            Caption = 'Amount (LCY)';
            FieldClass = FlowField;
        }
#endif
        field(13; "Cash Desk Report No."; Code[20])
        {
            Caption = 'Cash Desk Report No.';
        }
        field(15; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
        }
        field(17; "Created ID"; Code[50])
        {
            Caption = 'Created ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(18; "Released ID"; Code[50])
        {
            Caption = 'Released ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(19; "Posted ID"; Code[50])
        {
            Caption = 'Posted ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(20; "Cash Document Type"; Option)
        {
            Caption = 'Cash Document Type';
            OptionCaption = ' ,Receipt,Withdrawal';
            OptionMembers = " ",Receipt,Withdrawal;
        }
        field(21; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        field(23; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(24; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(25; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
        }
        field(30; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(35; "VAT Date"; Date)
        {
            Caption = 'VAT Date';
        }
        field(38; "Created Date"; Date)
        {
            Caption = 'Created Date';
        }
        field(40; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(42; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(45; "Amounts Including VAT"; Boolean)
        {
            Caption = 'Amounts Including VAT';
        }
#if not CLEAN17
        field(51; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Posted Cash Document Line"."VAT Base Amount" WHERE("Cash Desk No." = FIELD("Cash Desk No."),
                                                                                   "Cash Document No." = FIELD("No.")));
            Caption = 'VAT Base Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Posted Cash Document Line"."Amount Including VAT" WHERE("Cash Desk No." = FIELD("Cash Desk No."),
                                                                                        "Cash Document No." = FIELD("No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(55; "VAT Base Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum("Posted Cash Document Line"."VAT Base Amount (LCY)" WHERE("Cash Desk No." = FIELD("Cash Desk No."),
                                                                                         "Cash Document No." = FIELD("No.")));
            Caption = 'VAT Base Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "Amount Including VAT (LCY)"; Decimal)
        {
            CalcFormula = Sum("Posted Cash Document Line"."Amount Including VAT (LCY)" WHERE("Cash Desk No." = FIELD("Cash Desk No."),
                                                                                              "Cash Document No." = FIELD("No.")));
            Caption = 'Amount Including VAT (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
#endif
        field(60; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(61; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(62; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(65; "Payment Purpose"; Text[100])
        {
            Caption = 'Payment Purpose';
        }
        field(70; "Received By"; Text[80])
        {
            Caption = 'Received By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(71; "Identification Card No."; Code[10])
        {
            Caption = 'Identification Card No.';
        }
        field(72; "Paid By"; Text[100])
        {
            Caption = 'Paid By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(73; "Received From"; Text[100])
        {
            Caption = 'Received From';
        }
        field(74; "Paid To"; Text[100])
        {
            Caption = 'Paid To';
        }
        field(80; "Registration No."; Text[20])
        {
            Caption = 'Registration No.';
        }
        field(81; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(90; "Partner Type"; Option)
        {
            Caption = 'Partner Type';
            OptionCaption = ' ,Customer,Vendor,Contact,Salesperson/Purchaser,Employee';
            OptionMembers = " ",Customer,Vendor,Contact,"Salesperson/Purchaser",Employee;
        }
        field(91; "Partner No."; Code[20])
        {
            Caption = 'Partner No.';
            TableRelation = IF ("Partner Type" = CONST(Customer)) Customer
            ELSE
            IF ("Partner Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Partner Type" = CONST(Contact)) Contact
            ELSE
            IF ("Partner Type" = CONST("Salesperson/Purchaser")) "Salesperson/Purchaser"
            ELSE
            IF ("Partner Type" = CONST(Employee)) Employee;
        }
        field(98; "Canceled Document"; Boolean)
        {
            Caption = 'Canceled Document';
            Editable = false;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
#if not CLEAN17

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
#endif
        }
        field(31123; "EET Entry No."; Integer)
        {
            Caption = 'EET Entry No.';
#if CLEAN18
            ObsoleteState = Removed;
#else
            TableRelation = "EET Entry";
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
            ObsoleteTag = '18.0';
        }
#if not CLEAN18
        field(31124; "Receipt Serial No."; Code[50])
        {
            CalcFormula = Lookup("EET Entry"."Receipt Serial No." WHERE("Entry No." = FIELD("EET Entry No.")));
            Caption = 'Receipt Serial No.';
            Editable = false;
            FieldClass = FlowField;
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
            ObsoleteTag = '18.0';
        }
#endif
    }

    keys
    {
        key(Key1; "Cash Desk No.", "No.")
        {
            Clustered = true;
        }
        key(Key2; "Cash Desk No.", "Cash Document Type", "No.")
        {
        }
        key(Key3; "Cash Desk No.", "Posting Date")
        {
        }
        key(Key4; "External Document No.")
        {
        }
        key(Key5; "No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }
#if not CLEAN17

    trigger OnDelete()
    var
        PostedCashDocumentLine: Record "Posted Cash Document Line";
    begin
        PostedCashDocumentLine.SetRange("Cash Desk No.", "Cash Desk No.");
        PostedCashDocumentLine.SetRange("Cash Document No.", "No.");
        PostedCashDocumentLine.DeleteAll();
    end;

    var
        PostedCashDocHeader: Record "Posted Cash Document Header";
        DimMgt: Codeunit DimensionManagement;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        ReportSelection: Record "Cash Desk Report Selections";
    begin
        TestField("Cash Document Type");
        with PostedCashDocHeader do begin
            Copy(Rec);
            case "Cash Document Type" of
                "Cash Document Type"::Receipt:
                    ReportSelection.SetRange(Usage, ReportSelection.Usage::"P.C.Rcpt");
                "Cash Document Type"::Withdrawal:
                    ReportSelection.SetRange(Usage, ReportSelection.Usage::"P.C.Wdrwl");
            end;
            ReportSelection.SetFilter("Report ID", '<>0');
            ReportSelection.FindSet();
            repeat
                REPORT.RunModal(ReportSelection."Report ID", ShowRequestForm, false, PostedCashDocHeader);
            until ReportSelection.Next() = 0;
        end;
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure Navigate()
    var
        NavigateForm: Page Navigate;
    begin
        NavigateForm.SetDoc("Posting Date", "No.");
        NavigateForm.SetCashDesk("Cash Desk No.");
        NavigateForm.Run;
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption, "No."));
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure ShowEETEntry()
    var
        EETEntry: Record "EET Entry";
    begin
        TestField("EET Entry No.");
        EETEntry.Get("EET Entry No.");
        PAGE.Run(PAGE::"EET Entry Card", EETEntry);
    end;
#endif
}

