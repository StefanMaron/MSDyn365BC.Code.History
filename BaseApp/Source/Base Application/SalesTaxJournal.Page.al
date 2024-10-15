page 10101 "Sales Tax Journal"
{
    ApplicationArea = SalesTax;
    AutoSplitKey = true;
    Caption = 'Sales Tax Journal';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Gen. Journal Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = SalesTax;
                Caption = 'Batch Name';
                Lookup = true;
                ToolTip = 'Specifies the journal batch.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord;
                    GenJnlManagement.LookupName(CurrentJnlBatchName, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    GenJnlManagement.CheckName(CurrentJnlBatchName, Rec);
                    CurrentJnlBatchNameOnAfterVali;
                end;
            }
            repeater(Control1030011)
            {
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the date when the sales tax journal line was posted.';
                }
                field("Document Date"; "Document Date")
                {
                    ToolTip = 'Specifies the date on which you created the journal line.';
                    Visible = false;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the type of the document on the journal line.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the number of the document on the journal line.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the type of the affected account.';

                    trigger OnValidate()
                    begin
                        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
                    end;
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the number of the affected account.';

                    trigger OnValidate()
                    begin
                        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
                        ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies a description of the tax journal line.';
                }
                field("GST/HST"; "GST/HST")
                {
                    ApplicationArea = BasicCA;
                    ToolTip = 'Specifies the type of goods and services tax (GST) for the general journal line.';

                    trigger OnValidate()
                    begin
                        case "GST/HST" of
                            "GST/HST"::Acquisition:
                                Error(Text002);
                        end;
                    end;
                }
                field("Tax Group Code"; "Tax Group Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax group that is used to calculate and post sales tax.';
                    Visible = true;
                }
                field("Tax Jurisdiction Code"; "Tax Jurisdiction Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax jurisdiction that is used for the Tax Area Code field on the purchase or sales lines.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax amount.';
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the type of the G/L account or the bank account that a balancing entry will be posted to.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the number of the G/L account or the bank account that a balancing entry will be posted to.';

                    trigger OnValidate()
                    begin
                        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
                        ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
            }
            group(Control1030025)
            {
                ShowCaption = false;
                label(Control1030026)
                {
                    ApplicationArea = SalesTax;
                    CaptionClass = Text19039985;
                    ShowCaption = false;
                }
                field(AccName; AccName)
                {
                    ApplicationArea = SalesTax;
                    Editable = false;
                    ShowCaption = false;
                }
                field(BalAccName; BalAccName)
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Bal. Account Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the balancing account.';
                }
                field(Balance; Balance + "Balance (LCY)" - xRec."Balance (LCY)")
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Balance';
                    Editable = false;
                    ToolTip = 'Specifies the customer''s balance. ';
                    Visible = BalanceVisible;
                }
                field(TotalBalance; TotalBalance + "Balance (LCY)" - xRec."Balance (LCY)")
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Total Balance';
                    Editable = false;
                    ToolTip = 'Specifies the total amount of the lines that are adjustments.';
                    Visible = TotalBalanceVisible;
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
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                        CurrPage.SaveRecord;
                    end;
                }
            }
            group("A&ccount")
            {
                Caption = 'A&ccount';
                Image = ChartOfAccounts;
                action(Card)
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Codeunit "Gen. Jnl.-Show Card";
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the card for the customer.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Ledger E&ntries';
                    RunObject = Codeunit "Gen. Jnl.-Show Entries";
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
            }
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Reconcile)
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Reconcile';
                    Image = Reconcile;
                    ShortCutKey = 'Ctrl+F11';
                    ToolTip = 'View the balances on bank accounts that are marked for reconciliation, usually liquid accounts. ';

                    trigger OnAction()
                    begin
                        GenJnlLine.Copy(Rec);
                        ManageSalesTaxJournal.CreateTempGenJnlLines(GenJnlLine, TempGenJnlLine);
                        GLReconcile.SetGenJnlLine(TempGenJnlLine);
                        GLReconcile.Run;
                    end;
                }
                action("Test Report")
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        GenJnlLine.Copy(Rec);
                        ManageSalesTaxJournal.CreateTempGenJnlLines(GenJnlLine, TempGenJnlLine);
                        ReportPrint.PrintGenJnlLine(TempGenJnlLine);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = SalesTax;
                    Caption = 'P&ost';
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Post Sales Tax Jnl", Rec);
                        CurrentJnlBatchName := GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Post- Print Sales Tax Jnl", Rec);
                        CurrentJnlBatchName := GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ShowShortcutDimCode(ShortcutDimCode);
        AfterGetCurrentRecord;
    end;

    trigger OnInit()
    begin
        TotalBalanceVisible := true;
        BalanceVisible := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateBalance;
        SetUpNewLine(xRec, Balance, BelowxRec);
        Clear(ShortcutDimCode);
        Clear(AccName);
        AfterGetCurrentRecord;
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
    begin
        BalAccName := '';
        OpenedFromBatch := ("Journal Batch Name" <> '') and ("Journal Template Name" = '');
        if OpenedFromBatch then begin
            CurrentJnlBatchName := "Journal Batch Name";
            GenJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
            exit;
        end;
        GenJnlManagement.TemplateSelection(PAGE::"Sales Tax Journal", 10, false, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        GenJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        GLReconcile: Page Reconciliation;
        ManageSalesTaxJournal: Codeunit "Manage Sales Tax Journal";
        GenJnlManagement: Codeunit GenJnlManagement;
        ReportPrint: Codeunit "Test Report-Print";
        CurrentJnlBatchName: Code[10];
        AccName: Text[100];
        BalAccName: Text[100];
        Balance: Decimal;
        TotalBalance: Decimal;
        ShowBalance: Boolean;
        ShowTotalBalance: Boolean;
        ShortcutDimCode: array[8] of Code[20];
        OpenedFromBatch: Boolean;
        Text002: Label '"GST/HST" can not be Acquisition in Sales Tax Journal Line.';
        [InDataSet]
        BalanceVisible: Boolean;
        [InDataSet]
        TotalBalanceVisible: Boolean;
        Text19039985: Label 'Account Name';

    local procedure UpdateBalance()
    begin
        GenJnlManagement.CalcBalance(Rec, xRec, Balance, TotalBalance, ShowBalance, ShowTotalBalance);
        BalanceVisible := ShowBalance;
        TotalBalanceVisible := ShowTotalBalance;
    end;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord;
        GenJnlManagement.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
        UpdateBalance;
    end;
}

