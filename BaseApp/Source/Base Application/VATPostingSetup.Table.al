table 325 "VAT Posting Setup"
{
    Caption = 'VAT Posting Setup';
    DrillDownPageID = "VAT Posting Setup";
    LookupPageID = "VAT Posting Setup";

    fields
    {
        field(1; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(2; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(3; "VAT Calculation Type"; Option)
        {
            Caption = 'VAT Calculation Type';
            OptionCaption = 'Normal VAT,Reverse Charge VAT,Full VAT,Sales Tax';
            OptionMembers = "Normal VAT","Reverse Charge VAT","Full VAT","Sales Tax";
        }
        field(4; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("VAT %"));
                CheckVATIdentifier;
            end;
        }
        field(5; "Unrealized VAT Type"; Option)
        {
            Caption = 'Unrealized VAT Type';
            OptionCaption = ' ,Percentage,First,Last,First (Fully Paid),Last (Fully Paid)';
            OptionMembers = " ",Percentage,First,Last,"First (Fully Paid)","Last (Fully Paid)";

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("Unrealized VAT Type"));

                if "Unrealized VAT Type" > 0 then begin
                    GLSetup.Get;
                    if not GLSetup."Unrealized VAT" and not GLSetup."Prepayment Unrealized VAT" then
                        GLSetup.TestField("Unrealized VAT", true);
                end;
            end;
        }
        field(6; "Adjust for Payment Discount"; Boolean)
        {
            Caption = 'Adjust for Payment Discount';

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("Adjust for Payment Discount"));

                if "Adjust for Payment Discount" then begin
                    GLSetup.Get;
                    GLSetup.TestField("Adjust for Payment Disc.", true);
                end;
            end;
        }
        field(7; "Sales VAT Account"; Code[20])
        {
            Caption = 'Sales VAT Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("Sales VAT Account"));

                CheckGLAcc("Sales VAT Account");
            end;
        }
        field(8; "Sales VAT Unreal. Account"; Code[20])
        {
            Caption = 'Sales VAT Unreal. Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("Sales VAT Unreal. Account"));

                CheckGLAcc("Sales VAT Unreal. Account");
            end;
        }
        field(9; "Purchase VAT Account"; Code[20])
        {
            Caption = 'Purchase VAT Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("Purchase VAT Account"));

                CheckGLAcc("Purchase VAT Account");
            end;
        }
        field(10; "Purch. VAT Unreal. Account"; Code[20])
        {
            Caption = 'Purch. VAT Unreal. Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("Purch. VAT Unreal. Account"));

                CheckGLAcc("Purch. VAT Unreal. Account");
            end;
        }
        field(11; "Reverse Chrg. VAT Acc."; Code[20])
        {
            Caption = 'Reverse Chrg. VAT Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("Reverse Chrg. VAT Acc."));

                CheckGLAcc("Reverse Chrg. VAT Acc.");
            end;
        }
        field(12; "Reverse Chrg. VAT Unreal. Acc."; Code[20])
        {
            Caption = 'Reverse Chrg. VAT Unreal. Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("Reverse Chrg. VAT Unreal. Acc."));

                CheckGLAcc("Reverse Chrg. VAT Unreal. Acc.");
            end;
        }
        field(13; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';

            trigger OnValidate()
            begin
                "VAT %" := GetVATPtc;
            end;
        }
        field(14; "EU Service"; Boolean)
        {
            Caption = 'EU Service';
        }
        field(15; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        field(16; "Certificate of Supply Required"; Boolean)
        {
            Caption = 'Certificate of Supply Required';
        }
        field(17; "Tax Category"; Code[10])
        {
            Caption = 'Tax Category';
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "VAT Bus. Posting Group", "VAT Prod. Posting Group")
        {
            Clustered = true;
        }
        key(Key2; "VAT Prod. Posting Group", "VAT Bus. Posting Group")
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

    trigger OnInsert()
    begin
        if "VAT %" = 0 then
            "VAT %" := GetVATPtc;
    end;

    var
        Text000: Label '%1 must be entered on the tax jurisdiction line when %2 is %3.';
        Text001: Label '%1 = %2 has already been used for %3 = %4 in %5 for %6 = %7 and %8 = %9.';
        GLSetup: Record "General Ledger Setup";
        PostingSetupMgt: Codeunit PostingSetupManagement;
        YouCannotDeleteErr: Label 'You cannot delete %1 %2.', Comment = '%1 = Location Code; %2 = Posting Group';

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
        GLEntry.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
        if not GLEntry.IsEmpty then
            Error(YouCannotDeleteErr, "VAT Bus. Posting Group", "VAT Prod. Posting Group");
    end;

    procedure TestNotSalesTax(FromFieldName: Text[100])
    begin
        if "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" then
            Error(
              Text000,
              FromFieldName, FieldCaption("VAT Calculation Type"),
              "VAT Calculation Type");
    end;

    local procedure CheckVATIdentifier()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', "VAT Prod. Posting Group");
        VATPostingSetup.SetFilter("VAT %", '<>%1', "VAT %");
        VATPostingSetup.SetRange("VAT Identifier", "VAT Identifier");
        if VATPostingSetup.FindFirst then
            Error(
              Text001,
              FieldCaption("VAT Identifier"), VATPostingSetup."VAT Identifier",
              FieldCaption("VAT %"), VATPostingSetup."VAT %", TableCaption,
              FieldCaption("VAT Bus. Posting Group"), VATPostingSetup."VAT Bus. Posting Group",
              FieldCaption("VAT Prod. Posting Group"), VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure GetVATPtc(): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', "VAT Prod. Posting Group");
        VATPostingSetup.SetRange("VAT Identifier", "VAT Identifier");
        if not VATPostingSetup.FindFirst then
            VATPostingSetup."VAT %" := "VAT %";
        exit(VATPostingSetup."VAT %");
    end;

    procedure GetSalesAccount(Unrealized: Boolean): Code[20]
    var
        SalesVATAccountNo: Code[20];
        IsHandled: Boolean;
    begin
        OnBeforeGetSalesAccount(Rec, Unrealized, SalesVATAccountNo, IsHandled);
        if IsHandled then
            exit(SalesVATAccountNo);

        if Unrealized then begin
            if "Sales VAT Unreal. Account" = '' then
                PostingSetupMgt.SendVATPostingSetupNotification(Rec, FieldCaption("Sales VAT Unreal. Account"));
            TestField("Sales VAT Unreal. Account");
            exit("Sales VAT Unreal. Account");
        end;
        if "Sales VAT Account" = '' then
            PostingSetupMgt.SendVATPostingSetupNotification(Rec, FieldCaption("Sales VAT Account"));
        TestField("Sales VAT Account");
        exit("Sales VAT Account");
    end;

    procedure GetPurchAccount(Unrealized: Boolean): Code[20]
    var
        PurchVATAccountNo: Code[20];
        IsHandled: Boolean;
    begin
        OnBeforeGetPurchAccount(Rec, Unrealized, PurchVATAccountNo, IsHandled);
        if IsHandled then
            exit(PurchVATAccountNo);

        if Unrealized then begin
            if "Purch. VAT Unreal. Account" = '' then
                PostingSetupMgt.SendVATPostingSetupNotification(Rec, FieldCaption("Purch. VAT Unreal. Account"));
            TestField("Purch. VAT Unreal. Account");
            exit("Purch. VAT Unreal. Account");
        end;
        if "Purchase VAT Account" = '' then
            PostingSetupMgt.SendVATPostingSetupNotification(Rec, FieldCaption("Purchase VAT Account"));
        TestField("Purchase VAT Account");
        exit("Purchase VAT Account");
    end;

    procedure GetRevChargeAccount(Unrealized: Boolean): Code[20]
    begin
        if Unrealized then begin
            if "Reverse Chrg. VAT Unreal. Acc." = '' then
                PostingSetupMgt.SendVATPostingSetupNotification(Rec, FieldCaption("Reverse Chrg. VAT Unreal. Acc."));
            TestField("Reverse Chrg. VAT Unreal. Acc.");
            exit("Reverse Chrg. VAT Unreal. Acc.");
        end;
        if "Reverse Chrg. VAT Acc." = '' then
            PostingSetupMgt.SendVATPostingSetupNotification(Rec, FieldCaption("Reverse Chrg. VAT Acc."));
        TestField("Reverse Chrg. VAT Acc.");
        exit("Reverse Chrg. VAT Acc.");
    end;

    procedure SetAccountsVisibility(var UnrealizedVATVisible: Boolean; var AdjustForPmtDiscVisible: Boolean)
    begin
        GLSetup.Get;
        UnrealizedVATVisible := GLSetup."Unrealized VAT" or GLSetup."Prepayment Unrealized VAT";
        AdjustForPmtDiscVisible := GLSetup."Adjust for Payment Disc.";
    end;

    procedure SuggestSetupAccounts()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        SuggestVATAccounts(RecRef);
        RecRef.Modify;
    end;

    local procedure SuggestVATAccounts(var RecRef: RecordRef)
    begin
        if "Sales VAT Account" = '' then
            SuggestAccount(RecRef, FieldNo("Sales VAT Account"));
        if "Purchase VAT Account" = '' then
            SuggestAccount(RecRef, FieldNo("Purchase VAT Account"));

        if "Unrealized VAT Type" > 0 then begin
            if "Sales VAT Unreal. Account" = '' then
                SuggestAccount(RecRef, FieldNo("Sales VAT Unreal. Account"));
            if "Purch. VAT Unreal. Account" = '' then
                SuggestAccount(RecRef, FieldNo("Purch. VAT Unreal. Account"));
        end;

        if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then begin
            if "Reverse Chrg. VAT Acc." = '' then
                SuggestAccount(RecRef, FieldNo("Reverse Chrg. VAT Acc."));
            if ("Unrealized VAT Type" > 0) and ("Reverse Chrg. VAT Unreal. Acc." = '') then
                SuggestAccount(RecRef, FieldNo("Reverse Chrg. VAT Unreal. Acc."));
        end;
    end;

    local procedure SuggestAccount(var RecRef: RecordRef; AccountFieldNo: Integer)
    var
        TempAccountUseBuffer: Record "Account Use Buffer" temporary;
        RecFieldRef: FieldRef;
        VATPostingSetupRecRef: RecordRef;
        VATPostingSetupFieldRef: FieldRef;
    begin
        VATPostingSetupRecRef.Open(DATABASE::"VAT Posting Setup");

        VATPostingSetupRecRef.Reset;
        VATPostingSetupFieldRef := VATPostingSetupRecRef.Field(FieldNo("VAT Bus. Posting Group"));
        VATPostingSetupFieldRef.SetRange("VAT Bus. Posting Group");
        VATPostingSetupFieldRef := VATPostingSetupRecRef.Field(FieldNo("VAT Prod. Posting Group"));
        VATPostingSetupFieldRef.SetFilter('<>%1', "VAT Prod. Posting Group");
        TempAccountUseBuffer.UpdateBuffer(VATPostingSetupRecRef, AccountFieldNo);

        VATPostingSetupRecRef.Reset;
        VATPostingSetupFieldRef := VATPostingSetupRecRef.Field(FieldNo("VAT Bus. Posting Group"));
        VATPostingSetupFieldRef.SetFilter('<>%1', "VAT Bus. Posting Group");
        VATPostingSetupFieldRef := VATPostingSetupRecRef.Field(FieldNo("VAT Prod. Posting Group"));
        VATPostingSetupFieldRef.SetRange("VAT Prod. Posting Group");
        TempAccountUseBuffer.UpdateBuffer(VATPostingSetupRecRef, AccountFieldNo);

        VATPostingSetupRecRef.Close;

        TempAccountUseBuffer.Reset;
        TempAccountUseBuffer.SetCurrentKey("No. of Use");
        if TempAccountUseBuffer.FindLast then begin
            RecFieldRef := RecRef.Field(AccountFieldNo);
            RecFieldRef.Value(TempAccountUseBuffer."Account No.");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchAccount(var VATPostingSetup: Record "VAT Posting Setup"; Unrealized: Boolean; var PurchVATAccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesAccount(var VATPostingSetup: Record "VAT Posting Setup"; Unrealized: Boolean; var SalesVATAccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

