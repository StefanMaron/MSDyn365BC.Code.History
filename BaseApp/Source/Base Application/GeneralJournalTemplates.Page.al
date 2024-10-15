page 101 "General Journal Templates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'General Journal Templates';
    PageType = List;
    SourceTable = "Gen. Journal Template";
    UsageCategory = Administration;
    Permissions = tabledata "G/L Entry" = rm,
                  tabledata "G/L Register" = rm,
                  tabledata "Bank Account Ledger Entry" = rm,
                  tabledata "Cust. Ledger Entry" = rm,
                  tabledata "Employee Ledger Entry" = rm,
                  tabledata "Vendor LEdger Entry" = rm,
                  tabledata "VAT Entry" = rm;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal template you are creating.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a brief description of the journal template you are creating.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the journal type. The type determines what the window will look like.';
                }
                field(Recurring; Recurring)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the journal template will be a recurring journal.';
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Posting No. Series"; Rec."Posting No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign document numbers to ledger entries that are posted from journals using this template.';
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Force Doc. Balance"; Rec."Force Doc. Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether transactions that are posted in the general journal must balance by document number and document type, in addition to balancing by date.';
                }
                field("Copy VAT Setup to Jnl. Lines"; Rec."Copy VAT Setup to Jnl. Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the program to calculate VAT for accounts and balancing accounts on the journal line of the selected journal template.';

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if "Copy VAT Setup to Jnl. Lines" <> xRec."Copy VAT Setup to Jnl. Lines" then
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(Text001, FieldCaption("Copy VAT Setup to Jnl. Lines")), true)
                            then
                                Error(Text002);
                    end;
                }
                field("Increment Batch Name"; Rec."Increment Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if batch names using this template are automatically incremented. Example: The posting following BATCH001 is automatically named BATCH002.';
                }
                field("Allow VAT Difference"; Rec."Allow VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to allow the manual adjustment of VAT amounts in journals.';

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if "Allow VAT Difference" <> xRec."Allow VAT Difference" then
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(Text001, FieldCaption("Allow VAT Difference")), true)
                            then
                                Error(Text002);
                    end;
                }
                field("Allow Posting Date From"; Rec."Allow Posting Date From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date when posting to the journal template is allowed.';
                    Visible = false;
                }
                field("Allow Posting Date To"; Rec."Allow Posting Date To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date when posting to the journal template is allowed.';
                    Visible = false;
                }
                field("Allow Posting From"; Rec."Allow Posting From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date when posting to the journal template is allowed.';
                }
                field("Allow Posting To"; Rec."Allow Posting To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date when posting to the journal template is allowed.';
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Test Report ID"; Rec."Test Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the test report that is printed when you click Test Report.';
                    Visible = false;
                }
                field("Test Report Caption"; Rec."Test Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the test report that is printed when you print a journal under this journal template.';
                    Visible = false;
                }
                field("Posting Report ID"; Rec."Posting Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the posting report that is printed when you choose Post and Print.';
                    Visible = false;
                }
                field("Posting Report Caption"; Rec."Posting Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the report that is printed when you print the journal.';
                    Visible = false;
                }
                field("Force Posting Report"; Rec."Force Posting Report")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether a report is printed automatically when you post.';
                    Visible = false;
                }
                field("Cust. Receipt Report ID"; Rec."Cust. Receipt Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies how to print customer receipts when you post.';
                    Visible = false;
                }
                field("Cust. Receipt Report Caption"; Rec."Cust. Receipt Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies how to print customer receipts when you post.';
                    Visible = false;
                }
                field("Vendor Receipt Report ID"; Rec."Vendor Receipt Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies how to print vendor receipts when you post.';
                    Visible = false;
                }
                field("Vendor Receipt Report Caption"; Rec."Vendor Receipt Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies how to print vendor receipts when you post.';
                    Visible = false;
                }
                field("Copy to Posted Jnl. Lines"; Rec."Copy to Posted Jnl. Lines")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the journal lines to be copied to posted journal lines of the selected journal template.';

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if "Copy to Posted Jnl. Lines" <> xRec."Copy to Posted Jnl. Lines" then
                            if not ConfirmManagement.GetResponseOrDefault(EnableCopyToPostedQst, true) then
                                Error(Text002);
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Te&mplate")
            {
                Caption = 'Te&mplate';
                Image = Template;
                action(Batches)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Batches';
                    Image = Description;
                    RunObject = Page "General Journal Batches";
                    RunPageLink = "Journal Template Name" = FIELD(Name);
                    ToolTip = 'View or edit multiple journals for a specific template. You can use batches when you need multiple journals of a certain type.';
                }
                action(Update)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Journal Template Names in ledger entries and open documents.';
                    Image = Description;
                    ToolTip = 'This procedure will copy values from local Journal Template Name to new Journal Templ. Name if new field in the record is empty.';

                    trigger OnAction()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if not ConfirmManagement.GetResponse(ConfirmCopyTxt, true) then
                            exit;

                        UpgradeGeneralLedgerSetup();
                        UpgradeGenJournalTemplates();
                        UpgradeGLEntryJournalTemplateName();
                        UpgradeGLRegisterJournalTemplateName();
                        UpgradeVATEntryJournalTemplateName();
                        UpgradeBankAccLedgerEntryJournalTemplateName();
                        UpgradeCustLedgerEntryJournalTemplateName();
                        UpgradeEmplLedgerEntryJournalTemplateName();
                        UpgradeVendLedgerEntryJournalTemplateName();
                        UpgradePurchaseHeaderJournalTemplateName();
                        UpgradeSalesHeaderJournalTemplateName();
                        UpgradeServiceHeaderJournalTemplateName();
                    end;
                }
            }
        }
    }

    var
        Text001: Label 'Do you want to update the %1 field on all general journal batches?';
        Text002: Label 'Canceled.';
        EnableCopyToPostedQst: Label 'Do you want to enable copying of journal lines to posted general journal on journal batches that belong to selected general journal template?';
        ConfirmCopyTxt: Label 'This procedure will copy values from local Journal Template Name to new Journal Templ. Name if new field in the record is empty. Do you want to copy them?';

    local procedure UpgradeGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Journal Templ. Name Mandatory" := true;
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpgradeGenJournalTemplates()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetLoadFields(
            "Allow Posting Date From", "Allow Posting Date To", "Allow Posting From", "Allow Posting To");
        if GenJournalTemplate.FindSet(true) then
            repeat
                if (GenJournalTemplate."Allow Posting From" <> 0D) or (GenJournalTemplate."Allow Posting To" <> 0D) then begin
                    if GenJournalTemplate."Allow Posting Date From" <> 0D then
                        GenJournalTemplate."Allow Posting Date From" := GenJournalTemplate."Allow Posting From";
                    if GenJournalTemplate."Allow Posting Date To" <> 0D then
                        GenJournalTemplate."Allow Posting Date To" := GenJournalTemplate."Allow Posting To";
                    GenJournalTemplate.Modify();
                end;
            until GenJournalTemplate.Next() = 0;
    end;

    local procedure UpgradeGLEntryJournalTemplateName()
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        GLEntry.SetFilter("Journal Template Name", '<>%1', '');
        GLEntry.SetRange("Journal Templ. Name", '');
        if GLEntry.FindSet(true) then
            repeat
                GLEntry."Journal Templ. Name" := GLEntry."Journal Template Name";
                GLEntry.Modify();
            until GLEntry.Next() = 0;
    end;

    local procedure UpgradeGLRegisterJournalTemplateName()
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        GLRegister.SetFilter("Journal Template Name", '<>%1', '');
        GLRegister.SetRange("Journal Templ. Name", '');
        if GLRegister.FindSet(true) then
            repeat
                GLRegister."Journal Templ. Name" := GLRegister."Journal Template Name";
                GLRegister.Modify();
            until GLRegister.Next() = 0;
    end;

    local procedure UpgradeVATEntryJournalTemplateName()
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        VATEntry.SetFilter("Journal Template Name", '<>%1', '');
        VATEntry.SetRange("Journal Templ. Name", '');
        if VATEntry.FindSet(true) then
            repeat
                VATEntry."Journal Templ. Name" := VATEntry."Journal Template Name";
                VATEntry.Modify();
            until VATEntry.Next() = 0;
    end;

    local procedure UpgradeBankAccLedgerEntryJournalTemplateName()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        BankAccountLedgerEntry.SetFilter("Journal Template Name", '<>%1', '');
        BankAccountLedgerEntry.SetRange("Journal Templ. Name", '');
        if BankAccountLedgerEntry.FindSet(true) then
            repeat
                BankAccountLedgerEntry."Journal Templ. Name" := BankAccountLedgerEntry."Journal Template Name";
                BankAccountLedgerEntry.Modify();
            until BankAccountLedgerEntry.Next() = 0;
    end;

    local procedure UpgradeCustLedgerEntryJournalTemplateName()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        CustLedgerEntry.SetFilter("Journal Template Name", '<>%1', '');
        CustLedgerEntry.SetRange("Journal Templ. Name", '');
        if CustLedgerEntry.FindSet(true) then
            repeat
                CustLedgerEntry."Journal Templ. Name" := CustLedgerEntry."Journal Template Name";
                CustLedgerEntry.Modify();
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure UpgradeEmplLedgerEntryJournalTemplateName()
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        EmployeeLedgerEntry.SetFilter("Journal Template Name", '<>%1', '');
        EmployeeLedgerEntry.SetRange("Journal Templ. Name", '');
        if EmployeeLedgerEntry.FindSet(true) then
            repeat
                EmployeeLedgerEntry."Journal Templ. Name" := EmployeeLedgerEntry."Journal Template Name";
                EmployeeLedgerEntry.Modify();
            until EmployeeLedgerEntry.Next() = 0;
    end;

    local procedure UpgradeVendLedgerEntryJournalTemplateName()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgerEntry.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        VendLedgerEntry.SetFilter("Journal Template Name", '<>%1', '');
        VendLedgerEntry.SetRange("Journal Templ. Name", '');
        if VendLedgerEntry.FindSet(true) then
            repeat
                VendLedgerEntry."Journal Templ. Name" := VendLedgerEntry."Journal Template Name";
                VendLedgerEntry.Modify();
            until VendLedgerEntry.Next() = 0;
    end;

    local procedure UpgradeSalesHeaderJournalTemplateName()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        SalesHeader.SetFilter("Journal Template Name", '<>%1', '');
        SalesHeader.SetRange("Journal Templ. Name", '');
        if SalesHeader.FindSet(true) then
            repeat
                SalesHeader."Journal Templ. Name" := SalesHeader."Journal Template Name";
                SalesHeader.Modify();
            until SalesHeader.Next() = 0;
    end;

    local procedure UpgradeServiceHeaderJournalTemplateName()
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        ServiceHeader.SetFilter("Journal Template Name", '<>%1', '');
        ServiceHeader.SetRange("Journal Templ. Name", '');
        if ServiceHeader.FindSet(true) then
            repeat
                ServiceHeader."Journal Templ. Name" := ServiceHeader."Journal Template Name";
                ServiceHeader.Modify();
            until ServiceHeader.Next() = 0;
    end;

    local procedure UpgradePurchaseHeaderJournalTemplateName()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        PurchaseHeader.SetFilter("Journal Template Name", '<>%1', '');
        PurchaseHeader.SetRange("Journal Templ. Name", '');
        if PurchaseHeader.FindSet(true) then
            repeat
                PurchaseHeader."Journal Templ. Name" := PurchaseHeader."Journal Template Name";
                PurchaseHeader.Modify();
            until PurchaseHeader.Next() = 0;
    end;
}

