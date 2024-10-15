table 18747 "TDS Journal Line"
{
    Caption = 'TDS Journal Line';
    Extensible = true;
    Access = Public;
    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "TDS Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Account Type"; Enum "TDS Account Type")
        {
            Caption = 'Account Type';
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            begin
                if ("Account Type" In ["Account Type"::Customer, "Account Type"::Vendor]) AND
                   ("Bal. Account Type" IN ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor])
                then
                    ERROR(
                      AccountTypeErr,
                      FIELDCAPTION("Account Type"), FIELDCAPTION("Bal. Account Type"));
                VALIDATE("Account No.", '');
            end;
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Account Type" = CONST("G/L Account")) "G/L Account"
            else
            if ("Account Type" = CONST(Customer)) Customer
            else
            if ("Account Type" = CONST(Vendor)) Vendor
            else
            if ("Account Type" = CONST("Bank Account")) "Bank Account";

            trigger OnValidate()
            begin
                if "Account No." = '' then begin
                    CreateDim(
                      DimMgt.TypeToTableID1("Account Type"), "Account No.",
                      DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                      DATABASE::Job, '',
                      DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                      DATABASE::Campaign, '');
                    exit;
                end;
                case "Account Type" of
                    "Account Type"::"G/L Account":
                        begin
                            GLAcc.GET("Account No.");
                            CheckGLAcc();
                            GLSetup.GET();
                            ReplaceInfo := "Bal. Account No." = '';
                            IF NOT ReplaceInfo then begin
                                TDSJnlBatch.GET("Journal Template Name", "Journal Batch Name");
                                ReplaceInfo := TDSJnlBatch."Bal. Account No." <> '';
                            end;
                            IF ReplaceInfo then
                                Description := GLAcc.Name;

                        end;
                    "Account Type"::Customer:
                        begin
                            Cust.GET("Account No.");
                            Cust.CheckBlockedCustOnJnls(Cust, "Document Type", FALSE);
                            Description := Cust.Name;
                            "Salespers./Purch. Code" := Cust."Salesperson Code";
                        end;
                    "Account Type"::Vendor:
                        begin
                            Vend.GET("Account No.");
                            Vend.CheckBlockedVendOnJnls(Vend, "Document Type", FALSE);
                            Description := Vend.Name;
                            "Salespers./Purch. Code" := Vend."Purchaser Code";
                        end;
                    "Account Type"::"Bank Account":
                        begin
                            BankAcc.GET("Account No.");
                            BankAcc.TESTFIELD(Blocked, FALSE);
                            ReplaceInfo := "Bal. Account No." = '';
                            IF NOT ReplaceInfo then begin
                                TDSJnlBatch.GET("Journal Template Name", "Journal Batch Name");
                                ReplaceInfo := TDSJnlBatch."Bal. Account No." <> '';
                            end;
                            IF ReplaceInfo then
                                Description := BankAcc.Name;
                        end;
                end;
                CreateDim(
                  DimMgt.TypeToTableID1("Account Type"), "Account No.",
                  DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                  DATABASE::Job, '',
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                  DATABASE::Campaign, '');
            end;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ClosingDates = true;
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                if "Posting Date" < xRec."Posting Date" then
                    ERROR(PostingDateErr, "Posting Date", xRec."Posting Date");
                VALIDATE("Document Date", "Posting Date");
            end;
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Document Type';
            trigger OnValidate()
            begin
                if "Account No." <> '' then
                    case "Account Type" of
                        "Account Type"::Customer:
                            begin
                                Cust.GET("Account No.");
                                Cust.CheckBlockedCustOnJnls(Cust, "Document Type", FALSE);
                            end;
                        "Account Type"::Vendor:
                            begin
                                Vend.GET("Account No.");
                                Vend.CheckBlockedVendOnJnls(Vend, "Document Type", FALSE);
                            end;
                    end;
            end;
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            else
            IF ("Bal. Account Type" = CONST(Customer)) Customer
            else
            IF ("Bal. Account Type" = CONST(Vendor)) Vendor
            else
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account";

            trigger OnValidate()
            begin
                IF "Bal. Account No." = '' then begin
                    CreateDim(
                      DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                      DimMgt.TypeToTableID1("Account Type"), "Account No.",
                      DATABASE::Job, '',
                      DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                      DATABASE::Campaign, '');
                    exit;
                end;

                case "Bal. Account Type" of
                    "Bal. Account Type"::"G/L Account":
                        begin
                            GLAcc.GET("Bal. Account No.");
                            CheckGLAcc();
                            GLSetup.GET();
                            IF "Account No." = '' then
                                Description := GLAcc.Name;
                        end;
                    "Bal. Account Type"::Customer:
                        begin
                            Cust.GET("Bal. Account No.");
                            Cust.CheckBlockedCustOnJnls(Cust, "Document Type", FALSE);
                            IF "Account No." = '' then
                                Description := Cust.Name;
                        end;
                    "Bal. Account Type"::Vendor:
                        begin
                            Vend.GET("Bal. Account No.");
                            Vend.CheckBlockedVendOnJnls(Vend, "Document Type", FALSE);
                            IF "Account No." = '' then
                                Description := Vend.Name;
                        end;
                    "Bal. Account Type"::"Bank Account":
                        begin
                            BankAcc.GET("Bal. Account No.");
                            BankAcc.TESTFIELD(Blocked, FALSE);
                            if "Account No." = '' then
                                Description := BankAcc.Name;
                        end;
                end;
                CreateDim(
                  DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                  DimMgt.TypeToTableID1("Account Type"), "Account No.",
                  DATABASE::Job, '',
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                  DATABASE::Campaign, '');
            end;
        }
        field(10; "Salespers./Purch. Code"; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                GetCurrency();
                Amount := ROUND(Amount, Currency."Amount Rounding Precision");
            end;
        }
        field(12; "Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                GetCurrency();
                "Debit Amount" := ROUND("Debit Amount", Currency."Amount Rounding Precision");
                Amount := "Debit Amount";
                VALIDATE(Amount);
            end;
        }
        field(13; "Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                GetCurrency();
                "Credit Amount" := ROUND("Credit Amount", Currency."Amount Rounding Precision");
                Amount := -"Credit Amount";
                VALIDATE(Amount);
            end;
        }
        field(14; "Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Balance (LCY)';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(15; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
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
            Caption = 'Shortcut Dimension 2 Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(17; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Source Code";
        }
        field(18; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(19; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "TDS Journal Batch".Name WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(20; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Reason Code";
        }
        field(21; "Bal. Account Type"; Enum "TDS Bal. Account Type")
        {
            Caption = 'Bal. Account Type';
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            begin
                IF ("Account Type" IN ["Account Type"::Customer, "Account Type"::Vendor]) AND
                   ("Bal. Account Type" IN ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor])
                then
                    ERROR(AccountTypeErr, FIELDCAPTION("Account Type"), FIELDCAPTION("Bal. Account Type"));
                VALIDATE("Bal. Account No.", '');
            end;
        }
        field(22; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ClosingDates = true;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(23; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(24; "Posting No. Series"; Code[10])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(25; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
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
            Caption = 'State Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(27; "TDS Amount"; Decimal)
        {
            Caption = 'TDS Amount';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(28; "Tax Amount"; Decimal)
        {
            Caption = 'Tax Amount';
            DataClassification = EndUserIdentifiableInformation;
            DecimalPlaces = 0 : 4;
        }
        field(29; "Location Code"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(30; "Assessee Code"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Assessee Code';
            Editable = false;
            TableRelation = "Assessee Code";
        }
        field(31; "TDS %"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'TDS %';
            Editable = false;

            trigger OnValidate()
            begin
                IF xRec."TDS %" > 0 then begin
                    IF "Debit Amount" <> 0 then
                        TDSAmt := "Debit Amount"
                    else
                        TDSAmt := "Credit Amount";

                    IF "Bal. TDS Including SHE CESS" <> 0 then
                        TDSAmt := "Bal. TDS Including SHE CESS";
                    "Bal. TDS Including SHE CESS" := ROUND("TDS %" * TDSAmt / xRec."TDS %", Currency."Amount Rounding Precision");
                    "TDS Amount" := ROUND("TDS %" * TDSAmt / xRec."TDS %", Currency."Amount Rounding Precision");
                end else begin
                    "Bal. TDS Including SHE CESS" := ROUND(("TDS %" * (1 + "Surcharge %" / 100)) * Amount / 100,
                        Currency."Amount Rounding Precision");
                    "TDS Amount" := ROUND("TDS %" * Amount / 100, Currency."Amount Rounding Precision");
                end;
            end;
        }
        field(32; "TDS Amt Incl Surcharge"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'TDS Amt Incl Surcharge';
            Editable = false;
        }
        field(33; "Bal. TDS Including SHE CESS"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Bal. TDS Including SHE CESS';
            Editable = false;
        }
        field(34; "CESS Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'CESS Amount';

            trigger OnValidate()
            begin
                VALIDATE(Amount,
                  "CESS Amount" + "Surcharge Amount" +
                  "eCess Amount" + "SHE Cess Amount");
            end;
        }
        field(35; "eCess Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'eCess Amount';

            trigger OnValidate()
            begin
                VALIDATE(Amount,
                  "CESS Amount" + "Surcharge Amount" +
                  "eCess Amount" + "SHE Cess Amount");
            end;
        }
        field(36; "Surcharge %"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Surcharge %';
            Editable = false;
        }
        field(37; "Surcharge Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Surcharge Amount';
            Editable = false;
        }
        field(38; "Concessional Code"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Concessional Code';
            Editable = false;
            TableRelation = "Concessional Code";
        }
        field(39; "TDS Entry"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'TDS Entry';
        }
        field(40; "TDS % Applied"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'TDS % Applied';

            trigger OnValidate()
            begin
                IF "Work Tax" then
                    FIELDERROR("TDS % Applied");
                "TDS Adjusted" := TRUE;
                "Balance TDS Amount" := "TDS % Applied" * "TDS Base Amount" / 100;
                "Surcharge Base Amount" := "Balance TDS Amount";

                IF ("Surcharge % Applied" = 0) AND (NOT "Surcharge Adjusted") then begin
                    "Surcharge % Applied" := "Surcharge %";
                    "Balance Surcharge Amount" := "Surcharge %" * "Balance TDS Amount" / 100;
                END else
                    "Balance Surcharge Amount" := RoundTDSAmount("Balance TDS Amount" * "Surcharge % Applied" / 100);

                IF ("eCESS % Applied" = 0) AND (NOT "TDS eCess Adjusted") then begin
                    "eCESS % Applied" := "eCESS %";
                    "Balance eCESS on TDS Amt" := "eCESS %" * ("Balance TDS Amount" + "Balance Surcharge Amount") / 100;
                END else
                    "Balance eCESS on TDS Amt" := RoundTDSAmount(("Balance TDS Amount" + "Balance Surcharge Amount") *
                        "eCESS % Applied" / 100);

                IF ("SHE Cess % Applied" = 0) AND (NOT "TDS SHE Cess Adjusted") then begin
                    "SHE Cess % Applied" := "SHE Cess %";
                    "Bal. SHE Cess on TDS Amt" := "SHE Cess %" * ("Balance TDS Amount" + "Balance Surcharge Amount") / 100;
                END else
                    "Bal. SHE Cess on TDS Amt" := RoundTDSAmount(("Balance TDS Amount" + "Balance Surcharge Amount") *
                        "SHE Cess % Applied" / 100);

                if ("TDS % Applied" = 0) AND "TDS Adjusted" then begin
                    VALIDATE("Surcharge % Applied", 0);
                    VALIDATE("eCESS % Applied", 0);
                    VALIDATE("SHE Cess % Applied", 0);
                end;

                "Balance TDS Amount" := RoundTDSAmount("Balance TDS Amount");
                "Balance Surcharge Amount" := RoundTDSAmount("Balance Surcharge Amount");
                "Balance eCESS on TDS Amt" := RoundTDSAmount("Balance eCESS on TDS Amt");
                "Bal. SHE Cess on TDS Amt" := RoundTDSAmount("Bal. SHE Cess on TDS Amt");

                if "Debit Amount" < RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                "Bal. SHE Cess on TDS Amt") then begin
                    Amount := (RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                                     "Bal. SHE Cess on TDS Amt") - "Debit Amount");
                    "Bal. TDS Including SHE CESS" :=
                      ABS(RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                          "Bal. SHE Cess on TDS Amt"));
                end else begin
                    Amount := -("Debit Amount" - RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" +
                                  "Balance eCESS on TDS Amt" + "Bal. SHE Cess on TDS Amt"));
                    "Bal. TDS Including SHE CESS" := ABS(RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" +
                          "Balance eCESS on TDS Amt" + "Bal. SHE Cess on TDS Amt"));
                end;
            end;
        }
        field(41; "TDS Invoice No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'TDS Invoice No.';
            Editable = false;
        }
        field(42; "TDS Base Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'TDS Base Amount';
            Editable = false;
        }
        field(43; "Challan No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Challan No.';
        }
        field(44; "Challan Date"; Date)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Challan Date';
        }
        field(45; Adjustment; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Adjustment';
            Editable = false;
        }
        field(46; "TDS Transaction No."; Integer)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'TDS Transaction No.';
            Editable = false;
        }
        field(47; "E.C.C. No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'E.C.C. No.';
        }
        field(48; "Balance Surcharge Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Balance Surcharge Amount';
            Editable = false;
        }
        field(49; "Surcharge % Applied"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Surcharge % Applied';

            trigger OnValidate()
            var
                BalanceTDS: Decimal;
            begin
                if "Work Tax" then
                    FIELDERROR("Surcharge % Applied");
                if ("TDS % Applied" = 0) AND (NOT "TDS Adjusted") then
                    BalanceTDS := "TDS Base Amount" * "TDS %" / 100
                else
                    BalanceTDS := "TDS Base Amount" * "TDS % Applied" / 100;
                "Surcharge Adjusted" := TRUE;
                "Balance Surcharge Amount" := "Surcharge % Applied" * BalanceTDS / 100;
                if ("eCESS % Applied" = 0) AND (NOT "TDS eCess Adjusted") then
                    "Balance eCESS on TDS Amt" := ("Balance Surcharge Amount" + BalanceTDS) * "eCESS %" / 100
                else
                    "Balance eCESS on TDS Amt" := RoundTDSAmount(("Balance Surcharge Amount" + BalanceTDS) * "eCESS % Applied" / 100);

                if ("SHE Cess % Applied" = 0) AND (NOT "TDS SHE Cess Adjusted") then
                    "Bal. SHE Cess on TDS Amt" := ("Balance Surcharge Amount" + BalanceTDS) * "SHE Cess %" / 100
                else
                    "Bal. SHE Cess on TDS Amt" := RoundTDSAmount(("Balance Surcharge Amount" + BalanceTDS) * "SHE Cess % Applied" / 100);

                "Balance TDS Amount" := RoundTDSAmount(BalanceTDS);
                "Balance Surcharge Amount" := RoundTDSAmount("Balance Surcharge Amount");
                "Balance eCESS on TDS Amt" := RoundTDSAmount("Balance eCESS on TDS Amt");
                "Bal. SHE Cess on TDS Amt" := RoundTDSAmount("Bal. SHE Cess on TDS Amt");

                if "Debit Amount" < RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                     "Bal. SHE Cess on TDS Amt")
                then begin
                    Amount := RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                        "Bal. SHE Cess on TDS Amt") - "Debit Amount";
                    "Bal. TDS Including SHE CESS" :=
                      ABS(RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                          "Bal. SHE Cess on TDS Amt"));
                end else begin
                    Amount := -("Debit Amount" - RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" +
                                  "Balance eCESS on TDS Amt" + "Bal. SHE Cess on TDS Amt"));
                    "Bal. TDS Including SHE CESS" :=
                      ABS(RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                          "Bal. SHE Cess on TDS Amt"));
                end;
            end;
        }
        field(50; "Surcharge Base Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Surcharge Base Amount';
            Editable = false;
        }
        field(51; "Balance TDS Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Balance TDS Amount';
            Editable = false;
        }
        field(52; "eCESS %"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'eCESS %';
            Editable = false;
        }
        field(53; "eCESS on TDS Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'eCESS on TDS Amount';
            Editable = false;
        }
        field(54; "Total TDS Incl. SHE CESS"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Total TDS Incl. SHE CESS';
            Editable = false;
        }
        field(55; "eCESS Base Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'eCESS Base Amount';
        }
        field(56; "eCESS % Applied"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'eCESS % Applied';

            trigger OnValidate()
            var
                BalanceTDS: Decimal;
                BalanceSurcharge: Decimal;
            begin
                if "Work Tax" then
                    FIELDERROR("eCESS % Applied");
                if ("TDS % Applied" = 0) and (not "TDS Adjusted") then
                    BalanceTDS := "TDS Base Amount" * "TDS %" / 100
                else
                    BalanceTDS := "TDS Base Amount" * "TDS % Applied" / 100;

                if ("Surcharge % Applied" = 0) and (not "Surcharge Adjusted") then
                    BalanceSurcharge := BalanceTDS * "Surcharge %" / 100
                else
                    BalanceSurcharge := BalanceTDS * "Surcharge % Applied" / 100;

                "TDS eCess Adjusted" := TRUE;
                "Balance eCESS on TDS Amt" := (BalanceTDS + BalanceSurcharge) * "eCESS % Applied" / 100;

                if ("SHE Cess % Applied" = 0) and (not "TDS SHE Cess Adjusted") then
                    "Bal. SHE Cess on TDS Amt" := (BalanceTDS + BalanceSurcharge) * "SHE Cess %" / 100
                else
                    "Bal. SHE Cess on TDS Amt" := (BalanceTDS + BalanceSurcharge) * "SHE Cess % Applied" / 100;

                "Balance TDS Amount" := RoundTDSAmount(BalanceTDS);
                "Balance Surcharge Amount" := RoundTDSAmount(BalanceSurcharge);
                "Balance eCESS on TDS Amt" := RoundTDSAmount("Balance eCESS on TDS Amt");
                "Bal. SHE Cess on TDS Amt" := RoundTDSAmount("Bal. SHE Cess on TDS Amt");

                if "Debit Amount" < RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                     "Bal. SHE Cess on TDS Amt")
                then begin
                    Amount := (RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                                 "Bal. SHE Cess on TDS Amt") - "Debit Amount");
                    "Bal. TDS Including SHE CESS" :=
                      ABS(RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                          "Bal. SHE Cess on TDS Amt"));
                end else begin
                    Amount :=
                      -("Debit Amount" - RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                          "Bal. SHE Cess on TDS Amt"));
                    "Bal. TDS Including SHE CESS" :=
                      ABS(RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                          "Bal. SHE Cess on TDS Amt"));
                end;
            end;
        }
        field(58; "Per Contract"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Per Contract';
        }
        field(59; "Bal. SHE Cess on TDS Amt"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Bal. SHE Cess on TDS Amt';
        }
        field(60; "T.A.N. No."; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'T.A.N. No.';
            TableRelation = "TAN Nos.";
        }
        field(61; "SHE Cess Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            AutoFormatType = 1;
            Caption = 'SHE Cess Amount';

            trigger OnValidate()
            begin
                VALIDATE(Amount,
                  "CESS Amount" + "Surcharge Amount" +
                  "eCess Amount" + "SHE Cess Amount");
            end;
        }
        field(62; "SHE Cess %"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'SHE Cess %';
            Editable = false;
        }
        field(63; "SHE Cess on TDS Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'SHE Cess on TDS Amount';
            Editable = false;
        }
        field(64; "SHE Cess Base Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'SHE Cess Base Amount';
            Editable = false;
        }
        field(65; "SHE Cess % Applied"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'SHE Cess % Applied';

            trigger OnValidate()
            var
                BalanceTDS: Decimal;
                BalanceSurcharge: Decimal;
            begin
                if "Work Tax" then
                    FIELDERROR("SHE Cess % Applied");
                if ("TDS % Applied" = 0) and (not "TDS Adjusted") then
                    BalanceTDS := "TDS Base Amount" * "TDS %" / 100
                else
                    BalanceTDS := "TDS Base Amount" * "TDS % Applied" / 100;

                if ("Surcharge % Applied" = 0) and (not "Surcharge Adjusted") then
                    BalanceSurcharge := BalanceTDS * "Surcharge %" / 100
                else
                    BalanceSurcharge := BalanceTDS * "Surcharge % Applied" / 100;

                if ("eCESS % Applied" = 0) and (not "TDS eCess Adjusted") then
                    "Balance eCESS on TDS Amt" := (BalanceTDS + BalanceSurcharge) * "eCESS %" / 100
                else
                    "Balance eCESS on TDS Amt" := (BalanceTDS + BalanceSurcharge) * "eCESS % Applied" / 100;

                "TDS SHE Cess Adjusted" := TRUE;
                "Bal. SHE Cess on TDS Amt" := (BalanceTDS + BalanceSurcharge) * "SHE Cess % Applied" / 100;

                "Balance TDS Amount" := RoundTDSAmount(BalanceTDS);
                "Balance Surcharge Amount" := RoundTDSAmount(BalanceSurcharge);
                "Balance eCESS on TDS Amt" := RoundTDSAmount("Balance eCESS on TDS Amt");
                "Bal. SHE Cess on TDS Amt" := RoundTDSAmount("Bal. SHE Cess on TDS Amt");

                if "Debit Amount" < RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                     "Bal. SHE Cess on TDS Amt")
                then begin
                    Amount := (RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                                 "Bal. SHE Cess on TDS Amt") - "Debit Amount");
                    "Bal. TDS Including SHE CESS" :=
                      ABS(RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                          "Bal. SHE Cess on TDS Amt"));
                end else begin
                    Amount :=
                      -("Debit Amount" - RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                          "Bal. SHE Cess on TDS Amt"));
                    "Bal. TDS Including SHE CESS" :=
                      ABS(RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                          "Bal. SHE Cess on TDS Amt"));
                end;
            end;
        }
        field(66; "TDS Adjusted"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'TDS Adjusted';
        }
        field(67; "Surcharge Adjusted"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Surcharge Adjusted';
        }
        field(68; "TDS eCess Adjusted"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'TDS eCess Adjusted';
        }
        field(69; "TDS SHE Cess Adjusted"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'TDS SHE Cess Adjusted';
        }
        field(70; "TDS Base Amount Applied"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'TDS Base Amount Applied';

            trigger OnValidate()
            begin
                TestField("TDS Base Amount Applied", 0);
                if "Work Tax" then
                    FIELDERROR("TDS Base Amount Applied");
                "TDS Base Amount Adjusted" := TRUE;
                "TDS Base Amount" := "TDS Base Amount Applied";

                if ("TDS % Applied" = 0) and (not "TDS Adjusted") then begin
                    "TDS % Applied" := "TDS %";
                    "Balance TDS Amount" := "TDS %" * "TDS Base Amount" / 100;
                end else
                    "Balance TDS Amount" := RoundTDSAmount("TDS Base Amount" * "TDS % Applied" / 100);

                "Surcharge Base Amount" := "Balance TDS Amount";

                if ("Surcharge % Applied" = 0) and (not "Surcharge Adjusted") then begin
                    "Surcharge % Applied" := "Surcharge %";
                    "Balance Surcharge Amount" := "Surcharge %" * "Balance TDS Amount" / 100;
                end else
                    "Balance Surcharge Amount" := RoundTDSAmount("Balance TDS Amount" * "Surcharge % Applied" / 100);

                if ("eCESS % Applied" = 0) and (not "TDS eCess Adjusted") then begin
                    "eCESS % Applied" := "eCESS %";
                    "Balance eCESS on TDS Amt" := "eCESS %" * ("Balance TDS Amount" + "Balance Surcharge Amount") / 100;
                end else
                    "Balance eCESS on TDS Amt" := RoundTDSAmount(("Balance Surcharge Amount" +
                                                                      "Balance TDS Amount") * "eCESS % Applied" / 100);

                if ("SHE Cess % Applied" = 0) and (not "TDS SHE Cess Adjusted") then begin
                    "SHE Cess % Applied" := "SHE Cess %";
                    "Bal. SHE Cess on TDS Amt" := "SHE Cess %" * ("Balance TDS Amount" + "Balance Surcharge Amount") / 100;
                end else
                    "Bal. SHE Cess on TDS Amt" := RoundTDSAmount(("Balance Surcharge Amount" +
                                                                      "Balance TDS Amount") * "SHE Cess % Applied" / 100);

                if ("TDS Base Amount Applied" = 0) and "TDS Base Amount Adjusted" then begin
                    VALIDATE("TDS % Applied", 0);
                    VALIDATE("Surcharge % Applied", 0);
                    VALIDATE("eCESS % Applied", 0);
                    VALIDATE("SHE Cess % Applied", 0);
                end;

                "Balance TDS Amount" := RoundTDSAmount("Balance TDS Amount");
                "Balance Surcharge Amount" := RoundTDSAmount("Balance Surcharge Amount");
                "Balance eCESS on TDS Amt" := RoundTDSAmount("Balance eCESS on TDS Amt");
                "Bal. SHE Cess on TDS Amt" := RoundTDSAmount("Bal. SHE Cess on TDS Amt");

                if "TDS Section Code" <> '' then
                    if "Debit Amount" < RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                         "Bal. SHE Cess on TDS Amt")
                    then begin
                        Amount := (RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                                     "Bal. SHE Cess on TDS Amt") - "Debit Amount");
                        "Bal. TDS Including SHE CESS" :=
                          ABS(RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" + "Balance eCESS on TDS Amt" +
                              "Bal. SHE Cess on TDS Amt"));
                    end else begin
                        Amount := -("Debit Amount" - RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" +
                                      "Balance eCESS on TDS Amt" + "Bal. SHE Cess on TDS Amt"));
                        "Bal. TDS Including SHE CESS" := ABS(RoundTDSAmount("Balance TDS Amount" + "Balance Surcharge Amount" +
                              "Balance eCESS on TDS Amt" + "Bal. SHE Cess on TDS Amt"));
                    end;
            end;
        }
        field(71; "TDS Base Amount Adjusted"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'TDS Base Amount Adjusted';
            Editable = false;
        }
        field(72; "TDS Section Code"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'TDS Section Code';
            TableRelation = "TDS Section";
        }
        field(73; "TDSEntry"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'TDS Entry';
        }
        field(74; "Work Tax % Applied"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Work Tax % Applied';
            trigger OnValidate()
            begin
                if not "Work Tax" then
                    FieldError("Work Tax % Applied");
                if not "Reverse Work Tax" then begin
                    "W.T Amount" := "Work Tax % Applied" * "Work Tax Base Amount" / 100;
                    if ("Work Tax Nature Of Deduction" <> '') and ("W.T Amount" <> 0) then begin
                        if "Debit Amount" < RoundTDSAmount("W.T Amount") then
                            Amount := (RoundTDSAmount("W.T Amount") - "Debit Amount")
                        else
                            Amount := -("Debit Amount" - RoundTDSAmount("W.T Amount"));
                    end else
                        if ("Work Tax Nature Of Deduction" <> '') and ("W.T Amount" = 0) then
                            Amount := 0;
                end else
                    Amount := -"Debit Amount";
                if "Work Tax % Applied" <> 0 then
                    TestField("Reverse Work Tax", FALSE);
            end;
        }
        field(75; "W.T Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'W.T Amount';
            Editable = false;
        }
        field(76; "Work Tax"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Work Tax';
        }
        field(77; "Reverse Work Tax"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Reverse Work Tax';
        }
        field(78; "Work Tax Base Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Work Tax Base Amount';
        }
        field(79; "Work Tax %"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Work Tax %';
            Editable = false;
        }
        field(80; "Work Tax Paid"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Work Tax Paid';
            Editable = false;
        }
        field(81; "Work Tax Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Work Tax Amount';
            Editable = false;
        }
        field(82; "Work Tax Nature Of Deduction"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Work Tax Nature Of Deduction';
        }
        field(85; "Work Tax Base Amount Adjusted"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Work Tax Base Amount Adjusted';
        }
        field(86; "Work Tax Base Amount Applied"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Work Tax Base Amount Applied';
        }
        field(87; "Balance eCESS on TDS Amt"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Balance eCESS on TDS Amt';
        }
        field(88; "TDS Adjustment"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'TDS Adjustment';
        }
        field(89; "TDS Line Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'TDS Line Amount';
        }

    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
            MaintainSIFTIndex = false;
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

    var
        TDSJnlTemplate: Record "TDS Journal Template";
        TDSJnlBatch: Record "TDS Journal Batch";
        TDSJnlLine: Record "TDS Journal Line";
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        Currency: Record Currency;
        BankAcc: Record "Bank Account";
        GLSetup: Record "General Ledger Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        ReplaceInfo: Boolean;
        CurrencyCode: Code[10];
        TemplateFound: Boolean;
        AccountTypeErr: Label '%1 or %2 must be G/L Account or Bank Account.', Comment = '%1 = G/L Account No.,%2 = Bank Account No.';
        TDSAmt: Decimal;
        PostingDateErr: Label 'Posting Date %1 for TDS Adjustment cannot be earlier than the Invoice Date %2.', Comment = '%1 = Posting Date, %2 = xRec.Posting Date';

    trigger OnInsert()
    begin
        LOCKTABLE();
        TDSJnlTemplate.GET("Journal Template Name");
        TDSJnlBatch.GET("Journal Template Name", "Journal Batch Name");

        ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    procedure EmptyLine(): Boolean
    begin
        exit(
          ("Account No." = '') AND (Amount = 0) AND
          ("Bal. Account No." = ''));
    end;

    procedure SetUpNewLine(LastTDSJnlLine: Record "TDS Journal Line"; BottomLine: Boolean)
    begin
        TDSJnlTemplate.GET("Journal Template Name");
        TDSJnlBatch.GET("Journal Template Name", "Journal Batch Name");
        TDSJnlLine.SETRANGE("Journal Template Name", "Journal Template Name");
        TDSJnlLine.SETRANGE("Journal Batch Name", "Journal Batch Name");
        IF TDSJnlLine.FINDFIRST() then begin
            "Posting Date" := LastTDSJnlLine."Posting Date";
            "Document Date" := LastTDSJnlLine."Posting Date";
            "Document No." := LastTDSJnlLine."Document No.";
            IF BottomLine AND
               NOT LastTDSJnlLine.EmptyLine()
            then
                "Document No." := INCSTR("Document No.");
        end else begin
            "Posting Date" := WORKDATE();
            "Document Date" := WORKDATE();
            IF TDSJnlBatch."No. Series" <> '' then begin
                CLEAR(NoSeriesMgt);
                "Document No." := NoSeriesMgt.GetNextNo(TDSJnlBatch."No. Series", "Posting Date", FALSE);
            end;
        end;
        "Account Type" := LastTDSJnlLine."Account Type";
        "Document Type" := LastTDSJnlLine."Document Type";
        "Source Code" := TDSJnlTemplate."Source Code";
        "Reason Code" := TDSJnlBatch."Reason Code";
        "Posting No. Series" := TDSJnlBatch."Posting No. Series";
        "Bal. Account Type" := TDSJnlBatch."Bal. Account Type";
        "Location Code" := TDSJnlBatch."Location Code";
        IF ("Account Type" IN ["Account Type"::Customer, "Account Type"::Vendor]) AND
           ("Bal. Account Type" IN ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor])
        then
            "Account Type" := "Account Type"::"G/L Account";
        VALIDATE("Bal. Account No.", TDSJnlBatch."Bal. Account No.");
        Description := '';
    end;

    local procedure CheckGLAcc()
    begin
        GLAcc.CheckGLAcc();
        IF GLAcc."Direct Posting" OR ("Journal Template Name" = '') then
            exit;
        IF "Posting Date" <> 0D then
            IF "Posting Date" = CLOSINGDATE("Posting Date") then
                exit;
        GLAcc.TESTFIELD("Direct Posting", TRUE);
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
            TableID, No, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
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
        DimLbl: Label '%1 %2 %3', Comment = '%1=Journal Template Name, %2=Journal Batch Name, %3=Line No.';
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo(DimLbl, "Journal Template Name", "Journal Batch Name", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure GetTemplate()
    begin
        IF not TemplateFound then
            TDSJnlTemplate.GET("Journal Template Name");
        TemplateFound := TRUE;
    end;

    local procedure GetCurrency()
    begin
        GLSetup.GET();
        CurrencyCode := '';
        Currency.InitRoundingPrecision();
    end;

    procedure RoundTDSAmount(TDSAmount: Decimal): Decimal
    var
        TaxComponent: Record "Tax Component";
        TDSSetup: Record "TDS Setup";
        TDSRoundingDirection: Text;
    begin
        TDSSetup.get();
        TDSSetup.TestField("Tax Type");

        TaxComponent.SetRange("Tax Type", TDSSetup."Tax Type");
        TaxComponent.SetRange(Name, TDSSetup."Tax Type");
        TaxComponent.FindFirst();
        case TaxComponent.Direction of
            TaxComponent.Direction::Nearest:
                TDSRoundingDirection := '=';
            TaxComponent.Direction::Up:
                TDSRoundingDirection := '>';
            TaxComponent.Direction::Down:
                TDSRoundingDirection := '<';
        end;
        exit(ROUND(TDSAmount, TaxComponent."Rounding Precision", TDSRoundingDirection));
    end;
}

