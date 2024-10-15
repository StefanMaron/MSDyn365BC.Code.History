#if not CLEAN20
page 10140 Deposit
{
    Caption = 'Deposit';
    DataCaptionExpression = FormCaption();
    PageType = Document;
    SourceTable = "Deposit Header";
    SourceTableView = SORTING("Journal Template Name", "Journal Batch Name");
    ObsoleteReason = 'Replaced by new Bank Deposits extension';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the deposit that you are creating.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the bank account number to which this deposit is being made.';
                }
                field("Total Deposit Amount"; Rec."Total Deposit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the Deposit. The sum of the amounts must equal this field value before you will be able to post this Deposit.';
                }
                field("Total Deposit Lines"; Rec."Total Deposit Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the amounts in the Amount fields on the associated deposit lines.';
                }
                field(Difference; GetDifference())
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Difference';
                    Editable = false;
                    ToolTip = 'Specifies the difference between the Amount field and the Cleared Amount field.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the Deposit should be posted. This should be the date that the Deposit is deposited in the bank.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the deposit document.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the dimension value code the deposit header will be associated with.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the dimension value code the deposit header will be associated with.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency that will be used for this Deposit.';
                }
            }
            part(Subform; "Deposit Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Journal Template Name" = FIELD("Journal Template Name"),
                              "Journal Batch Name" = FIELD("Journal Batch Name");
                UpdatePropagation = Both;
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
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
            group("&Deposit")
            {
                Caption = '&Deposit';
                action(Comments)
                {
                    ApplicationArea = Comments;
                    Caption = 'Comments';
                    Image = ViewComments;
                    RunObject = Page "Bank Comment Sheet";
                    RunPageLink = "Bank Account No." = FIELD("Bank Account No."),
                                  "No." = FIELD("No.");
                    RunPageView = WHERE("Table Name" = CONST(Deposit));
                    ToolTip = 'View deposit comments that apply.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDocDim();
                        CurrPage.SaveRecord();
                    end;
                }
                separator(Action1020018)
                {
                }
                action("Change &Batch")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change &Batch';
                    Image = ChangeBatch;
                    ToolTip = 'Edit the journal batch that the deposit is based on.';

                    trigger OnAction()
                    begin
                        CurrPage.SaveRecord();
                        GenJnlManagement.LookupName(CurrentJnlBatchName, GenJnlLine);
                        if "Journal Batch Name" <> CurrentJnlBatchName then begin
                            Clear(Rec);
                            SyncFormWithJournal();
                            OnChangeBatchActionOnAfterSyncFormWithJournal(GenJnlLine);
                        end;
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
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        DepositHeader.SetRange("No.", "No.");
                        REPORT.Run(REPORT::"Deposit Test Report", true, false, DepositHeader);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = Post;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Deposit-Post (Yes/No)", Rec);
                    end;
                }
                action(PostAndPrint)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Deposit-Post + Print", Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Post_Promoted; Post)
                {
                }
                actionref(PostAndPrint_Promoted; PostAndPrint)
                {
                }
                actionref("Test Report_Promoted"; "Test Report")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Deposit', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Comments_Promoted; Comments)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CalcFields("Total Deposit Lines");
    end;

    trigger OnOpenPage()
    begin
        CurrentJnlBatchName := Rec."Journal Batch Name";
        if Rec."Journal Template Name" <> '' then begin
            GenJnlLine.FilterGroup(2);
            GenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
            GenJnlLine.FilterGroup(0);
        end else begin
            GenJnlManagement.TemplateSelection(Page::Deposit, "Gen. Journal Template Type"::Deposits, false, GenJnlLine, JnlSelected);
            if not JnlSelected then
                Error('');
        end;
        if GenJnlLine.GetRangeMax("Journal Template Name") <> Rec."Journal Template Name" then
            CurrentJnlBatchName := '';
        GenJnlManagement.OpenJnl(CurrentJnlBatchName, GenJnlLine);
        SyncFormWithJournal();
    end;

    var
        DepositHeader: Record "Deposit Header";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlManagement: Codeunit GenJnlManagement;
        JnlSelected: Boolean;
        CurrentJnlBatchName: Code[10];

    local procedure GetDifference(): Decimal
    begin
        exit("Total Deposit Amount" - "Total Deposit Lines");
    end;

    local procedure SyncFormWithJournal()
    begin
        GenJnlLine.FilterGroup(2);
        FilterGroup(2);
        GenJnlLine.CopyFilter("Journal Template Name", "Journal Template Name");
        GenJnlLine.CopyFilter("Journal Batch Name", "Journal Batch Name");
        "Journal Template Name" := GetRangeMax("Journal Template Name");
        "Journal Batch Name" := GetRangeMax("Journal Batch Name");
        FilterGroup(0);
        GenJnlLine.FilterGroup(0);
        if not Find('-') then;
    end;

    local procedure FormCaption(): Text[80]
    begin
        if "No." = '' then
            exit(GetRangeMax("Journal Batch Name"));

        exit("No." + ' (' + "Journal Batch Name" + ')');
    end;

    [IntegrationEvent(true, false)]
    local procedure OnChangeBatchActionOnAfterSyncFormWithJournal(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;
}

#endif