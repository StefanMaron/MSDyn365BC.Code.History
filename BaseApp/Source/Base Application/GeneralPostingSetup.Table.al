table 252 "General Posting Setup"
{
    Caption = 'General Posting Setup';
    DrillDownPageID = "General Posting Setup";
    LookupPageID = "General Posting Setup";

    fields
    {
        field(1; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(2; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            NotBlank = true;
            TableRelation = "Gen. Product Posting Group";
        }
        field(10; "Sales Account"; Code[20])
        {
            Caption = 'Sales Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Sales Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "Sales Account", GLAccountCategory."Account Category"::Income,
                      StrSubstNo('%1|%2', GLAccountCategoryMgt.GetIncomeProdSales, GLAccountCategoryMgt.GetIncomeService));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Account");
            end;
        }
        field(11; "Sales Line Disc. Account"; Code[20])
        {
            Caption = 'Sales Line Disc. Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Sales Line Disc. Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "Sales Line Disc. Account", GLAccountCategory."Account Category"::Income,
                      GLAccountCategoryMgt.GetIncomeSalesDiscounts);
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Line Disc. Account");
            end;
        }
        field(12; "Sales Inv. Disc. Account"; Code[20])
        {
            Caption = 'Sales Inv. Disc. Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Sales Inv. Disc. Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "Sales Inv. Disc. Account", GLAccountCategory."Account Category"::Income,
                      GLAccountCategoryMgt.GetIncomeSalesDiscounts);
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Inv. Disc. Account");
            end;
        }
        field(13; "Sales Pmt. Disc. Debit Acc."; Code[20])
        {
            Caption = 'Sales Pmt. Disc. Debit Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Pmt. Disc. Debit Acc.");
                if "Sales Pmt. Disc. Debit Acc." <> '' then begin
                    GLSetup.Get();
                    GLSetup.TestField("Adjust for Payment Disc.", true);
                end;
            end;
        }
        field(14; "Purch. Account"; Code[20])
        {
            Caption = 'Purch. Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Purch. Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "Purch. Account", GLAccountCategory."Account Category"::"Cost of Goods Sold",
                      StrSubstNo('%1|%2', GLAccountCategoryMgt.GetCOGSMaterials, GLAccountCategoryMgt.GetCOGSLabor));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Account");
            end;
        }
        field(15; "Purch. Line Disc. Account"; Code[20])
        {
            Caption = 'Purch. Line Disc. Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Purch. Line Disc. Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "Purch. Line Disc. Account", GLAccountCategory."Account Category"::"Cost of Goods Sold",
                      GLAccountCategoryMgt.GetCOGSDiscountsGranted);
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Line Disc. Account");
            end;
        }
        field(16; "Purch. Inv. Disc. Account"; Code[20])
        {
            Caption = 'Purch. Inv. Disc. Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Purch. Inv. Disc. Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "Purch. Inv. Disc. Account", GLAccountCategory."Account Category"::"Cost of Goods Sold",
                      GLAccountCategoryMgt.GetCOGSDiscountsGranted);
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Inv. Disc. Account");
            end;
        }
        field(17; "Purch. Pmt. Disc. Credit Acc."; Code[20])
        {
            Caption = 'Purch. Pmt. Disc. Credit Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Pmt. Disc. Credit Acc.");
                if "Purch. Pmt. Disc. Credit Acc." <> '' then begin
                    GLSetup.Get();
                    GLSetup.TestField("Adjust for Payment Disc.", true);
                end;
            end;
        }
        field(18; "COGS Account"; Code[20])
        {
            Caption = 'COGS Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("COGS Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "COGS Account", GLAccountCategory."Account Category"::"Cost of Goods Sold",
                      StrSubstNo('%1|%2', GLAccountCategoryMgt.GetCOGSMaterials, GLAccountCategoryMgt.GetCOGSLabor));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("COGS Account");
            end;
        }
        field(19; "Inventory Adjmt. Account"; Code[20])
        {
            Caption = 'Inventory Adjmt. Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Inventory Adjmt. Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "Inventory Adjmt. Account", GLAccountCategory."Account Category"::"Cost of Goods Sold",
                      StrSubstNo('%1|%2', GLAccountCategoryMgt.GetCOGSMaterials, GLAccountCategoryMgt.GetCOGSLabor));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Inventory Adjmt. Account");
            end;
        }
        field(27; "Sales Credit Memo Account"; Code[20])
        {
            Caption = 'Sales Credit Memo Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Credit Memo Account");
            end;
        }
        field(28; "Purch. Credit Memo Account"; Code[20])
        {
            Caption = 'Purch. Credit Memo Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Credit Memo Account");
            end;
        }
        field(30; "Sales Pmt. Disc. Credit Acc."; Code[20])
        {
            Caption = 'Sales Pmt. Disc. Credit Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Pmt. Disc. Credit Acc.");
                if "Sales Pmt. Disc. Credit Acc." <> '' then begin
                    GLSetup.Get();
                    GLSetup.TestField("Adjust for Payment Disc.", true);
                end;
            end;
        }
        field(31; "Purch. Pmt. Disc. Debit Acc."; Code[20])
        {
            Caption = 'Purch. Pmt. Disc. Debit Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Pmt. Disc. Debit Acc.");
                if "Purch. Pmt. Disc. Debit Acc." <> '' then begin
                    GLSetup.Get();
                    GLSetup.TestField("Adjust for Payment Disc.", true);
                end;
            end;
        }
        field(32; "Sales Pmt. Tol. Debit Acc."; Code[20])
        {
            Caption = 'Sales Pmt. Tol. Debit Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Pmt. Tol. Debit Acc.");
                if "Purch. Pmt. Disc. Debit Acc." <> '' then begin
                    GLSetup.Get();
                    GLSetup.TestField("Adjust for Payment Disc.", true);
                end;
            end;
        }
        field(33; "Sales Pmt. Tol. Credit Acc."; Code[20])
        {
            Caption = 'Sales Pmt. Tol. Credit Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Pmt. Tol. Credit Acc.");
                if "Purch. Pmt. Disc. Debit Acc." <> '' then begin
                    GLSetup.Get();
                    GLSetup.TestField("Adjust for Payment Disc.", true);
                end;
            end;
        }
        field(34; "Purch. Pmt. Tol. Debit Acc."; Code[20])
        {
            Caption = 'Purch. Pmt. Tol. Debit Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Pmt. Tol. Debit Acc.");
                if "Purch. Pmt. Disc. Debit Acc." <> '' then begin
                    GLSetup.Get();
                    GLSetup.TestField("Adjust for Payment Disc.", true);
                end;
            end;
        }
        field(35; "Purch. Pmt. Tol. Credit Acc."; Code[20])
        {
            Caption = 'Purch. Pmt. Tol. Credit Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Pmt. Tol. Credit Acc.");
                if "Purch. Pmt. Disc. Debit Acc." <> '' then begin
                    GLSetup.Get();
                    GLSetup.TestField("Adjust for Payment Disc.", true);
                end;
            end;
        }
        field(36; "Sales Prepayments Account"; Code[20])
        {
            Caption = 'Sales Prepayments Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Prepayments Account");
            end;
        }
        field(37; "Purch. Prepayments Account"; Code[20])
        {
            Caption = 'Purch. Prepayments Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Prepayments Account");
            end;
        }
        field(50; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(51; "View All Accounts on Lookup"; Boolean)
        {
            Caption = 'View All Accounts on Lookup';
        }
        field(5600; "Purch. FA Disc. Account"; Code[20])
        {
            Caption = 'Purch. FA Disc. Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. FA Disc. Account");
            end;
        }
        field(5801; "Invt. Accrual Acc. (Interim)"; Code[20])
        {
            Caption = 'Invt. Accrual Acc. (Interim)';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Inventory Adjmt. Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "Inventory Adjmt. Account", GLAccountCategory."Account Category"::"Cost of Goods Sold",
                      StrSubstNo('%1|%2', GLAccountCategoryMgt.GetCOGSMaterials, GLAccountCategoryMgt.GetCOGSLabor));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Invt. Accrual Acc. (Interim)");
            end;
        }
        field(5803; "COGS Account (Interim)"; Code[20])
        {
            Caption = 'COGS Account (Interim)';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("COGS Account (Interim)")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "COGS Account (Interim)", GLAccountCategory."Account Category"::"Cost of Goods Sold",
                      StrSubstNo('%1|%2', GLAccountCategoryMgt.GetCOGSMaterials, GLAccountCategoryMgt.GetCOGSLabor));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("COGS Account (Interim)");
            end;
        }
        field(99000752; "Direct Cost Applied Account"; Code[20])
        {
            Caption = 'Direct Cost Applied Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Direct Cost Applied Account");
            end;
        }
        field(99000753; "Overhead Applied Account"; Code[20])
        {
            Caption = 'Overhead Applied Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Overhead Applied Account");
            end;
        }
        field(99000754; "Purchase Variance Account"; Code[20])
        {
            Caption = 'Purchase Variance Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Purchase Variance Account");
            end;
        }
    }

    keys
    {
        key(Key1; "Gen. Bus. Posting Group", "Gen. Prod. Posting Group")
        {
            Clustered = true;
        }
        key(Key2; "Gen. Prod. Posting Group", "Gen. Bus. Posting Group")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckSetupUsage;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        YouCannotDeleteErr: Label 'You cannot delete %1 %2.', Comment = '%1 = Location Code; %2 = Posting Group';
        PostingSetupMgt: Codeunit PostingSetupManagement;

    procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc;
        end;
    end;

    local procedure CheckSetupUsage()
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
        GLEntry.SetRange("Gen. Prod. Posting Group", "Gen. Prod. Posting Group");
        if not GLEntry.IsEmpty then
            Error(YouCannotDeleteErr, "Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
    end;

    local procedure FilterBlankSalesDiscountAccounts(DiscountPosting: Option; var FieldNumber: Integer) Found: Boolean
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        if DiscountPosting = SalesSetup."Discount Posting"::"All Discounts" then
            FilterGroup(-1);
        if DiscountPosting <> SalesSetup."Discount Posting"::"Line Discounts" then begin
            SetRange("Sales Inv. Disc. Account", '');
            FieldNumber := FieldNo("Sales Inv. Disc. Account");
        end;
        if DiscountPosting <> SalesSetup."Discount Posting"::"Invoice Discounts" then begin
            SetRange("Sales Line Disc. Account", '');
            FieldNumber := FieldNo("Sales Line Disc. Account");
        end;
        Found := FindSet;
        if (DiscountPosting = SalesSetup."Discount Posting"::"All Discounts") and ("Sales Line Disc. Account" <> '') then
            FieldNumber := FieldNo("Sales Inv. Disc. Account");
    end;

    local procedure FilterBlankPurchDiscountAccounts(DiscountPosting: Option; var FieldNumber: Integer) Found: Boolean
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        if DiscountPosting = PurchSetup."Discount Posting"::"All Discounts" then
            FilterGroup(-1);
        if DiscountPosting <> PurchSetup."Discount Posting"::"Line Discounts" then begin
            SetRange("Purch. Inv. Disc. Account", '');
            FieldNumber := FieldNo("Purch. Inv. Disc. Account");
        end;
        if DiscountPosting <> PurchSetup."Discount Posting"::"Invoice Discounts" then begin
            SetRange("Purch. Line Disc. Account", '');
            FieldNumber := FieldNo("Purch. Line Disc. Account");
        end;
        Found := FindSet;
        if (DiscountPosting = PurchSetup."Discount Posting"::"All Discounts") and ("Purch. Line Disc. Account" <> '') then
            FieldNumber := FieldNo("Purch. Inv. Disc. Account");
    end;

    procedure FindSetupMissingSalesDiscountAccount(DiscountPosting: Option; var FieldNumber: Integer): Boolean
    begin
        if FilterBlankSalesDiscountAccounts(DiscountPosting, FieldNumber) then begin
            MarkRecords;
            exit(FindSet);
        end;
    end;

    procedure FindSetupMissingPurchDiscountAccount(DiscountPosting: Option; var FieldNumber: Integer): Boolean
    begin
        if FilterBlankPurchDiscountAccounts(DiscountPosting, FieldNumber) then begin
            MarkRecords;
            exit(FindSet);
        end;
    end;

    local procedure MarkRecords()
    begin
        if FindSet then
            repeat
                Mark(true);
            until Next = 0;
        FilterGroup(0);
        MarkedOnly(true);
    end;

    procedure GetCOGSAccount(): Code[20]
    begin
        if "COGS Account" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("COGS Account"));
        TestField("COGS Account");
        exit("COGS Account");
    end;

    procedure GetCOGSInterimAccount(): Code[20]
    begin
        if "COGS Account (Interim)" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("COGS Account (Interim)"));
        TestField("COGS Account (Interim)");
        exit("COGS Account (Interim)");
    end;

    procedure GetInventoryAdjmtAccount(): Code[20]
    begin
        if "Inventory Adjmt. Account" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Inventory Adjmt. Account"));
        TestField("Inventory Adjmt. Account");
        exit("Inventory Adjmt. Account");
    end;

    procedure GetInventoryAccrualAccount(): Code[20]
    begin
        if "Invt. Accrual Acc. (Interim)" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Invt. Accrual Acc. (Interim)"));
        TestField("Invt. Accrual Acc. (Interim)");
        exit("Invt. Accrual Acc. (Interim)");
    end;

    procedure GetSalesAccount(): Code[20]
    begin
        if "Sales Account" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Sales Account"));
        TestField("Sales Account");
        exit("Sales Account");
    end;

    procedure GetSalesCrMemoAccount(): Code[20]
    begin
        if "Sales Credit Memo Account" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Sales Credit Memo Account"));
        TestField("Sales Credit Memo Account");
        exit("Sales Credit Memo Account");
    end;

    procedure GetSalesInvDiscAccount(): Code[20]
    begin
        if "Sales Inv. Disc. Account" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Sales Inv. Disc. Account"));
        TestField("Sales Inv. Disc. Account");
        exit("Sales Inv. Disc. Account");
    end;

    procedure GetSalesLineDiscAccount(): Code[20]
    begin
        if "Sales Line Disc. Account" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Sales Line Disc. Account"));
        TestField("Sales Line Disc. Account");
        exit("Sales Line Disc. Account");
    end;

    procedure GetSalesPmtDiscountAccount(Debit: Boolean): Code[20]
    begin
        if Debit then begin
            if "Sales Pmt. Disc. Debit Acc." = '' then
                PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Sales Pmt. Disc. Debit Acc."));
            TestField("Sales Pmt. Disc. Debit Acc.");
            exit("Sales Pmt. Disc. Debit Acc.");
        end;
        if "Sales Pmt. Disc. Credit Acc." = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Sales Pmt. Disc. Credit Acc."));
        TestField("Sales Pmt. Disc. Credit Acc.");
        exit("Sales Pmt. Disc. Credit Acc.");
    end;

    procedure GetSalesPmtToleranceAccount(Debit: Boolean): Code[20]
    begin
        if Debit then begin
            if "Sales Pmt. Tol. Debit Acc." = '' then
                PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Sales Pmt. Tol. Debit Acc."));
            TestField("Sales Pmt. Tol. Debit Acc.");
            exit("Sales Pmt. Tol. Debit Acc.");
        end;
        if "Sales Pmt. Tol. Credit Acc." = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Sales Pmt. Tol. Credit Acc."));
        TestField("Sales Pmt. Tol. Credit Acc.");
        exit("Sales Pmt. Tol. Credit Acc.");
    end;

    procedure GetSalesPrepmtAccount(): Code[20]
    begin
        if "Sales Prepayments Account" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Sales Prepayments Account"));
        TestField("Sales Prepayments Account");
        exit("Sales Prepayments Account");
    end;

    procedure GetPurchAccount(): Code[20]
    begin
        if "Purch. Account" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Purch. Account"));
        TestField("Purch. Account");
        exit("Purch. Account");
    end;

    procedure GetPurchCrMemoAccount(): Code[20]
    begin
        if "Purch. Credit Memo Account" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Purch. Credit Memo Account"));
        TestField("Purch. Credit Memo Account");
        exit("Purch. Credit Memo Account");
    end;

    procedure GetPurchInvDiscAccount(): Code[20]
    begin
        if "Purch. Inv. Disc. Account" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Purch. Inv. Disc. Account"));
        TestField("Purch. Inv. Disc. Account");
        exit("Purch. Inv. Disc. Account");
    end;

    procedure GetPurchLineDiscAccount(): Code[20]
    begin
        if "Purch. Line Disc. Account" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Purch. Line Disc. Account"));
        TestField("Purch. Line Disc. Account");
        exit("Purch. Line Disc. Account");
    end;

    procedure GetPurchPmtDiscountAccount(Debit: Boolean): Code[20]
    begin
        if Debit then begin
            if "Purch. Pmt. Disc. Debit Acc." = '' then
                PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Purch. Pmt. Disc. Debit Acc."));
            TestField("Purch. Pmt. Disc. Debit Acc.");
            exit("Purch. Pmt. Disc. Debit Acc.");
        end;
        if "Purch. Pmt. Disc. Credit Acc." = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Purch. Pmt. Disc. Credit Acc."));
        TestField("Purch. Pmt. Disc. Credit Acc.");
        exit("Purch. Pmt. Disc. Credit Acc.");
    end;

    procedure GetPurchPmtToleranceAccount(Debit: Boolean): Code[20]
    begin
        if Debit then begin
            if "Purch. Pmt. Tol. Debit Acc." = '' then
                PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Purch. Pmt. Tol. Debit Acc."));
            TestField("Purch. Pmt. Tol. Debit Acc.");
            exit("Purch. Pmt. Tol. Debit Acc.");
        end;
        if "Purch. Pmt. Tol. Credit Acc." = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Purch. Pmt. Tol. Credit Acc."));
        TestField("Purch. Pmt. Tol. Credit Acc.");
        exit("Purch. Pmt. Tol. Credit Acc.");
    end;

    procedure GetPurchPrepmtAccount(): Code[20]
    begin
        if "Purch. Prepayments Account" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Purch. Prepayments Account"));
        TestField("Purch. Prepayments Account");
        exit("Purch. Prepayments Account");
    end;

    procedure GetPurchFADiscAccount(): Code[20]
    begin
        if "Purch. FA Disc. Account" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Purch. FA Disc. Account"));
        TestField("Purch. FA Disc. Account");
        exit("Purch. FA Disc. Account");
    end;

    procedure GetDirectCostAppliedAccount(): Code[20]
    begin
        if "Direct Cost Applied Account" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Direct Cost Applied Account"));
        TestField("Direct Cost Applied Account");
        exit("Direct Cost Applied Account");
    end;

    procedure GetOverheadAppliedAccount(): Code[20]
    begin
        if "Overhead Applied Account" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Overhead Applied Account"));
        TestField("Overhead Applied Account");
        exit("Overhead Applied Account");
    end;

    procedure GetPurchaseVarianceAccount(): Code[20]
    begin
        if "Purchase Variance Account" = '' then
            PostingSetupMgt.SendGenPostingSetupNotification(Rec, FieldCaption("Purchase Variance Account"));
        TestField("Purchase Variance Account");
        exit("Purchase Variance Account");
    end;

    procedure SetAccountsVisibility(var PmtToleranceVisible: Boolean; var PmtDiscountVisible: Boolean; var SalesInvDiscVisible: Boolean; var SalesLineDiscVisible: Boolean; var PurchInvDiscVisible: Boolean; var PurchLineDiscVisible: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        PaymentTerms: Record "Payment Terms";
    begin
        GLSetup.Get();
        PmtToleranceVisible := (GLSetup."Payment Tolerance %" > 0) or (GLSetup."Max. Payment Tolerance Amount" <> 0);

        PmtDiscountVisible := PaymentTerms.UsePaymentDiscount;

        SalesSetup.Get();
        SalesLineDiscVisible :=
          SalesSetup."Discount Posting" in [SalesSetup."Discount Posting"::"All Discounts",
                                            SalesSetup."Discount Posting"::"Line Discounts"];
        SalesInvDiscVisible :=
          SalesSetup."Discount Posting" in [SalesSetup."Discount Posting"::"All Discounts",
                                            SalesSetup."Discount Posting"::"Invoice Discounts"];

        PurchSetup.Get();
        PurchLineDiscVisible :=
          PurchSetup."Discount Posting" in [PurchSetup."Discount Posting"::"All Discounts",
                                            PurchSetup."Discount Posting"::"Line Discounts"];
        PurchInvDiscVisible :=
          PurchSetup."Discount Posting" in [PurchSetup."Discount Posting"::"All Discounts",
                                            PurchSetup."Discount Posting"::"Invoice Discounts"];
    end;

    procedure SuggestSetupAccounts()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        SuggestSalesAccounts(RecRef);
        SuggestPurchAccounts(RecRef);
        SuggestInvtAccounts(RecRef);
        RecRef.Modify();
    end;

    local procedure SuggestSalesAccounts(var RecRef: RecordRef)
    begin
        if "Sales Account" = '' then
            SuggestAccount(RecRef, FieldNo("Sales Account"));
        if "Sales Credit Memo Account" = '' then
            SuggestAccount(RecRef, FieldNo("Sales Credit Memo Account"));
        if "Sales Inv. Disc. Account" = '' then
            SuggestAccount(RecRef, FieldNo("Sales Inv. Disc. Account"));
        if "Sales Line Disc. Account" = '' then
            SuggestAccount(RecRef, FieldNo("Sales Line Disc. Account"));
        if "Sales Pmt. Disc. Credit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Sales Pmt. Disc. Credit Acc."));
        if "Sales Pmt. Disc. Debit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Sales Pmt. Disc. Debit Acc."));
        if "Sales Pmt. Tol. Credit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Sales Pmt. Tol. Credit Acc."));
        if "Sales Pmt. Tol. Debit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Sales Pmt. Tol. Debit Acc."));
        if "Sales Prepayments Account" = '' then
            SuggestAccount(RecRef, FieldNo("Sales Prepayments Account"));

        OnAfterSuggestSalesAccounts(Rec, RecRef);
    end;

    local procedure SuggestPurchAccounts(var RecRef: RecordRef)
    begin
        if "Purch. Account" = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Account"));
        if "Purch. Credit Memo Account" = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Credit Memo Account"));
        if "Purch. Inv. Disc. Account" = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Inv. Disc. Account"));
        if "Purch. Line Disc. Account" = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Line Disc. Account"));
        if "Purch. Pmt. Disc. Credit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Pmt. Disc. Credit Acc."));
        if "Purch. Pmt. Disc. Debit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Pmt. Disc. Debit Acc."));
        if "Purch. Pmt. Tol. Credit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Pmt. Tol. Credit Acc."));
        if "Purch. Pmt. Tol. Debit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Pmt. Tol. Debit Acc."));
        if "Purch. Prepayments Account" = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Prepayments Account"));

        OnAfterSuggestPurchAccounts(Rec, RecRef);
    end;

    local procedure SuggestInvtAccounts(var RecRef: RecordRef)
    begin
        if "COGS Account" = '' then
            SuggestAccount(RecRef, FieldNo("COGS Account"));
        if "COGS Account (Interim)" = '' then
            SuggestAccount(RecRef, FieldNo("COGS Account (Interim)"));
        if "Inventory Adjmt. Account" = '' then
            SuggestAccount(RecRef, FieldNo("Inventory Adjmt. Account"));
        if "Invt. Accrual Acc. (Interim)" = '' then
            SuggestAccount(RecRef, FieldNo("Invt. Accrual Acc. (Interim)"));
        if "Direct Cost Applied Account" = '' then
            SuggestAccount(RecRef, FieldNo("Direct Cost Applied Account"));
        if "Overhead Applied Account" = '' then
            SuggestAccount(RecRef, FieldNo("Overhead Applied Account"));
        if "Purchase Variance Account" = '' then
            SuggestAccount(RecRef, FieldNo("Purchase Variance Account"));

        OnAfterSuggestInvtAccounts(Rec, RecRef);
    end;

    local procedure SuggestAccount(var RecRef: RecordRef; AccountFieldNo: Integer)
    var
        TempAccountUseBuffer: Record "Account Use Buffer" temporary;
        RecFieldRef: FieldRef;
        GenPostingSetupRecRef: RecordRef;
        GenPostingSetupFieldRef: FieldRef;
    begin
        GenPostingSetupRecRef.Open(DATABASE::"General Posting Setup");

        GenPostingSetupRecRef.Reset();
        GenPostingSetupFieldRef := GenPostingSetupRecRef.Field(FieldNo("Gen. Bus. Posting Group"));
        GenPostingSetupFieldRef.SetRange("Gen. Bus. Posting Group");
        GenPostingSetupFieldRef := GenPostingSetupRecRef.Field(FieldNo("Gen. Prod. Posting Group"));
        GenPostingSetupFieldRef.SetFilter('<>%1', "Gen. Prod. Posting Group");
        TempAccountUseBuffer.UpdateBuffer(GenPostingSetupRecRef, AccountFieldNo);

        GenPostingSetupRecRef.Reset();
        GenPostingSetupFieldRef := GenPostingSetupRecRef.Field(FieldNo("Gen. Bus. Posting Group"));
        GenPostingSetupFieldRef.SetFilter('<>%1', "Gen. Bus. Posting Group");
        GenPostingSetupFieldRef := GenPostingSetupRecRef.Field(FieldNo("Gen. Prod. Posting Group"));
        GenPostingSetupFieldRef.SetRange("Gen. Prod. Posting Group");
        TempAccountUseBuffer.UpdateBuffer(GenPostingSetupRecRef, AccountFieldNo);

        GenPostingSetupRecRef.Close;

        TempAccountUseBuffer.Reset();
        TempAccountUseBuffer.SetCurrentKey("No. of Use");
        if TempAccountUseBuffer.FindLast then begin
            RecFieldRef := RecRef.Field(AccountFieldNo);
            RecFieldRef.Value(TempAccountUseBuffer."Account No.");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSuggestInvtAccounts(var GeneralPostingSetup: Record "General Posting Setup"; RecRef: RecordRef);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSuggestSalesAccounts(var GeneralPostingSetup: Record "General Posting Setup"; RecRef: RecordRef);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSuggestPurchAccounts(var GeneralPostingSetup: Record "General Posting Setup"; RecRef: RecordRef);
    begin
    end;
}

