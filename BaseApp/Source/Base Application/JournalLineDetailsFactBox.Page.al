page 9120 "Journal Line Details FactBox"
{
    PageType = CardPart;
    Caption = 'Journal Line Details';
    Editable = false;
    LinksAllowed = false;
    UsageCategory = Administration;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(Content)
        {
            field(PostingGroup; "Posting Group")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posting Group';
                Editable = false;
                Enabled = VATPostingSetupEnabled;
                ToolTip = 'Specifies the account posting group that the entry on the journal line will be posted to.';

                trigger OnDrillDown()
                begin
                    DrillDownPostingGroup();
                end;
            }
            group(Account)
            {
                Caption = 'Account';
                field(AccountName; AccName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Name';
                    Editable = false;
                    Enabled = AccountEnabled;
                    ToolTip = 'Specifies the account name that the entry on the journal line will be posted to.';

                    trigger OnDrillDown()
                    begin
                        Codeunit.Run(Codeunit::"Gen. Jnl.-Show Card", Rec);
                    end;
                }
                field(GenPostingSetup; GenPostingSetupText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Posting Setup';
                    Editable = false;
                    Enabled = GenPostingSetupEnabled;
                    ToolTip = 'Specifies the account name that the entry on the journal line will be posted to.';

                    trigger OnDrillDown()
                    var
                        GeneralPostingSetup: Record "General Posting Setup";
                    begin
                        if GeneralPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group") then
                            Page.Run(Page::"General Posting Setup", GeneralPostingSetup);
                    end;
                }
                field(VATPostingSetup; VATPostingSetupText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Posting Setup';
                    Editable = false;
                    Enabled = VATPostingSetupEnabled;
                    ToolTip = 'Specifies the account name that the entry on the journal line will be posted to.';

                    trigger OnDrillDown()
                    var
                        VATPostingSetupLocal: Record "VAT Posting Setup";
                    begin
                        if VATPostingSetupLocal.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                            Page.Run(Page::"VAT Posting Setup", VATPostingSetupLocal);
                    end;
                }
            }
            group(BalAccount)
            {
                Caption = 'Balance Account';
                field(BalAccountName; BalAccName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bal. Account Name';
                    Editable = false;
                    Enabled = BalAccountEnabled;
                    ToolTip = 'Specifies the name of the balancing account that has been entered on the journal line.';

                    trigger OnDrillDown()
                    var
                        GenJnlLine: Record "Gen. Journal Line";
                    begin
                        if "Bal. Account No." <> '' then begin
                            GenJnlLine.TransferFields(Rec);
                            CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJnlLine);
                            Codeunit.Run(Codeunit::"Gen. Jnl.-Show Card", GenJnlLine);
                        end;
                    end;
                }
                field(BalGenPostingSetup; BalGenPostingSetupText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Posting Setup';
                    Editable = false;
                    Enabled = BalGenPostingSetupEnabled;
                    ToolTip = 'Specifies the account name that the entry on the journal line will be posted to.';

                    trigger OnDrillDown()
                    var
                        GeneralPostingSetup: Record "General Posting Setup";
                    begin
                        if GeneralPostingSetup.Get("Bal. Gen. Bus. Posting Group", "Bal. Gen. Prod. Posting Group") then
                            Page.Run(Page::"General Posting Setup", GeneralPostingSetup);
                    end;
                }
                field(BalVATPostingSetup; BalVATPostingSetupText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Posting Setup';
                    Editable = false;
                    Enabled = BalVATPostingSetupEnabled;
                    ToolTip = 'Specifies the account name that the entry on the journal line will be posted to.';

                    trigger OnDrillDown()
                    var
                        VATPostingSetupLocal: Record "VAT Posting Setup";
                    begin
                        if VATPostingSetupLocal.Get("Bal. VAT Bus. Posting Group", "Bal. VAT Prod. Posting Group") then
                            Page.Run(Page::"VAT Posting Setup", VATPostingSetupLocal);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
        SetControlEnabled();
        MakePostingSetupText();
    end;

    var
        GenJnlManagement: Codeunit GenJnlManagement;
        AccName: Text[100];
        BalAccName: Text[100];
        GenPostingSetupText: Text;
        VATPostingSetupText: Text;
        BalGenPostingSetupText: Text;
        BalVATPostingSetupText: Text;
        AccountEnabled: Boolean;
        BalAccountEnabled: Boolean;
        GenPostingSetupEnabled: Boolean;
        VATPostingSetupEnabled: Boolean;
        BalGenPostingSetupEnabled: Boolean;
        BalVATPostingSetupEnabled: Boolean;

    local procedure MakePostingSetupText()
    begin
        GenPostingSetupText := GetPostingSetupText("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
        VATPostingSetupText := GetPostingSetupText("VAT Bus. Posting Group", "VAT Prod. Posting Group");
        BalGenPostingSetupText := GetPostingSetupText("Bal. Gen. Bus. Posting Group", "Bal. Gen. Prod. Posting Group");
        BalVATPostingSetupText := GetPostingSetupText("Bal. VAT Bus. Posting Group", "Bal. VAT Prod. Posting Group");
    end;

    local procedure GetPostingSetupText(BusPostingGroup: Code[20]; ProdPostingGroup: Code[20]): Text
    begin
        if (BusPostingGroup = '') and (ProdPostingGroup = '') then
            exit('');

        exit(BusPostingGroup + ', ' + ProdPostingGroup);
    end;

    local procedure SetControlEnabled()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetupLocal: Record "VAT Posting Setup";
    begin
        AccountEnabled := "Account No." <> '';
        BalAccountEnabled := "Bal. Account No." <> '';
        GenPostingSetupEnabled := AccountEnabled and GeneralPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
        VATPostingSetupEnabled := AccountEnabled and VATPostingSetupLocal.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
        BalGenPostingSetupEnabled := BalAccountEnabled and GeneralPostingSetup.Get("Bal. Gen. Bus. Posting Group", "Bal. Gen. Prod. Posting Group");
        BalVATPostingSetupEnabled := BalAccountEnabled and VATPostingSetupLocal.Get("Bal. VAT Bus. Posting Group", "Bal. VAT Prod. Posting Group");

    end;

    local procedure DrillDownPostingGroup()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
        FAPostingGroup: Record "FA Posting Group";
    begin
        case true of
            ("Account Type" = "Account Type"::Customer) or
            ("Bal. Account Type" = "Bal. Account Type"::Customer):
                if CustomerPostingGroup.Get("Posting Group") then
                    Page.Run(Page::"Customer Posting Groups", CustomerPostingGroup);
            ("Account Type" = "Account Type"::Vendor) or
            ("Bal. Account Type" = "Bal. Account Type"::Vendor):
                if VendorPostingGroup.Get("Posting Group") then
                    Page.Run(Page::"Vendor Posting Groups", VendorPostingGroup);
            ("Account Type" = "Account Type"::"Fixed Asset") or
            ("Bal. Account Type" = "Bal. Account Type"::"Fixed Asset"):
                if FAPostingGroup.Get("Posting Group") then
                    Page.Run(Page::"FA Posting Groups", FAPostingGroup);
        end;
    end;
}