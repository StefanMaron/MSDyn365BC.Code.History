table 18870 "TCS Journal Line"
{
    Caption = 'TCS Journal Line';
    Access = Public;
    Extensible = true;
    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "TCS Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Account Type"; Enum "TCS Account Type")
        {
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            var
                AccountErr: Label '%1 or %2 must be G/L Account or Bank Account.', Comment = '%1= G/L Account., %2=Bank Account.';
            begin
                if ("Account Type" = "Account Type"::Customer) and
                   ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor])
                Then
                    Error(
                      AccountErr,
                      FIELDCAPTION("Account Type"), FIELDCAPTION("Bal. Account Type"));
                Validate("Account No.", '');
            end;
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Account Type" = CONST("G/L Account")) "G/L Account"
            Else
            if ("Account Type" = CONST(Customer)) Customer;
            trigger OnValidate()
            begin
                if "Account No." = '' Then Begin
                    CreateDim(
                      DimMgt.TypeToTableID1("Account Type"), "Account No.",
                      DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                      Database::Job, '',
                      Database::"Salesperson/Purchaser", '',
                      Database::Campaign, '');
                    Exit;
                end;
                UpdateDataOnAccountNo();
                CreateDim(
                  DimMgt.TypeToTableID1("Account Type"), "Account No.",
                  DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                  Database::Job, '',
                  Database::"Salesperson/Purchaser", '',
                  Database::Campaign, '');
            end;
        }
        field(5; "Posting Date"; Date)
        {
            ClosingDates = true;
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            var
                DateValidateErr: Label 'Posting Date %1 for TCS Adjustment cannot be earlier than the Invoice Date %2.', Comment = '%1=Posting date., %2=Invoice Date.';
            begin
                if "Posting Date" < xRec."Posting Date" Then
                    Error(DateValidateErr, "Posting Date", xRec."Posting Date");
                Validate("Document Date", "Posting Date");
            end;
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            var
                Cust: Record Customer;
            begin
                if "Account No." <> '' Then
                    if "Account Type" = "Account Type"::Customer then Begin
                        Cust.Get("Account No.");
                        Cust.CheckBlockedCustOnJnls(Cust, "Document Type", False);
                    end;
                if "Bal. Account No." <> '' Then
                    if "Bal. Account Type" = "Account Type"::Customer then Begin
                        Cust.Get("Bal. Account No.");
                        Cust.CheckBlockedCustOnJnls(Cust, "Document Type", False);
                    end;
            end;
        }
        field(7; "Document No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; Description; Text[100])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Bal. Account No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            Else
            if ("Bal. Account Type" = CONST(Customer)) Customer
            Else
            if ("Bal. Account Type" = CONST(Vendor)) Vendor
            Else
            if ("Bal. Account Type" = CONST("Bank Account")) "Bank Account";

            trigger OnValidate()
            begin
                if "Bal. Account No." = '' Then Begin
                    CreateDim(
                      DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                      DimMgt.TypeToTableID1("Account Type"), "Account No.",
                     Database::Job, '',
                      Database::"Salesperson/Purchaser", '',
                      Database::Campaign, '');
                    Exit;
                end;
                UpdateDataOnBalAccountNo();
                CreateDim(
                  DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                  DimMgt.TypeToTableID1("Account Type"), "Account No.",
                  Database::Job, '',
                  Database::"Salesperson/Purchaser", '',
                  Database::Campaign, '');
            end;
        }
        field(10; "Customer No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = Customer."No.";
        }
        field(11; Amount; Decimal)
        {
            AutoFormatType = 1;
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                GetCurrency();
                Amount := Round(Amount, Currency."Amount Rounding Precision");
            end;
        }
        field(12; "Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                GetCurrency();
                "Debit Amount" := Round("Debit Amount", Currency."Amount Rounding Precision");
                Amount := "Debit Amount";
                Validate(Amount);
            end;
        }
        field(13; "Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                GetCurrency();
                "Credit Amount" := Round("Credit Amount", Currency."Amount Rounding Precision");
                Amount := -"Credit Amount";
                Validate(Amount);
            end;
        }
        field(14; "Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(15; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(16; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }

        field(17; "Journal Batch Name"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "TCS Journal Batch".Name WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(18; "TCS Adjusted"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(19; "Surcharge Adjusted"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(20; "eCess Adjusted"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
        }

        field(21; "Bal. Account Type"; Enum "Bal. Account Type")
        {
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            var
                AccountErr: Label '%1 or %2 must be G/L Account or Bank Account.', Comment = '%1= G/L Account., %2=Bank Account.';
            begin
                if ("Account Type" = "Account Type"::Customer) and
                   ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor])
                Then
                    Error(
                      AccountErr,
                      FieldCaption("Account Type"), FieldCaption("Bal. Account Type"));
                Validate("Bal. Account No.", '');
            end;
        }
        field(22; "Document Date"; Date)
        {
            ClosingDates = true;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(23; "External Document No."; Code[35])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(24; "Posting No. Series"; Code[10])
        {
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(25; "Dimension Set ID"; Integer)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
        }
        field(26; "State Code"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(27; "TCS Nature of Collection"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "TCS Nature Of Collection";
        }
        field(28; "TCS Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(29; "SHE Cess Adjusted"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(30; "Location Code"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = Location;
        }
        field(31; "Assessee Code"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Assessee Code";
        }
        field(32; "TCS %"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            trigger OnValidate()
            var
                TCSAmt: Decimal;
            begin
                if xRec."TCS %" > 0 Then Begin
                    if "Debit Amount" <> 0 Then
                        TCSAmt := "Debit Amount"
                    Else
                        TCSAmt := "Credit Amount";

                    if "Bal. TCS Including SHECESS" <> 0 Then
                        TCSAmt := "Bal. TCS Including SHECESS";
                    "Bal. TCS Including SHECESS" := Round("TCS %" * TCSAmt / xRec."TCS %", Currency."Amount Rounding Precision");
                    "TCS Amount" := Round("TCS %" * TCSAmt / xRec."TCS %", Currency."Amount Rounding Precision");
                end Else Begin
                    "Bal. TCS Including SHECESS" := Round(("TCS %" * (1 + "Surcharge %" / 100)) * Amount / 100,
                        Currency."Amount Rounding Precision");
                    "TCS Amount" := Round("TCS %" * Amount / 100, Currency."Amount Rounding Precision");
                end;
            end;
        }
        field(33; "TCS Amt Incl Surcharge"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(34; "Bal. TCS Including SHECESS"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(35; "eCess Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            begin
                Validate(Amount,
                  "Surcharge Amount" +
                  "eCess Amount" + "SHE Cess Amount");
            end;
        }
        field(36; "Surcharge %"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(37; "Surcharge Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(38; "Concessional Code"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Concessional Code";
        }
        field(39; "TCS % Applied"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            begin
                "TCS Adjusted" := true;
                "Balance TCS Amount" := "TCS % Applied" * "TCS Base Amount" / 100;
                "Surcharge Base Amount" := "Balance TCS Amount";

                TCSAdjustment.UpdateBalSurchargeAmount(Rec);
                TCSAdjustment.UpdateBalECessAmount(Rec);
                TCSAdjustment.UpdateBalSHECessAmount(Rec);

                if ("TCS % Applied" = 0) and "TCS Adjusted" then begin
                    Validate("Surcharge % Applied", 0);
                    Validate("eCESS % Applied", 0);
                    Validate("SHE Cess % Applied", 0);
                end;

                TCSAdjustment.RoundTCSAmounts(Rec, "Balance TCS Amount");
                TCSAdjustment.UpdateAmountForTCS(Rec);
            end;
        }
        field(40; "TCS Invoice No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(41; "TCS Base Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(42; "Challan No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(43; "Challan Date"; Date)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(44; Adjustment; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(45; "TCS Transaction No."; Integer)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(46; "Balance Surcharge Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(47; "Surcharge % Applied"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            var
                BalanceTCS: Decimal;
            begin
                if ("TCS % Applied" = 0) and (not "TCS Adjusted") then
                    BalanceTCS := "TCS Base Amount" * "TCS %" / 100
                else
                    BalanceTCS := "TCS Base Amount" * "TCS % Applied" / 100;

                "Surcharge Adjusted" := true;
                "Balance Surcharge Amount" := "Surcharge % Applied" * BalanceTCS / 100;

                if ("eCESS % Applied" = 0) and (not "eCess Adjusted") then
                    "Balance eCESS on TCS Amt" := ("Balance Surcharge Amount" + BalanceTCS) * "eCESS %" / 100
                else
                    "Balance eCESS on TCS Amt" := TCSManagement.RoundTCSAmount(("Balance Surcharge Amount" + BalanceTCS) * "eCESS % Applied" / 100);

                if ("SHE Cess % Applied" = 0) and (not "SHE Cess Adjusted") then
                    "Bal. SHE Cess on TCS Amt" := ("Balance Surcharge Amount" + BalanceTCS) * "SHE Cess % on TCS" / 100
                else
                    "Bal. SHE Cess on TCS Amt" := TCSManagement.RoundTCSAmount(("Balance Surcharge Amount" + BalanceTCS) * "SHE Cess % Applied" / 100);

                TCSAdjustment.RoundTCSAmounts(Rec, BalanceTCS);
                TCSAdjustment.UpdateAmount(rec);
            end;
        }
        field(48; "Surcharge Base Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(49; "Balance TCS Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(50; "eCESS %"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(51; "eCESS on TCS Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(52; "Total TCS Incl. SHE CESS"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(53; "eCESS Base Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(54; "eCESS % Applied"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            var
                BalanceTCS: Decimal;
                BalanceSurcharge: Decimal;
            begin
                if ("TCS % Applied" = 0) and (not "TCS Adjusted") then
                    BalanceTCS := "TCS Base Amount" * "TCS %" / 100
                else
                    BalanceTCS := "TCS Base Amount" * "TCS % Applied" / 100;

                if ("Surcharge % Applied" = 0) and (not "Surcharge Adjusted") then
                    BalanceSurcharge := BalanceTCS * "Surcharge %" / 100
                else
                    BalanceSurcharge := BalanceTCS * "Surcharge % Applied" / 100;

                "eCess Adjusted" := TRUE;
                "Balance eCESS on TCS Amt" := (BalanceTCS + BalanceSurcharge) * "eCESS % Applied" / 100;

                if ("SHE Cess % Applied" = 0) and (not "SHE Cess Adjusted") then
                    "Bal. SHE Cess on TCS Amt" := (BalanceTCS + BalanceSurcharge) * "SHE Cess % on TCS" / 100
                else
                    "Bal. SHE Cess on TCS Amt" := (BalanceTCS + BalanceSurcharge) * "SHE Cess % Applied" / 100;

                TCSAdjustment.RoundTCSAmounts(Rec, BalanceTCS);
                TCSAdjustment.UpdateAmount(Rec);
            end;
        }
        field(55; "Balance eCESS on TCS Amt"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(56; "Bal. SHE Cess on TCS Amt"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(57; "Pay TCS"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(58; "T.C.A.N. No."; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "T.C.A.N. No.";
        }
        field(59; "SHE Cess Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            AutoFormatType = 1;
        }
        field(60; "SHE Cess % on TCS"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(61; "SHE Cess on TCS Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(62; "SHE Cess Base Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(63; "SHE Cess % Applied"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            var
                BalanceTCS: Decimal;
                BalanceSurcharge: Decimal;
            begin
                if ("TCS % Applied" = 0) and (not "TCS Adjusted") then
                    BalanceTCS := "TCS Base Amount" * "TCS %" / 100
                else
                    BalanceTCS := "TCS Base Amount" * "TCS % Applied" / 100;

                if ("Surcharge % Applied" = 0) and (not "Surcharge Adjusted") then
                    BalanceSurcharge := BalanceTCS * "Surcharge %" / 100
                else
                    BalanceSurcharge := BalanceTCS * "Surcharge % Applied" / 100;

                if ("eCESS % Applied" = 0) and (not "eCess Adjusted") then
                    "Balance eCESS on TCS Amt" := (BalanceTCS + BalanceSurcharge) * "eCESS %" / 100
                else
                    "Balance eCESS on TCS Amt" := (BalanceTCS + BalanceSurcharge) * "eCESS % Applied" / 100;

                "SHE Cess Adjusted" := TRUE;
                "Bal. SHE Cess on TCS Amt" := (BalanceTCS + BalanceSurcharge) * "SHE Cess % Applied" / 100;

                TCSAdjustment.RoundTCSAmounts(Rec, BalanceTCS);
                TCSAdjustment.UpdateAmount(Rec);
            end;
        }
        field(64; "TCS Base Amount Applied"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            begin
                TestField("TCS Base Amount Applied", 0);
                "TCS Base Amount Adjusted" := TRUE;
                "TCS Base Amount" := "TCS Base Amount Applied";

                if ("TCS % Applied" = 0) and (not "TCS Adjusted") then begin
                    "TCS % Applied" := "TCS %";
                    "Balance TCS Amount" := "TCS %" * "TCS Base Amount" / 100;
                end else
                    "Balance TCS Amount" := TCSManagement.RoundTCSAmount("TCS Base Amount" * "TCS % Applied" / 100);

                "Surcharge Base Amount" := "Balance TCS Amount";
                TCSAdjustment.UpdateBalSurchargeAmount(Rec);
                TCSAdjustment.UpdateBalECessAmount(Rec);
                TCSAdjustment.UpdateBalSHECessAmount(Rec);

                if ("TCS Base Amount Applied" = 0) and "TCS Base Amount Adjusted" then begin
                    Validate("TCS % Applied", 0);
                    Validate("Surcharge % Applied", 0);
                    Validate("eCESS % Applied", 0);
                    Validate("SHE Cess % Applied", 0);
                end;

                TCSAdjustment.RoundTCSAmounts(Rec, "Balance TCS Amount");
                TCSAdjustment.UpdateAmountForTCS(Rec);
            end;
        }
        field(65; "TCS Base Amount Adjusted"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(66; "Source Code"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Source Code";
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
            MaintainSifTIndex = false;
            SumIndexFields = "Balance (LCY)";
        }
        key(Key2; "Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key3; "Journal Template Name", "Journal Batch Name", "Location Code", "Document No.")
        {
        }
    }
    trigger OnInsert()
    begin
        LockTable();
        TCSJnlTemplate.Get("Journal Template Name");
        TCSJnlBatch.Get("Journal Template Name", "Journal Batch Name");

        ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    procedure EmptyLine(): Boolean
    begin
        Exit(
          ("Account No." = '') and (Amount = 0) and
          ("Bal. Account No." = ''));
    end;

    procedure SetUpNewLine(LastTCSJnlLine: Record "TCS Journal Line"; var Balance: Decimal; BottomLine: Boolean)
    var
        TCSJnlLine: Record "TCS Journal Line";
    begin
        TCSJnlTemplate.Get("Journal Template Name");
        TCSJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        TCSJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        TCSJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if not TCSJnlLine.IsEmpty() Then Begin
            "Posting Date" := LastTCSJnlLine."Posting Date";
            "Document Date" := LastTCSJnlLine."Posting Date";
            "Document No." := LastTCSJnlLine."Document No.";
            if BottomLine and
               (Balance - LastTCSJnlLine."Balance (LCY)" = 0) and
               Not LastTCSJnlLine.EmptyLine()
            Then
                "Document No." := inCSTR("Document No.");
        end Else Begin
            "Posting Date" := WorkDate();
            "Document Date" := WorkDate();
            if TCSJnlBatch."No. Series" <> '' Then Begin
                Clear(NoSeriesMgt);
                "Document No." := NoSeriesMgt.GetNextNo(TCSJnlBatch."No. Series", "Posting Date", False);
            end;
        end;
        "Account Type" := LastTCSJnlLine."Account Type";
        "Document Type" := LastTCSJnlLine."Document Type";
        "Posting No. Series" := TCSJnlBatch."Posting No. Series";
        "Bal. Account Type" := TCSJnlBatch."Bal. Account Type";
        "Location Code" := TCSJnlBatch."Location Code";
        "Source Code" := TCSJnlTemplate."Source Code";
        if ("Account Type" = "Account Type"::Customer) and
           ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor])
        Then
            "Account Type" := "Account Type"::"G/L Account";
        Validate("Bal. Account No.", TCSJnlBatch."Bal. Account No.");
        Description := '';
    end;

    local procedure CheckGLAcc()
    begin
        GLAcc.CheckGLAcc();
        if GLAcc."Direct Posting" or ("Journal Template Name" = '') Then
            Exit;
        if "Posting Date" <> 0D Then
            if "Posting Date" = CLOSinGDATE("Posting Date") Then
                Exit;
        GLAcc.TestField("Direct Posting", True);
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20]; Type4: Integer; No4: Code[20]; Type5: Integer; No5: Code[20])
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        TableID[3] := Type3;
        No[3] := No3;
        TableID[4] := Type4;
        No[4] := No4;
        TableID[5] := Type5;
        No[5] := No5;
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetDefaultDimID(
            TableID, No, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowDimensions()
    var
        ShowDimensionLbl: Label '%1 %2 %3', Comment = '%1= Journal Template Name %2= Journal Batch Name %3 = Line No.';
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo(ShowDimensionLbl),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure GetTemplate()
    begin
        if Not TemplateFound Then
            TCSJnlTemplate.Get("Journal Template Name");
        TemplateFound := True;
    end;

    local procedure GetCurrency()
    var
        CurrencyCode: Code[10];
    begin
        GLSetup.Get();
        CurrencyCode := '';
        Currency.InitRoundingPrecision();
    end;

    local procedure UpdateDataOnAccountNo()
    var
        Cust: Record Customer;
    begin
        Case "Account Type" Of
            "Account Type"::"G/L Account":
                Begin
                    GLAcc.Get("Account No.");
                    CheckGLAcc();
                    GLSetup.Get();
                    ReplaceInfo := "Bal. Account No." = '';
                    if Not ReplaceInfo Then Begin
                        TCSJnlBatch.Get("Journal Template Name", "Journal Batch Name");
                        ReplaceInfo := TCSJnlBatch."Bal. Account No." <> '';
                    end;
                    if ReplaceInfo Then
                        Description := GLAcc.Name;
                end;
            "Account Type"::Customer:
                Begin
                    Cust.Get("Account No.");
                    Cust.CheckBlockedCustOnJnls(Cust, "Document Type", False);
                    Description := Cust.Name;
                end;
        end;
    end;

    local procedure UpdateDataOnBalAccountNo()
    var
        Cust: Record Customer;
        BankAcc: Record "Bank Account";
    begin
        Case "Bal. Account Type" Of
            "Bal. Account Type"::"G/L Account":
                Begin
                    GLAcc.Get("Bal. Account No.");
                    CheckGLAcc();
                    GLSetup.Get();
                    if "Account No." = '' Then
                        Description := GLAcc.Name;
                end;
            "Bal. Account Type"::Customer:
                Begin
                    Cust.Get("Bal. Account No.");
                    Cust.CheckBlockedCustOnJnls(Cust, "Document Type", False);
                    if "Account No." = '' Then
                        Description := Cust.Name;
                end;
            "Bal. Account Type"::"Bank Account":
                Begin
                    BankAcc.Get("Bal. Account No.");
                    BankAcc.TestField(Blocked, False);
                    if "Account No." = '' Then
                        Description := BankAcc.Name;
                end;
        end;
    end;

    var
        TCSJnlTemplate: Record "TCS Journal Template";
        TCSJnlBatch: Record "TCS Journal Batch";
        GLAcc: Record "G/L Account";
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        TCSManagement: Codeunit "TCS Management";
        TCSAdjustment: Codeunit "TCS Adjustment";
        ReplaceInfo: Boolean;
        TemplateFound: Boolean;
}