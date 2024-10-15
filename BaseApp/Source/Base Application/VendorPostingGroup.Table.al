table 93 "Vendor Posting Group"
{
    Caption = 'Vendor Posting Group';
    LookupPageID = "Vendor Posting Groups";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Payables Account"; Code[20])
        {
            Caption = 'Payables Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Payables Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "Payables Account", GLAccountCategory."Account Category"::Liabilities,
                      GLAccountCategoryMgt.GetCII4TradePayables()); // NAVCZ

                Validate("Payables Account");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Payables Account", false, false)
                else
                    GLAccountCategoryMgt.CheckGLAccount(
                      "Payables Account", false, false, GLAccountCategory."Account Category"::Liabilities,
                      GLAccountCategoryMgt.GetCII4TradePayables()); // NAVCZ
                CheckOpenVendLedgEntries(false); // NAVCZ
            end;
        }
        field(7; "Service Charge Acc."; Code[20])
        {
            Caption = 'Service Charge Acc.';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Service Charge Acc.")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "Service Charge Acc.", GLAccountCategory."Account Category"::Expense,
                      GLAccountCategoryMgt.GetKOtherFinancialCosts()); // NAVCZ

                Validate("Service Charge Acc.");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Service Charge Acc.", true, true)
                else
                    GLAccountCategoryMgt.CheckGLAccount(
                      "Service Charge Acc.", true, true, GLAccountCategory."Account Category"::Expense,
                      GLAccountCategoryMgt.GetKOtherFinancialCosts()); // NAVCZ
            end;
        }
        field(8; "Payment Disc. Debit Acc."; Code[20])
        {
            Caption = 'Payment Disc. Debit Acc.';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Payment Disc. Debit Acc.")
                else
                    GLAccountCategoryMgt.LookupGLAccount("Payment Disc. Debit Acc.", GLAccountCategory."Account Category"::Income, '');

                Validate("Payment Disc. Debit Acc.");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Payment Disc. Debit Acc.", false, false)
                else
                    GLAccountCategoryMgt.CheckGLAccount("Payment Disc. Debit Acc.", false, false, GLAccountCategory."Account Category"::Income, '');
            end;
        }
        field(9; "Invoice Rounding Account"; Code[20])
        {
            Caption = 'Invoice Rounding Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Invoice Rounding Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount("Invoice Rounding Account", GLAccountCategory."Account Category"::Expense, '');

                Validate("Invoice Rounding Account");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Invoice Rounding Account", true, false)
                else
                    GLAccountCategoryMgt.CheckGLAccount("Invoice Rounding Account", true, false, GLAccountCategory."Account Category"::Expense, '');
            end;
        }
        field(10; "Debit Curr. Appln. Rndg. Acc."; Code[20])
        {
            Caption = 'Debit Curr. Appln. Rndg. Acc.';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Debit Curr. Appln. Rndg. Acc.")
                else
                    GLAccountCategoryMgt.LookupGLAccount("Debit Curr. Appln. Rndg. Acc.", GLAccountCategory."Account Category"::Income, '');

                Validate("Debit Curr. Appln. Rndg. Acc.");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Debit Curr. Appln. Rndg. Acc.", false, false)
                else
                    GLAccountCategoryMgt.CheckGLAccount(
                      "Debit Curr. Appln. Rndg. Acc.", false, false, GLAccountCategory."Account Category"::Income, '');
            end;
        }
        field(11; "Credit Curr. Appln. Rndg. Acc."; Code[20])
        {
            Caption = 'Credit Curr. Appln. Rndg. Acc.';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Credit Curr. Appln. Rndg. Acc.")
                else
                    GLAccountCategoryMgt.LookupGLAccount("Credit Curr. Appln. Rndg. Acc.", GLAccountCategory."Account Category"::Income, '');

                Validate("Credit Curr. Appln. Rndg. Acc.");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Credit Curr. Appln. Rndg. Acc.", false, false)
                else
                    GLAccountCategoryMgt.CheckGLAccount(
                      "Credit Curr. Appln. Rndg. Acc.", false, false, GLAccountCategory."Account Category"::Income, '');
            end;
        }
        field(12; "Debit Rounding Account"; Code[20])
        {
            Caption = 'Debit Rounding Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Debit Rounding Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount("Debit Rounding Account", GLAccountCategory."Account Category"::Expense, '');

                Validate("Debit Rounding Account");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Debit Rounding Account", false, false)
                else
                    GLAccountCategoryMgt.CheckGLAccount("Debit Rounding Account", false, false, GLAccountCategory."Account Category"::Expense, '');
            end;
        }
        field(13; "Credit Rounding Account"; Code[20])
        {
            Caption = 'Credit Rounding Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Credit Rounding Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount("Credit Rounding Account", GLAccountCategory."Account Category"::Expense, '');

                Validate("Credit Rounding Account");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Credit Rounding Account", false, false)
                else
                    GLAccountCategoryMgt.CheckGLAccount("Credit Rounding Account", false, false, GLAccountCategory."Account Category"::Expense, '');
            end;
        }
        field(16; "Payment Disc. Credit Acc."; Code[20])
        {
            Caption = 'Payment Disc. Credit Acc.';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Payment Disc. Credit Acc.")
                else
                    GLAccountCategoryMgt.LookupGLAccount("Payment Disc. Credit Acc.", GLAccountCategory."Account Category"::Income, '');

                Validate("Payment Disc. Credit Acc.");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Payment Disc. Credit Acc.", false, false)
                else
                    GLAccountCategoryMgt.CheckGLAccount("Payment Disc. Credit Acc.", false, false, GLAccountCategory."Account Category"::Income, '');
            end;
        }
        field(17; "Payment Tolerance Debit Acc."; Code[20])
        {
            Caption = 'Payment Tolerance Debit Acc.';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Payment Tolerance Debit Acc.")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "Payment Tolerance Debit Acc.", GLAccountCategory."Account Category"::Income, ''); // NAVCZ

                Validate("Payment Tolerance Debit Acc.");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Payment Tolerance Debit Acc.", false, false)
                else
                    GLAccountCategoryMgt.CheckGLAccount(
                      "Payment Tolerance Debit Acc.", false, false, GLAccountCategory."Account Category"::Income, ''); // NAVCZ
            end;
        }
        field(18; "Payment Tolerance Credit Acc."; Code[20])
        {
            Caption = 'Payment Tolerance Credit Acc.';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Payment Tolerance Credit Acc.")
                else
                    GLAccountCategoryMgt.LookupGLAccount(
                      "Payment Tolerance Credit Acc.", GLAccountCategory."Account Category"::Income, ''); // NAVCZ

                Validate("Payment Tolerance Credit Acc.");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Payment Tolerance Credit Acc.", false, false)
                else
                    GLAccountCategoryMgt.CheckGLAccount(
                      "Payment Tolerance Credit Acc.", false, false, GLAccountCategory."Account Category"::Income, ''); // NAVCZ
            end;
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(21; "View All Accounts on Lookup"; Boolean)
        {
            Caption = 'View All Accounts on Lookup';
        }
        field(31001; "Advance Account"; Code[20])
        {
            Caption = 'Advance Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Advance Account")
                else
                    GLAccountCategoryMgt.LookupGLAccount("Advance Account", GLAccountCategory."Account Category"::Assets,
                        GLAccountCategoryMgt.GetCII244ShorttermAdvancedPayments());

                Validate("Advance Account");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Advance Account", false, false)
                else
                    GLAccountCategoryMgt.CheckGLAccount("Advance Account", false, false, GLAccountCategory."Account Category"::Assets,
                        GLAccountCategoryMgt.GetCII244ShorttermAdvancedPayments());

                CheckOpenVendLedgEntries(true);
            end;
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
        fieldgroup(Brick; "Code")
        {
        }
    }

    trigger OnDelete()
    begin
        CheckGroupUsage;
        DeleteSubstPostingGroups; // NAVCZ
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        PostingSetupMgt: Codeunit PostingSetupManagement;
        YouCannotDeleteErr: Label 'You cannot delete %1.', Comment = '%1 = Code';

    local procedure CheckGroupUsage()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        Vendor.SetRange("Vendor Posting Group", Code);
        if not Vendor.IsEmpty() then
            Error(YouCannotDeleteErr, Code);

        VendorLedgerEntry.SetRange("Vendor Posting Group", Code);
        if not VendorLedgerEntry.IsEmpty() then
            Error(YouCannotDeleteErr, Code);
    end;

    procedure GetPayablesAccount(): Code[20]
    begin
        if "Payables Account" = '' then
            PostingSetupMgt.SendVendPostingGroupNotification(Rec, FieldCaption("Payables Account"));
        TestField("Payables Account");
        exit("Payables Account");
    end;

    procedure GetPmtDiscountAccount(Debit: Boolean): Code[20]
    begin
        if Debit then begin
            if "Payment Disc. Debit Acc." = '' then
                PostingSetupMgt.SendVendPostingGroupNotification(Rec, FieldCaption("Payment Disc. Debit Acc."));
            TestField("Payment Disc. Debit Acc.");
            exit("Payment Disc. Debit Acc.");
        end;
        if "Payment Disc. Credit Acc." = '' then
            PostingSetupMgt.SendVendPostingGroupNotification(Rec, FieldCaption("Payment Disc. Credit Acc."));
        TestField("Payment Disc. Credit Acc.");
        exit("Payment Disc. Credit Acc.");
    end;

    procedure GetPmtToleranceAccount(Debit: Boolean): Code[20]
    begin
        if Debit then begin
            if "Payment Tolerance Debit Acc." = '' then
                PostingSetupMgt.SendVendPostingGroupNotification(Rec, FieldCaption("Payment Tolerance Debit Acc."));
            TestField("Payment Tolerance Debit Acc.");
            exit("Payment Tolerance Debit Acc.");
        end;
        if "Payment Tolerance Credit Acc." = '' then
            PostingSetupMgt.SendVendPostingGroupNotification(Rec, FieldCaption("Payment Tolerance Credit Acc."));
        TestField("Payment Tolerance Credit Acc.");
        exit("Payment Tolerance Credit Acc.");
    end;

    procedure GetRoundingAccount(Debit: Boolean): Code[20]
    begin
        if Debit then begin
            if "Debit Rounding Account" = '' then
                PostingSetupMgt.SendVendPostingGroupNotification(Rec, FieldCaption("Debit Rounding Account"));
            TestField("Debit Rounding Account");
            exit("Debit Rounding Account");
        end;
        if "Credit Rounding Account" = '' then
            PostingSetupMgt.SendVendPostingGroupNotification(Rec, FieldCaption("Credit Rounding Account"));
        TestField("Credit Rounding Account");
        exit("Credit Rounding Account");
    end;

    procedure GetApplRoundingAccount(Debit: Boolean): Code[20]
    begin
        if Debit then begin
            if "Debit Curr. Appln. Rndg. Acc." = '' then
                PostingSetupMgt.SendVendPostingGroupNotification(Rec, FieldCaption("Debit Curr. Appln. Rndg. Acc."));
            TestField("Debit Curr. Appln. Rndg. Acc.");
            exit("Debit Curr. Appln. Rndg. Acc.");
        end;
        if "Credit Curr. Appln. Rndg. Acc." = '' then
            PostingSetupMgt.SendVendPostingGroupNotification(Rec, FieldCaption("Credit Curr. Appln. Rndg. Acc."));
        TestField("Credit Curr. Appln. Rndg. Acc.");
        exit("Credit Curr. Appln. Rndg. Acc.");
    end;

    procedure GetInvRoundingAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        if "Invoice Rounding Account" <> '' then begin
            GLAccount.Get("Invoice Rounding Account");
            GLAccount.CheckGenProdPostingGroup();
        end else
            PostingSetupMgt.SendVendPostingGroupNotification(Rec, FieldCaption("Invoice Rounding Account"));
        TestField("Invoice Rounding Account");
        exit("Invoice Rounding Account");
    end;

    procedure GetServiceChargeAccount(): Code[20]
    begin
        if "Service Charge Acc." = '' then
            PostingSetupMgt.SendVendPostingGroupNotification(Rec, FieldCaption("Service Charge Acc."));
        TestField("Service Charge Acc.");
        exit("Service Charge Acc.");
    end;

    procedure SetAccountVisibility(var PmtToleranceVisible: Boolean; var PmtDiscountVisible: Boolean; var InvRoundingVisible: Boolean; var ApplnRoundingVisible: Boolean)
    var
        PurchSetup: Record "Purchases & Payables Setup";
        PaymentTerms: Record "Payment Terms";
    begin
        GLSetup.Get();
        PmtToleranceVisible := GLSetup.GetPmtToleranceVisible;
        PmtDiscountVisible := PaymentTerms.UsePaymentDiscount;

        PurchSetup.Get();
        InvRoundingVisible := PurchSetup."Invoice Rounding";
        ApplnRoundingVisible := PurchSetup."Appln. between Currencies" <> PurchSetup."Appln. between Currencies"::None;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    procedure GetPayablesAccNo(PostingGroupCode: Code[20]; Advance: Boolean): Code[20]
    begin
        // NAVCZ
        Get(PostingGroupCode);
        if Advance then begin
            if "Advance Account" = '' then
                PostingSetupMgt.SendVendPostingGroupNotification(Rec, FieldCaption("Advance Account"));
            TestField("Advance Account");
            exit("Advance Account");
        end;
        if "Payables Account" = '' then
            PostingSetupMgt.SendVendPostingGroupNotification(Rec, FieldCaption("Payables Account"));
        TestField("Payables Account");
        exit("Payables Account");
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    procedure DeleteSubstPostingGroups()
    var
        SubstVendPostingGroup: Record "Subst. Vendor Posting Group";
    begin
        // NAVCZ
        SubstVendPostingGroup.SetRange("Parent Vend. Posting Group", Code);
        SubstVendPostingGroup.DeleteAll();
        SubstVendPostingGroup.Reset();
        SubstVendPostingGroup.SetRange("Vendor Posting Group", Code);
        SubstVendPostingGroup.DeleteAll();
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    local procedure CheckOpenVendLedgEntries(Prepayment1: Boolean)
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        ConfirmManagement: Codeunit "Confirm Management";        
        Caption1: Text[250];
        ChangeText: Label 'Do you really want to change %1 although open entries exist?';
        IsHandled: Boolean;
    begin
        // NAVCZ
        IsHandled := false;
        OnBeforeCheckOpenVendLedgEntries(Prepayment1, IsHandled);
        if IsHandled then
            exit;

        VendLedgerEntry.SetCurrentKey(Open);
        VendLedgerEntry.SetRange(Open, true);
        VendLedgerEntry.SetRange("Vendor Posting Group", Code);
        VendLedgerEntry.SetRange(Prepayment, Prepayment1);
        if not VendLedgerEntry.IsEmpty() then begin
            if Prepayment1 then
                Caption1 := FieldCaption("Advance Account")
            else
                Caption1 := FieldCaption("Payables Account");
            if not ConfirmManagement.GetResponse(StrSubstNo(ChangeText, Caption1), false) then                
                Error('');
        end;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckOpenVendLedgEntries(var Prepayment1: Boolean; var IsHandled: Boolean);
    begin
    end;
}

