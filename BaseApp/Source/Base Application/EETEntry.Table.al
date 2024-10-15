table 31123 "EET Entry"
{
    Caption = 'EET Entry';
    DrillDownPageID = "EET Entries";
    LookupPageID = "EET Entries";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(10; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Cash Desk';
            OptionMembers = " ","Cash Desk";
        }
        field(12; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST("Cash Desk")) "Bank Account" WHERE("Account Type" = CONST("Cash Desk"));
        }
        field(20; "Business Premises Code"; Code[10])
        {
            Caption = 'Business Premises Code';
            NotBlank = true;
            TableRelation = "EET Business Premises";
        }
        field(25; "Cash Register Code"; Code[10])
        {
            Caption = 'Cash Register Code';
            NotBlank = true;
            TableRelation = "EET Cash Register".Code WHERE("Business Premises Code" = FIELD("Business Premises Code"));
        }
        field(30; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(40; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(50; "Applied Document Type"; Option)
        {
            Caption = 'Applied Document Type';
            OptionCaption = ' ,Invoice,Credit Memo,Prepayment';
            OptionMembers = " ",Invoice,"Credit Memo",Prepayment;
        }
        field(55; "Applied Document No."; Code[20])
        {
            Caption = 'Applied Document No.';
        }
        field(60; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(62; "Creation Datetime"; DateTime)
        {
            Caption = 'Creation Datetime';
        }
        field(70; "EET Status"; Option)
        {
            Caption = 'EET Status';
            OptionCaption = 'Created,Send Pending,Sent,Failure,Success,Success with Warnings,Sent to Verification,Verified,Verified with Warnings';
            OptionMembers = Created,"Send Pending",Sent,Failure,Success,"Success with Warnings","Sent to Verification",Verified,"Verified with Warnings";
        }
        field(72; "EET Status Last Changed"; DateTime)
        {
            Caption = 'EET Status Last Changed';
        }
        field(75; "Message UUID"; Text[36])
        {
            Caption = 'Message UUID';
        }
        field(76; "Signature Code (PKP)"; BLOB)
        {
            Caption = 'Signature Code (PKP)';
        }
        field(77; "Security Code (BKP)"; Text[44])
        {
            Caption = 'Security Code (BKP)';
        }
        field(78; "Fiscal Identification Code"; Text[39])
        {
            Caption = 'Fiscal Identification Code';
        }
        field(85; "Receipt Serial No."; Code[50])
        {
            Caption = 'Receipt Serial No.';
        }
        field(150; "Total Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Sales Amount';
        }
        field(155; "Amount Exempted From VAT"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount Exempted From VAT';
        }
        field(160; "VAT Base (Basic)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base (Basic)';
            Editable = false;
        }
        field(161; "VAT Amount (Basic)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount (Basic)';
        }
        field(164; "VAT Base (Reduced)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base (Reduced)';
            Editable = false;
        }
        field(165; "VAT Amount (Reduced)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount (Reduced)';
        }
        field(167; "VAT Base (Reduced 2)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base (Reduced 2)';
            Editable = false;
        }
        field(168; "VAT Amount (Reduced 2)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount (Reduced 2)';
        }
        field(170; "Amount - Art.89"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount - Art.89';
        }
        field(175; "Amount (Basic) - Art.90"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (Basic) - Art.90';
        }
        field(177; "Amount (Reduced) - Art.90"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (Reduced) - Art.90';
        }
        field(179; "Amount (Reduced 2) - Art.90"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (Reduced 2) - Art.90';
        }
        field(190; "Amt. For Subseq. Draw/Settle"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amt. For Subseq. Draw/Settle';
        }
        field(195; "Amt. Subseq. Drawn/Settled"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amt. Subseq. Drawn/Settled';
        }
        field(200; "Canceled By Entry No."; Integer)
        {
            Caption = 'Canceled By Entry No.';
            TableRelation = "EET Entry";
        }
        field(210; "Simple Registration"; Boolean)
        {
            Caption = 'Simple Registration';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Business Premises Code", "Cash Register Code")
        {
        }
        key(Key3; "EET Status")
        {
        }
        key(Key4; "Document No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        EETEntryMgt: Codeunit "EET Entry Management";
        RegSalesRegimeTxt: Label 'Regular Record Of Sale';
        SimpleSalesRegimeTxt: Label 'Simplified Record Of Sale';
        SendToServiceQst: Label 'Do you want to send %1 %2 to EET service?', Comment = '%1 = Table Caption;%2 = Entry No.';

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    [Scope('OnPrem')]
    procedure ShowStatusLog()
    var
        EETEntryStatus: Record "EET Entry Status";
    begin
        EETEntryStatus.SetCurrentKey("EET Entry No.");
        EETEntryStatus.SetRange("EET Entry No.", "Entry No.");
        PAGE.Run(0, EETEntryStatus);
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.5')]
    [Scope('OnPrem')]
    procedure ShowDocument()
    var
        PstdCashDocHeader: Record "Posted Cash Document Header";
    begin
        TestField("Source No.");
        TestField("Document No.");
        case "Source Type" of
            "Source Type"::"Cash Desk":
                if PstdCashDocHeader.Get("Source No.", "Document No.") then
                    PAGE.Run(PAGE::"Posted Cash Document", PstdCashDocHeader);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCertificateCode(): Code[10]
    var
        EETCashRegister: Record "EET Cash Register";
        EETBusinessPremises: Record "EET Business Premises";
        EETServiceSetup: Record "EET Service Setup";
    begin
        EETCashRegister.Get("Business Premises Code", "Cash Register Code");
        if EETCashRegister."Certificate Code" <> '' then
            exit(EETCashRegister."Certificate Code");

        EETBusinessPremises.Get("Business Premises Code");
        if EETBusinessPremises."Certificate Code" <> '' then
            exit(EETBusinessPremises."Certificate Code");

        EETServiceSetup.Get();
        EETServiceSetup.TestField("Certificate Code");
        exit(EETServiceSetup."Certificate Code");
    end;

    [Scope('OnPrem')]
    procedure GetBusinessPremisesId(): Code[6]
    var
        EETBusinessPremises: Record "EET Business Premises";
    begin
        EETBusinessPremises.Get("Business Premises Code");
        exit(EETBusinessPremises.Identification);
    end;

    [Scope('OnPrem')]
    procedure GetCashRegisterNo(): Code[20]
    var
        EETCashRegister: Record "EET Cash Register";
    begin
        EETCashRegister.Get("Business Premises Code", "Cash Register Code");
        exit(EETCashRegister.Code);
    end;

    [Scope('OnPrem')]
    procedure SaveSignatureCode(SignatureCode: Text)
    var
        OutStream: OutStream;
    begin
        if SignatureCode = '' then
            exit;

        "Signature Code (PKP)".CreateOutStream(OutStream);
        OutStream.Write(SignatureCode);
    end;

    [Scope('OnPrem')]
    procedure GetSignatureCode(): Text
    var
        InStream: InStream;
        SignatureCode: Text;
    begin
        CalcFields("Signature Code (PKP)");
        "Signature Code (PKP)".CreateInStream(InStream);
        InStream.Read(SignatureCode);
        exit(SignatureCode);
    end;

    [Scope('OnPrem')]
    procedure GenerateSignatureCode(): Text
    begin
        exit(EETEntryMgt.GenerateSignatureCode(Rec));
    end;

    [Scope('OnPrem')]
    procedure GenerateSecurityCode(): Text[44]
    var
        SignatureCode: Text;
    begin
        SignatureCode := GetSignatureCode;
        if SignatureCode = '' then
            SignatureCode := GenerateSignatureCode;

        exit(EETEntryMgt.GenerateSecurityCode(SignatureCode));
    end;

    [Scope('OnPrem')]
    procedure GetSalesRegimeText(): Text
    var
        EETServiceSetup: Record "EET Service Setup";
    begin
        EETServiceSetup.Get();
        case EETServiceSetup."Sales Regime" of
            EETServiceSetup."Sales Regime"::Regular:
                exit(RegSalesRegimeTxt);
            EETServiceSetup."Sales Regime"::Simplified:
                exit(SimpleSalesRegimeTxt);
        end;
    end;

    [Scope('OnPrem')]
    procedure IsFirstSending(): Boolean
    var
        EETEntryStatus: Record "EET Entry Status";
    begin
        EETEntryStatus.SetRange("EET Entry No.", "Entry No.");
        EETEntryStatus.SetRange(Status, EETEntryStatus.Status::Sent);
        exit(EETEntryStatus.Count = 1);
    end;

    [Scope('OnPrem')]
    procedure SendToService(VerificationMode: Boolean)
    begin
        if not VerificationMode then
            if not Confirm(SendToServiceQst, false, TableCaption, "Entry No.") then
                exit;

        EETEntryMgt.SendEntryToService(Rec, VerificationMode);
    end;

    [Scope('OnPrem')]
    procedure ReverseAmounts()
    begin
        "Total Sales Amount" := -"Total Sales Amount";
        "Amount Exempted From VAT" := -"Amount Exempted From VAT";
        "VAT Base (Basic)" := -"VAT Base (Basic)";
        "VAT Amount (Basic)" := -"VAT Amount (Basic)";
        "VAT Base (Reduced)" := -"VAT Base (Reduced)";
        "VAT Amount (Reduced)" := -"VAT Amount (Reduced)";
        "VAT Base (Reduced 2)" := -"VAT Base (Reduced 2)";
        "VAT Amount (Reduced 2)" := -"VAT Amount (Reduced 2)";
        "Amount - Art.89" := -"Amount - Art.89";
        "Amount (Basic) - Art.90" := -"Amount (Basic) - Art.90";
        "Amount (Reduced) - Art.90" := -"Amount (Reduced) - Art.90";
        "Amount (Reduced 2) - Art.90" := -"Amount (Reduced 2) - Art.90";
        "Amt. For Subseq. Draw/Settle" := -"Amt. For Subseq. Draw/Settle";
        "Amt. Subseq. Drawn/Settled" := -"Amt. Subseq. Drawn/Settled";
    end;

    [Scope('OnPrem')]
    procedure CopySourceInfoFromEntry(EETEntry: Record "EET Entry"; InitializeSerialNo: Boolean)
    var
        EETBusinessPremises: Record "EET Business Premises";
        EETCashRegister: Record "EET Cash Register";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        ReceiptSerialNo: Code[50];
    begin
        ReceiptSerialNo := EETEntry."Receipt Serial No.";
        if InitializeSerialNo then begin
            EETBusinessPremises.Get(EETEntry."Business Premises Code");
            EETCashRegister.Get(EETEntry."Business Premises Code", EETEntry."Cash Register Code");
            EETCashRegister.TestField("Receipt Serial Nos.");
            ReceiptSerialNo := NoSeriesManagement.GetNextNo(EETCashRegister."Receipt Serial Nos.", Today, true);
        end;

        "Source Type" := EETEntry."Source Type";
        "Source No." := EETEntry."Source No.";
        "Business Premises Code" := EETEntry."Business Premises Code";
        "Cash Register Code" := EETEntry."Cash Register Code";
        "Document No." := EETEntry."Document No.";
        "Receipt Serial No." := ReceiptSerialNo;
        Description := EETEntry.Description;
        "Applied Document Type" := EETEntry."Applied Document Type";
        "Applied Document No." := EETEntry."Applied Document No.";
    end;

    [Scope('OnPrem')]
    procedure CopyAmountsFromEntry(EETEntry: Record "EET Entry")
    begin
        "Total Sales Amount" := EETEntry."Total Sales Amount";
        "Amount Exempted From VAT" := EETEntry."Amount Exempted From VAT";
        "VAT Base (Basic)" := EETEntry."VAT Base (Basic)";
        "VAT Amount (Basic)" := EETEntry."VAT Amount (Basic)";
        "VAT Base (Reduced)" := EETEntry."VAT Base (Reduced)";
        "VAT Amount (Reduced)" := EETEntry."VAT Amount (Reduced)";
        "VAT Base (Reduced 2)" := EETEntry."VAT Base (Reduced 2)";
        "VAT Amount (Reduced 2)" := EETEntry."VAT Amount (Reduced 2)";
        "Amount - Art.89" := EETEntry."Amount - Art.89";
        "Amount (Basic) - Art.90" := EETEntry."Amount (Basic) - Art.90";
        "Amount (Reduced) - Art.90" := EETEntry."Amount (Reduced) - Art.90";
        "Amount (Reduced 2) - Art.90" := EETEntry."Amount (Reduced 2) - Art.90";
        "Amt. For Subseq. Draw/Settle" := EETEntry."Amt. For Subseq. Draw/Settle";
        "Amt. Subseq. Drawn/Settled" := EETEntry."Amt. Subseq. Drawn/Settled";
    end;

    [Scope('OnPrem')]
    procedure SumPartialAmounts(): Decimal
    begin
        exit(
          "Amount Exempted From VAT" +
          "VAT Base (Basic)" + "VAT Amount (Basic)" +
          "VAT Base (Reduced)" + "VAT Amount (Reduced)" +
          "VAT Base (Reduced 2)" + "VAT Amount (Reduced 2)" +
          "Amount - Art.89" +
          "Amount (Basic) - Art.90" + "Amount (Reduced) - Art.90" + "Amount (Reduced 2) - Art.90" +
          "Amt. For Subseq. Draw/Settle" + "Amt. Subseq. Drawn/Settled");
    end;

    local procedure FormatDateTime(dt: DateTime): Text
    begin
        exit(Format(dt, 0, 3));
    end;

    [Scope('OnPrem')]
    procedure GetFormattedCreationDatetime(): Text
    begin
        exit(FormatDateTime("Creation Datetime"));
    end;

    [Scope('OnPrem')]
    procedure GetFormattedEETStatusLastChanged(): Text
    begin
        exit(FormatDateTime("EET Status Last Changed"));
    end;
}

