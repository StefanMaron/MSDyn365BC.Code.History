page 11728 "Specification Appl. Parametrs"
{
    Caption = 'Specification Appl. Parametrs';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    InstructionalText = 'Set appl. parameters.';
    ModifyAllowed = false;
    PageType = ConfirmationDialog;

    layout
    {
        area(content)
        {
            field(NotApplyCustLedgerEntries; NotApplyCustLedgerEntries)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Not Apply Cust. Ledger Entries';
                ToolTip = 'Specifies if Apply Automatically function in Payment Recon.Journal applies to Customer Ledger Entries.';
            }
            field(NotApplyVendLedgerEntries; NotApplyVendLedgerEntries)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Not Apply Vend. Ledger Entries';
                ToolTip = 'Specifies if Apply Automatically function in Payment Recon.Journal applies to Vendor Ledger Entries.';
            }
            field(NotApplySalesAdvances; NotApplySalesAdvances)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Not Apply Sales Advances';
                ToolTip = 'Specifies if Apply Automatically function in Payment Recon.Journal applies to Sales Advances.';
            }
            field(NotApplyPurchaseAdvances; NotApplyPurchaseAdvances)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Not Apply Purchase Advances';
                ToolTip = 'Specifies if Apply Automatically function in Payment Recon.Journal applies to Purchase Advances.';
            }
            field(NotApplyGenLedgerEntries; NotApplyGenLedgerEntries)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Not Apply Gen. Ledger Entries';
                ToolTip = 'Specifies if Apply Automatically function in Payment Recon.Journal applies to General Ledger Entries.';
                Visible = IsManual;
            }
            field(NotAplBankAccLedgEntries; NotAplBankAccLedgEntries)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Not Apl. Bank Acc.Ledg.Entries';
                ToolTip = 'Specifies if Apply Automatically function in Payment Recon.Journal applies to Bank Account Ledger Entries.';
            }
            field(UsePaymentAppRules; UsePaymentAppRules)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Use Payment Application Rules';
                ToolTip = 'Specifies if Apply Automatically function in Payment Recon.Journal use Payment Application Rules.';
            }
            field(BankPmtApplRuleCode; BankPmtApplRuleCode)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Pmt. Appl. Rule Code';
                Editable = UsePaymentAppRules;
                TableRelation = "Bank Pmt. Appl. Rule Code";
                ToolTip = 'Specifies which Payment Application Rules use Apply Automatically function in Payment Recon.Journal.';
            }
            field(UseTextToAccMappingCode; UseTextToAccMappingCode)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Use Text-to-Account Mapping';
                ToolTip = 'Specifies if Apply Automatically function in Payment Recon.Journal use Text-to-Account Mapping.';
            }
            field(TextToAccMappingCode; TextToAccMappingCode)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Text-to-Account Mapping Code';
                Editable = UseTextToAccMappingCode;
                TableRelation = "Text-to-Account Mapping Code";
                ToolTip = 'Specifies which Text-to-Account Mapping use Apply Automatically function in Payment Recon.Journal.';
            }
            field(OnlyNotAppliedLines; OnlyNotAppliedLines)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Only Not Applied Lines';
                ToolTip = 'Specifies if Apply Automatically function in Payment Recon.Journal applies only lines without any application.';
                Visible = NOT IsManual;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CurrPage.Update(false);
    end;

    var
        NotApplyCustLedgerEntries: Boolean;
        NotApplyVendLedgerEntries: Boolean;
        NotApplySalesAdvances: Boolean;
        NotApplyPurchaseAdvances: Boolean;
        NotApplyGenLedgerEntries: Boolean;
        NotAplBankAccLedgEntries: Boolean;
        UsePaymentAppRules: Boolean;
        UseTextToAccMappingCode: Boolean;
        BankPmtApplRuleCode: Code[10];
        TextToAccMappingCode: Code[10];
        OnlyNotAppliedLines: Boolean;
        IsManual: Boolean;

    [Scope('OnPrem')]
    procedure SetBankAccount(BankAccount: Record "Bank Account")
    begin
        NotApplyCustLedgerEntries := BankAccount."Not Apply Cust. Ledger Entries";
        NotApplyVendLedgerEntries := BankAccount."Not Apply Vend. Ledger Entries";
        NotApplySalesAdvances := BankAccount."Not Apply Sales Advances";
        NotApplyPurchaseAdvances := BankAccount."Not Apply Purchase Advances";
        NotApplyGenLedgerEntries := BankAccount."Not Apply Gen. Ledger Entries";
        NotAplBankAccLedgEntries := BankAccount."Not Apl. Bank Acc.Ledg.Entries";
        BankPmtApplRuleCode := BankAccount."Bank Pmt. Appl. Rule Code";
        TextToAccMappingCode := BankAccount."Text-to-Account Mapping Code";

        UsePaymentAppRules := true;
        UseTextToAccMappingCode := true;
    end;

    [Scope('OnPrem')]
    procedure SetIsManual(Manual: Boolean)
    begin
        IsManual := Manual;
    end;

    [Scope('OnPrem')]
    procedure GetValuesForApp(var NotApplyCustLedgerEntriesNew: Boolean; var NotApplyVendLedgerEntriesNew: Boolean; var NotApplySalesAdvancesNew: Boolean; var NotApplyPurchaseAdvancesNew: Boolean; var NotApplyGenLedgerEntriesNew: Boolean; var NotAplBankAccLedgEntriesNew: Boolean; var UsePaymentAppRulesNew: Boolean; var UseTextToAccMappingCodeNew: Boolean; var BankPmtApplRuleCodeNew: Code[10]; var TextToAccountMappingCodeNew: Code[10]; var OnlyNotAppliedLinesNew: Boolean)
    begin
        if not UsePaymentAppRules then begin
            NotApplyCustLedgerEntries := true;
            NotApplyVendLedgerEntries := true;
            NotApplySalesAdvances := true;
            NotApplyPurchaseAdvances := true;
            NotApplyGenLedgerEntries := true;
            NotAplBankAccLedgEntries := true;
        end;

        NotApplyCustLedgerEntriesNew := NotApplyCustLedgerEntries;
        NotApplyVendLedgerEntriesNew := NotApplyVendLedgerEntries;
        NotApplySalesAdvancesNew := NotApplySalesAdvances;
        NotApplyPurchaseAdvancesNew := NotApplyPurchaseAdvances;
        NotApplyGenLedgerEntriesNew := NotApplyGenLedgerEntries;
        NotAplBankAccLedgEntriesNew := NotAplBankAccLedgEntries;
        UsePaymentAppRulesNew := UsePaymentAppRules;
        UseTextToAccMappingCodeNew := UseTextToAccMappingCode;
        BankPmtApplRuleCodeNew := BankPmtApplRuleCode;
        TextToAccountMappingCodeNew := TextToAccMappingCode;
        OnlyNotAppliedLinesNew := OnlyNotAppliedLines;
    end;
}

