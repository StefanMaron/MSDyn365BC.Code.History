page 28090 "Post Dated Checks"
{
    AutoSplitKey = true;
    Caption = 'Post Dated Checks';
    CardPageID = "Post Dated Checks List";
    DelayedInsert = true;
    PageType = Document;
    SaveValues = true;
    SourceTable = "Post Dated Check Line";
    SourceTableView = SORTING("Line Number")
                      WHERE("Account Type" = FILTER(" " | Customer | "G/L Account"));

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
                field(CustomerNo; CustomerNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    ToolTip = 'Specifies the customer.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Clear(CustomerList);
                        CustomerList.LookupMode(true);
                        if not (CustomerList.RunModal = ACTION::LookupOK) then
                            exit(false);

                        Text := CustomerList.GetSelectionFilter;
                        exit(true);

                        UpdateCustomer;
                        SetFilter("Check Date", GetFilter("Date Filter"));
                        if not FindFirst then
                            UpdateBalance;
                    end;

                    trigger OnValidate()
                    begin
                        CustomerNoOnAfterValidate();
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
                field("Bank Account"; "Bank Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account No. where you want to bank the post-dated check.';
                    Visible = false;
                }
                field("Check Date"; "Check Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the post-dated check when it is supposed to be banked.';
                }
                field("Check No."; "Check No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the check No. for the post-dated check.';
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
                    ToolTip = 'Specifies this is an auto-generated field which calculates the LCY amount.';
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
                    ToolTip = 'Specifies this field is used if the journal line will be applied to an already-posted document.';
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies this field is used if the journal line will be applied to an already-posted document.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the comment for the transaction for your reference.';
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
                field(CustomerBalance; CustomerBalance)
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
                            "Account Type"::Customer:
                                begin
                                    Customer.Get("Account No.");
                                    PAGE.RunModal(PAGE::"Customer Card", Customer);
                                end;
                        end;
                    end;
                }
            }
            group("F&unction")
            {
                Caption = 'F&unction';
                Image = "Action";
                action(SuggestChecksToBank)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Suggest Checks to Bank';
                    Image = FilterLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Get a list of checks to bank based on the check date.';

                    trigger OnAction()
                    begin
                        CustomerNo := '';
                        DateFilter := '';
                        SetView('SORTING(Line Number) WHERE(Account Type=FILTER(Customer|G/L Account))');
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
                        CustomerNo := '';
                        DateFilter := '';
                        SetView('SORTING(Line Number) WHERE(Account Type=FILTER(Customer|G/L Account))');
                    end;
                }
                action("Apply &Entries")
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
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(CreateCashJournal)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Create Cash Journal';
                    Image = CheckJournal;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Open the cash journal and create journal lines based on your current selection.';

                    trigger OnAction()
                    begin
                        if Confirm(Text001, false) then begin
                            PostDatedCheckMgt.Post(Rec);
                            CustomerNo := '';
                            DateFilter := '';
                            Reset;
                        end;
                        SetFilter("Account Type", 'Customer|G/L Account');
                    end;
                }
            }
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
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
            action("Customer Card")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Card';
                Image = Customer;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Customer Card";
                ToolTip = 'View more information about the customer.';
            }
        }
        area(reporting)
        {
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
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateBalance;
    end;

    var
        CustomerNo: Code[20];
        Customer: Record Customer;
        PostDatedCheck: Record "Post Dated Check Line";
        GLAccount: Record "G/L Account";
        CustomerList: Page "Customer List";
        PostDatedCheckMgt: Codeunit PostDatedCheckMgt;
        FilterTokens: Codeunit "Filter Tokens";
        CountCheck: Integer;
        LineCount: Integer;
        CustomerBalance: Decimal;
        LineAmount: Decimal;
        DateFilter: Text[250];
        BankDate: Text[30];
        Text001: Label 'Are you sure you want to create Cash Journal Lines?';
        Text002: Label 'There are %1 check(s) to bank.';

    [Scope('OnPrem')]
    procedure UpdateBalance()
    begin
        LineAmount := 0;
        LineCount := 0;
        if Customer.Get("Account No.") then begin
            Customer.CalcFields("Balance (LCY)");
            CustomerBalance := Customer."Balance (LCY)";
        end else
            CustomerBalance := 0;
        PostDatedCheck.Reset();
        PostDatedCheck.SetCurrentKey("Account Type", "Account No.");
        if DateFilter <> '' then
            PostDatedCheck.SetFilter("Check Date", DateFilter);
        PostDatedCheck.SetRange("Account Type", PostDatedCheck."Account Type"::Customer);
        if CustomerNo <> '' then
            PostDatedCheck.SetRange("Account No.", CustomerNo);
        if PostDatedCheck.FindSet then begin
            repeat
                LineAmount := LineAmount + PostDatedCheck."Amount (LCY)";
            until PostDatedCheck.Next() = 0;
            LineCount := PostDatedCheck.Count();
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateCustomer()
    begin
        if CustomerNo = '' then
            SetRange("Account No.")
        else
            SetRange("Account No.", CustomerNo);
        CurrPage.Update(false);
    end;

    local procedure DateFilterOnAfterValidate()
    begin
        FilterTokens.MakeDateFilter(DateFilter);
        SetFilter("Check Date", DateFilter);
        UpdateCustomer;
        UpdateBalance;
    end;

    local procedure CustomerNoOnAfterValidate()
    begin
        SetFilter("Check Date", DateFilter);
        UpdateCustomer;
        UpdateBalance;
    end;
}

