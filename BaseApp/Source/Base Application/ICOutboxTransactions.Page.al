page 611 "IC Outbox Transactions"
{
    ApplicationArea = Intercompany;
    Caption = 'Intercompany Outbox Transactions';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
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
                        if not (PartnerList.RunModal() = ACTION::LookupOK) then
                            exit(false);
                        Text := PartnerList.GetSelectionFilter();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        PartnerFilterOnAfterValidate();
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
                        ShowLinesOnAfterValidate();
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
                        ShowActionOnAfterValidate();
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Transaction No."; Rec."Transaction No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the transaction''s entry number.';
                }
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies whether the transaction was created in a journal, a sales document or a purchase document.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Transaction Source"; Rec."Transaction Source")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies which company created the transaction.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Line Action"; Rec."Line Action")
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
                    ToolTip = 'View transaction details.';

                    trigger OnAction()
                    begin
                        ShowDetails();
                    end;
                }
                action(Comments)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Comments';
                    Image = ViewComments;
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
#if not CLEAN21
                group("Set Line Action")
                {
                    Caption = 'Set Line Action';
                    Image = SelectLineToApply;
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Not needed, will be removed.';
                    ObsoleteTag = '21.0';
                }
                separator(Action23)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Not needed, will be removed.';
                    ObsoleteTag = '21.0';
                }
# endif
                action("Complete Line Actions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Carry out Line Actions';
                    Image = CompleteLine;
                    RunObject = Codeunit "IC Outbox Export";
                    ToolTip = 'Carry out the actions that are specified on the lines.';
                }
            }
            group(LineActions)
            {
                Caption = 'Actions';
                Image = SelectLineToApply;

                action("No Action")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'No Action';
                    Image = Cancel;
                    Scope = Repeater;
                    ToolTip = 'Sets the Line Action to No action so that the selected entries stay in the outbox.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(ICOutboxTransaction);
                        if ICOutboxTransaction.FindSet() then
                            repeat
                                ICOutboxTransaction."Line Action" := ICOutboxTransaction."Line Action"::"No Action";
                                ICOutboxTransaction.Modify();
                            until ICOutboxTransaction.Next() = 0;
                    end;
                }
                action(SendToICPartner)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Send to IC Partner';
                    Image = SendMail;
                    Scope = Repeater;
                    ToolTip = 'Will send the selected entries to the IC Partners.';

                    trigger OnAction()
                    var
                        ICOutboxExport: Codeunit "IC Outbox Export";
                    begin
                        CurrPage.SetSelectionFilter(ICOutboxTransaction);
                        if ICOutboxTransaction.FindSet() then
                            repeat
                                ICOutboxTransaction.Validate("Line Action", ICOutboxTransaction."Line Action"::"Send to IC Partner");
                                ICOutboxTransaction.Modify();
                            until ICOutboxTransaction.Next() = 0;
                        ICOutboxExport.RunOutboxTransactions(ICOutboxTransaction);
                    end;
                }
                action("Return to Inbox")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Return to Inbox';
                    Image = Return;
                    Scope = Repeater;
                    ToolTip = 'Will send the selected entries back to the Inbox for reevaluation.';

                    trigger OnAction()
                    var
                        ICOutboxExport: Codeunit "IC Outbox Export";
                    begin
                        CurrPage.SetSelectionFilter(ICOutboxTransaction);
                        if ICOutboxTransaction.FindSet() then
                            repeat
                                TestField("Transaction Source", ICOutboxTransaction."Transaction Source"::"Rejected by Current Company");
                                ICOutboxTransaction."Line Action" := ICOutboxTransaction."Line Action"::"Return to Inbox";
                                ICOutboxTransaction.Modify();
                            until ICOutboxTransaction.Next() = 0;
                        ICOutboxExport.RunOutboxTransactions(ICOutboxTransaction);
                    end;
                }
                action(Cancel)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Cancel';
                    Image = Cancel;
                    Scope = Repeater;
                    ToolTip = 'Will delete the selected entries from the outbox.';

                    trigger OnAction()
                    var
                        ICOutboxExport: Codeunit "IC Outbox Export";
                    begin
                        CurrPage.SetSelectionFilter(ICOutboxTransaction);
                        if ICOutboxTransaction.FindSet() then
                            repeat
                                ICOutboxTransaction."Line Action" := ICOutboxTransaction."Line Action"::Cancel;
                                ICOutboxTransaction.Modify();
                            until ICOutboxTransaction.Next() = 0;
                        ICOutboxExport.RunOutboxTransactions(ICOutboxTransaction);
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
                Caption = 'Functions', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Complete Line Actions_Promoted"; "Complete Line Actions")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Outbox Transaction', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Details_Promoted; Details)
                {
                }
                actionref(Comments_Promoted; Comments)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Actions', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref("No Action_Promoted"; "No Action")
                {
                }
                actionref(SendToICPartner_Promoted; SendToICPartner)
                {
                }
                actionref("Return to Inbox_Promoted"; "Return to Inbox")
                {
                }
                actionref(Cancel_Promoted; Cancel)
                {
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

