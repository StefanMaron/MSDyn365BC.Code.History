#if not CLEAN20
page 36646 Deposits
{
    ApplicationArea = Basic, Suite;
    Caption = 'Deposits';
    CardPageID = Deposit;
    Editable = false;
    PageType = List;
    SourceTable = "Deposit Header";
    UsageCategory = Lists;
    ObsoleteReason = 'Replaced by new Bank Deposits extension';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the deposit that you are creating.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account number to which this deposit is being made.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the Deposit should be posted. This should be the date that the Deposit is deposited in the bank.';
                }
                field("Journal Batch Name"; "Journal Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the journal batch name from the general journal batch.';
                    Visible = false;
                }
                field("Total Deposit Amount"; "Total Deposit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the Deposit. The sum of the amounts must equal this field value before you will be able to post this Deposit.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the deposit document.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the dimension value code the deposit header will be associated with.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the dimension value code the deposit header will be associated with.';
                    Visible = false;
                }
                field("Posting Description"; "Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s document type and number (Deposit No. 1001, for example).';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency that will be used for this Deposit.';
                    Visible = false;
                }
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account''s language code from the Bank Account table.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(TestReport)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    var
                        DepositHeader: Record "Deposit Header";
                    begin
                        DepositHeader.SetRange("No.", "No.");
                        REPORT.Run(REPORT::"Deposit Test Report", true, false, DepositHeader);
                    end;
                }
                action("P&ost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Codeunit "Deposit-Post (Yes/No)";
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';
                }
                action("Post and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Codeunit "Deposit-Post + Print";
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';
                }
            }
        }
    }

    trigger OnInit()
    var
        BankDepositFeatureMgt: Codeunit "Bank Deposit Feature Mgt.";
        OpenDepositsPage: Codeunit "Open Deposits Page";
    begin
        if BankDepositFeatureMgt.IsEnabled() then begin
            OpenDepositsPage.Run();
            Error('Opening "Bank Deposits" instead.');
        end;
    end;
}

#endif