#if not CLEAN17
page 11744 "Cash Desk List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Cash Desks (Obsolete)';
    CardPageID = "Cash Desk Card";
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    SourceTable = "Bank Account";
    SourceTableView = WHERE("Account Type" = CONST("Cash Desk"));
    UsageCategory = Lists;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Control1220011)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the cash document.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of cash desk.';
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the phone number associated with the cash desk card.';
                    Visible = false;
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee contacted with cash desk.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field("Cashier No."; "Cashier No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cashier number from employee list.';
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a search name for the cash desk.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1220002; "Cash Desk FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
            }
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Cash Desk")
            {
                Caption = '&Cash Desk';
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Cash Desk Statistics";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View the statistics on the selected cash desk.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Bank Account"),
                                  "No." = FIELD("No.");
                    ToolTip = 'Specifies cash desk comments.';
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = CONST(270),
                                      "No." = FIELD("No.");
                        ShortCutKey = 'Shift+Ctrl+D';
                        ToolTip = 'View or edit the dimension sets that are set up for the cash document.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'Show how a group of cash desk use dimensions and dimension values.';

                        trigger OnAction()
                        var
                            BankAcc: Record "Bank Account";
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(BankAcc);
                            DefaultDimMultiple.SetMultiRecord(BankAcc, FieldNo("No."));
                            DefaultDimMultiple.RunModal;
                        end;
                    }
                }
                action(Balance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    Image = Balance;
                    RunObject = Page "Bank Account Balance";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ToolTip = 'Show the cash desk balance during the period.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = LedgerEntries;
                    RunObject = Page "Bank Account Ledger Entries";
                    RunPageLink = "Bank Account No." = FIELD("No.");
                    RunPageView = SORTING("Bank Account No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'Open the page with bank account ledger entries of this cash desk.';
                }
                action("C&ontact")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ontact';
                    Image = ContactPerson;
                    ToolTip = 'The function creates contact card or Specifies created contact card for cash desk.';

                    trigger OnAction()
                    begin
                        ShowContact;
                    end;
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                action("Opened Cash Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Opened Cash Documents';
                    Image = Document;
                    RunObject = Page "Cash Document List";
                    RunPageLink = "Cash Desk No." = FIELD("No.");
                    RunPageView = WHERE(Status = CONST(Open));
                    ToolTip = 'Show the overview of opened cash documents.';
                }
                action("Released Cash Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Released Cash Documents';
                    Image = Confirm;
                    RunObject = Page "Cash Document List";
                    RunPageLink = "Cash Desk No." = FIELD("No.");
                    RunPageView = WHERE(Status = CONST(Released));
                    ToolTip = 'Show the overview of released cash documents.';
                }
                action("Posted Cash Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Cash Documents';
                    Image = PostDocument;
                    RunObject = Page "Posted Cash Document List";
                    RunPageLink = "Cash Desk No." = FIELD("No.");
                    ToolTip = 'Show the overview of posted cash documents.';
                }
            }
        }
        area(creation)
        {
            action("Cash &Document")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash &Document';
                Image = Document;
                Promoted = true;
                PromotedCategory = New;
                RunObject = Page "Cash Document";
                RunPageLink = "Cash Desk No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new cash document.';
            }
        }
        area(reporting)
        {
            action(Cashbook)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cashbook';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Open the report for cash desk entries during the period.';

                trigger OnAction()
                var
                    BankAcc: Record "Bank Account";
                begin
                    BankAcc := Rec;
                    BankAcc.SetRecFilter;
                    REPORT.RunModal(REPORT::"Cash Desk Book", true, false, BankAcc);
                end;
            }
            action("Cash Inventory")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Inventory';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Open the report for cash inventory.';

                trigger OnAction()
                var
                    CashInventory: Report "Cash Inventory";
                begin
                    CashInventory.SetParameters("No.");
                    CashInventory.RunModal;
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        CashDesksFilter: Text;
    begin
        CheckCashDesks;
        CashDesksFilter := CashDeskMgt.GetCashDesksFilter;

        FilterGroup(2);
        if CashDesksFilter <> '' then
            SetFilter("No.", CashDesksFilter);
        FilterGroup(0);
    end;

    var
        CashDeskMgt: Codeunit CashDeskManagement;
}
#endif