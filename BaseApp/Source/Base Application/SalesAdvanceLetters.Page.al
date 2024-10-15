#if not CLEAN19
page 31002 "Sales Advance Letters"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Sales Advance Letters (Obsolete)';
    CardPageID = "Sales Advance Letter";
    Editable = false;
    PageType = List;
    SourceTable = "Sales Advance Letter Header";
    UsageCategory = Lists;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Control1220011)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the sales advance letter.';
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of bill-to customer.';
                }
                field("Bill-to Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the stage during advance process.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                }
                field("Template Code"; Rec."Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an advance template code.';
                    Visible = false;
                }
                field("Amount To Link"; Rec."Amount To Link")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount not yet paid by customer.';
                    Visible = false;
                }
                field("Amount To Invoice"; Rec."Amount To Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the paid amount for advance VAT document.';
                    Visible = false;
                }
                field("Amount To Deduct"; Rec."Amount To Deduct")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum advance value for use in final sales invoice.';
                    Visible = false;
                }
                field("Document Linked Amount"; Rec."Document Linked Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document linked amount.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220028; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220027; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Letter")
            {
                Caption = '&Letter';
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View the statistics on the selected advance letter.';

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"Sales Adv. Letter Statistics", Rec);
                    end;
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'Specifies advance dimensions.';

                    trigger OnAction()
                    begin
                        ShowDocDim();
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Sales Comment Sheet";
                    RunPageLink = "No." = FIELD("No."),
                                  "Document Line No." = CONST(0),
                                  "Document Type" = CONST("Advance Letter");
                    ToolTip = 'Specifies advance comments.';
                }
                action("A&pprovals")
                {
                    ApplicationArea = Suite;
                    Caption = 'A&pprovals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OpenApprovalEntriesPage(RecordId);
                    end;
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                action("Assignment Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assignment Documents';
                    Image = Documents;
                    ToolTip = 'Conection to the sales document.';

                    trigger OnAction()
                    begin
                        ShowDocs();
                    end;
                }
                action("Assignment Documents - detail")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assignment Documents - detail';
                    Image = ViewDetails;
                    RunObject = Page "Advance Letter Line Relations";
                    RunPageLink = Type = CONST(Sale),
                                  "Letter No." = FIELD("No.");
                    RunPageView = SORTING(Type, "Letter No.", "Letter Line No.", "Document No.", "Document Line No.");
                    ToolTip = 'Conection to the sales document.';
                }
                action("Li&nked Advance Payments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Li&nked Advance Payments';
                    Image = Payment;
                    ToolTip = 'Show the advance payments by customer.';

                    trigger OnAction()
                    begin
                        ShowLinkedAdvances();
                    end;
                }
                action("Advance Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Advance Invoices';
                    Image = Invoice;
                    RunObject = Page "Posted Sales Invoices";
                    RunPageLink = "Letter No." = FIELD("No.");
                    RunPageView = SORTING("Letter No.");
                    ToolTip = 'Show advance invoice if they were posted.';
                }
                action("Advance Credi&t Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Advance Credi&t Memos';
                    Image = CreditMemo;
                    RunObject = Page "Posted Sales Credit Memos";
                    RunPageLink = "Letter No." = FIELD("No.");
                    RunPageView = SORTING("Letter No.");
                    ToolTip = 'Show advance credit memos if they were posted.';
                }
            }
        }
        area(processing)
        {
            group(Release)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action(Action1220023)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the sales advance to indicate that it has been printed or exported. The status then changes to Released.';

                    trigger OnAction()
                    begin
                        PerformManualRelease();
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have tha Released status and must be opened before they can be changed.';

                    trigger OnAction()
                    begin
                        PerformManualReopen();
                    end;
                }
            }
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action("Advance Letter")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Advance Letter';
                    Ellipsis = true;
                    Image = PrintReport;
                    ToolTip = 'Allows the print of advance letter.';

                    trigger OnAction()
                    begin
                        SalesAdvanceLetterHeader := Rec;
                        CurrPage.SetSelectionFilter(SalesAdvanceLetterHeader);
                        SalesAdvanceLetterHeader.PrintRecord(true);
                    end;
                }
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';
                Image = SendApprovalRequest;
                action(SendApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = NOT OpenApprovalEntriesExist;
                    Image = SendApprovalRequest;
                    ToolTip = 'Relations to the workflow.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckSalesAdvanceLetterApprovalsWorkflowEnabled(Rec) then
                            ApprovalsMgmt.OnSendSalesAdvanceLetterForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = OpenApprovalEntriesExist;
                    Image = CancelApprovalRequest;
                    ToolTip = 'Relations to the workflow.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OnCancelSalesAdvanceLetterApprovalRequest(Rec);
                    end;
                }
            }
        }
        area(reporting)
        {
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Action1220023_Promoted; Action1220023)
                {
                }
                actionref("Assignment Documents_Promoted"; "Assignment Documents")
                {
                }
                actionref("Li&nked Advance Payments_Promoted"; "Li&nked Advance Payments")
                {
                }
                actionref("Advance Invoices_Promoted"; "Advance Invoices")
                {
                }
                actionref("Advance Credi&t Memos_Promoted"; "Advance Credi&t Memos")
                {
                }
                actionref("Re&open_Promoted"; "Re&open")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Advance Letter_Promoted"; "Advance Letter")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Approve', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Category5)
            {
                Caption = 'Request Approval', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(SendApprovalRequest_Promoted; SendApprovalRequest)
                {
                }
                actionref(CancelApprovalRequest_Promoted; CancelApprovalRequest)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
        SetControlAppearance();
    end;

    trigger OnOpenPage()
    begin
        TemplateSelection();
        SetSecurityFilterOnRespCenter();
    end;

    var
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        OpenApprovalEntriesExist: Boolean;

    [Scope('OnPrem')]
    procedure TemplateSelection() Result: Boolean
    var
        SalesAdvPmtTemplate: Record "Sales Adv. Payment Template";
    begin
        SalesAdvPmtTemplate.Reset();
        case SalesAdvPmtTemplate.Count of
            0:
                exit(Result);
            1:
                Result := SalesAdvPmtTemplate.FindFirst();
            else begin
                    Result := PAGE.RunModal(PAGE::"Sales Advanced Paym. Selection", SalesAdvPmtTemplate) = ACTION::LookupOK;
                    if not Result then
                        Error('');
                end;
        end;

        if Result then begin
            SetCurrentKey("Template Code");
            FilterGroup := 2;
            SetRange("Template Code", SalesAdvPmtTemplate.Code);
            FilterGroup := 0;
        end;
    end;

    local procedure SetControlAppearance()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
    end;
}
#endif
