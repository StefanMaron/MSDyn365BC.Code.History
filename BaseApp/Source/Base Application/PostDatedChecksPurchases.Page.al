page 28092 "Post Dated Checks-Purchases"
{
    AutoSplitKey = true;
    Caption = 'Post Dated Checks-Purchases';
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Post Dated Check Line";
    SourceTableView = SORTING("Line Number")
                      WHERE("Account Type" = FILTER(" " | Vendor | "G/L Account"));

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies a filter, that will filter entries by date. You can enter a particular date or a time interval.';

                    trigger OnValidate()
                    begin
                        DateFilterOnAfterValidate;
                    end;
                }
                field(VendorNo; VendorNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor';
                    ToolTip = 'Specifies the vendor.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Clear(VendorList);
                        VendorList.LookupMode(true);
                        if not (VendorList.RunModal = ACTION::LookupOK) then
                            exit(false);

                        Text := VendorList.GetSelectionFilter;
                        exit(true);

                        UpdateVendor;
                        SetFilter("Check Date", DateFilter);
                        if not FindFirst then
                            UpdateBalance;
                    end;

                    trigger OnValidate()
                    begin
                        VendorNoOnAfterValidate();
                    end;
                }
            }
            repeater(Control1500007)
            {
                ShowCaption = false;
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that the entry on the journal line will be posted to.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account that the entry on the journal line will be posted to.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document no. for this post-dated check journal.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description for the post-dated check journal line.';
                }
                field("Check Date"; "Check Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the post-dated check when it is supposed to be banked.';
                    Visible = true;
                }
                field("Check No."; "Check No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the check No. for the post-dated check.';
                    Visible = true;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the post-dated check.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Amount of the post-dated check.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the calculated amount in LCY.';
                }
                field("Date Received"; "Date Received")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when we received the post-dated check.';
                }
                field("Replacement Check"; "Replacement Check")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this check is a replacement for any earlier unusable check.';
                }
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the journal line will be applied to an already-posted document.';
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the journal line will be applied to an already-posted document.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the comment for the transaction for your reference.';
                }
                field("Bank Account"; "Bank Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account No. where you want to bank the post-dated check.';
                    Visible = true;
                }
                field("Bank Payment Type"; "Bank Payment Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the payment type to be used for the entry on the payment journal line.';
                }
                field("Batch Name"; "Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a default batch.';
                }
            }
            group(Control1500001)
            {
                ShowCaption = false;
                field(Description2; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description for the post-dated check journal line.';
                }
                field(VendorBalance; VendorBalance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the balance in your currency.';
                }
                field(LineCount; LineCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Count';
                    Editable = false;
                    ToolTip = 'Specifies the number of journal lines.';
                }
                field(LineAmount; LineAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount for the line.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1905532107; "Dimensions FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                Visible = false;
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
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions for the selected records.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                        CurrPage.SaveRecord;
                    end;
                }
            }
            group("&Account")
            {
                Caption = '&Account';
                Image = ChartOfAccounts;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View more information about the selected line.';

                    trigger OnAction()
                    begin
                        case "Account Type" of
                            "Account Type"::"G/L Account":
                                begin
                                    GLAccount.Get("Account No.");
                                    PAGE.RunModal(PAGE::"G/L Account Card", GLAccount);
                                end;
                            "Account Type"::Vendor:
                                begin
                                    Vendor.Get("Account No.");
                                    PAGE.RunModal(PAGE::"Vendor Card", Vendor);
                                end;
                        end;
                    end;
                }
            }
            group("F&unction")
            {
                Caption = 'F&unction';
                Image = "Action";
                action("&Suggest Checks to Bank")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Suggest Checks to Bank';
                    Image = FilterLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Get a list of checks to bank based on the check date.';

                    trigger OnAction()
                    begin
                        VendorNo := '';
                        DateFilter := '';
                        SetView('SORTING(Line Number) WHERE(Account Type=FILTER(Vendor|G/L Account))');

                        BankDate := '..' + Format(WorkDate);
                        SetFilter("Date Filter", BankDate);
                        SetFilter("Check Date", GetFilter("Date Filter"));
                        CurrPage.Update(false);
                        CountCheck := Count;
                        Message(Text002, CountCheck);
                    end;
                }
                action("Show &All")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show &All';
                    Image = RemoveFilterLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Clear the filters and view all check lines.';

                    trigger OnAction()
                    begin
                        VendorNo := '';
                        DateFilter := '';
                        SetView('SORTING(Line Number) WHERE(Account Type=FILTER(Vendor|G/L Account))');
                    end;
                }
                action(ApplyEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply &Entries';
                    Image = ApplyEntries;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Apply the lines to the related documents.';

                    trigger OnAction()
                    begin
                        PostDatedCheckMgt.ApplyEntries(Rec);
                    end;
                }
            }
            group("&Payment")
            {
                Caption = '&Payment';
                action(SuggestVendorPayments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Vendor Payments';
                    Image = SuggestVendorPayments;
                    ToolTip = 'View the suggest document.';

                    trigger OnAction()
                    begin
                        TestField("Account Type", "Account Type"::Vendor);
                        PostDatedCheckMgt.SuggestVendorPayments;
                    end;
                }
                action("Preview Check")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview Check';
                    Image = ViewCheck;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'View a preview of the check.';

                    trigger OnAction()
                    begin
                        PostDatedCheckMgt.PreviewCheck(Rec);
                    end;
                }
                action("Print Check")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print Check';
                    Image = PrintCheck;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Print the check.';

                    trigger OnAction()
                    begin
                        PostDatedCheckMgt.PrintCheck(Rec);
                    end;
                }
                action("Void Check")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Void Check';
                    Image = VoidCheck;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Start the process of voiding the check.';

                    trigger OnAction()
                    begin
                        PostDatedCheckMgt.VoidCheck(Rec);
                    end;
                }
                action(CreateCheckInstallments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Check Installments';
                    Image = Installments;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Start the process of creating check installments for post-dated checks. You can define the number of installments that a payment will be divided into, the percent of interest, and the period in which the checks will be created.';

                    trigger OnAction()
                    begin
                        TestField("Check Date");
                        TestField("Account Type", "Account Type"::Vendor);
                        TestField("Bank Account");
                        TestField("Document No.");
                        TestField("Check Printed", false);
                        CreateInstallments.SetPostDatedCheckLine(Rec);
                        CreateInstallments.RunModal;
                        Clear(CreateInstallments);
                    end;
                }
            }
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(CreatePaymentJournal)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Create Payment Journal';
                    Image = SuggestVendorPayments;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Open the payment journal and create journal lines based on your current selection.';

                    trigger OnAction()
                    begin
                        if Confirm(Text001, false) then begin
                            PostDatedCheckMgt.Post(Rec);
                            VendorNo := '';
                            DateFilter := '';
                            Reset;
                        end;
                        SetFilter("Account Type", 'Vendor|G/L Account');
                    end;
                }
                action("Print Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print Report';
                    ToolTip = 'Print a report based on the current filters on the check line.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Post Dated Checks", true, true, Rec);
                    end;
                }
                action("Print Acknowledgement Receipt")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print Acknowledgement Receipt';
                    Image = PrintAcknowledgement;
                    ToolTip = 'Print the receipt.';

                    trigger OnAction()
                    begin
                        PostDatedCheck.CopyFilters(Rec);
                        PostDatedCheck.SetRange("Account Type", "Account Type");
                        PostDatedCheck.SetRange("Account No.", "Account No.");
                        if PostDatedCheck.FindFirst then
                            REPORT.RunModal(REPORT::"PDC Acknowledgement Receipt", true, true, PostDatedCheck);
                    end;
                }
            }
            action("Cash Receipt Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Receipt Journal';
                Image = CashReceiptJournal;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Cash Receipt Journal";
                ToolTip = 'Open the cash receipt journal and create journal lines based on your current selection.';
            }
        }
        area(reporting)
        {
            action("PDC Acknowledgement Receipt")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'PDC Acknowledgement Receipt';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "PDC Acknowledgement Receipt";
                ToolTip = 'Create a PDC acknowledgement receipt.';
            }
            action("Post Dated Checks")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Post Dated Checks';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Post Dated Checks";
                ToolTip = 'View the information that you want to print on the Post Dated Checks report based on the filters that you have set up for the check line.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateBalance;
    end;

    var
        Text001: Label 'Are you sure you want to create Cash Journal Lines?';
        Text002: Label 'There are %1 check(s) to bank.';
        VendorNo: Code[250];
        Vendor: Record Vendor;
        PostDatedCheck: Record "Post Dated Check Line";
        GLAccount: Record "G/L Account";
        VendorList: Page "Vendor List";
        CreateInstallments: Report "Create Check Installments";
        PostDatedCheckMgt: Codeunit PostDatedCheckMgt;
        FilterTokens: Codeunit "Filter Tokens";
        CountCheck: Integer;
        LineCount: Integer;
        VendorBalance: Decimal;
        LineAmount: Decimal;
        DateFilter: Text[250];
        BankDate: Text[30];

    [Scope('OnPrem')]
    procedure UpdateBalance()
    begin
        LineAmount := 0;
        LineCount := 0;
        if Vendor.Get("Account No.") then begin
            Vendor.CalcFields("Balance (LCY)");
            VendorBalance := Vendor."Balance (LCY)";
        end else
            VendorBalance := 0;
        PostDatedCheck.Reset();
        PostDatedCheck.SetCurrentKey("Account Type", "Account No.");
        if DateFilter <> '' then
            PostDatedCheck.SetFilter("Check Date", DateFilter);
        PostDatedCheck.SetRange("Account Type", PostDatedCheck."Account Type"::Vendor);
        if VendorNo <> '' then
            PostDatedCheck.SetRange("Account No.", VendorNo);
        if PostDatedCheck.FindSet then begin
            repeat
                LineAmount := LineAmount + PostDatedCheck."Amount (LCY)";
            until PostDatedCheck.Next = 0;
            LineCount := PostDatedCheck.Count();
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateVendor()
    begin
        if VendorNo = '' then
            SetRange("Account No.")
        else
            SetRange("Account No.", VendorNo);
        CurrPage.Update(false);
    end;

    local procedure DateFilterOnAfterValidate()
    begin
        FilterTokens.MakeDateFilter(DateFilter);
        SetFilter("Check Date", DateFilter);
        UpdateVendor;
        UpdateBalance;
    end;

    local procedure VendorNoOnAfterValidate()
    begin
        SetFilter("Check Date", DateFilter);
        UpdateVendor;
        UpdateBalance;
    end;
}

