page 12409 "Posted Gen. Journals"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted General Journals';
    DataCaptionFields = "Journal Batch Name";
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Gen. Journal Line Archive";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentJnlTemplateName; CurrentJnlTemplateName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Journal Template Name';
                Editable = false;
                ToolTip = 'Specifies the name of the journal template, the basis of the journal batch, that the entries were posted from.';
            }
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Journal Batch Name';
                Lookup = true;

                trigger OnLookup(var Text: Text): Boolean
                begin
                    if PAGE.RunModal(PAGE::"Posted Gen. Journal Batches", GenJnlBatch) = ACTION::LookupOK then begin
                        CurrentJnlTemplateName := GenJnlBatch."Journal Template Name";
                        CurrentJnlBatchName := GenJnlBatch.Name;
                        SetName;
                    end;
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    GenJnlManagement.CheckName(CurrentJnlBatchName, GenJnlLine);
                    CurrentJnlBatchNameOnAfterVali;
                end;
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Date"; "Document Date")
                {
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("External Document No."; "External Document No.")
                {
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                    Visible = false;
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the account.';

                    trigger OnValidate()
                    begin
                        GetAccounts(AccName, BalAccName);
                    end;
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number associated with this line.';

                    trigger OnValidate()
                    begin
                        GetAccounts(AccName, BalAccName);
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Business Unit Code"; "Business Unit Code")
                {
                    ToolTip = 'Specifies the code for the business unit, in a company group structure.';
                    Visible = false;
                }
                field("Salespers./Purch. Code"; "Salespers./Purch. Code")
                {
                    ToolTip = 'Specifies the code for the salesperson or purchaser who is linked to the sale or purchase on the journal line.';
                    Visible = false;
                }
                field("Campaign No."; "Campaign No.")
                {
                    ToolTip = 'Specifies the number of the campaign that the journal line is linked to.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    AssistEdit = true;
                    ToolTip = 'Specifies the currency code for the record.';
                    Visible = false;

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", "Posting Date");
                        if ChangeExchangeRate.RunModal = ACTION::OK then
                            Validate("Currency Factor", ChangeExchangeRate.GetParameter);
                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Gen. Posting Type"; "Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of transaction.';
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of this line.';
                }
                field("VAT Amount"; "VAT Amount")
                {
                    ToolTip = 'Specifies the amount of VAT that is included in the total amount.';
                    Visible = false;
                }
                field("VAT Difference"; "VAT Difference")
                {
                    ToolTip = 'Specifies the difference between the calculated VAT amount and a VAT amount that you have entered manually.';
                    Visible = false;
                }
                field("Bal. VAT Amount"; "Bal. VAT Amount")
                {
                    ToolTip = 'Specifies the amount of Bal. VAT included in the total amount.';
                    Visible = false;
                }
                field("Bal. VAT Difference"; "Bal. VAT Difference")
                {
                    ToolTip = 'Specifies the difference between the calculate VAT amount and the VAT amount that you have entered manually.';
                    Visible = false;
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry will posted, such as a cash account for cash purchases.';

                    trigger OnValidate()
                    begin
                        GetAccounts(AccName, BalAccName);
                    end;
                }
                field("Bal. Gen. Posting Type"; "Bal. Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general posting type associated with the balancing account that will be used when you post the entry on the journal line.';
                }
                field("Bal. Gen. Bus. Posting Group"; "Bal. Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general business posting group code associated with the balancing account that will be used when you post the entry.';
                }
                field("Bal. Gen. Prod. Posting Group"; "Bal. Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general product posting group code associated with the balancing account that will be used when you post the entry.';
                }
                field("Bal. VAT Bus. Posting Group"; "Bal. VAT Bus. Posting Group")
                {
                    ToolTip = 'Specifies the code of the VAT business posting group that will be used when you post the entry on the journal line.';
                    Visible = false;
                }
                field("Bal. VAT Prod. Posting Group"; "Bal. VAT Prod. Posting Group")
                {
                    ToolTip = 'Specifies the code of the VAT product posting group that will be used when you post the entry on the journal line.';
                    Visible = false;
                }
                field("Bill-to/Pay-to No."; "Bill-to/Pay-to No.")
                {
                    ToolTip = 'Specifies the number of the bill-to customer or pay-to vendor that the entry is linked to.';
                    Visible = false;
                }
                field("Ship-to/Order Address Code"; "Ship-to/Order Address Code")
                {
                    ToolTip = 'Specifies the address code of the ship-to customer or order-from vendor that the entry is linked to.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                    Visible = false;
                }
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                    Visible = false;
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                    Visible = false;
                }
                field("Applies-to ID"; "Applies-to ID")
                {
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                    Visible = false;
                }
                field("On Hold"; "On Hold")
                {
                    ToolTip = 'Specifies that the related entry represents an unpaid invoice for which either a payment suggestion, a reminder, or a finance charge memo exists.';
                    Visible = false;
                }
                field("Bank Payment Type"; "Bank Payment Type")
                {
                    ToolTip = 'Specifies the code for the payment type to be used for the entry on the journal line.';
                    Visible = false;
                }
                field("Reason Code"; "Reason Code")
                {
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Posted Gen. Journal Line Card";
                    RunPageLink = "Journal Template Name" = FIELD("Journal Template Name"),
                                  "Journal Batch Name" = FIELD("Journal Batch Name"),
                                  "Line No." = FIELD("Line No.");
                    ShortCutKey = 'Shift+F4';
                    ToolTip = 'View or edit details about the selected entity.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                        CurrPage.Update;
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    NavigatePage.SetDoc("Posting Date", "Document No.");
                    NavigatePage.Run;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetAccounts(AccName, BalAccName);
    end;

    trigger OnOpenPage()
    begin
        OpenJnl;
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlManagement: Codeunit GenJnlManagement;
        ChangeExchangeRate: Page "Change Exchange Rate";
        NavigatePage: Page Navigate;
        CurrentJnlTemplateName: Code[10];
        CurrentJnlBatchName: Code[10];
        AccName: Text[30];
        BalAccName: Text[30];

    [Scope('OnPrem')]
    procedure OpenJnl()
    begin
        FilterGroup := 2;
        SetRange("Journal Template Name", CurrentJnlTemplateName);
        SetRange("Journal Batch Name", CurrentJnlBatchName);
        FilterGroup := 0;
        if Find('-') then;
    end;

    [Scope('OnPrem')]
    procedure SetName()
    begin
        FilterGroup := 2;
        SetRange("Journal Template Name", CurrentJnlTemplateName);
        SetRange("Journal Batch Name", CurrentJnlBatchName);
        FilterGroup := 0;
        if Find('-') then;
    end;

    [Scope('OnPrem')]
    procedure GetAccounts(var AccName: Text[30]; var BalAccName: Text[30])
    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        FA: Record "Fixed Asset";
    begin
        AccName := '';
        if GenJnlLine."Account No." <> '' then
            case GenJnlLine."Account Type" of
                GenJnlLine."Account Type"::"G/L Account":
                    if GLAcc.Get(GenJnlLine."Account No.") then
                        AccName := GLAcc.Name;
                GenJnlLine."Account Type"::Customer:
                    if Cust.Get(GenJnlLine."Account No.") then
                        AccName := Cust.Name;
                GenJnlLine."Account Type"::Vendor:
                    if Vend.Get(GenJnlLine."Account No.") then
                        AccName := Vend.Name;
                GenJnlLine."Account Type"::"Bank Account":
                    if BankAcc.Get(GenJnlLine."Account No.") then
                        AccName := BankAcc.Name;
                GenJnlLine."Account Type"::"Fixed Asset":
                    if FA.Get(GenJnlLine."Account No.") then
                        AccName := FA.Description;
            end;

        BalAccName := '';
        if GenJnlLine."Bal. Account No." <> '' then
            case GenJnlLine."Bal. Account Type" of
                GenJnlLine."Bal. Account Type"::"G/L Account":
                    if GLAcc.Get(GenJnlLine."Bal. Account No.") then
                        BalAccName := GLAcc.Name;
                GenJnlLine."Bal. Account Type"::Customer:
                    if Cust.Get(GenJnlLine."Bal. Account No.") then
                        BalAccName := Cust.Name;
                GenJnlLine."Bal. Account Type"::Vendor:
                    if Vend.Get(GenJnlLine."Bal. Account No.") then
                        BalAccName := Vend.Name;
                GenJnlLine."Bal. Account Type"::"Bank Account":
                    if BankAcc.Get(GenJnlLine."Bal. Account No.") then
                        BalAccName := BankAcc.Name;
                GenJnlLine."Bal. Account Type"::"Fixed Asset":
                    if FA.Get(GenJnlLine."Bal. Account No.") then
                        BalAccName := FA.Description;
            end;
    end;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord;
        SetName;
        CurrPage.Update(false);
    end;
}

