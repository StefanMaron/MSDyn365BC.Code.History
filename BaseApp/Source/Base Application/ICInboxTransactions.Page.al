page 615 "IC Inbox Transactions"
{
    ApplicationArea = Intercompany;
    Caption = 'Intercompany Inbox Transactions';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Functions,Inbox Transaction';
    SourceTable = "IC Inbox Transaction";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Control25)
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
                    OptionCaption = ' ,Returned by Partner,Created by Partner';
                    ToolTip = 'Specifies how you want to filter the lines shown in the window. You can choose to see only new transactions that your intercompany partner(s) have created, only transactions that you created and your intercompany partner(s) returned to you, or both.';

                    trigger OnValidate()
                    begin
                        SetRange("Transaction Source");
                        case ShowLines of
                            ShowLines::"Returned by Partner":
                                SetRange("Transaction Source", "Transaction Source"::"Returned by Partner");
                            ShowLines::"Created by Partner":
                                SetRange("Transaction Source", "Transaction Source"::"Created by Partner");
                        end;
                        ShowLinesOnAfterValidate;
                    end;
                }
                field(ShowAction; ShowAction)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Show Line Action';
                    OptionCaption = 'All,No Action,Accept,Return to IC Partner';
                    ToolTip = 'Specifies how you want to filter the lines shown in the window. You can choose to see all lines, or only lines with a specific option in the Line Action field.';

                    trigger OnValidate()
                    begin
                        SetRange("Line Action");
                        case ShowAction of
                            ShowAction::"No Action":
                                SetRange("Line Action", "Line Action"::"No Action");
                            ShowAction::Accept:
                                SetRange("Line Action", "Line Action"::Accept);
                            ShowAction::"Return to IC Partner":
                                SetRange("Line Action", "Line Action"::"Return to IC Partner");
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
                    ToolTip = 'Specifies whether the transaction was created in a journal, a sales document, or a purchase document.';
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
                    ToolTip = 'Specifies what action is taken for the line when you choose the Complete Line Actions action.';
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
            group("&Inbox Transaction")
            {
                Caption = '&Inbox Transaction';
                Image = Import;
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
                    RunPageLink = "Table Name" = CONST("IC Inbox Transaction"),
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
                        ToolTip = 'Set the Line Action field on the selected line to No Action, to indicate that the transaction will remain in the inbox.';

                        trigger OnAction()
                        begin
                            CurrPage.SetSelectionFilter(ICInboxTransaction);
                            if ICInboxTransaction.Find('-') then
                                repeat
                                    ICInboxTransaction."Line Action" := ICInboxTransaction."Line Action"::"No Action";
                                    ICInboxTransaction.Modify();
                                until ICInboxTransaction.Next = 0;
                        end;
                    }
                    action(Accept)
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Accept';
                        Image = Approve;
                        Promoted = true;
                        PromotedCategory = Category4;
                        PromotedOnly = true;
                        ToolTip = 'Set line action to Accept. If the field contains Accept, the transaction will be transferred to a document or journal (the program will ask you to specify the journal batch and template).';

                        trigger OnAction()
                        var
                            ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
                        begin
                            CurrPage.SetSelectionFilter(ICInboxTransaction);
                            if ICInboxTransaction.Find('-') then
                                repeat
                                    TestField("Transaction Source", ICInboxTransaction."Transaction Source"::"Created by Partner");
                                    ICInboxTransaction.Validate("Line Action", ICInboxTransaction."Line Action"::Accept);
                                    ICInboxTransaction.Modify();
                                until ICInboxTransaction.Next = 0;

                            if ApplicationAreaMgmtFacade.IsFoundationEnabled then
                                RunInboxTransactions(ICInboxTransaction);
                        end;
                    }
                    action("Return to IC Partner")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Return to IC Partner';
                        Image = Return;
                        Promoted = true;
                        PromotedCategory = Category4;
                        PromotedOnly = true;
                        ToolTip = 'Set line action to Return to IC Partner. If the field contains Return to IC Partner, the transaction will be moved to the outbox.';

                        trigger OnAction()
                        var
                            ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
                        begin
                            CurrPage.SetSelectionFilter(ICInboxTransaction);
                            if ICInboxTransaction.Find('-') then
                                repeat
                                    TestField("Transaction Source", ICInboxTransaction."Transaction Source"::"Created by Partner");
                                    ICInboxTransaction."Line Action" := ICInboxTransaction."Line Action"::"Return to IC Partner";
                                    ICInboxTransaction.Modify();
                                until ICInboxTransaction.Next = 0;

                            if ApplicationAreaMgmtFacade.IsFoundationEnabled then
                                RunInboxTransactions(ICInboxTransaction);
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
                        ToolTip = 'Set the Line Action field on the selected line to Cancel, to indicate that the transaction will deleted from the inbox.';

                        trigger OnAction()
                        var
                            ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
                        begin
                            CurrPage.SetSelectionFilter(ICInboxTransaction);
                            if ICInboxTransaction.Find('-') then
                                repeat
                                    ICInboxTransaction."Line Action" := ICInboxTransaction."Line Action"::Cancel;
                                    ICInboxTransaction.Modify();
                                until ICInboxTransaction.Next = 0;

                            if ApplicationAreaMgmtFacade.IsFoundationEnabled then
                                RunInboxTransactions(ICInboxTransaction);
                        end;
                    }
                }
                separator(Action38)
                {
                }
                action("Complete Line Actions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Complete Line Actions';
                    Ellipsis = true;
                    Image = CompleteLine;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'Carry out the actions that are specified on the lines.';

                    trigger OnAction()
                    begin
                        RunInboxTransactions(Rec);
                    end;
                }
                separator(Action9)
                {
                }
                action("Import Transaction File")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Import Transaction File';
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    RunObject = Codeunit "IC Inbox Import";
                    RunPageOnRec = true;
                    ToolTip = 'Import a file to create the transaction with.';
                }
            }
        }
    }

    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        PartnerFilter: Code[250];
        ShowLines: Option " ","Returned by Partner","Created by Partner";
        ShowAction: Option All,"No Action",Accept,"Return to IC Partner",Cancel;

    local procedure PartnerFilterOnAfterValidate()
    begin
        SetFilter("IC Partner Code", PartnerFilter);
        CurrPage.Update(false);
    end;

    local procedure ShowLinesOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure ShowActionOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    procedure RunInboxTransactions(var ICInboxTransaction: Record "IC Inbox Transaction")
    var
        ICInboxTransactionCopy: Record "IC Inbox Transaction";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        RunReport: Boolean;
    begin
        if ApplicationAreaMgmtFacade.IsFoundationEnabled then
            RunReport := false
        else
            RunReport := true;

        ICInboxTransactionCopy.Copy(ICInboxTransaction);
        ICInboxTransactionCopy.SetRange("Source Type", ICInboxTransactionCopy."Source Type"::Journal);

        if not ICInboxTransactionCopy.IsEmpty then
            RunReport := true;

        Commit();
        REPORT.RunModal(REPORT::"Complete IC Inbox Action", RunReport, false, ICInboxTransaction);
        CurrPage.Update(true);
    end;
}

