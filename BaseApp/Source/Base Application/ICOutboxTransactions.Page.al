page 611 "IC Outbox Transactions"
{
    ApplicationArea = Intercompany;
    Caption = 'Intercompany Outbox Transactions';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Functions,Outbox Transaction';
    SourceTable = "IC Outbox Transaction";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Control31)
            {
                ShowCaption = false;
                field(PartnerFilter; PartnerFilter)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Partner Filter';
                    ToolTip = 'Specifies how you want to filter the lines shown in the window. If the field is blank, the window will show the transactions for all of your intercompany partners. You can set a filter to determine the partner or partners whose transactions will be shown in the window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PartnerList: Page "IC Partner List";
                    begin
                        PartnerList.LookupMode(true);
                        if not (PartnerList.RunModal = ACTION::LookupOK) then
                            exit(false);
                        Text := PartnerList.GetSelectionFilter;
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        PartnerFilterOnAfterValidate;
                    end;
                }
                field(ShowLines; ShowLines)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Show Transaction Source';
                    OptionCaption = ' ,Rejected by Current Company,Created by Current Company';
                    ToolTip = 'Specifies how you want to filter the lines shown in the window. You can choose to see only new transactions that your intercompany partner(s) have created, only transactions that you created and your intercompany partner(s) returned to you, or both.';

                    trigger OnValidate()
                    begin
                        SetRange("Transaction Source");
                        case ShowLines of
                            ShowLines::"Rejected by Current Company":
                                SetRange("Transaction Source", "Transaction Source"::"Rejected by Current Company");
                            ShowLines::"Created by Current Company":
                                SetRange("Transaction Source", "Transaction Source"::"Created by Current Company");
                        end;
                        ShowLinesOnAfterValidate;
                    end;
                }
                field(ShowAction; ShowAction)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Show Line Action';
                    OptionCaption = 'All,No Action,Send to IC Partner,Return to Inbox,Create Correction Lines';
                    ToolTip = 'Specifies how you want to filter the lines shown in the window. You can choose to see all lines, or only lines with a specific option in the Line Action field.';

                    trigger OnValidate()
                    begin
                        SetRange("Line Action");
                        case ShowAction of
                            ShowAction::"No Action":
                                SetRange("Line Action", "Line Action"::"No Action");
                            ShowAction::"Send to IC Partner":
                                SetRange("Line Action", "Line Action"::"Send to IC Partner");
                            ShowAction::"Return to Inbox":
                                SetRange("Line Action", "Line Action"::"Return to Inbox");
                            ShowAction::Cancel:
                                SetRange("Line Action", "Line Action"::Cancel);
                        end;
                        ShowActionOnAfterValidate;
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Transaction No."; "Transaction No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the transaction''s entry number.';
                }
                field("IC Partner Code"; "IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies whether the transaction was created in a journal, a sales document or a purchase document.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Transaction Source"; "Transaction Source")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies which company created the transaction.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Line Action"; "Line Action")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies what happens to the transaction when you complete line actions. If the field contains No Action, the line will remain in the Outbox. If the field contains Send to IC Partner, the transaction will be sent to your intercompany partner''s inbox.';
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
            group("&Outbox Transaction")
            {
                Caption = '&Outbox Transaction';
                Image = Export;
                action(Details)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Details';
                    Image = View;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    ToolTip = 'View transaction details.';

                    trigger OnAction()
                    begin
                        ShowDetails;
                    end;
                }
                action(Comments)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Comments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "IC Comment Sheet";
                    RunPageLink = "Table Name" = CONST("IC Outbox Transaction"),
                                  "Transaction No." = FIELD("Transaction No."),
                                  "IC Partner Code" = FIELD("IC Partner Code"),
                                  "Transaction Source" = FIELD("Transaction Source");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                group("Set Line Action")
                {
                    Caption = 'Set Line Action';
                    Image = SelectLineToApply;
                    action("No Action")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'No Action';
                        Image = Cancel;
                        Promoted = true;
                        PromotedCategory = Category4;
                        PromotedOnly = true;
                        ToolTip = 'Set the Line Action field on the selected line to No Action, to indicate that the transaction will remain in the outbox.';

                        trigger OnAction()
                        begin
                            CurrPage.SetSelectionFilter(ICOutboxTransaction);
                            if ICOutboxTransaction.Find('-') then
                                repeat
                                    ICOutboxTransaction."Line Action" := ICOutboxTransaction."Line Action"::"No Action";
                                    ICOutboxTransaction.Modify();
                                until ICOutboxTransaction.Next = 0;
                        end;
                    }
                    action(SendToICPartner)
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Send to IC Partner';
                        Image = SendMail;
                        Promoted = true;
                        PromotedCategory = Category4;
                        PromotedOnly = true;
                        ToolTip = 'Set the Line Action field on the selected line to Send to IC Partner, to indicate that the transaction will be sent to the IC partner.';

                        trigger OnAction()
                        var
                            ICOutboxExport: Codeunit "IC Outbox Export";
                        begin
                            CurrPage.SetSelectionFilter(ICOutboxTransaction);
                            if ICOutboxTransaction.Find('-') then
                                repeat
                                    ICOutboxTransaction.Validate("Line Action", ICOutboxTransaction."Line Action"::"Send to IC Partner");
                                    ICOutboxTransaction.Modify();
                                until ICOutboxTransaction.Next = 0;
                            ICOutboxExport.RunOutboxTransactions(ICOutboxTransaction);
                        end;
                    }
                    action("Return to Inbox")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Return to Inbox';
                        Image = Return;
                        Promoted = true;
                        PromotedCategory = Category4;
                        PromotedOnly = true;
                        ToolTip = 'Set the Line Action field on the selected line to Return to Inbox, to indicate that the transaction will be sent back to the inbox for reevaluation.';

                        trigger OnAction()
                        var
                            ICOutboxExport: Codeunit "IC Outbox Export";
                        begin
                            CurrPage.SetSelectionFilter(ICOutboxTransaction);
                            if ICOutboxTransaction.Find('-') then
                                repeat
                                    TestField("Transaction Source", ICOutboxTransaction."Transaction Source"::"Rejected by Current Company");
                                    ICOutboxTransaction."Line Action" := ICOutboxTransaction."Line Action"::"Return to Inbox";
                                    ICOutboxTransaction.Modify();
                                until ICOutboxTransaction.Next = 0;
                            ICOutboxExport.RunOutboxTransactions(ICOutboxTransaction);
                        end;
                    }
                    action(Cancel)
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Cancel';
                        Image = Cancel;
                        Promoted = true;
                        PromotedCategory = Category4;
                        PromotedOnly = true;
                        ToolTip = 'Set the Line Action field on the selected line to Cancel, to indicate that the transaction will deleted from the outbox.';

                        trigger OnAction()
                        var
                            ICOutboxExport: Codeunit "IC Outbox Export";
                        begin
                            CurrPage.SetSelectionFilter(ICOutboxTransaction);
                            if ICOutboxTransaction.Find('-') then
                                repeat
                                    ICOutboxTransaction."Line Action" := ICOutboxTransaction."Line Action"::Cancel;
                                    ICOutboxTransaction.Modify();
                                until ICOutboxTransaction.Next = 0;
                            ICOutboxExport.RunOutboxTransactions(ICOutboxTransaction);
                        end;
                    }
                }
                separator(Action23)
                {
                }
                action("Complete Line Actions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Complete Line Actions';
                    Image = CompleteLine;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    RunObject = Codeunit "IC Outbox Export";
                    ToolTip = 'Complete the line with the action specified.';
                }
            }
        }
    }

    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        PartnerFilter: Code[250];
        ShowLines: Option " ","Rejected by Current Company","Created by Current Company";
        ShowAction: Option All,"No Action","Send to IC Partner","Return to Inbox",Cancel;

    local procedure ShowLinesOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure ShowActionOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure PartnerFilterOnAfterValidate()
    begin
        SetFilter("IC Partner Code", PartnerFilter);
        CurrPage.Update(false);
    end;
}

