table 14901 "Vendor Agreement"
{
    Caption = 'Vendor Agreement';
    DataCaptionFields = "Vendor No.", "No.";
    DrillDownPageID = "Vendor Agreements";
    LookupPageID = "Vendor Agreements";

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    Vend.Get("Vendor No.");
                    NoSeriesMgt.TestManual(Vend."Agreement Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(4; "External Agreement No."; Text[30])
        {
            Caption = 'External Agreement No.';
        }
        field(5; "Agreement Date"; Date)
        {
            Caption = 'Agreement Date';
        }
        field(6; Active; Boolean)
        {
            Caption = 'Active';
        }
        field(7; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                CheckDates;
            end;
        }
        field(8; "Expire Date"; Date)
        {
            Caption = 'Expire Date';

            trigger OnValidate()
            begin
                CheckDates;
            end;
        }
        field(9; "Agreement Group"; Code[20])
        {
            Caption = 'Agreement Group';
            TableRelation = "Agreement Group".Code WHERE(Type = CONST(Purchases));
        }
        field(12; Comment; Boolean)
        {
            CalcFormula = Exist ("Purch. Comment Line" WHERE("Document Type" = CONST(Agreement),
                                                             "No." = FIELD("No.")));
            Caption = 'Comment';
            FieldClass = FlowField;
        }
        field(14; Contact; Text[100])
        {
            Caption = 'Contact';
        }
        field(15; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
        }
        field(16; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(17; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(21; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            TableRelation = "Vendor Posting Group";

            trigger OnValidate()
            begin
                if "Vendor Posting Group" <> xRec."Vendor Posting Group" then begin
                    PurchSetup.Get;
                    if not PurchSetup."Allow Alter Posting Groups" then
                        Error(Text12401, FieldCaption("Vendor Posting Group"),
                          PurchSetup.FieldCaption("Allow Alter Posting Groups"), PurchSetup.TableCaption);
                end;
            end;
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(24; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(27; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(29; "Purchaser Code"; Code[20])
        {
            Caption = 'Purchaser Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        field(39; Blocked; Option)
        {
            Caption = 'Blocked';
            OptionCaption = ' ,Payment,All';
            OptionMembers = " ",Payment,All;
        }
        field(46; Priority; Integer)
        {
            Caption = 'Priority';
        }
        field(47; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(55; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(56; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(57; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(58; Balance; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum ("Detailed Vendor Ledg. Entry".Amount WHERE("Vendor No." = FIELD("Vendor No."),
                                                                           "Agreement No." = FIELD("No.")));
            Caption = 'Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        field(59; "Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum ("Detailed Vendor Ledg. Entry"."Amount (LCY)" WHERE("Vendor No." = FIELD("Vendor No."),
                                                                                   "Agreement No." = FIELD("No.")));
            Caption = 'Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Net Change"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Detailed Vendor Ledg. Entry".Amount WHERE("Vendor No." = FIELD("Vendor No."),
                                                                          "Initial Entry Global Dim. 1" = FIELD("Global Dimension 1 Filter"),
                                                                          "Initial Entry Global Dim. 2" = FIELD("Global Dimension 2 Filter"),
                                                                          "Posting Date" = FIELD("Date Filter"),
                                                                          "Agreement No." = FIELD("No.")));
            Caption = 'Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Net Change (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Detailed Vendor Ledg. Entry"."Amount (LCY)" WHERE("Vendor No." = FIELD("Vendor No."),
                                                                                  "Initial Entry Global Dim. 1" = FIELD("Global Dimension 1 Filter"),
                                                                                  "Initial Entry Global Dim. 2" = FIELD("Global Dimension 2 Filter"),
                                                                                  "Posting Date" = FIELD("Date Filter"),
                                                                                  "Agreement No." = FIELD("No.")));
            Caption = 'Net Change (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(88; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(95; "Order Address Code"; Code[10])
        {
            Caption = 'Order Address Code';
            TableRelation = "Order Address".Code WHERE("Vendor No." = FIELD("Vendor No."));
        }
        field(97; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum ("Detailed Vendor Ledg. Entry"."Debit Amount" WHERE("Vendor No." = FIELD("Vendor No."),
                                                                                  "Entry Type" = FILTER(<> Application),
                                                                                  "Initial Entry Global Dim. 1" = FIELD("Global Dimension 1 Filter"),
                                                                                  "Initial Entry Global Dim. 2" = FIELD("Global Dimension 2 Filter"),
                                                                                  "Posting Date" = FIELD("Date Filter"),
                                                                                  "Agreement No." = FIELD("No.")));
            Caption = 'Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(98; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum ("Detailed Vendor Ledg. Entry"."Credit Amount" WHERE("Vendor No." = FIELD("Vendor No."),
                                                                                   "Entry Type" = FILTER(<> Application),
                                                                                   "Initial Entry Global Dim. 1" = FIELD("Global Dimension 1 Filter"),
                                                                                   "Initial Entry Global Dim. 2" = FIELD("Global Dimension 2 Filter"),
                                                                                   "Posting Date" = FIELD("Date Filter"),
                                                                                   "Agreement No." = FIELD("No.")));
            Caption = 'Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(99; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum ("Detailed Vendor Ledg. Entry"."Debit Amount (LCY)" WHERE("Vendor No." = FIELD("Vendor No."),
                                                                                        "Entry Type" = FILTER(<> Application),
                                                                                        "Initial Entry Global Dim. 1" = FIELD("Global Dimension 1 Filter"),
                                                                                        "Initial Entry Global Dim. 2" = FIELD("Global Dimension 2 Filter"),
                                                                                        "Posting Date" = FIELD("Date Filter"),
                                                                                        "Agreement No." = FIELD("No.")));
            Caption = 'Debit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(100; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum ("Detailed Vendor Ledg. Entry"."Credit Amount (LCY)" WHERE("Vendor No." = FIELD("Vendor No."),
                                                                                         "Entry Type" = FILTER(<> Application),
                                                                                         "Initial Entry Global Dim. 1" = FIELD("Global Dimension 1 Filter"),
                                                                                         "Initial Entry Global Dim. 2" = FIELD("Global Dimension 2 Filter"),
                                                                                         "Posting Date" = FIELD("Date Filter"),
                                                                                         "Agreement No." = FIELD("No.")));
            Caption = 'Credit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(102; "E-Mail"; Text[80])
        {
            Caption = 'Email';
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(110; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(5701; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
        }
        field(12400; "Default Bank Code"; Code[20])
        {
            Caption = 'Default Bank Code';
            TableRelation = "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("Vendor No."));
        }
        field(12411; "VAT Agent Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Agent Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(12412; "VAT Payment Source Type"; Option)
        {
            Caption = 'VAT Payment Source Type';
            OptionCaption = 'Vendor Funds,Internal Funds';
            OptionMembers = "Vendor Funds","Internal Funds";
        }
        field(12414; "Tax Authority No."; Code[20])
        {
            Caption = 'Tax Authority No.';
            TableRelation = Vendor WHERE("Vendor Type" = CONST("Tax Authority"));
        }
        field(12425; "G/L Account Filter"; Code[20])
        {
            Caption = 'G/L Account Filter';
            FieldClass = FlowFilter;
            TableRelation = "G/L Account";
        }
        field(12426; "G/L Starting Date Filter"; Date)
        {
            Caption = 'G/L Starting Date Filter';
            FieldClass = FlowFilter;
        }
        field(12427; "G/L Starting Balance"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("G/L Entry".Amount WHERE("Source Type" = CONST(Vendor),
                                                        "Source No." = FIELD("Vendor No."),
                                                        "Agreement No." = FIELD("No."),
                                                        "G/L Account No." = FIELD("G/L Account Filter"),
                                                        "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                        "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                        "Posting Date" = FIELD(UPPERLIMIT("G/L Starting Date Filter"))));
            Caption = 'G/L Starting Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12428; "G/L Net Change"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("G/L Entry".Amount WHERE("Source Type" = CONST(Vendor),
                                                        "Source No." = FIELD("Vendor No."),
                                                        "Agreement No." = FIELD("No."),
                                                        "G/L Account No." = FIELD("G/L Account Filter"),
                                                        "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                        "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                        "Posting Date" = FIELD("Date Filter")));
            Caption = 'G/L Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12429; "G/L Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("G/L Entry"."Debit Amount" WHERE("Source Type" = CONST(Vendor),
                                                                "Source No." = FIELD("Vendor No."),
                                                                "G/L Account No." = FIELD("G/L Account Filter"),
                                                                "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                "Agreement No." = FIELD("No."),
                                                                "Posting Date" = FIELD("Date Filter")));
            Caption = 'G/L Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12430; "G/L Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("G/L Entry"."Credit Amount" WHERE("Source Type" = CONST(Vendor),
                                                                 "Source No." = FIELD("Vendor No."),
                                                                 "G/L Account No." = FIELD("G/L Account Filter"),
                                                                 "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                 "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                 "Agreement No." = FIELD("No."),
                                                                 "Posting Date" = FIELD("Date Filter")));
            Caption = 'G/L Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12431; "G/L Balance to Date"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("G/L Entry".Amount WHERE("Source Type" = CONST(Vendor),
                                                        "Source No." = FIELD("Vendor No."),
                                                        "G/L Account No." = FIELD("G/L Account Filter"),
                                                        "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                        "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                        "Agreement No." = FIELD("No."),
                                                        "Posting Date" = FIELD(UPPERLIMIT("Date Filter"))));
            Caption = 'G/L Balance to Date';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "No.")
        {
            Clustered = true;
        }
        key(Key2; "Agreement Group", "No.")
        {
        }
        key(Key3; "No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        LaborContract: Record "Labor Contract";
    begin
        VendLedgEntry.Reset;
        VendLedgEntry.SetRange("Vendor No.", "Vendor No.");
        VendLedgEntry.SetRange("Agreement No.", "No.");
        if not VendLedgEntry.IsEmpty then
            Error(Text001);

        LaborContract.SetRange("Vendor No.", "Vendor No.");
        LaborContract.SetRange("Vendor Agreement No.", "No.");
        if not LaborContract.IsEmpty then
            Error(Text17360);

        PurchSetup.Get;
        if DimValue.Get(PurchSetup."Vendor Agreement Dim. Code", "No.") then
            DimValue.Delete;
    end;

    trigger OnInsert()
    begin
        Vend.Get("Vendor No.");
        Vend.TestField("Agreement Posting", Vend."Agreement Posting"::Mandatory);
        if "No." = '' then begin
            Vend.TestField("Agreement Nos.");
            NoSeriesMgt.InitSeries(Vend."Agreement Nos.", xRec."No. Series", WorkDate, "No.", "No. Series");
            Description := StrSubstNo('%1 %2', Text12400, "No.");
        end;

        VendAgrmt.Reset;
        VendAgrmt.SetCurrentKey("No.");
        VendAgrmt.SetRange("No.", "No.");
        if VendAgrmt.FindSet then
            repeat
                if VendAgrmt."Vendor No." <> "Vendor No." then
                    Error(Text12403, FieldCaption("No."), VendAgrmt."Vendor No.");
            until VendAgrmt.Next = 0;

        VendTransferFields;
        VendTransferDimensions;

        PurchSetup.Get;
        if PurchSetup."Synch. Agreement Dimension" then begin
            PurchSetup.TestField("Vendor Agreement Dim. Code");

            DimValue.Init;
            DimValue."Dimension Code" := PurchSetup."Vendor Agreement Dim. Code";
            DimValue.Code := "No.";
            DimValue.Name := CopyStr("No.", 1, MaxStrLen(DimValue.Name));
            if DimValue.Insert then;

            DefaultDim2.Init;
            DefaultDim2."Table ID" := DATABASE::"Vendor Agreement";
            DefaultDim2."No." := "No.";
            DefaultDim2."Dimension Code" := PurchSetup."Vendor Agreement Dim. Code";
            DefaultDim2."Dimension Value Code" := "No.";
            DefaultDim2."Value Posting" := DefaultDim2."Value Posting"::"Same Code";
            if DefaultDim2.Insert then;
        end;
    end;

    trigger OnModify()
    begin
        PurchSetup.Get;
        if DimValue.Get(PurchSetup."Vendor Agreement Dim. Code", "No.") then begin
            DimValue.Name := CopyStr("No.", 1, MaxStrLen(DimValue.Name));
            if Blocked > 0 then
                DimValue.Blocked := true
            else
                DimValue.Blocked := false;
            DimValue.Modify;
        end;
    end;

    trigger OnRename()
    begin
        Error(Text003, TableCaption);
    end;

    var
        Text001: Label 'You cannot delete agreement if you already have ledger entries.';
        PurchSetup: Record "Purchases & Payables Setup";
        Vend: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        DimValue: Record "Dimension Value";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        DefaultDim: Record "Default Dimension";
        DefaultDim2: Record "Default Dimension";
        VendAgrmt: Record "Vendor Agreement";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        Text003: Label 'You cannot rename %1.';
        Text005: Label 'post';
        Text006: Label 'create';
        Text007: Label 'You cannot %1 this type of document when Vendor %2 is blocked with type %3.';
        Text12400: Label 'Agreement';
        Text12401: Label 'You cannot change %1 until you check %2 in %3.';
        Text12402: Label '%1 should be later than %2.';
        Text12403: Label 'This %1 already used for vendor %2.';
        Text17360: Label 'You cannot delete agreement if you already have labor contracts.';
        PrivacyBlockedActionErr: Label 'You cannot %1 this type of document when Vendor %2 is blocked for privacy.', Comment = '%1 = action (create or post), %2 = vendor code.';

    [Scope('OnPrem')]
    procedure AssistEdit(OldVendAgreement: Record "Vendor Agreement"): Boolean
    begin
        Vend.Get("Vendor No.");
        Vend.TestField("Agreement Nos.");
        if NoSeriesMgt.SelectSeries(Vend."Agreement Nos.", OldVendAgreement."No. Series", "No. Series") then begin
            NoSeriesMgt.SetSeries("No.");
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.SaveDefaultDim(DATABASE::"Vendor Agreement", "No.", FieldNumber, ShortcutDimCode);
        Modify;
    end;

    [Scope('OnPrem')]
    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.SaveDefaultDim(DATABASE::"Vendor Agreement", "No.", FieldNumber, ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure CheckBlockedVendOnDocs(Vend2: Record Vendor; Transaction: Boolean)
    begin
        if Vend2."Privacy Blocked" then
            VendPrivacyBlockedErrorMessage(Vend2, Transaction);

        if Vend2.Blocked in [Vend2.Blocked::All] then
            VendBlockedErrorMessage(Vend2, Transaction);
    end;

    [Scope('OnPrem')]
    procedure CheckBlockedVendOnJnls(Vend2: Record Vendor; DocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge",Reminder,Refund; Transaction: Boolean)
    begin
        if Vend2."Privacy Blocked" then
            VendPrivacyBlockedErrorMessage(Vend2, Transaction);

        if (Vend2.Blocked in [Vend2.Blocked::All]) or
           (Vend2.Blocked = Vend2.Blocked::Payment) and (DocType = DocType::Payment)
        then
            VendBlockedErrorMessage(Vend2, Transaction);
    end;

    [Scope('OnPrem')]
    procedure VendBlockedErrorMessage(Vend2: Record Vendor; Transaction: Boolean)
    var
        "Action": Text[30];
    begin
        if Transaction then
            Action := Text005
        else
            Action := Text006;
        Error(Text007, Action, Vend2."No.", Vend2.Blocked);
    end;

    [Scope('OnPrem')]
    procedure VendPrivacyBlockedErrorMessage(Vend2: Record Vendor; Transaction: Boolean)
    var
        "Action": Text[30];
    begin
        if Transaction then
            Action := Text005
        else
            Action := Text006;

        Error(PrivacyBlockedActionErr, Action, Vend2."No.");
    end;

    [Scope('OnPrem')]
    procedure VendTransferFields()
    begin
        Contact := Vend.Contact;
        "Phone No." := Vend."Phone No.";
        "E-Mail" := Vend."E-Mail";
        Blocked := Vend.Blocked;
        "Vendor Posting Group" := Vend."Vendor Posting Group";
        "Gen. Bus. Posting Group" := Vend."Gen. Bus. Posting Group";
        "VAT Bus. Posting Group" := Vend."VAT Bus. Posting Group";
        "Global Dimension 1 Code" := Vend."Global Dimension 1 Code";
        "Global Dimension 2 Code" := Vend."Global Dimension 2 Code";
        "Currency Code" := Vend."Currency Code";
        "Prices Including VAT" := Vend."Prices Including VAT";
        "Language Code" := Vend."Language Code";
        "Payment Terms Code" := Vend."Payment Terms Code";
        "Payment Method Code" := Vend."Payment Method Code";
        "Purchaser Code" := Vend."Purchaser Code";
        "Location Code" := Vend."Location Code";
        "Responsibility Center" := Vend."Responsibility Center";
        "Default Bank Code" := Vend."Default Bank Code";
    end;

    [Scope('OnPrem')]
    procedure VendTransferDimensions()
    begin
        DefaultDim.Reset;
        DefaultDim.SetRange("Table ID", DATABASE::Vendor);
        DefaultDim.SetRange("No.", "Vendor No.");
        if DefaultDim.FindSet then
            repeat
                DefaultDim2.Init;
                DefaultDim2."Table ID" := DATABASE::"Vendor Agreement";
                DefaultDim2."No." := "No.";
                DefaultDim2."Dimension Code" := DefaultDim."Dimension Code";
                DefaultDim2."Dimension Value Code" := DefaultDim."Dimension Value Code";
                DefaultDim2."Value Posting" := DefaultDim."Value Posting";
                DefaultDim2.Insert;
            until DefaultDim.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckDates()
    begin
        if ("Expire Date" <> 0D) and ("Starting Date" <> 0D) and ("Expire Date" < "Starting Date") then
            Error(Text12402, FieldCaption("Expire Date"), FieldCaption("Starting Date"));
    end;

    [Scope('OnPrem')]
    procedure GetDefaultDimSetID(DimSetID: Integer; var ShortcutDim1Code: Code[20]; var ShortcutDim2Code: Code[20]): Integer
    var
        AgrmtMgt: Codeunit "Agreement Management";
        DimSetIDArr: array[10] of Integer;
    begin
        DimSetIDArr[1] := DimSetID;
        DimSetIDArr[2] := AgrmtMgt.GetAgrmtDefaultDimSetID(DATABASE::"Vendor Agreement", "No.");
        exit(
          DimMgt.GetCombinedDimensionSetID(
            DimSetIDArr, ShortcutDim1Code, ShortcutDim2Code));
    end;
}

